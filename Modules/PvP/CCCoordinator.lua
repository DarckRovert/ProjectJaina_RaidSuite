--[[
    Sequito - CCCoordinator.lua
    Coordinador de Crowd Control con DR Tracking
    Version: 7.3.0
    
    Funcionalidades:
    - Asignar CCs a objetivos específicos
    - Alertar si alguien rompe CC
    - Mostrar DR (Diminishing Returns) de CCs en enemigos
    - Sincronización con el grupo
]]

local addonName, S = ...
S.CCCoordinator = {}
local CC = S.CCCoordinator

-- Estado
CC.Assignments = {}  -- {targetName = {player = "Name", spell = "Polymorph", icon = 123}}
CC.ActiveCCs = {}    -- {targetGUID = {spell, caster, endTime, drCategory}}
CC.DRTracking = {}   -- {targetGUID = {category = {stacks, resetTime}}}
CC.Frame = nil
CC.IsVisible = false

-- Categorías de DR (WotLK 3.3.5)
local DR_CATEGORIES = {
    -- Stuns
    ["stun"] = {
        [853] = true,    -- Hammer of Justice
        [408] = true,    -- Kidney Shot
        [1833] = true,   -- Cheap Shot
        [5211] = true,   -- Bash
        [22570] = true,  -- Maim
        [30283] = true,  -- Shadowfury
        [44572] = true,  -- Deep Freeze
        [46968] = true,  -- Shockwave
        [20549] = true,  -- War Stomp
        [25274] = true,  -- Intercept Stun
    },
    -- Fears
    ["fear"] = {
        [5782] = true,   -- Fear
        [6215] = true,   -- Fear (rank 3)
        [5484] = true,   -- Howl of Terror
        [8122] = true,   -- Psychic Scream
        [1513] = true,   -- Scare Beast
        [10326] = true,  -- Turn Evil
    },
    -- Roots
    ["root"] = {
        [339] = true,    -- Entangling Roots
        [122] = true,    -- Frost Nova
        [33395] = true,  -- Freeze (Water Elemental)
        [16979] = true,  -- Feral Charge Effect
        [45334] = true,  -- Feral Charge Effect (Cat)
    },
    -- Incapacitates
    ["incapacitate"] = {
        [118] = true,    -- Polymorph
        [28272] = true,  -- Polymorph (Pig)
        [28271] = true,  -- Polymorph (Turtle)
        [61305] = true,  -- Polymorph (Cat)
        [61721] = true,  -- Polymorph (Rabbit)
        [61780] = true,  -- Polymorph (Turkey)
        [6770] = true,   -- Sap
        [2094] = true,   -- Blind
        [51514] = true,  -- Hex
        [20066] = true,  -- Repentance
        [1776] = true,   -- Gouge
        [19386] = true,  -- Wyvern Sting
    },
    -- Silences
    ["silence"] = {
        [15487] = true,  -- Silence (Priest)
        [18469] = true,  -- Silenced - Improved Counterspell
        [34490] = true,  -- Silencing Shot
        [18425] = true,  -- Silenced - Improved Kick
        [1330] = true,   -- Garrote - Silence
        [47476] = true,  -- Strangulate
    },
    -- Disarms
    ["disarm"] = {
        [676] = true,    -- Disarm
        [51722] = true,  -- Dismantle
        [64058] = true,  -- Psychic Horror (Disarm)
    },
    -- Cyclone (propia categoría)
    ["cyclone"] = {
        [33786] = true,  -- Cyclone
    },
    -- Horrors
    ["horror"] = {
        [64044] = true,  -- Psychic Horror
        [6789] = true,   -- Death Coil
    },
}

-- Nombres de CC para display
local CC_NAMES = {
    [118] = "Polymorph",
    [28272] = "Polymorph",
    [28271] = "Polymorph",
    [61305] = "Polymorph",
    [61721] = "Polymorph",
    [61780] = "Polymorph",
    [6770] = "Sap",
    [2094] = "Blind",
    [51514] = "Hex",
    [20066] = "Repentance",
    [339] = "Entangling Roots",
    [5782] = "Fear",
    [8122] = "Psychic Scream",
    [853] = "Hammer of Justice",
    [408] = "Kidney Shot",
    [1833] = "Cheap Shot",
    [33786] = "Cyclone",
    [19386] = "Wyvern Sting",
    [3355] = "Freezing Trap",
}

