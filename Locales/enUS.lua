--[[
    SEQUITO - Localization (enUS) - Default/Fallback
    This file provides English fallback strings for all localization keys.
    It loads BEFORE esMX.lua so Spanish strings can override these.
]]--

local addonName, S = ...
S.L = S.L or {}
setmetatable(S.L, {
    __index = function(t, k)
        return k
    end
})

-- Default English strings (fallback)
S.L["INITIALIZED"] = "Jaina: System initialized."
S.L["OPTIONS"] = "Options"
S.L["LOCKED"] = "Position Locked"
S.L["UNLOCKED"] = "Position Unlocked"

-- RaidAssist System
S.L["RAIDASSIST"] = "Raid Assistant"
S.L["RAIDASSIST_PANEL"] = "Assistant Panel"
S.L["RAIDASSIST_LEADER"] = "Leader Panel"
S.L["RAIDASSIST_ENABLED"] = "System Enabled"
S.L["RAIDASSIST_MODE"] = "Mode"
S.L["MODE_FARM"] = "Farm"
S.L["MODE_PROGRESSION"] = "Progression"

-- Features
S.L["INTERRUPT_COORDINATOR"] = "Interrupt Coordinator"
S.L["COOLDOWN_SHARING"] = "Cooldown Sharing"
S.L["SMART_MARKERS"] = "Smart Markers"
S.L["CONSUMABLES_TRACKER"] = "Consumables Tracker"
S.L["PULL_TIMER"] = "Pull Timer"
S.L["WIPE_ANALYSIS"] = "Wipe Analysis"
S.L["MECHANIC_ANNOUNCEMENTS"] = "Mechanic Announcements"

-- UI Elements - Options Panel
S.L["RAIDASSIST_OPTIONS"] = "Raid Assist Options"
S.L["ENABLE_SYSTEM"] = "Raid Assist system enabled"
S.L["ENABLE_SYSTEM_DESC"] = "Enable or disable the complete raid assistance system"
S.L["SELECT_MODE"] = "Operation Mode:"
S.L["MODE_DESC"] = "Adjust assistance level based on raid type"
S.L["MODE_FARM_TEXT"] = "Farm (fewer alerts)"
S.L["MODE_PROGRESSION_TEXT"] = "Progression (more help)"
S.L["FEATURE_SETTINGS"] = "Features:"
S.L["RAIDASSIST_INFO"] = "Raid Assist works best when multiple raid members have Jaina installed. Use |cff00ff00/sequito ra|r to open the main panel."
S.L["INTERRUPT_DESC"] = "Track and suggest interrupt rotations"
S.L["COOLDOWN_DESC"] = "Sync important raid cooldowns"
S.L["MARKERS_DESC"] = "Distribute targets among DPS automatically"
S.L["CONSUMABLES_DESC"] = "Verify flask/food of all members"
S.L["PULLTIMER_DESC"] = "Synchronized countdown for pulls"
S.L["WIPEANALYSIS_DESC"] = "Detect death causes and patterns"
S.L["ANNOUNCEMENTS_DESC"] = "Announce boss phases and important mechanics"

-- v7.2.0 Modules
S.L["COOLDOWN_MONITOR"] = "Cooldown Monitor"
S.L["COOLDOWN_MONITOR_DESC"] = "Track important raid cooldowns"
S.L["ASSIGNMENTS"] = "Assignments"
S.L["ASSIGNMENTS_DESC"] = "Manage raid assignments"
S.L["READY_CHECKER"] = "Ready Checker"
S.L["READY_CHECKER_DESC"] = "Pre-pull verification system"
S.L["TRINKET_TRACKER"] = "Trinket Tracker"
S.L["TRINKET_TRACKER_DESC"] = "Track enemy PvP trinkets"
S.L["WIPE_ANALYZER"] = "Wipe Analyzer"
S.L["WIPE_ANALYZER_DESC"] = "Analyze wipes and deaths"

-- v7.3.0 PvP Modules
S.L["FOCUS_FIRE"] = "Focus Fire"
S.L["FOCUS_FIRE_DESC"] = "Target call system for PvP"
S.L["CC_COORDINATOR"] = "CC Coordinator"
S.L["CC_COORDINATOR_DESC"] = "Coordinate crowd control with DR tracking"
S.L["HEALER_TRACKER"] = "Healer Tracker"
S.L["HEALER_TRACKER_DESC"] = "Track enemy healer mana"
S.L["DEFENSIVE_ALERTS"] = "Defensive Alerts"
S.L["DEFENSIVE_ALERTS_DESC"] = "Quick buttons for peel/heal requests"

-- v7.3.0 Dungeon Modules
S.L["PULL_GUIDE"] = "Pull Guide"
S.L["PULL_GUIDE_DESC"] = "Auto-mark mobs for pulls"
S.L["DUNGEON_TIMER"] = "Dungeon Timer"
S.L["DUNGEON_TIMER_DESC"] = "Track heroic dungeon resets"
S.L["LOOT_COUNCIL"] = "Loot Council"
S.L["LOOT_COUNCIL_DESC"] = "Quick loot voting system"

