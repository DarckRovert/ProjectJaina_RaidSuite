--[[
    ProjectJaina_RaidSuite — Suite Definitiva de Combate y Raids
    Universal Sphere & Raid Management UI for WotLK 3.3.5a
    
    Addon universal para TODAS las clases del Project Jaina.
    - Reconocimiento de clase/raza
    - Generacion de macros personalizadas
    - Sincronizacion de raid (hasta 40 jugadores)
    - Datos estrategicos en tiempo real
    
    NOTA: La tabla global `Jaina` se mantiene intencionalmente para
    garantizar compatibilidad con todos los modulos internos y los
    SavedVariables existentes de los jugadores (JainaDB, etc.).
    
    Copyright (c) 2026 DarckRovert (Ingame: Elnazzareno) & Project Jaina Team
]]--

-- Namespace principal del addon
local addonName, S = ...
_G.Jaina = S -- Tabla global interna (nombre legacy mantenido por compatibilidad)

-- Version
S.Version = "11.2.1"
S.Build = "Ecosystem Edition"

-- C_Timer polyfill is in Core/Constants.lua (loads first via TOC)


-- WotLK Group API Polyfills
if not IsInRaid then
    function IsInRaid()
        return GetNumRaidMembers() > 0
    end
end

if not IsInGroup then
    function IsInGroup()
        return GetNumRaidMembers() > 0 or GetNumPartyMembers() > 0
    end
end

-- Addon Message wrapper for modules
function S:SendAddonMessage(prefix, message, channel, target)
    if RegisterAddonMessagePrefix then
        RegisterAddonMessagePrefix(prefix)
    end
    SendAddonMessage(prefix, message, channel, target)
end

-- Database Defaults
S.defaults = {
    profile = {
        Enabled = true, -- Master switch
        Scale = 1.0,
        Alpha = 1.0,
        Position = {point = "CENTER", relativeTo = "UIParent", relativePoint = "CENTER", x = 0, y = 0},
        Locked = false,
        Language = "esMX",
        ShowWelcome = true,
        Debug = false,
        ShowMinimap = true,
        ShowTooltips = true,
        
        -- Sphere
        ShowSphere = true,
        SphereScale = 1.0,
        SphereText = true,
        SpherePercent = true,
        
        -- Raid Panel
        ShowRaidPanel = true,
        RaidPanelScale = 1.0,
        RaidPanelHP = true,
        RaidPanelRoles = true,
        RaidPanelAuto = false,
        RaidPanelSort = "class",

        -- Features
        ShowSpeech = true,
        RaidSync = true,
        SyncAnnounce = true,
        ShowAlerts = true,
        AlertSound = true,
        AlertFlash = true,
        AlertCombatOnly = true,
        AlertLowHP = true,
        AlertBuffs = true,
        AlertCDs = true,
        AlertRaid = true,
        
        -- Logistics
        AutoRepair = true,
        AutoSell = true,
        AutoTrade = true,
        ShardLimit = 28,
        -- Menu Toggles
        ShowRunes = true,
        ShowMounts = true,
        AutoMacros = true,
        MacroConfirm = true,
        DeathSound = true, -- Added
        RadialEnabled = true, -- Radial Menu
        SummonAssistant = true, -- Coven Summon Queue
        SoulstoneTracker = true,
        SoulstoneAlerts = true,
        AudioFX = true,
    }
}

-- Core Event Frame
S.Core = CreateFrame("Frame")
S.Core:RegisterEvent("ADDON_LOADED")
S.Core:RegisterEvent("PLAYER_LOGIN")
S.Core:RegisterEvent("PLAYER_ENTERING_WORLD")

S.Core:SetScript("OnEvent", function(self, event, ...)
    if event == "ADDON_LOADED" and ... == addonName then
        S:OnInitialize()
    elseif event == "PLAYER_LOGIN" then
        S:OnEnable()
    elseif event == "PLAYER_ENTERING_WORLD" then
        S:OnEnterWorld()
    end
end)

function S:OnInitialize()
    -- Initialize Database safely
    if not JainaDB then JainaDB = {} end
    
    -- v10.2.0 Profile System
    if S.ProfileManager then
        S.ProfileManager:Initialize()
        -- S.db is now set by ProfileManager
    else
        -- Fallback for safety (should not happen if ProfileManager is loaded)
        self.db = JainaDB
        if not self.db.profile then self.db.profile = {} end
    end

    -- Merge defaults if needed (now handled by ProfileManager logic mostly, but keep for safety)
    if self.db and self.db.profile then
        for k, v in pairs(S.defaults.profile) do
            if self.db.profile[k] == nil then
                self.db.profile[k] = v
            end
        end
    end
    
    -- Mensaje de carga
    print(string.format("|cFFFF00FFJaina|r v%s |cFF888888%s|r cargando...", self.Version, self.Build))
end