-- Duraciones de DR
local DR_DURATION = 18  -- Segundos hasta que DR se resetea
local DR_REDUCTION = {1.0, 0.5, 0.25, 0}  -- 100%, 50%, 25%, immune

-- Helper para obtener configuración
function CC:GetOption(key)
    if S.ModuleConfig then
        return S.ModuleConfig:GetValue("CCCoordinator", key)
    end
    return true
end

-- Helper canónico de canal PvP en 3.3.5a
function CC:GetChannel()
    local _, instanceType = IsInInstance()
    if instanceType == "pvp" then
        return "BATTLEGROUND"
    elseif IsInRaid() then
        return "RAID"
    elseif (IsInGroup and IsInGroup()) or (GetNumPartyMembers() > 0) then
        return "PARTY"
    end
    return nil
end

function CC:Initialize()
    if not self:GetOption("enabled") then
        return
    end
    
    self:CreateFrame()
    self:RegisterEvents()
    self:RegisterComm()
end

function CC:CreateFrame()
    self.Frame = CreateFrame("Frame", "SequitoCCCoordinatorFrame", UIParent)
    self.Frame:SetSize(300, 250)
    self.Frame:SetPoint("LEFT", UIParent, "LEFT", 50, 0)
    self.Frame:SetMovable(true)
    self.Frame:EnableMouse(true)
    self.Frame:RegisterForDrag("LeftButton")
    self.Frame:SetScript("OnDragStart", function(f) f:StartMoving() end)
    self.Frame:SetScript("OnDragStop", function(f) f:StopMovingOrSizing() end)
    self.Frame:Hide()
    
    -- Fondo
    self.Frame.bg = self.Frame:CreateTexture(nil, "BACKGROUND")
    self.Frame.bg:SetAllPoints()
    self.Frame.bg:SetTexture("Interface\\Buttons\\WHITE8X8")
    self.Frame.bg:SetVertexColor(0, 0, 0, 0.85)
    
    -- Borde
    self.Frame.border = CreateFrame("Frame", nil, self.Frame)
    self.Frame.border:SetAllPoints()
    self.Frame.border:SetBackdrop({
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 14,
    })
    self.Frame.border:SetBackdropBorderColor(0.6, 0.2, 0.8, 1)
    
    -- Título
    self.Frame.title = self.Frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    self.Frame.title:SetPoint("TOP", self.Frame, "TOP", 0, -10)
    self.Frame.title:SetText("|cFF9932CCCC Coordinator|r")
    
    -- Botón cerrar
    self.Frame.closeBtn = CreateFrame("Button", nil, self.Frame, "UIPanelCloseButton")
    self.Frame.closeBtn:SetPoint("TOPRIGHT", self.Frame, "TOPRIGHT", -2, -2)
    self.Frame.closeBtn:SetScript("OnClick", function() self.Frame:Hide() end)
    
    -- Sección de Asignaciones
    self.Frame.assignHeader = self.Frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    self.Frame.assignHeader:SetPoint("TOPLEFT", self.Frame, "TOPLEFT", 15, -35)
    self.Frame.assignHeader:SetText("|cFFFFFF00Asignaciones de CC:|r")
    
    -- Lista de asignaciones
    self.Frame.assignList = CreateFrame("Frame", nil, self.Frame)
    self.Frame.assignList:SetSize(270, 80)
    self.Frame.assignList:SetPoint("TOPLEFT", self.Frame.assignHeader, "BOTTOMLEFT", 0, -5)
    self.Frame.assignRows = {}
    
    for i = 1, 4 do
        local row = self.Frame.assignList:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        row:SetPoint("TOPLEFT", self.Frame.assignList, "TOPLEFT", 0, -(i-1) * 18)
        row:SetText("")
        row:SetJustifyH("LEFT")
        self.Frame.assignRows[i] = row
    end
    
    -- Sección de DR Tracking
    self.Frame.drHeader = self.Frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    self.Frame.drHeader:SetPoint("TOPLEFT", self.Frame.assignList, "BOTTOMLEFT", 0, -15)
    self.Frame.drHeader:SetText("|cFFFF6600DR Tracking:|r")
    
    -- Lista de DR
    self.Frame.drList = CreateFrame("Frame", nil, self.Frame)
    self.Frame.drList:SetSize(270, 100)
    self.Frame.drList:SetPoint("TOPLEFT", self.Frame.drHeader, "BOTTOMLEFT", 0, -5)
    self.Frame.drRows = {}
    
    for i = 1, 5 do
        local row = self.Frame.drList:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        row:SetPoint("TOPLEFT", self.Frame.drList, "TOPLEFT", 0, -(i-1) * 18)
        row:SetText("")
        row:SetJustifyH("LEFT")
        self.Frame.drRows[i] = row
    end
    
    -- OnUpdate para timers con throttling de 0.1s
    self.updateTimer = 0
    self.Frame:SetScript("OnUpdate", function(frame, elapsed)
        self.updateTimer = (self.updateTimer or 0) + elapsed
        if self.updateTimer >= 0.1 then
            self:OnUpdate(self.updateTimer)
            self.updateTimer = 0
        end
    end)