-- v7.3.0 General Modules
S.L["PLAYER_NOTES"] = "Player Notes"
S.L["PLAYER_NOTES_DESC"] = "Save notes about players"
S.L["BUILD_MANAGER"] = "Build Manager"
S.L["BUILD_MANAGER_DESC"] = "Save and load talent builds"
S.L["EVENT_CALENDAR"] = "Event Calendar"
S.L["EVENT_CALENDAR_DESC"] = "Guild event integration"
S.L["PERFORMANCE_STATS"] = "Performance Stats"
S.L["PERFORMANCE_STATS_DESC"] = "Track your DPS/HPS over time"
S.L["VOTING_SYSTEM"] = "Voting System"
S.L["VOTING_SYSTEM_DESC"] = "Create quick polls for the group"
S.L["VERSION_SYNC"] = "Version Sync"
S.L["VERSION_SYNC_DESC"] = "Check addon versions in group"
S.L["QUICK_WHISPER"] = "Quick Whisper"
S.L["QUICK_WHISPER_DESC"] = "Predefined whisper templates"

-- 10.2.0 New Strings
S.L["FILTER_ALL"] = "All"
S.L["FILTER_BRES"] = "BRes"
S.L["FILTER_LUST"] = "Lust"
S.L["FILTER_RAID_CD"] = "Raid CD"
S.L["FILTER_EXTERNAL"] = "External"
S.L["FILTER_TANK_CD"] = "Tank CD"
S.L["CM_TIMELINE_MODE"] = "Timeline Mode"
S.L["CM_COMPACT_MODE"] = "Compact Mode"
S.L["CM_CLASS_COLOR"] = "Color by Class"
S.L["SEQUITO_PLATES"] = "Jaina Plates"
S.L["SHOW_CC"] = "Show CC"
S.L["SHOW_THREAT"] = "Show Threat"
S.L["SCALE"] = "Scale"
S.L["MODULE_OPTIONS"] = "Options"
S.L["MODULE_HELP"] = "Help"
S.L["CD_READY"] = "READY!"

-- Common UI
S.L["SHOW"] = "Show"
S.L["HIDE"] = "Hide"
S.L["TOGGLE"] = "Toggle"
S.L["ENABLE"] = "Enable"
S.L["DISABLE"] = "Disable"
S.L["SAVE"] = "Save"
S.L["DELETE"] = "Delete"
S.L["CLEAR"] = "Clear"
S.L["REFRESH"] = "Refresh"
S.L["CLOSE"] = "Close"
S.L["CANCEL"] = "Cancel"
S.L["CONFIRM"] = "Confirm"
S.L["YES"] = "Yes"
S.L["NO"] = "No"

-- Alerts
S.L["NEED_PEEL"] = "NEED PEEL!"
S.L["NEED_HEAL"] = "NEED HEAL!"
S.L["NEED_DISPEL"] = "NEED DISPEL!"
S.L["USING_DEFENSIVE"] = "Using Defensive"
S.L["LOW_HP"] = "LOW HP!"

-- Status
S.L["READY"] = "Ready"
S.L["NOT_READY"] = "Not Ready"
S.L["AVAILABLE"] = "Available"
S.L["ON_COOLDOWN"] = "On Cooldown"
S.L["UPDATED"] = "Updated"
S.L["OUTDATED"] = "Outdated"

-- Gamification & Achievements
S.L["ACH_INITIATE"] = "Initiate"
S.L["ACH_INITIATE_DESC"] = "Log in with the Jaina addon active in your guild."
S.L["ACH_MACRO_MASTER"] = "Macro Master"
S.L["ACH_MACRO_MASTER_DESC"] = "Generate a set of optimized automatic class macros."
S.L["ACH_WIPE_SAVIOR"] = "Raid Savior"
S.L["ACH_WIPE_SAVIOR_DESC"] = "Cast a crucial raid-saving cooldown (Divine Hymn, Tranquility, or Rebirth) in combat."
S.L["ACH_CANNON_FODDER"] = "Cannon Fodder"
S.L["ACH_CANNON_FODDER_DESC"] = "Fall in battle during a challenging dungeon or raid encounter."

-- Menu & Quick Settings
S.L["OPEN_OPTIONS"] = "Open Options"
S.L["ANALYZE_WIPE"] = "Analyze Last Wipe"
S.L["COOLDOWN_MONITOR"] = "Cooldown Monitor"
S.L["RAID_TOOLS"] = "Raid Tools"
S.L["READY_CHECK"] = "Ready Check"
S.L["QUICK_SETTINGS"] = "Quick Settings"
S.L["LOCK_SPHERE"] = "Lock Sphere"

-- Academy & Inspection
S.L["ACADEMY_INSPECTOR"] = "Academy Inspector"
S.L["TALENTS"] = "Talents"
S.L["ILVL_APPROX"] = "Approx. Item Level"
S.L["COOLDOWN_ASSIGNMENTS"] = "Cooldown Assignments"
S.L["NOT_RAID_LEADER"] = "Only the Raid Leader can perform this action."

-- Humor & Fun Speech
S.L["HUMOR_TITLE"] = "Raid Humor & Fun Speech"
S.L["HUMOR_DESC"] = "Automatic humorous and immersive quotes for guild activities."
S.L["HUMOR_ENABLED"] = "Enable Humor Mode"