function S:OnEnable()
    -- 0. Inicializar ModuleConfig PRIMERO (Configuración crítica)
    if S.ModuleConfig and S.ModuleConfig.Initialize then S.ModuleConfig:Initialize() end

    -- 0.5. Inicializar Theme (Antes de cualquier UI)
    if S.Theme and S.Theme.Initialize then S.Theme:Initialize() end

    -- 3. Inicializar Dashboard (Contenedor UI)
    if S.Dashboard and S.Dashboard.Initialize then 
        S.Dashboard:Initialize() 
    end

    -- 4. Inicializar Options (Configuración) - NECESARIO para registrar tab
    if S.Options and S.Options.Initialize then
        S.Options:Initialize()
    end
    

    
    -- 2. Inicializar GUI (Esfera) - Ahora seguro porque ModuleConfig está listo
    if S.GUI and S.GUI.Initialize then
        print("|cFF00FFFFJaina|r: Creando Interfaz...")
        S.GUI:Initialize()
    else
        print("|cFFFF0000Jaina Error|r: Modulo GUI no encontrado.")
    end
    
    -- 3. Generar Macros (Silencioso en arranque)
    if S.MacroGen then
        S.MacroGen:GenerateClassMacros(true)
    end
    
    -- Inicializar otros modulos

    
    -- RaidAssist (Nuevo)

    
    -- MacroSync (Sistema de macros compartidos)


    -- v8.0.0 Sistema Automático


    -- v8.0.0 Modules Initialization
    local modules = {
        "Theme", -- Initialize Theme early
        "Universal", "CooldownMonitor", "Assignments", "ReadyChecker", "TrinketTracker", 
        "WipeAnalyzer", "FocusFire", "CCCoordinator", "HealerTracker", 
        "DefensiveAlerts", "PullGuide", "DungeonTimer", "LootCouncil", 
        "PlayerNotes", "BuildManager", "EventCalendar", "PerformanceStats", 
        "VotingSystem", "VersionSync", "QuickWhisper", "Trade", "Audio",
        -- v9.0 Definitive Edition Modules
        "AcademyInspector", "AcademyRotation", "Achievements",
        "Performance", "LootGallery",
        -- v10.0 Warlock & Class Modules
        "Coven", "Soulstones", "DoTTracker", "CCTracker", "PetManager", "Mounts", "Visuals",
        -- v10.0 GUI & Misc
        "MinimapButton", "Coach", "Radial", "Overlord",
        -- Missing Core/Utility Connections
        "MacroSync", "RaidSync", "RaidAssist", "SoulEngine", "Logistics", "RaidIntel", "Connect", "RaidCmd",
        -- PvP & Class Extras
        "Spy", "Runes", "SpecWatcher",
        -- Smart Coach UI & Automation
        "RaidPanel", "RaidAssistUI", "JainaPlates", "CombatTracker",
        "AutoSync", "ContextEngine", "SmartDefaults",
        -- Ecosistema Project Jaina (debe iniciar tras ContextEngine)
        "EcosystemBridge"
    }

    local _, playerClass = UnitClass("player")
    local classRestrictions = {
        Coven = "WARLOCK",
        Soulstones = "WARLOCK",
        DoTTracker = "WARLOCK",
        Runes = "DEATHKNIGHT",
    }

    for _, moduleName in ipairs(modules) do
        local requiredClass = classRestrictions[moduleName]
        if requiredClass and requiredClass ~= playerClass then
            -- Skip module not applicable to current class (memory & CPU saving)
        elseif S[moduleName] and S[moduleName].Initialize then
            local status, err = pcall(function() S[moduleName]:Initialize() end)
            if not status then
                print("|cFFFF0000Jaina Error|r: Fallo al iniciar modulo " .. moduleName .. ": " .. tostring(err))
            end
        end
    end
    
    -- Reporte Final
    if S.Sphere and S.Sphere:IsVisible() then
        -- Sphere OK
    else
        -- Auto-fix position silently
        if S.Sphere then
            S.Sphere:ClearAllPoints()
            S.Sphere:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
            S.Sphere:Show()
            print("|cFF00FF00Jaina|r: Posicion de esfera restaurada.")
        end
    end
    
    print("|cFFFF00FFJaina|r: Sistema listo. (/jaina help)")
    if S.db.profile.ShowSpeech then
        PlaySoundFile("Sound\\Creature\\HeadlessHorseman\\Horseman_Laugh_01.wav")
    end
end

function S:OnEnterWorld()
    -- Re-check UI
    if S.GUI and not S.Sphere then
        S.GUI:Initialize()
    end
    -- Aplicar adaptaciones del ecosistema segun modo de juego del personaje
    if S.EcosystemBridge and S.EcosystemBridge.ApplyGameModeAdaptations then
        S.EcosystemBridge:ApplyGameModeAdaptations()
    end
end

-- ===========================================================================
-- SLASH COMMANDS
-- ===========================================================================
SLASH_JAINA_RAIDSUITE1 = "/jaina"
SLASH_JAINA_RAIDSUITE2 = "/raidsuite"
SLASH_JAINA_RAIDSUITE3 = "/pjrs"
SLASH_JAINA_RAIDSUITE4 = "/jaina"
SLASH_JAINA_RAIDSUITE5 = "/seq"

