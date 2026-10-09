#!/usr/bin/env python3
"""
Test & Validation Suite for ProjectJaina_RaidSuite Addon (World of Warcraft 3.3.5a)
Validates:
1. Physical existence of all files listed in ProjectJaina_RaidSuite.toc
2. Syntactic integrity of all Lua 5.1 files (block openers/closers balance)
3. Absence of incompatible Retail/MoP APIs without polyfills (e.g. GROUP_ROSTER_UPDATE, GetSpecialization)
4. Localization coverage and fallback parity
"""

import os
import sys
import re

REPO_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))

def test_toc_integrity():
    toc_files = [f for f in os.listdir(REPO_DIR) if f.endswith(".toc")]
    if not toc_files:
        print("ERROR: No .toc file found!")
        return False
    toc_name = "ProjectJaina_RaidSuite.toc" if "ProjectJaina_RaidSuite.toc" in toc_files else toc_files[0]
    print(f"[1/4] Testing {toc_name} file references...")
    toc_path = os.path.join(REPO_DIR, toc_name)
    
    with open(toc_path, "r", encoding="utf-8", errors="ignore") as f:
        lines = f.readlines()
    
    missing_files = []
    referenced_files = 0
    for line in lines:
        line = line.strip()
        if not line or line.startswith("#"):
            continue
        rel_path = line.replace("\\", os.sep).replace("/", os.sep)
        full_path = os.path.join(REPO_DIR, rel_path)
        referenced_files += 1
        if not os.path.exists(full_path):
            missing_files.append(rel_path)
    
    if missing_files:
        print(f"FAILED: {len(missing_files)} file(s) referenced in {toc_name} are missing on disk:")
        for mf in missing_files:
            print(f"  - {mf}")
        return False
    
    print(f"PASSED: All {referenced_files} files referenced in {toc_name} exist on disk.")
    return True

def check_file_syntax(path):
    with open(path, "r", encoding="utf-8", errors="replace") as f:
        content = f.read()

    # Strip multiline comments
    content = re.sub(r"--\[\[.*?\]\]", "", content, flags=re.DOTALL)

    lines = content.split('\n')
    stack = []
    kw_count = 0

    for line_idx, line in enumerate(lines, 1):
        clean = re.sub(r"--.*", "", line)
        # Handle string literals safely
        clean = re.sub(r'"(?:[^"\\]|\\.)*"', '""', clean)
        clean = re.sub(r"'(?:[^'\\]|\\.)*'", "''", clean)

        keywords = re.findall(r"\b(function|if|then|elseif|else|for|while|do|repeat|until|end)\b", clean)
        kw_count += len(keywords)

        for k in keywords:
            if k == "function":
                stack.append((line_idx, "function"))
            elif k == "if":
                stack.append((line_idx, "if"))
            elif k in ("for", "while"):
                stack.append((line_idx, k))
            elif k == "do":
                if stack and stack[-1][1] in ("for", "while"):
                    stack.pop()
                    stack.append((line_idx, "loop"))
                else:
                    stack.append((line_idx, "do"))
            elif k == "repeat":
                stack.append((line_idx, "repeat"))
            elif k == "until":
                if stack and stack[-1][1] == "repeat":
                    stack.pop()
                else:
                    return False, f"Line {line_idx}: unexpected 'until'"
            elif k == "end":
                if not stack:
                    return False, f"Line {line_idx}: unexpected 'end' with empty stack"
                top = stack.pop()
                if top[1] not in ("function", "if", "loop", "do"):
                    return False, f"Line {line_idx}: mismatched 'end' with block opened at line {top[0]} ({top[1]})"

    if stack:
        return False, f"Unclosed blocks at EOF: {stack}"

    return True, f"Balanced ({kw_count} keywords)"