end

function CC:RegisterEvents()
    local eventFrame = CreateFrame("Frame")
    eventFrame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
    eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
    
    eventFrame:SetScript("OnEvent", function(self, event, ...)
        if event == "COMBAT_LOG_EVENT_UNFILTERED" then
            CC:OnCombatLog(...)
        elseif event == "PLAYER_REGEN_ENABLED" then
            -- Limpiar al salir de combate
            CC:ClearActiveCCs()
        end
    end)
end

function CC:RegisterComm()
    if S.RegisterComm then
        S:RegisterComm("SEQCC", function(prefix, message, channel, sender)
            CC:OnCommReceived(prefix, message, channel, sender)
        end)
    end
end

function CC:OnCombatLog(...)
    local timestamp, event, sourceGUID, sourceName, sourceFlags, destGUID, destName, destFlags, spellId, spellName, spellSchool, auraType = ...
    
    -- Detectar aplicación de CC
    if event == "SPELL_AURA_APPLIED" then
        -- Verificar si DR tracking está habilitado
        if not self:GetOption("trackDR") then return end
        local category = self:GetDRCategory(spellId)
        if category then
            self:OnCCApplied(destGUID, destName, spellId, spellName, sourceName, category)
        end
    -- Detectar remoción de CC
    elseif event == "SPELL_AURA_REMOVED" then
        local category = self:GetDRCategory(spellId)
        if category then
            self:OnCCRemoved(destGUID, destName, spellId, spellName)
        end
    -- Detectar CC roto por daño
    elseif event == "SPELL_AURA_BROKEN" or event == "SPELL_AURA_BROKEN_SPELL" then
        local category = self:GetDRCategory(spellId)
        if category then
            self:OnCCBroken(destGUID, destName, spellId, spellName, sourceName)
        end
    end
end

function CC:GetDRCategory(spellId)
    for category, spells in pairs(DR_CATEGORIES) do
        if spells[spellId] then
            return category
        end
    end
    return nil
end

function CC:OnCCApplied(targetGUID, targetName, spellId, spellName, casterName, category)
    -- Registrar CC activo
    self.ActiveCCs[targetGUID] = {
        spell = spellName,
        spellId = spellId,
        caster = casterName,
        startTime = GetTime(),
        category = category,
    }
    
    -- Actualizar DR
    if not self.DRTracking[targetGUID] then
        self.DRTracking[targetGUID] = {}
    end
    
    if not self.DRTracking[targetGUID][category] then
        self.DRTracking[targetGUID][category] = {
            stacks = 1,
            resetTime = GetTime() + DR_DURATION,
        }
    else
        local dr = self.DRTracking[targetGUID][category]
        if GetTime() > dr.resetTime then
            -- DR reseteado
            dr.stacks = 1
        else
            -- Incrementar DR
            dr.stacks = math.min(dr.stacks + 1, 4)
        end
        dr.resetTime = GetTime() + DR_DURATION
    end
    
    -- Actualizar UI
    self:UpdateDisplay()
    
    -- Verificar si es un target asignado
    self:CheckAssignment(targetName, casterName, spellName)
