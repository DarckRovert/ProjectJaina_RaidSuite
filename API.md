# 🔌 API Documentation - Project Jaina RaidSuite

**Version:** 10.2.0 (Definitive Edition)  
**Author:** DarckRovert (Ingame: Elnazzareno) & Project Jaina Team

---

## 📋 Table of Contents

1. [Introduction](#introduction)
2. [Core API](#core-api)
3. [Universal API](#universal-api)
4. [Dashboard API](#dashboard-api) *(NEW v10.0)*
5. [Connect API](#connect-api) *(NEW v10.0)*

---

## 📖 Introduction

This document provides complete API documentation for developers who want to integrate with Sequito.

### Compatibility
- **WoW Version:** 3.3.5a (WotLK)
- **Lua Version:** 5.1

---

## 🎯 Core API

### `Sequito_RegisterTab(name, icon, frame)`
Registers a new tab in the Sequito Dashboard.
- **name:** Title of the tab.
- **icon:** Texture path for the icon.
- **frame:** The frame to display when the tab is selected.

### `Sequito_ExportReport()`
Opens the Export window with the current raid report.

---


### `Sequito_GetVersion()`

Returns the current version of Sequito.

**Returns:**
- `string`: Version number (e.g., "2.2.0")

**Example:**
```lua
local version = Sequito_GetVersion()
print("Sequito version: " .. version)
```

---

### `Sequito_IsLoaded()`

Checks if Sequito is fully loaded and initialized.

**Returns:**
- `boolean`: `true` if loaded, `false` otherwise

**Example:**
```lua
if Sequito_IsLoaded() then
    print("Sequito is ready!")
end
```

---

### `Sequito_GetDB()`

Returns the SavedVariables database.

**Returns:**
- `table`: Database table with all saved settings

**Example:**
```lua
local db = Sequito_GetDB()
print("Macros enabled: " .. tostring(db.settings.macros_enabled))
```

---

### `Sequito_Print(message)`

Prints a message to chat with Sequito prefix.

**Parameters:**
- `message` (string): Message to print

**Example:**
```lua
Sequito_Print("Hello from Sequito!")
-- Output: [Sequito] Hello from Sequito!
```

---

## 🔍 Universal API

### `Sequito_Universal_GetPlayerInfo()`

Gets complete player information.

**Returns:**
```lua
{
    name = "PlayerName",
    class = "WARLOCK",
    classLocalized = "Brujo",
    race = "Orc",
    raceLocalized = "Orco",
    level = 80,
    spec = "Affliction",
    specIndex = 1,
    role = "DPS",
    resource = "Mana",
    resourceCurrent = 15420,
    resourceMax = 18500,
    resourcePercent = 83.35
}
```

**Example:**
```lua
local info = Sequito_Universal_GetPlayerInfo()
if info.class == "WARLOCK" then
    print("You are a Warlock!")
end
```

---

### `Sequito_Universal_GetClass()`

Gets player's class.

**Returns:**
- `string`: Class name in English (e.g., "WARLOCK", "MAGE")

**Example:**
```lua
local class = Sequito_Universal_GetClass()
```

---

### `Sequito_Universal_GetClassLocalized()`

Gets player's class in localized language.

**Returns:**
- `string`: Localized class name (e.g., "Brujo", "Mago")

**Example:**
```lua
local class = Sequito_Universal_GetClassLocalized()
```

---

### `Sequito_Universal_GetSpec()`

Gets player's current specialization.

**Returns:**
- `string`: Spec name (e.g., "Affliction", "Fire", "Protection")

**Example:**
```lua
local spec = Sequito_Universal_GetSpec()
if spec == "Affliction" then
    print("Affliction Warlock detected")
end
```

---

### `Sequito_Universal_GetRole()`

Gets player's role based on spec.

**Returns:**
- `string`: "Tank", "Healer", or "DPS"

**Example:**
```lua
local role = Sequito_Universal_GetRole()
if role == "Tank" then
    print("You are a tank!")
end
```

---

### `Sequito_Universal_GetClassColor(class)`

Gets the color for a specific class.

**Parameters:**
- `class` (string): Class name in English

**Returns:**
```lua
{
    r = 0.58,  -- Red (0-1)
    g = 0.51,  -- Green (0-1)
    b = 0.79,  -- Blue (0-1)
    hex = "9482C9"  -- Hex color
}
```

**Example:**
```lua
local color = Sequito_Universal_GetClassColor("WARLOCK")
local r, g, b = color.r, color.g, color.b
```

---

### `Sequito_Universal_GetResource()`

Gets player's current resource information.

**Returns:**
```lua
{
    type = "Mana",
    current = 15420,
    max = 18500,
    percent = 83.35
}
```

**Example:**
```lua
local resource = Sequito_Universal_GetResource()
print(string.format("Mana: %d/%d (%.1f%%)", 
    resource.current, resource.max, resource.percent))
```

---

## 🔧 Macro Generator API

### `Sequito_MacroGenerator_CreateMacros()`

Generates macros for current class and spec.

**Returns:**
- `boolean`: `true` if successful, `false` otherwise

**Example:**
```lua
if Sequito_MacroGenerator_CreateMacros() then
    Sequito_Print("Macros created successfully!")
end
```

---

### `Sequito_MacroGenerator_GetMacrosForClass(class, spec)`

Gets macro definitions for a specific class and spec.

**Parameters:**
- `class` (string): Class name in English
- `spec` (string): Spec name

**Returns:**
```lua
{
    {
        name = "[SEQ] Macro Name",
        icon = "Interface\\Icons\\IconPath",
        body = "#showtooltip\n/cast SpellName"
    },
    ...
}
```

**Example:**
```lua
local macros = Sequito_MacroGenerator_GetMacrosForClass("WARLOCK", "Affliction")
for _, macro in ipairs(macros) do
    print("Macro: " .. macro.name)
end
```

---

### `Sequito_MacroGenerator_CreateMacro(name, icon, body)`

Creates a single macro.

**Parameters:**
- `name` (string): Macro name (max 16 chars)
- `icon` (string): Icon path or icon ID
- `body` (string): Macro body (max 255 chars)

**Returns:**
- `number`: Macro index if successful, `nil` otherwise

**Example:**
```lua
local index = Sequito_MacroGenerator_CreateMacro(
    "[SEQ] Test",
    "Interface\\Icons\\INV_Misc_QuestionMark",
    "/say Hello World!"
)
```

---

### `Sequito_MacroGenerator_DeleteMacro(name)`

Deletes a macro by name.

**Parameters:**
- `name` (string): Macro name

**Returns:**
- `boolean`: `true` if deleted, `false` otherwise

**Example:**
```lua
Sequito_MacroGenerator_DeleteMacro("[SEQ] Old Macro")
```

---

## 🔄 Macro Sync API **

### `S.MacroSync:ShareMacro(macroName)`

Shares a macro with your raid/party members.

**Parameters:**
- `macroName` (string): Name of the macro to share

**Example:**
```lua
S.MacroSync:ShareMacro("SeqDotAll")
```

---

### `S.MacroSync:ListSharedMacros()`

Lists all macros received from other players.

**Example:**
```lua
S.MacroSync:ListSharedMacros()
```

---

### `S.MacroSync:ImportMacro(macroName)`

Imports a shared macro to your macro list.

**Parameters:**
- `macroName` (string): Name of the shared macro to import

**Example:**
```lua
S.MacroSync:ImportMacro("SeqDotAll")
```

---

### `S.MacroSync:ListLibraryMacros(class, spec)`

Lists macros from the class library.

**Parameters:**
- `class` (string, optional): Class name (defaults to player's class)
- `spec` (number, optional): Spec index (0 = all specs)

**Example:**
```lua
S.MacroSync:ListLibraryMacros("WARLOCK", 1) -- Affliction macros
```

---

### `S.MacroSync:ImportFromLibrary(macroName)`

Imports a macro from the class library.

**Parameters:**
- `macroName` (string): Name of the library macro

**Example:**
```lua
S.MacroSync:ImportFromLibrary("SeqDotAll")
```

---

### `S.MacroSync:ImportAllFromLibrary(spec)`

Imports all macros from the library for your class.

**Parameters:**
- `spec` (number, optional): Spec index (0 = all specs)

**Example:**
```lua
S.MacroSync:ImportAllFromLibrary(1) -- Import all Affliction macros
```

---

### `S.MacroSync:RequestMacroList()`

Requests macro list from other Sequito users in your group.

**Example:**
```lua
S.MacroSync:RequestMacroList()
```

---

## 👥 Raid Sync API

### `Sequito_RaidSync_SendData(dataType, data)`

Sends data to raid members.

**Parameters:**
- `dataType` (string): Type of data ("SPEC", "BUFF", "CD", "CUSTOM")
- `data` (table): Data to send

**Example:**
```lua
Sequito_RaidSync_SendData("SPEC", {
    class = "WARLOCK",
    spec = "Affliction",
    role = "DPS"
})
```

---

### `Sequito_RaidSync_SendCommand(command, target)`

Sends a tactical command to raid.

**Parameters:**
- `command` (string): "FOCUS" or "ALPHA"
- `target` (string, optional): Target name (for FOCUS)

**Example:**
```lua
-- Send focus command
Sequito_RaidSync_SendCommand("FOCUS", "Ragnaros")

-- Send alpha strike command
Sequito_RaidSync_SendCommand("ALPHA")
```

---

### `Sequito_RaidSync_GetRaidData()`

Gets synchronized data from all raid members.

**Returns:**
```lua
{
    ["PlayerName"] = {
        class = "WARLOCK",
        spec = "Affliction",
        role = "DPS",
        level = 80,
        lastUpdate = 1234567890
    },
    ...
}
```

**Example:**
```lua
local raidData = Sequito_RaidSync_GetRaidData()
for player, data in pairs(raidData) do
    print(player .. " is " .. data.spec .. " " .. data.class)
end
```

---

### `Sequito_RaidSync_RegisterCallback(dataType, callback)`

Registers a callback for received data.

**Parameters:**
- `dataType` (string): Type of data to listen for
- `callback` (function): Function to call when data is received

**Callback Parameters:**
- `sender` (string): Player who sent the data
- `data` (table): Received data

**Example:**
```lua
Sequito_RaidSync_RegisterCallback("CUSTOM", function(sender, data)
    print(sender .. " sent: " .. tostring(data.message))
end)
```

---

### `Sequito_RaidSync_IsInRaid()`

Checks if player is in a raid.

**Returns:**
- `boolean`: `true` if in raid, `false` otherwise

**Example:**
```lua
if Sequito_RaidSync_IsInRaid() then
    print("You are in a raid!")
end
```

---

## 📊 Raid Intel API

### `Sequito_RaidIntel_ScanBuffs()`

Scans raid for missing buffs.

**Returns:**
```lua
{
    ["Blessing of Kings"] = {
        missing = 5,
        players = {"Player1", "Player2", ...},
        providers = {"Paladin1", "Druid1"}
    },
    ...
}
```

**Example:**
```lua
local buffs = Sequito_RaidIntel_ScanBuffs()
for buffName, info in pairs(buffs) do
    if info.missing > 0 then
        print(buffName .. " missing on " .. info.missing .. " players")
    end
end
```

---

### `Sequito_RaidIntel_GetClassCount()`

Gets count of each class in raid.

**Returns:**
```lua
{
    WARRIOR = 3,
    PALADIN = 2,
    HUNTER = 4,
    ROGUE = 2,
    PRIEST = 3,
    DEATHKNIGHT = 2,
    SHAMAN = 3,
    MAGE = 3,
    WARLOCK = 2,
    DRUID = 1
}
```

**Example:**
```lua
local classes = Sequito_RaidIntel_GetClassCount()
print("Warriors in raid: " .. (classes.WARRIOR or 0))
```

---

### `Sequito_RaidIntel_GetRoleCount()`

Gets count of each role in raid.

**Returns:**
```lua
{
    Tank = 2,
    Healer = 5,
    DPS = 18
}
```

**Example:**
```lua
local roles = Sequito_RaidIntel_GetRoleCount()
print("Tanks: " .. roles.Tank)
print("Healers: " .. roles.Healer)
print("DPS: " .. roles.DPS)
```

---

### `Sequito_RaidIntel_GetAvailableCooldowns()`

Gets list of available raid cooldowns.

**Returns:**
```lua
{
    {
        player = "Shaman1",
        class = "SHAMAN",
        spell = "Bloodlust",
        spellID = 2825,
        ready = true,
        cooldown = 0
    },
    {
        player = "Mage1",
        class = "MAGE",
        spell = "Time Warp",
        spellID = 80353,
        ready = false,
        cooldown = 120
    },
    ...
}
```

**Example:**
```lua
local cds = Sequito_RaidIntel_GetAvailableCooldowns()
for _, cd in ipairs(cds) do
    if cd.ready then
        print(cd.player .. " has " .. cd.spell .. " ready!")
    end
end
```

---

## 🛡️ Raid Assist API **

### `S.RaidAssist:StartPullTimer(seconds)`

Starts a pull countdown timer.

**Parameters:**
- `seconds` (number): Countdown duration (default: 10)

**Example:**
```lua
S.RaidAssist:StartPullTimer(5) -- 5 second pull timer
```

---

### `S.RaidAssist:CancelPullTimer()`

Cancels an active pull timer.

**Example:**
```lua
S.RaidAssist:CancelPullTimer()
```

---

### `S.RaidAssist:ShowAlert(message, duration, position)`

Shows a customizable alert on screen.

**Parameters:**
- `message` (string): Alert text
- `duration` (number, optional): Display duration in seconds (default: 3)
- `position` (string, optional): "TOP", "CENTER", or "BOTTOM" (default: "TOP")

**Example:**
```lua
S.RaidAssist:ShowAlert("Bloodlust in 5 seconds!", 5, "CENTER")
```

---

### `S.RaidAssist:GetWipeHistory()`

Gets the wipe history statistics.

**Returns:**
```lua
{
    ["Icecrown Citadel"] = {
        wipes = 15,
        lastWipe = 1234567890,
        attempts = {
            { time = 1234567890, duration = 245 },
            ...
        }
    },
    ...
}
```

**Example:**
```lua
local history = S.RaidAssist:GetWipeHistory()
for zone, data in pairs(history) do
    print(zone .. ": " .. data.wipes .. " wipes")
end
```

---

### `S.RaidAssist:ClearWipeHistory()`

Clears all wipe history data.

**Example:**
```lua
S.RaidAssist:ClearWipeHistory()
```

---

### `S.RaidAssist:SetAlertPosition(position)`

Sets the default alert position.

**Parameters:**
- `position` (string): "TOP", "CENTER", or "BOTTOM"

**Example:**
```lua
S.RaidAssist:SetAlertPosition("CENTER")
```

---

## ⚔️ Combat Tracker API

### `Sequito_CombatTracker_Start()`

Starts combat tracking.

**Example:**
```lua
Sequito_CombatTracker_Start()
```

---

### `Sequito_CombatTracker_Stop()`

Stops combat tracking and generates report.

**Returns:**
```lua
{
    duration = 332,
    damage = 1500000,
    healing = 500000,
    damageTaken = 300000,
    deaths = 2,
    dps = 4523,
    hps = 1506
}
```

**Example:**
```lua
local report = Sequito_CombatTracker_Stop()
print("DPS: " .. report.dps)
```

---

### `Sequito_CombatTracker_GetReport()`

Gets the last combat report.

**Returns:**
```lua
{
    personal = {
        damage = 1500000,
        dps = 4523,
        ...
    },
    raid = {
        {
            player = "PlayerName",
            class = "WARLOCK",
            dps = 5234,
            damage = 1734567,
            ...
        },
        ...
    }
}
```

**Example:**
```lua
local report = Sequito_CombatTracker_GetReport()
if report then
    print("Your DPS: " .. report.personal.dps)
end
```

---

### `Sequito_CombatTracker_IsActive()`

Checks if combat tracking is active.

**Returns:**
- `boolean`: `true` if tracking, `false` otherwise

**Example:**
```lua
if Sequito_CombatTracker_IsActive() then
    print("Combat tracking is active")
end
```

---

## 📡 Events

### Custom Events

Sequito fires custom events that other addons can listen to:

#### `SEQUITO_LOADED`

Fired when Sequito is fully loaded.

**Example:**
```lua
local frame = CreateFrame("Frame")
frame:RegisterEvent("SEQUITO_LOADED")
frame:SetScript("OnEvent", function(self, event)
    print("Sequito is loaded!")
end)
```

---

#### `SEQUITO_SPEC_CHANGED`

Fired when player changes specialization.

**Payload:**
- `arg1` (string): Old spec
- `arg2` (string): New spec

**Example:**
```lua
local frame = CreateFrame("Frame")
frame:RegisterEvent("SEQUITO_SPEC_CHANGED")
frame:SetScript("OnEvent", function(self, event, oldSpec, newSpec)
    print("Spec changed from " .. oldSpec .. " to " .. newSpec)
end)
```

---

#### `SEQUITO_MACROS_GENERATED`

Fired when macros are generated.

**Payload:**
- `arg1` (number): Number of macros created

**Example:**
```lua
local frame = CreateFrame("Frame")
frame:RegisterEvent("SEQUITO_MACROS_GENERATED")
frame:SetScript("OnEvent", function(self, event, count)
    print(count .. " macros generated!")
end)
```

---

#### `SEQUITO_RAID_SYNC`

Fired when raid data is synchronized.

**Payload:**
- `arg1` (string): Data type
- `arg2` (string): Sender name
- `arg3` (table): Data

**Example:**
```lua
local frame = CreateFrame("Frame")
frame:RegisterEvent("SEQUITO_RAID_SYNC")
frame:SetScript("OnEvent", function(self, event, dataType, sender, data)
    print(sender .. " sent " .. dataType .. " data")
end)
```

---

#### `SEQUITO_COMMAND_RECEIVED`

Fired when a tactical command is received.

**Payload:**
- `arg1` (string): Command type ("FOCUS" or "ALPHA")
- `arg2` (string): Sender name
- `arg3` (string): Target (for FOCUS)

**Example:**
```lua
local frame = CreateFrame("Frame")
frame:RegisterEvent("SEQUITO_COMMAND_RECEIVED")
frame:SetScript("OnEvent", function(self, event, command, sender, target)
    if command == "FOCUS" then
        print(sender .. " wants us to focus " .. target)
    end
end)
```

---

## 📦 Data Structures

### PlayerInfo

```lua
{
    name = "PlayerName",
    class = "WARLOCK",
    classLocalized = "Brujo",
    race = "Orc",
    raceLocalized = "Orco",
    level = 80,
    spec = "Affliction",
    specIndex = 1,
    role = "DPS",
    resource = "Mana",
    resourceCurrent = 15420,
    resourceMax = 18500,
    resourcePercent = 83.35
}
```

---

### MacroDefinition

```lua
{
    name = "[SEQ] Macro Name",
    icon = "Interface\\Icons\\IconPath",
    body = "#showtooltip\n/cast SpellName\n/cast AnotherSpell"
}
```

---

### RaidMemberData

```lua
{
    name = "PlayerName",
    class = "WARLOCK",
    spec = "Affliction",
    role = "DPS",
    level = 80,
    online = true,
    dead = false,
    lastUpdate = 1234567890
}
```

---

### BuffInfo

```lua
{
    name = "Blessing of Kings",
    spellID = 20217,
    missing = 5,
    players = {"Player1", "Player2", ...},
    providers = {"Paladin1", "Druid1"}
}
```

---

### CooldownInfo

```lua
{
    player = "Shaman1",
    class = "SHAMAN",
    spell = "Bloodlust",
    spellID = 2825,
    ready = true,
    cooldown = 0,
    duration = 600
}
```

---

### CombatReport

```lua
{
    duration = 332,
    damage = 1500000,
    healing = 500000,
    damageTaken = 300000,
    deaths = 2,
    dps = 4523,
    hps = 1506,
    startTime = 1234567890,
    endTime = 1234568222
}
```

---

## 💡 Examples

### Example 1: Check Player Class and Generate Macros

```lua
local info = Sequito_Universal_GetPlayerInfo()

if info.class == "WARLOCK" then
    print("You are a Warlock!")
    
    if info.spec == "Affliction" then
        print("Affliction spec detected")
        Sequito_MacroGenerator_CreateMacros()
    end
end
```

---

### Example 2: Monitor Raid Composition

```lua
local function CheckRaidComp()
    if not Sequito_RaidSync_IsInRaid() then
        print("Not in raid")
        return
    end
    
    local classes = Sequito_RaidIntel_GetClassCount()
    local roles = Sequito_RaidIntel_GetRoleCount()
    
    print("Raid Composition:")
    print("Tanks: " .. roles.Tank)
    print("Healers: " .. roles.Healer)
    print("DPS: " .. roles.DPS)
    
    if roles.Healer < 5 then
        print("WARNING: Not enough healers!")
    end
end

CheckRaidComp()
```

---

### Example 3: Listen for Tactical Commands

```lua
local frame = CreateFrame("Frame")
frame:RegisterEvent("SEQUITO_COMMAND_RECEIVED")
frame:SetScript("OnEvent", function(self, event, command, sender, target)
    if command == "FOCUS" then
        -- Set focus target
        TargetByName(target)
        FocusUnit("target")
        print("Focusing " .. target .. " as ordered by " .. sender)
    elseif command == "ALPHA" then
        -- Use cooldowns
        print(sender .. " called for Alpha Strike!")
        -- Your cooldown logic here
    end
end)
```

---

### Example 4: Track Combat DPS

```lua
local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_REGEN_DISABLED")
frame:RegisterEvent("PLAYER_REGEN_ENABLED")

frame:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_REGEN_DISABLED" then
        -- Combat started
        Sequito_CombatTracker_Start()
    elseif event == "PLAYER_REGEN_ENABLED" then
        -- Combat ended
        local report = Sequito_CombatTracker_Stop()
        if report then
            print(string.format("Combat ended. DPS: %.0f", report.dps))
        end
    end
end)
```

---

### Example 5: Custom Raid Sync

```lua
-- Register callback for custom data
Sequito_RaidSync_RegisterCallback("CUSTOM", function(sender, data)
    print(sender .. " says: " .. data.message)
end)

-- Send custom data
Sequito_RaidSync_SendData("CUSTOM", {
    message = "Hello from my addon!",
    timestamp = time()
})
```

---

## 🔒 Best Practices

### 1. Check if Sequito is Loaded

Always check if Sequito is loaded before using its API:

```lua
if Sequito_IsLoaded() then
    -- Use Sequito API
else
    print("Sequito is not loaded!")
end
```

---

### 2. Handle Nil Returns

Some functions may return `nil` if data is not available:

```lua
local report = Sequito_CombatTracker_GetReport()
if report then
    print("DPS: " .. report.dps)
else
    print("No combat data available")
end
```

---

### 3. Use Events for Real-Time Updates

Instead of polling, use events:

```lua
-- Bad: Polling
local function CheckSpec()
    local spec = Sequito_Universal_GetSpec()
    -- Check every second
end

-- Good: Event-driven
local frame = CreateFrame("Frame")
frame:RegisterEvent("SEQUITO_SPEC_CHANGED")
frame:SetScript("OnEvent", function(self, event, oldSpec, newSpec)
    print("Spec changed to " .. newSpec)
end)
```

---

### 4. Respect User Settings

Check if modules are enabled before using them:

```lua
local db = Sequito_GetDB()
if db.settings.raidsync_enabled then
    Sequito_RaidSync_SendData("CUSTOM", data)
end
```

---

## ⚔️ TrinketTracker API **

Tracker de trinkets PvP enemigos.

### Functions

#### `Sequito.TrinketTracker:Toggle()`
Abre/cierra el panel de trinkets.

#### `Sequito.TrinketTracker:Show()` / `Sequito.TrinketTracker:Hide()`
Muestra/oculta el panel.

#### `Sequito.TrinketTracker:GetTrinketStatus(playerName)`
Retorna el estado del trinket de un enemigo.
- **Returns:** `status` ("cd"/"ready"/nil), `remaining` (seconds)

#### `Sequito.TrinketTracker:AnnounceAll()`
Anuncia el estado de todos los trinkets al grupo.

#### `Sequito.TrinketTracker:ClearAll()`
Limpia todos los datos del tracker.

---

## 💀 WipeAnalyzer API **

Analizador de wipes para raids.

### Functions

#### `Sequito.WipeAnalyzer:Toggle()`
Abre/cierra el panel de análisis.

#### `Sequito.WipeAnalyzer:Analyze()`
Analiza el último wipe y muestra el panel.

#### `Sequito.WipeAnalyzer:AnnounceAnalysis()`
Anuncia el análisis al raid/party.

#### `Sequito.WipeAnalyzer:ClearCurrent()`
Limpia los datos del combate actual.

#### `Sequito.WipeAnalyzer:ShowHistory()`
Muestra el historial de wipes.

---

## 📊 CooldownMonitor API **

Monitor de cooldowns del raid en tiempo real.

### Functions

#### `Sequito.CooldownMonitor:Toggle()`
Abre/cierra el panel de cooldowns.

#### `Sequito.CooldownMonitor:GetAvailableBRes()`
Retorna lista de Battle Res disponibles.
- **Returns:** `table` de cooldowns disponibles

#### `Sequito.CooldownMonitor:GetAvailableLust()`
Retorna si Heroism/Bloodlust está disponible.
- **Returns:** `cooldown` data o `nil`

#### `Sequito.CooldownMonitor:AnnounceAvailable(cdType)`
Anuncia cooldowns disponibles de un tipo.
- **cdType:** "bres", "lust", "raid_cd", "external", "tank_cd"

---

## 🎯 Assignments API **

Sistema de asignaciones para raids.

### Functions

#### `Sequito.Assignments:Toggle()`
Abre/cierra el panel de asignaciones.

#### `Sequito.Assignments:AutoAssignInterrupts()`
Auto-asigna rotación de interrupts basada en clases.

#### `Sequito.Assignments:AnnounceAll()`
Anuncia todas las asignaciones al raid.

#### `Sequito.Assignments:SyncToRaid()`
Sincroniza asignaciones con otros usuarios de Sequito.

#### `Sequito.Assignments:ClearAll()`
Limpia todas las asignaciones.

---

## ✅ ReadyChecker API **

Chequeo pre-pull mejorado.

### Functions

#### `Sequito.ReadyChecker:Toggle()`
Abre/cierra el panel de ready check.

#### `Sequito.ReadyChecker:ScanRaid()`
Escanea el raid en busca de problemas.

#### `Sequito.ReadyChecker:AnnounceProblems()`
Anuncia los problemas detectados al raid.

#### `Sequito.ReadyChecker:QuickCheck()`
Verifica rápidamente si todos están listos.
- **Returns:** `boolean` (true si todos listos)

---

## 📝 Notes

- All API functions are global and can be called from any addon
- Functions prefixed with `Sequito_` are public API
- Internal functions may change without notice
- Always check return values for `nil`
- Use events instead of polling when possible

---

## 📚 More Information

- [MODULES.md](MODULES.md) - Module documentation
- [USAGE.md](USAGE.md) - Usage guide
- [COMMANDS.md](COMMANDS.md) - Command list

---

**Created by DarckRovert (Ingame: Elnazzareno) & Project Jaina Team**