SlashCmdList["JAINA_RAIDSUITE"] = function(msg)
    local cmd, arg = strsplit(" ", msg, 2)
    cmd = cmd:lower()
    
    if cmd == "" then
        if S.Options then
            S.Options:Toggle()
        else
            S:PrintHelp()
        end
    elseif cmd == "help" then
        S:PrintHelp()
    elseif cmd == "macros" then
        if S.MacroGen then
            S.MacroGen.forceSync = true
            S.MacroGen:GenerateClassMacros(false)
        end
    elseif cmd == "raid" or cmd == "comp" then
        if S.RaidSync then
            S.RaidSync:PrintRaidComposition()
        end
    elseif cmd == "buffs" or cmd == "scan" then
        if S.RaidIntel then
            S.RaidIntel:PrintBuffReport()
        end
    elseif cmd == "focus" then
        if S.RaidSync then
            S.RaidSync:SendFocus(arg)
        end
    elseif cmd == "alpha" then
        if S.RaidSync then
            S.RaidSync:SendAlphaStrike()
        end
    elseif cmd == "class" or cmd == "classes" then
        if S.RaidIntel then
            S.RaidIntel:PrintClassCount()
        end
    elseif cmd == "info" then
        S:PrintPlayerInfo()
    elseif cmd == "panel" or cmd == "raidpanel" then
        if S.RaidPanel then
            S.RaidPanel:Toggle()
        end
    elseif cmd == "options" or cmd == "config" or cmd == "opciones" then
        if S.Dashboard then
            S.Dashboard:Toggle()
        else
            if S.Options then S.Options:Toggle() end
        end
    elseif cmd == "report" or cmd == "reporte" or cmd == "connect" then
        if S.Connect then
            S.Connect:GenerateReport()
        end
    elseif cmd == "combat" or cmd == "dps" then
        if S.CombatTracker then
            S.CombatTracker:PrintSummary()
        end
    elseif cmd == "combatclear" or cmd == "clearhistory" then
        if S.CombatTracker then
            S.CombatTracker:ClearHistory()
        end
    elseif cmd == "spec" then
        if S.SpecWatcher then
            local info = S.SpecWatcher:GetInfo()
            print("|cFFFF00FF=== Jaina: Especializacion ===")
            print(string.format("Clase: |cFFFFFFFF%s|r", info.class))
            print(string.format("Spec: |cFFFFFFFF%s|r (Arbol %d)", info.specName, info.spec))
            print(string.format("Grupo de Talentos: |cFFFFFFFF%d|r", info.talentGroup))
            print(string.format("Auto-update macros: |cFFFFFFFF%s|r", info.autoUpdate and "Si" or "No"))
        end
    elseif cmd == "specauto" or cmd == "autospec" then
        if S.SpecWatcher then
            local current = S.SpecWatcher:GetInfo().autoUpdate
            S.SpecWatcher:SetAutoUpdate(not current)
        end
    elseif cmd == "lock" then
        S.db.profile.Locked = not S.db.profile.Locked
        print("|cFFFF00FFJaina|r: Posicion " .. (S.db.profile.Locked and "bloqueada" or "desbloqueada"))
    elseif cmd == "reset" or cmd == "resetpos" then
        S.db.profile.Position = S.defaults.profile.Position
        if S.Sphere then
            S.Sphere:ClearAllPoints()
            S.Sphere:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
        end
        print("|cFFFF00FFJaina|r: Posicion reiniciada.")
    elseif cmd == "mounts" or cmd == "monturas" then
        if S.Mounts then
            S.Mounts:ListMounts()
        end
    elseif cmd == "setflying" then
        if S.Mounts and arg then
            S.Mounts:SetFavorite("flying", arg)
        end
    elseif cmd == "setground" then
        if S.Mounts and arg then
            S.Mounts:SetFavorite("ground", arg)
        end
    elseif cmd == "setaquatic" then
        if S.Mounts and arg then
            S.Mounts:SetFavorite("aquatic", arg)
        end
    elseif cmd == "ra" or cmd == "raidassist" then
        if S.RaidAssistUI then
            S.RaidAssistUI:Toggle()
        end
    elseif cmd == "raleader" then
        if S.RaidAssistUI then
            S.RaidAssistUI:ToggleLeaderPanel()
        end
    elseif cmd == "pull" then
        local seconds = tonumber(arg) or 10
        if S.RaidAssist then
            S.RaidAssist:StartPullTimer(seconds)
        end
    elseif cmd == "phase" then
        if S.RaidAssist and arg then
            S.RaidAssist:AnnouncePhase(arg)
        end
    elseif cmd == "checkbuffs" or cmd == "checkcons" then
        if S.RaidAssist then
            S.RaidAssist:CheckConsumables()
            local report = S.RaidAssist:GetConsumableReport()
            S:Print("=== Reporte de Consumibles ===")
            S:Print(report)
        end
    elseif cmd == "wipes" then
        if S.RaidAssist then
            S:Print("Wipes en esta sesión: " .. S.RaidAssist.wipeCount)
        end
    elseif cmd == "resetwipes" then
        if S.RaidAssist then
            S.RaidAssist:ResetWipeCounter()
            S:Print("Contador de wipes reiniciado")
        end
    elseif cmd == "mode" then
        if S.RaidAssist then
            local newMode = arg and arg:upper() or (S.RaidAssist.mode == "FARM" and "PROGRESSION" or "FARM")
            S.RaidAssist:SetMode(newMode)
        end
    elseif cmd == "wipehistory" or cmd == "wipestats" then
        if S.RaidAssist then
            S.RaidAssist:PrintWipeHistory()
        end
    elseif cmd == "clearwipes" then
        if S.RaidAssist then
            S.RaidAssist:ClearWipeHistory()
        end
    elseif cmd == "alert" then
        if S.RaidAssist and arg then
            S.RaidAssist:ShowAlert(arg, "INFO", 5)
        end
    elseif cmd == "alertpos" then
        if S.RaidAssist and arg then
            local pos = arg:upper()
            if pos == "TOP" or pos == "CENTER" or pos == "BOTTOM" then
                S.RaidAssist:SetAlertPosition(pos)
                S:Print("Posici\195\179n de alertas: " .. pos)
            end
        end
    -- Spy Commands (PvP)
    elseif cmd == "spy" then
        if S.Spy then
            S.Spy:Toggle()
        else
            S:Print("Modulo Spy no cargado.")
        end
    -- Overlord Commands
    elseif cmd == "overlord" or cmd == "hud" then
        if S.ModuleConfig then
            S.ModuleConfig:OpenCategory("Overlord")
        end
        
    -- TrinketTracker Commands (PvP)
    elseif cmd == "trinkets" or cmd == "tt" then
        if S.TrinketTracker then
            local subcmd = arg and arg:lower() or ""
            if subcmd == "clear" then
                S.TrinketTracker:ClearAll()
            elseif subcmd == "announce" then
                S.TrinketTracker:AnnounceAll()
            else
                S.TrinketTracker:Toggle()
            end
        end
    -- WipeAnalyzer Commands (PvE)
    elseif cmd == "analyze" or cmd == "wa" then
        if S.WipeAnalyzer then
            local subcmd = arg and arg:lower() or ""
            if subcmd == "announce" then
                S.WipeAnalyzer:AnnounceAnalysis()
            elseif subcmd == "clear" then
                S.WipeAnalyzer:ClearCurrent()
            elseif subcmd == "history" then
                S.WipeAnalyzer:ShowHistory()
            else
                S.WipeAnalyzer:Analyze()
            end
        end
    -- CooldownMonitor Commands
    elseif cmd == "cooldowns" or cmd == "cd" then
        if S.CooldownMonitor then
            local subcmd = arg and arg:lower() or ""
            if subcmd == "bres" then
                S.CooldownMonitor:AnnounceAvailable("bres")
            elseif subcmd == "lust" then
                S.CooldownMonitor:AnnounceAvailable("lust")
            elseif subcmd == "raid" then
                S.CooldownMonitor:AnnounceAvailable("raid_cd")
            elseif subcmd == "external" then
                S.CooldownMonitor:AnnounceAvailable("external")
            else
                S.CooldownMonitor:Toggle()
            end
        end
    -- Assignments Commands
    elseif cmd == "assign" or cmd == "as" then
        if S.Assignments then
            local subcmd = arg and arg:lower() or ""
            if subcmd == "interrupts" then
                S.Assignments:AutoAssignInterrupts()
            elseif subcmd == "announce" then
                S.Assignments:AnnounceAll()
            elseif subcmd == "clear" then
                S.Assignments:ClearAll()
            elseif subcmd == "sync" then
                S.Assignments:SyncToRaid()
            else
                S.Assignments:Toggle()
            end
        end
    -- Pull Timer Command
    elseif cmd == "pull" then
        if S.Assignments then
            S.Assignments:StartPullTimer(tonumber(arg) or 10)
        end
    -- ReadyChecker Commands
    elseif cmd == "readycheck" or cmd == "rc" or cmd == "ready" then
        if S.ReadyChecker then
            local subcmd = arg and arg:lower() or ""
            if subcmd == "full" then
                S.ReadyChecker:ScanRaid()
                S.ReadyChecker:AnnounceProblems()
            elseif subcmd == "scan" then
                S.ReadyChecker:ScanRaid()
            else
                S.ReadyChecker:Toggle()
            end
        end
    -- Sync Generic Command
    elseif cmd == "sync" then
        if S.VersionSync then
            if S.VersionSync.RequestVersions then
                S.VersionSync:RequestVersions()
            elseif S.VersionSync.CheckVersions then
                S.VersionSync:CheckVersions()
            end
        elseif S.AutoSync and S.AutoSync.BroadcastState then
            S.AutoSync:BroadcastState()
        end
    -- FocusFire Commands (PvP)
    elseif cmd == "focusfire" or cmd == "ff" then
        if S.FocusFire then
            local subcmd = arg and arg:lower() or ""
            if subcmd == "call" then
                S.FocusFire:CallTarget()
            else
                S.FocusFire:Toggle()
            end
        end
    -- CCCoordinator Commands (PvP)
    elseif cmd == "cc" or cmd == "cccoord" then
        if S.CCCoordinator then
            local subcmd = arg and arg:lower() or ""
            if subcmd == "assign" then
                if S.CCCoordinator.Assign then
                    local p, t, s = UnitName("player"), UnitName("target") or "Target", "CC"
                    S.CCCoordinator:Assign(p, t, s)
                elseif S.CCCoordinator.AssignCC then
                    S.CCCoordinator:AssignCC()
                end
            elseif subcmd == "clear" then
                if S.CCCoordinator.ClearAssignments then
                    S.CCCoordinator:ClearAssignments()
                end
            else
                S.CCCoordinator:Toggle()
            end
        end
    -- CCTracker Commands (PvP/Class)
    elseif cmd == "cct" or cmd == "cctracker" then
        if S.CCTracker then
            S.CCTracker:SlashCommand(arg)
        end
    -- HealerTracker Commands (PvP)
    elseif cmd == "healers" or cmd == "ht" then
        if S.HealerTracker then
            S.HealerTracker:Toggle()
        end
    -- DefensiveAlerts Commands (PvP)
    elseif cmd == "defensive" or cmd == "def" then
        if S.DefensiveAlerts then
            local subcmd = arg and arg:lower() or ""
            if subcmd == "peel" then
                S.DefensiveAlerts:RequestPeel()
            elseif subcmd == "heal" then
                S.DefensiveAlerts:RequestHeal()
            elseif subcmd == "dispel" then
                S.DefensiveAlerts:RequestDispel()
            else
                S.DefensiveAlerts:Toggle()
            end
        end
    -- PullGuide Commands (Dungeons)
    elseif cmd == "pullguide" or cmd == "pg" then
        if S.PullGuide then
            local subcmd = arg and arg:lower() or ""
            if subcmd == "mark" then
                S.PullGuide:MarkPack()
            else
                S.PullGuide:Toggle()
            end
        end
    -- DungeonTimer Commands (Dungeons)
    elseif cmd == "dungeon" or cmd == "dt" then
        if S.DungeonTimer then
            S.DungeonTimer:Toggle()
        end
    -- LootCouncil Commands (Dungeons)
    elseif cmd == "loot" or cmd == "lc" then
        if S.LootCouncil then
            local subcmd = arg and arg:lower() or ""
            if subcmd == "start" then
                S.LootCouncil:StartSession()
            elseif subcmd == "end" then
                S.LootCouncil:EndSession()
            else
                S.LootCouncil:Toggle()
            end
        end
    -- PlayerNotes Commands (General)
    elseif cmd == "notes" or cmd == "pn" then
        if S.PlayerNotes then
            local subcmd, subarg = strsplit(" ", arg or "", 2)
            subcmd = subcmd and subcmd:lower() or ""
            if subcmd == "add" and subarg then
                local player, note = strsplit(" ", subarg, 2)
                if player and note then
                    S.PlayerNotes:AddNote(player, note)
                end
            elseif subcmd == "show" and subarg then
                S.PlayerNotes:ShowNote(subarg)
            elseif subcmd == "delete" and subarg then
                S.PlayerNotes:DeleteNote(subarg)
            else
                S.PlayerNotes:Toggle()
            end
        end
    -- BuildManager Commands (General)
    elseif cmd == "build" or cmd == "bm" then
        if S.BuildManager then
            local subcmd, subarg = strsplit(" ", arg or "", 2)
            subcmd = subcmd and subcmd:lower() or ""
            if subcmd == "save" and subarg then
                S.BuildManager:SaveBuild(subarg)
            elseif subcmd == "load" and subarg then
                S.BuildManager:LoadBuild(subarg)
            elseif subcmd == "list" then
                S.BuildManager:ListBuilds()
            elseif subcmd == "delete" and subarg then
                S.BuildManager:DeleteBuild(subarg)
            else
                S.BuildManager:Toggle()
            end
        end
    -- EventCalendar Commands (General)
    elseif cmd == "calendar" or cmd == "cal" then
        if S.EventCalendar then
            S.EventCalendar:Toggle()
        end
    -- PerformanceStats Commands (General)
    elseif cmd == "stats" or cmd == "ps" then
        if S.PerformanceStats then
            local subcmd = arg and arg:lower() or ""
            if subcmd == "clear" then
                S.PerformanceStats:ClearStats()
            elseif subcmd == "compare" then
                S.PerformanceStats:CompareRaids()
            else
                S.PerformanceStats:Toggle()
            end
        end
    -- VotingSystem Commands (General)
    elseif cmd == "poll" or cmd == "vote" then
        if S.VotingSystem then
            local subcmd = arg and arg:lower() or ""
            if subcmd == "yes" then
                S.VotingSystem:Vote("yes")
            elseif subcmd == "no" then
                S.VotingSystem:Vote("no")
            elseif subcmd:find("create") then
                local question = arg:gsub("create%s*", "")
                S.VotingSystem:CreatePoll(question)
            elseif subcmd == "end" then
                if S.VotingSystem.ClosePoll then
                    S.VotingSystem:ClosePoll()
                elseif S.VotingSystem.EndPoll then
                    S.VotingSystem:EndPoll()
                end
            else
                S.VotingSystem:Toggle()
            end
        end
    -- VersionSync Commands (General)
    elseif cmd == "version" or cmd == "vs" then
        if S.VersionSync then
            local subcmd = arg and arg:lower() or ""
            if subcmd == "check" then
                if S.VersionSync.RequestVersions then
                    S.VersionSync:RequestVersions()
                elseif S.VersionSync.CheckVersions then
                    S.VersionSync:CheckVersions()
                end
            else
                S.VersionSync:Toggle()
            end
        end
    -- QuickWhisper Commands (General)
    elseif cmd == "whisper" or cmd == "qw" then
        if S.QuickWhisper then
            local subcmd = arg and arg:lower() or ""
            if subcmd == "1" then
                S.QuickWhisper:SendTemplate(1)
            elseif subcmd == "2" then
                S.QuickWhisper:SendTemplate(2)
            elseif subcmd == "3" then
                S.QuickWhisper:SendTemplate(3)
            else
                S.QuickWhisper:Toggle()
            end
        end
    -- MacroSync Commands
    elseif cmd == "macro" then
        if S.MacroSync then
            local subcmd, subarg = strsplit(" ", arg or "", 2)
            subcmd = subcmd and subcmd:lower() or ""
            
            if subcmd == "share" and subarg then
                S.MacroSync:ShareMacro(subarg)
            elseif subcmd == "list" then
                S.MacroSync:ListSharedMacros()
            elseif subcmd == "import" and subarg then
                S.MacroSync:ImportMacro(subarg)
            elseif subcmd == "library" or subcmd == "lib" then
                local spec = S.Universal and S.Universal:GetSpec() or 0
                S.MacroSync:ListLibraryMacros(nil, spec)
            elseif subcmd == "libraryall" then
                S.MacroSync:ListLibraryMacros(nil, 0)
            elseif subcmd == "getlib" and subarg then
                S.MacroSync:ImportFromLibrary(subarg)
            elseif subcmd == "getall" then
                local spec = S.Universal and S.Universal:GetSpec() or 0
                S.MacroSync:ImportAllFromLibrary(spec)
            elseif subcmd == "request" then
                S.MacroSync:RequestMacroList()
            elseif subcmd == "get" and subarg then
                local macroName, target = strsplit(" ", subarg, 2)
                if macroName and target then
                    S.MacroSync:RequestMacro(macroName, target)
                else
                    S:Print("Uso: /jaina macro get <nombre> <jugador>")
                end
            else
                S:Print("Subcomandos de macro:")
                S:Print("  share <nombre> - Comparte un macro con el grupo")
                S:Print("  list - Lista macros compartidos recibidos")
                S:Print("  import <nombre> - Importa un macro compartido")
                S:Print("  library - Muestra biblioteca de tu clase/spec")
                S:Print("  libraryall - Muestra toda la biblioteca de tu clase")
                S:Print("  getlib <nombre> - Importa macro de biblioteca")
                S:Print("  getall - Importa todos los macros de biblioteca")
                S:Print("  request - Solicita lista de macros del grupo")
                S:Print("  get <nombre> <jugador> - Solicita macro específico")
            end
        end
    -- AcademyInspector Commands
    elseif cmd == "inspect" then
        if S.AcademyInspector and S.AcademyInspector.InspectUnit then
            S.AcademyInspector:InspectUnit("target")
        end
    -- RaidAssistUI Commands
    elseif cmd == "assist" then
        if S.RaidAssistUI then
            if not S.RaidAssistUI.mainFrame and S.RaidAssistUI.CreateMainWindow then
                S.RaidAssistUI:CreateMainWindow()
            end
            if S.RaidAssistUI.mainFrame then
                if S.RaidAssistUI.mainFrame:IsShown() then
                    S.RaidAssistUI.mainFrame:Hide()
                else
                    S.RaidAssistUI.mainFrame:Show()
                end
            end
        end
    -- RaidPanel Commands
    elseif cmd == "panel" then
        if S.Dashboard and S.Dashboard.Toggle then
            S.Dashboard:Toggle()
        elseif S.RaidPanel and S.RaidPanel.Toggle then
            S.RaidPanel:Toggle()
        end
    -- LootGallery Commands
    elseif cmd == "gallery" then
        if S.LootGallery then
            if S.LootGallery.frame then S.LootGallery.frame:Show() end
            if S.LootGallery.UpdateGallery then S.LootGallery:UpdateGallery() end
        end
    else
        print("|cFFFF00FFJaina|r: Comando desconocido. Usa /jaina help")
    end