end

function CC:OnCCRemoved(targetGUID, targetName, spellId, spellName)
    if self.ActiveCCs[targetGUID] and self.ActiveCCs[targetGUID].spellId == spellId then
        self.ActiveCCs[targetGUID] = nil
        self:UpdateDisplay()
    end
end

function CC:OnCCBroken(targetGUID, targetName, spellId, spellName, breakerName)
    -- Verificar si alertas están habilitadas
    if not self:GetOption("alerts") then
        self.ActiveCCs[targetGUID] = nil
        self:UpdateDisplay()
        return
    end
    
    -- Alertar que alguien rompió el CC
    if S.Print then
        S:Print(string.format("|cFFFF0000¡CC ROTO!|r %s rompió %s en %s", 
            breakerName or "Alguien", spellName, targetName))
    end
    
    -- Sonido de alerta si está habilitado
    if self:GetOption("playSound") then
        PlaySound("RaidWarning")
    end
    
    -- Anunciar al grupo si está configurado
    if self:GetOption("announce") then
        local channel = self:GetChannel()
        if channel then
            SendChatMessage(string.format("[Sequito] CC ROTO: %s rompió %s en %s!", 
                breakerName or "Alguien", spellName, targetName), channel)
        end
    end
    
    self.ActiveCCs[targetGUID] = nil
    self:UpdateDisplay()
end

function CC:CheckAssignment(targetName, casterName, spellName)
    local assignment = self.Assignments[targetName]
    if assignment then
        if assignment.player ~= casterName then
            -- Alguien diferente al asignado hizo el CC
            if S.Print then
                S:Print(string.format("|cFFFFFF00Aviso:|r %s debería hacer CC en %s, pero %s lo hizo.", 
                    assignment.player, targetName, casterName))
            end
        else
            -- CC correcto
            if S.Print then
                S:Print(string.format("|cFF00FF00✓|r %s -> %s (%s)", casterName, targetName, spellName))
            end
        end
    end
end

function CC:OnUpdate(elapsed)
    -- Actualizar timers de DR
    local now = GetTime()
    local needsUpdate = false
    
    for guid, categories in pairs(self.DRTracking) do
        for category, data in pairs(categories) do
            if now > data.resetTime then
                categories[category] = nil
                needsUpdate = true
            end
        end
        -- Limpiar GUIDs vacíos
        if not next(categories) then
            self.DRTracking[guid] = nil
        end
    end
    
    if needsUpdate and self.Frame:IsShown() then
        self:UpdateDisplay()
    end
end

function CC:UpdateDisplay()
    if not self.Frame:IsShown() then return end
    
    -- Actualizar nameplates si está habilitado
    if self:GetOption("showDROnNameplates") then
        self:UpdateNameplates()
    end
    
    -- Actualizar asignaciones
    local i = 1
    for target, data in pairs(self.Assignments) do
        if i <= 4 then
            self.Frame.assignRows[i]:SetText(string.format("%s -> %s (%s)", 
                data.player, target, data.spell or "CC"))
            i = i + 1
        end
    end
    for j = i, 4 do
        self.Frame.assignRows[j]:SetText("")
    end
    
    -- Actualizar DR tracking
    i = 1
    for guid, categories in pairs(self.DRTracking) do
        for category, data in pairs(categories) do
            if i <= 5 then
                local timeLeft = data.resetTime - GetTime()
                local drPercent = DR_REDUCTION[data.stacks] or 0
                local color = drPercent == 0 and "|cFFFF0000" or 
                              drPercent <= 0.25 and "|cFFFF6600" or
                              drPercent <= 0.5 and "|cFFFFFF00" or "|cFF00FF00"
                
                -- Obtener nombre del target
                local targetName = self:GetNameFromGUID(guid) or "Desconocido"
                
                self.Frame.drRows[i]:SetText(string.format("%s%s|r: %s (%.0f%%) - %.1fs", 
                    color, targetName, category, drPercent * 100, timeLeft))
                i = i + 1
            end
        end
    end
    for j = i, 5 do
        self.Frame.drRows[j]:SetText("")
    end