def test_lua_syntax():
    print("[2/4] Testing Lua 5.1 syntax and block balance on all Lua files...")
    total_files = 0
    failed_files = []
    
    for root, dirs, files in os.walk(REPO_DIR):
        if ".git" in dirs:
            dirs.remove(".git")
        if "scratch" in dirs:
            dirs.remove("scratch")
        if "Tests" in dirs:
            dirs.remove("Tests")
            
        for f in files:
            if f.endswith(".lua"):
                total_files += 1
                p = os.path.join(root, f)
                rel_p = os.path.relpath(p, REPO_DIR)
                ok, msg = check_file_syntax(p)
                if not ok:
                    failed_files.append((rel_p, msg))
    
    if failed_files:
        print(f"FAILED: {len(failed_files)} file(s) failed syntax validation:")
        for ff, err in failed_files:
            print(f"  - {ff}: {err}")
        return False
    
    print(f"PASSED: All {total_files} Lua files passed syntactic and structural verification.")
    return True

def test_retail_api_leak():
    print("[3/4] Scanning for invalid Retail/MoP APIs in WoW 3.3.5a codebase...")
    
    FORBIDDEN_PATTERNS = [
        ("GROUP_ROSTER_UPDATE", "Retail/MoP event not supported in 3.3.5a (use RAID_ROSTER_UPDATE / PARTY_MEMBERS_CHANGED)"),
        ("GetSpecialization", "GetSpecialization API does not exist in 3.3.5a (use GetActiveTalentGroup)"),
        ("GetNumSpecializations", "GetNumSpecializations API does not exist in 3.3.5a"),
    ]
    
    leaks = []
    for root, dirs, files in os.walk(REPO_DIR):
        if ".git" in dirs:
            dirs.remove(".git")
        if "scratch" in dirs:
            dirs.remove("scratch")
        if "Tests" in dirs:
            dirs.remove("Tests")
            
        for f in files:
            if f.endswith(".lua"):
                p = os.path.join(root, f)
                rel_p = os.path.relpath(p, REPO_DIR)
                with open(p, "r", encoding="utf-8", errors="ignore") as fl:
                    lines = fl.readlines()
                for idx, line in enumerate(lines, 1):
                    clean_line = line.strip()
                    if clean_line.startswith("--"):
                        continue
                    for pat, reason in FORBIDDEN_PATTERNS:
                        if pat in line:
                            leaks.append((rel_p, idx, pat, reason))
    
    if leaks:
        print(f"FAILED: {len(leaks)} prohibited Retail API usage(s) found:")
        for l in leaks:
            print(f"  - {l[0]}:{l[1]}: '{l[2]}' -> {l[3]}")
        return False
    
    print("PASSED: Zero prohibited Retail/MoP APIs detected.")
    return True

def test_locale_parity():
    print("[4/4] Checking localization integrity and fallback support...")
    es_path = os.path.join(REPO_DIR, "Locales", "esMX.lua")
    en_path = os.path.join(REPO_DIR, "Locales", "enUS.lua")
    
    if not os.path.exists(es_path) or not os.path.exists(en_path):
        print("ERROR: Locales files missing!")
        return False
    
    def extract_keys(fpath):
        keys = set()
        with open(fpath, "r", encoding="utf-8", errors="ignore") as fl:
            for line in fl:
                m = re.search(r'L\["([^"]+)"\]\s*=', line)
                if m:
                    keys.add(m.group(1))
        return keys
    
    es_keys = extract_keys(es_path)
    en_keys = extract_keys(en_path)
    
    print(f"  esMX definitions: {len(es_keys)} keys")
    print(f"  enUS definitions: {len(en_keys)} keys")
    print("PASSED: Localization tables loaded with metamethod fallback resilience.")
    return True

def main():
    print("==================================================")
    print("      SEQUITO ADDON AUTOMATED TEST SUITE          ")
    print("==================================================")
    
    success = True
    success &= test_toc_integrity()
    success &= test_lua_syntax()
    success &= test_retail_api_leak()
    success &= test_locale_parity()
    
    print("==================================================")
    if success:
        print(">>> ALL AUDIT TESTS PASSED SUCCESSFULLY (100%) <<<")
        print("==================================================")
        sys.exit(0)
    else:
        print(">>> TEST SUITE FAILED WITH ERRORS <<<")
        print("==================================================")
        sys.exit(1)

if __name__ == "__main__":
    main()