end

function S:PrintHelp()
    print("|cFFFF00FF=== Jaina v" .. self.Version .. " - Comandos ===")
    print("|cFFFFFFFF/jaina macros|r - Genera macros para tu clase")
    print("|cFFFFFFFF/jaina raid|r - Muestra composicion de raid")
    print("|cFFFFFFFF/jaina buffs|r - Escanea buffs faltantes")
    print("|cFFFFFFFF/jaina class|r - Cuenta clases en raid")
    print("|cFFFFFFFF/jaina focus [nombre]|r - Envia orden de focus")
    print("|cFFFFFFFF/jaina alpha|r - Envia Alpha Strike")
    print("|cFFFFFFFF/jaina info|r - Muestra tu info de clase")
    print("|cFFFFFFFF/jaina panel|r - Abre/cierra panel de raid")
    print("|cFFFFFFFF/jaina options|r - Abre panel de opciones")
    print("|cFFFFFFFF/jaina combat|r - Muestra resumen de combate")
    print("|cFFFFFFFF/jaina spec|r - Muestra info de especializacion")
    print("|cFFFFFFFF/jaina specauto|r - Toggle auto-update de macros")
    print("|cFFFFFFFF/jaina lock|r - Bloquea/desbloquea posicion")
    print("|cFFFFFFFF/jaina reset|r - Reinicia posicion")
    print("|cFFFFFFFF/jaina mounts|r - Lista monturas disponibles")
    print("|cFF00FFFF=== RaidAssist ===")
    print("|cFFFFFFFF/jaina ra|r - Abre panel de RaidAssist")
    print("|cFFFFFFFF/jaina raleader|r - Panel de Raid Leader")
    print("|cFFFFFFFF/jaina pull [seg]|r - Inicia pull timer")
    print("|cFFFFFFFF/jaina phase [num]|r - Anuncia fase de boss")
    print("|cFFFFFFFF/jaina checkcons|r - Revisa consumibles")
    print("|cFFFFFFFF/jaina wipes|r - Muestra contador de wipes")
    print("|cFFFFFFFF/jaina resetwipes|r - Reinicia contador")
    print("|cFFFFFFFF/jaina mode [farm/progression]|r - Cambia modo")
    print("|cFFFFFFFF/jaina wipehistory|r - Muestra historial de wipes")
    print("|cFFFFFFFF/jaina clearwipes|r - Borra historial de wipes")
    print("|cFFFFFFFF/jaina alert [mensaje]|r - Muestra alerta de prueba")
    print("|cFFFFFFFF/jaina alertpos [top/center/bottom]|r - Posici\195\179n de alertas")
    print("|cFF00FFFF=== Monturas ===|r")
    print("|cFFFFFFFF/jaina setflying [nombre]|r - Establece montura voladora favorita")
    print("|cFFFFFFFF/jaina setground [nombre]|r - Establece montura terrestre favorita")
    print("|cFFFFFFFF/jaina setaquatic [nombre]|r - Establece montura acuatica favorita")
    print("|cFF00FFFF=== Macros Compartidos ===|r")
    print("|cFFFFFFFF/jaina macro share <nombre>|r - Comparte macro con grupo")
    print("|cFFFFFFFF/jaina macro list|r - Lista macros recibidos")
    print("|cFFFFFFFF/jaina macro import <nombre>|r - Importa macro compartido")
    print("|cFFFFFFFF/jaina macro library|r - Biblioteca de tu clase")
    print("|cFFFFFFFF/jaina macro getlib <nombre>|r - Importa de biblioteca")
    print("|cFFFFFFFF/jaina macro getall|r - Importa todos de biblioteca")
    print("|cFF00FFFF=== PvP - TrinketTracker ===|r")
    print("|cFFFFFFFF/jaina trinkets|r - Panel de trinkets enemigos")
    print("|cFFFFFFFF/jaina trinkets clear|r - Limpiar tracker")
    print("|cFFFFFFFF/jaina trinkets announce|r - Anunciar trinkets")
    print("|cFF00FFFF=== PvE - Raid Tools ===|r")
    print("|cFFFFFFFF/jaina analyze|r - An\195\161lisis del \195\186ltimo wipe")
    print("|cFFFFFFFF/jaina cooldowns|r - Monitor de CDs del raid")
    print("|cFFFFFFFF/jaina cd bres|r - Anuncia Battle Res disponibles")
    print("|cFFFFFFFF/jaina assign|r - Panel de asignaciones")
    print("|cFFFFFFFF/jaina assign interrupts|r - Auto-asignar interrupts")
    print("|cFFFFFFFF/jaina readycheck|r - Chequeo pre-pull mejorado")
    print("|cFF00FFFF=== PvP - Herramientas ===")
    print("|cFFFFFFFF/jaina spy|r - Toggle Spy (PvP Intel)")
    print("|cFFFFFFFF/jaina focusfire|r - Panel de Focus Fire")
    print("|cFFFFFFFF/jaina ff call|r - Llamar target actual")
    print("|cFFFFFFFF/jaina overlord|r - Configurar Overlord HUD")
    print("|cFFFFFFFF/jaina cc|r - Coordinador de CC")
    print("|cFFFFFFFF/jaina healers|r - Monitor de healers enemigos")
    print("|cFFFFFFFF/jaina defensive|r - Panel de alertas defensivas")
    print("|cFFFFFFFF/jaina def peel/heal/dispel|r - Pedir ayuda")
    print("|cFF00FFFF=== Dungeons ===")
    print("|cFFFFFFFF/jaina pullguide|r - Gu\195\173a de pulls")
    print("|cFFFFFFFF/jaina pg mark|r - Marcar pack actual")
    print("|cFFFFFFFF/jaina dungeon|r - Timer de heroicas")
    print("|cFFFFFFFF/jaina loot|r - Panel de Loot Council")
    print("|cFF00FFFF=== General ===")
    print("|cFFFFFFFF/jaina notes|r - Notas de jugadores")
    print("|cFFFFFFFF/jaina notes add <jugador> <nota>|r - Agregar nota")
    print("|cFFFFFFFF/jaina build|r - Gestor de builds")
    print("|cFFFFFFFF/jaina build save/load <nombre>|r - Guardar/cargar")
    print("|cFFFFFFFF/jaina calendar|r - Calendario de eventos")
    print("|cFFFFFFFF/jaina stats|r - Estad\195\173sticas de rendimiento")
    print("|cFFFFFFFF/jaina poll|r - Sistema de votaciones")
    print("|cFFFFFFFF/jaina poll create <pregunta>|r - Crear votaci\195\179n")
    print("|cFFFFFFFF/jaina version|r - Sincronizaci\195\179n de versiones")
    print("|cFFFFFFFF/jaina whisper|r - Mensajes r\195\161pidos")