end

function CC:UpdateNameplates()
    -- Actualizar iconos de DR en nameplates
    if not self:GetOption("showDROnNameplates") then return end
    
    -- Iterar nameplates visibles (WotLK compatible via WorldFrame children)
    local numChildren = WorldFrame:GetNumChildren()
    for i = 1, numChildren do
        local frame = select(i, WorldFrame:GetChildren())
        if frame and frame:IsShown() and frame:GetName() == nil then
            -- Verificar si es un nameplate buscando la estructura típica
            local regions = { frame:GetRegions() }
            local nameRegion = nil
            for _, region in ipairs(regions) do
                if region:GetObjectType() == "FontString" then
                    nameRegion = region
                    break
                end
            end
            
            if nameRegion then
                local name = nameRegion:GetText()
                if name then
                    -- Buscar si este target tiene DR activo
                    for guid, categories in pairs(self.DRTracking) do
                        local targetName = self:GetNameFromGUID(guid)
                        if targetName == name then
                            -- Mostrar indicador de DR si hay stacks
                            for category, data in pairs(categories) do
                                if data.stacks > 0 and data.resetTime > GetTime() then
                                    self:ShowNameplateDR(frame, category, data.stacks)
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end

function CC:ShowNameplateDR(nameplate, category, stacks)
    -- Crear o reutilizar icono de DR sobre el nameplate
    if not nameplate.seqDRIcon then
        nameplate.seqDRIcon = nameplate:CreateTexture(nil, "OVERLAY")
        nameplate.seqDRIcon:SetSize(16, 16)
        nameplate.seqDRIcon:SetPoint("RIGHT", nameplate, "RIGHT", 20, 0)
        
        nameplate.seqDRText = nameplate:CreateFontString(nil, "OVERLAY")
        nameplate.seqDRText:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
        nameplate.seqDRText:SetPoint("CENTER", nameplate.seqDRIcon, "CENTER", 0, 0)
    end
    
    -- Color por stacks de DR (verde->amarillo->rojo)
    local colors = {
        [1] = {0, 1, 0},    -- 1 stack = verde (50% duración)
        [2] = {1, 1, 0},    -- 2 stacks = amarillo (25% duración)
        [3] = {1, 0, 0},    -- 3 stacks = rojo (inmune)
    }
    local c = colors[stacks] or colors[3]
    
    nameplate.seqDRIcon:SetTexture("Interface\\Icons\\Spell_Magic_LesserInvisibilty")
    nameplate.seqDRIcon:SetVertexColor(c[1], c[2], c[3])
    nameplate.seqDRText:SetText(stacks)
    nameplate.seqDRIcon:Show()
    nameplate.seqDRText:Show()
end

function CC:GetNameFromGUID(guid)
    -- Intentar obtener nombre de varias fuentes
    if UnitExists("target") and UnitGUID("target") == guid then
        return UnitName("target")
    end
    if UnitExists("focus") and UnitGUID("focus") == guid then
        return UnitName("focus")
    end
    for i = 1, 40 do
        local unit = "nameplate" .. i
        if UnitExists(unit) and UnitGUID(unit) == guid then
            return UnitName(unit)
        end
    end
    return nil
end

function CC:ClearActiveCCs()
    wipe(self.ActiveCCs)
    wipe(self.DRTracking)
    self:UpdateDisplay()
end

-- Asignar CC a un jugador
function CC:Assign(playerName, targetName, spellName)
    self.Assignments[targetName] = {
        player = playerName,
        spell = spellName,
    }
    
    if S.Print then
        S:Print(string.format("CC Asignado: %s -> %s (%s)", playerName, targetName, spellName or "CC"))
    end
    
    -- Sincronizar con el grupo
    self:SyncAssignment(playerName, targetName, spellName)
    self:UpdateDisplay()
end

function CC:RemoveAssignment(targetName)
    self.Assignments[targetName] = nil
    self:UpdateDisplay()
end

function CC:ClearAssignments()
    wipe(self.Assignments)
    self:UpdateDisplay()
    if S.Print then
        S:Print("Todas las asignaciones de CC han sido borradas.")
    end