end

function S:PrintPlayerInfo()
    if not S.Universal then return end
    
    local info = S.Universal:GetPlayerInfo()
    local r, g, b = S.Universal:GetClassColor(info.class)
    local count, resType = S.Universal:GetResourceCount()
    
    print("|cFFFF00FF=== Jaina: Tu Informacion ===")
    print(string.format("Nombre: |cFFFFFFFF%s|r", info.name))
    print(string.format("Clase: |cFF%02x%02x%02x%s|r", r*255, g*255, b*255, info.class))
    print(string.format("Raza: |cFFFFFFFF%s|r", info.race))
    print(string.format("Spec: |cFFFFFFFF%d|r | Rol: |cFFFFFFFF%s|r", info.spec, info.role))
    print(string.format("Recursos (%s): |cFFFFFFFF%d|r", resType, count))
end

-- ===========================================================================
-- UTILIDADES
-- ===========================================================================
function S:Msg(text, msgType)
    if S.Alerts and S.Alerts.Show then
        if msgType == "ERROR" then
            S.Alerts:Show(text, "ERROR")
        elseif msgType == "WARNING" then
            S.Alerts:Show(text, "WARNING")
        else
            S.Alerts:Show(text, "INFO")
        end
    else
        -- Fallback si AlertManager no cargó
        if msgType == "ERROR" then
            print("|cFFFF0000Jaina Error:|r " .. text)
        elseif msgType == "WARNING" then
            print("|cFFFFFF00Jaina:|r " .. text)
        else
            print("|cFFFF00FFJaina:|r " .. text)
        end
    end
end

function S:Print(msg)
    self:Msg(msg)
end

-- ===========================================================================
-- FLAVOR SPEECH SYSTEM
-- ===========================================================================
-- Merge Local Speeches into Data (if Data exists)
if S.Data and S.Data.Speech then
    -- Helper to merge (defined first so we can use it for all categories)
    local function AddPhrases(category, list)
        if not S.Data.Speech[category] then S.Data.Speech[category] = {} end
        for _, text in ipairs(list) do
            table.insert(S.Data.Speech[category], text)
        end
    end

    -- Append extra phrases to categories already defined in Speech.lua
    AddPhrases("Nightfall", {
        "¡OCASO! ¡Descarga de las Sombras instantánea!",
        "¡Siente el poder del Ocaso!",
        "¡Shadow Trance!",
    })
    AddPhrases("Backlash", {
        "¡CONTRAGOLPE! ¡Incinerar/Descarga instantánea!",
        "¡Venganza de Fuego!",
    })
    AddPhrases("Banish", {
        "¡DESTERRADO! ¡Vuelve a tu plano, <target>!",
        "¡No molestas más, <target>!",
    })
    AddPhrases("Enslave", {
        "¡AHORA ME SIRVES A MÍ, <target>!",
        "¡Obedece a tu nuevo maestro, <target>!",
    })
    AddPhrases("Fear", {
        "¡CORRE, COBARDE!",
        "¡Miedo en estado puro!",
    })

    -- Add Serious/Dark Phrases (Core Style) to the Fun/Utility Phrases (Data Style)
    AddPhrases("Summon", {
        "¡Invoco a las fuerzas de la oscuridad!",
        "¡Venid a mí, esbirros del caos!",
        "¡Desde el Vacío Abisal, te llamo!",
        "¡Tu alma me pertenece, demonio!",
        "¡Aparece y destruye!"
    })
    AddPhrases("Soulstone", {
        "¡Tu alma está guardada en esta piedra, <target>!",
        "¡No temas a la muerte, <target>. He robado tu alma.",
        "¡<target> tiene una segunda oportunidad... por un precio.",
        "¡La muerte es solo un contratiempo para ti, <target>!",
        "¡He atado tu alma a este plano, <target>!"
    })
    AddPhrases("Resurrect", {
        "¡Levántate, <target>! ¡Aun no has terminado de servir!",
        "¡Vuelve a la vida, <target>! ¡El maestro te ordena!",
        "¡La muerte te rechaza, <target>!",
    })
    AddPhrases("Mount", {
        "¡Cabalga hacia la destrucción!",
        "¡Ni la muerte detiene mi marcha!",
        "¡Cabalgamos hacia la gloria!",
        "¡Tiemblen ante mi llegada!",
    })