end

function CC:SyncAssignment(playerName, targetName, spellName)
    local channel = self:GetChannel()
    if channel and S.SendAddonMessage then
        local message = string.format("ASSIGN:%s:%s:%s", playerName, targetName, spellName or "CC")
        S:SendAddonMessage("SEQCC", message, channel)
    end
end

function CC:OnCommReceived(prefix, message, channel, sender)
    if sender == UnitName("player") then return end
    
    local cmd, arg1, arg2, arg3 = strsplit(":", message)
    
    if cmd == "ASSIGN" then
        self.Assignments[arg2] = {
            player = arg1,
            spell = arg3,
        }
        self:UpdateDisplay()
    elseif cmd == "CLEAR" then
        wipe(self.Assignments)
        self:UpdateDisplay()
    end
end

function CC:AnnounceAssignments()
    local channel = self:GetChannel()
    if not channel then
        if S.Print then
            S:Print("No estás en un grupo.")
        end
        return
    end
    
    SendChatMessage("=== Asignaciones de CC ===", channel)
    for target, data in pairs(self.Assignments) do
        SendChatMessage(string.format("%s -> %s (%s)", data.player, target, data.spell or "CC"), channel)
    end
end

function CC:GetDRInfo(targetGUID, category)
    if self.DRTracking[targetGUID] and self.DRTracking[targetGUID][category] then
        local data = self.DRTracking[targetGUID][category]
        local timeLeft = data.resetTime - GetTime()
        local reduction = DR_REDUCTION[data.stacks] or 0
        return data.stacks, reduction, timeLeft
    end
    return 0, 1.0, 0
end

function CC:Toggle()
    if not self.Frame then return end
    if self.Frame:IsShown() then
        self.Frame:Hide()
    else
        self.Frame:Show()
        self:UpdateDisplay()
    end
end

-- Wrapper method for Bindings.xml keybinds
function CC:AnnounceCC()
    self:AnnounceAssignments()
end

-- Registrar configuración en ModuleConfig
if S.ModuleConfig then
    S.ModuleConfig:RegisterModule("CCCoordinator", {
        name = "CC Coordinator",
        icon = "Interface\\Icons\\Spell_Frost_FreezingBreath",
        description = "Coordinador de Crowd Control con tracking de Diminishing Returns",
        category = "pvp",
        options = {
            {
                type = "checkbox",
                key = "enabled",
                label = "Habilitar CC Coordinator",
                tooltip = "Activa/desactiva el coordinador de CC",
                default = true,
            },
            {
                type = "checkbox",
                key = "trackDR",
                label = "Trackear Diminishing Returns",
                tooltip = "Muestra el estado de DR en los enemigos",
                default = true,
            },
            {
                type = "checkbox",
                key = "alerts",
                label = "Alertar CC Roto",
                tooltip = "Alerta cuando alguien rompe un CC asignado",
                default = true,
            },
            {
                type = "checkbox",
                key = "announce",
                label = "Anunciar en Chat",
                tooltip = "Anuncia al grupo/banda/campo de batalla cuando se rompe un CC",
                default = false,
            },
            {
                type = "checkbox",
                key = "showDROnNameplates",
                label = "Mostrar DR en Nameplates",
                tooltip = "Muestra iconos de DR en las barras de nombre",
                default = false,
            },
            {
                type = "checkbox",
                key = "playSound",
                label = "Reproducir Sonido",
                tooltip = "Reproduce sonido cuando se rompe un CC",
                default = true,
            },
            {
                type = "slider",
                key = "drResetTime",
                label = "Tiempo Reset DR (seg)",
                tooltip = "Tiempo para que se resetee el DR",
                min = 15,
                max = 30,
                step = 1,
                default = 18,
            },
        },
    })
end

-- Inicializar
if S.RegisterModule then
    S:RegisterModule("CCCoordinator", CC)
else
    local initFrame = CreateFrame("Frame")
    initFrame:RegisterEvent("PLAYER_LOGIN")
    initFrame:SetScript("OnEvent", function()
        CC:Initialize()
    end)
end