end

-- NOTE: S:GetRandomSpeech() is NOT defined here because it comes from Data/Speech.lua
-- which loads BEFORE this file.




-- Target/Attack Binding Helper
function S:TargetOrAttack()
    if UnitExists("target") and UnitCanAttack("player", "target") then
        if not IsCurrentSpell(6603) then AttackTarget() end
    else
        TargetNearestEnemy()
    end
end

-- ===========================================================================
-- COMMUNICATION & MESSAGE BUS
-- ===========================================================================
S.CommHandlers = S.CommHandlers or {}

function S:RegisterComm(prefix, callback)
    if not prefix or type(callback) ~= "function" then return end
    self.CommHandlers[prefix] = callback
end

function S:GetCommChannel()
    local inInstance, instanceType = IsInInstance()
    if inInstance and (instanceType == "pvp" or instanceType == "arena") then
        return "BATTLEGROUND"
    elseif GetNumRaidMembers() > 0 then
        return "RAID"
    elseif GetNumPartyMembers() > 0 then
        return "PARTY"
    elseif IsInGuild() then
        return "GUILD"
    end
    return nil
end

function S:SendComm(prefix, message, channel, target)
    if not prefix or not message then return end
    local chan = channel or self:GetCommChannel()
    if not chan then return end
    if #message > 240 then message = message:sub(1, 240) end
    if RegisterAddonMessagePrefix then
        RegisterAddonMessagePrefix(prefix)
    end
    SendAddonMessage(prefix, message, chan, target)
end

S.MessageListeners = S.MessageListeners or {}

function S:RegisterMessage(message, callback)
    if not message or type(callback) ~= "function" then return end
    self.MessageListeners[message] = self.MessageListeners[message] or {}
    table.insert(self.MessageListeners[message], callback)
end

function S:SendMessage(message, ...)
    if not message or not self.MessageListeners or not self.MessageListeners[message] then return end
    for _, cb in ipairs(self.MessageListeners[message]) do
        pcall(cb, message, ...)
    end
end

-- ===========================================================================
-- MAIN EVENT HANDLER
-- ===========================================================================
function S:RegisterMainEvents()
    local f = CreateFrame("Frame")
    f:RegisterEvent("PLAYER_ENTERING_WORLD")
    f:RegisterEvent("PLAYER_REGEN_DISABLED")
    f:RegisterEvent("PLAYER_REGEN_ENABLED")
    f:RegisterEvent("PLAYER_DEAD")
    f:RegisterEvent("CHAT_MSG_ADDON")
    
    f:SetScript("OnEvent", function(self, event, ...)
        if event == "PLAYER_ENTERING_WORLD" then
            S:OnEnterWorld()
        elseif event == "PLAYER_REGEN_DISABLED" then
            if S.GUI then S.GUI:UpdateCombatStatus(true) end
        elseif event == "PLAYER_REGEN_ENABLED" then
            if S.GUI then S.GUI:UpdateCombatStatus(false) end
        elseif event == "PLAYER_DEAD" then
            -- Necrosis Style Death Sound ("I'll be back...")
            if S.db and S.db.profile and S.db.profile.DeathSound then
                PlaySoundFile("Sound\\Creature\\LordMarrowgar\\IC_Marrowgar_Slay01.wav")
                print("|cFFFF0000Jaina:|r La muerte es solo el principio...")
            end
            if S.GUI then S.GUI:UpdateCombatStatus(false) end
        elseif event == "CHAT_MSG_ADDON" then
            local prefix, message, channel, sender = ...
            if S.CommHandlers[prefix] then
                S.CommHandlers[prefix](prefix, message, channel, sender)
            end
        end
    end)
end

-- Call Registration
S:RegisterMainEvents()

-- ===========================================================================
-- GLOBAL ALERT SYSTEM
-- ===========================================================================
function S:ShowAlert(msg, type, icon, colorOverride)
    if S.AlertHub and S.AlertHub.Show then
        S.AlertHub:Show(msg, type, icon, colorOverride)
    else
        -- Fallback
        S:Print(msg)
        if type == "CRITICAL" or type == "WARNING" then
            PlaySound("RaidWarning")
        end
    end
end


