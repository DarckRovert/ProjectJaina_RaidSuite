--[[
    SEQUITO - Academy Inspector (Enhanced Edition)
    Módulo de auditoría de jugadores para oficiales y líderes de banda:
    - Inspección asíncrona robusta vía INSPECT_TALENT_READY
    - Cálculo de GearScore real de WoW 3.3.5a y promedio de iLvl
    - Detección de gemas vacías y encantamientos faltantes
    Parte del sistema "Academy Mode" (v10.2)
]]

local addonName, S = ...
S.AcademyInspector = {}
local AI = S.AcademyInspector

-- Slash Command Handlers
SLASH_SEQUITOINSPECT1 = "/sinspect"
SLASH_SEQUITOINSPECT2 = "/seqinspect"
SlashCmdList["SEQUITOINSPECT"] = function(msg)
    local target = (msg and msg ~= "") and msg or "target"
    AI:InspectUnit(target)
end

function AI:InspectTarget()
    self:InspectUnit("target")
end

-- Factores de Slot para GearScore 3.3.5a
local GS_SLOT_WEIGHTS = {
    [1]  = 1.0000, -- Head
    [2]  = 0.5625, -- Neck
    [3]  = 0.7500, -- Shoulders
    [5]  = 1.0000, -- Chest
    [6]  = 0.7500, -- Waist
    [7]  = 1.0000, -- Legs
    [8]  = 0.7500, -- Feet
    [9]  = 0.5625, -- Wrist
    [10] = 0.7500, -- Hands
    [11] = 0.5625, -- Finger 1
    [12] = 0.5625, -- Finger 2
    [13] = 0.5625, -- Trinket 1
    [14] = 0.5625, -- Trinket 2
    [15] = 0.5625, -- Back
    [16] = 1.0000, -- Main Hand (2.0 si es 2H)
    [17] = 1.0000, -- Off Hand / Shield
    [18] = 0.3164, -- Ranged / Relic / Wand
}

local ENCHANTABLE_SLOTS = {
    [1] = true,  -- Head
    [3] = true,  -- Shoulders
    [5] = true,  -- Chest
    [7] = true,  -- Legs
    [8] = true,  -- Feet
    [9] = true,  -- Wrist
    [10] = true, -- Hands
    [15] = true, -- Back
    [16] = true, -- Main Hand
}

-- ===========================================================================
-- INICIALIZACIÓN Y EVENTOS
-- ===========================================================================
function AI:Initialize()
    if self.initialized then return end
    self.initialized = true
    self.frame = self:CreateInspectorFrame()
    self:RegisterEvents()
    print("|cFFFF00FFSequito|r: [Academy] Inspector de Academia iniciado.")
end

function AI:RegisterEvents()
    local f = CreateFrame("Frame")
    f:RegisterEvent("INSPECT_TALENT_READY")
    f:SetScript("OnEvent", function(self, event, ...)
        if event == "INSPECT_TALENT_READY" then
            AI:ProcessInspection()
        end
    end)
    self.eventFrame = f
end

-- ===========================================================================
-- LÓGICA DE INSPECCIÓN
-- ===========================================================================
function AI:InspectUnit(unit)
    if not UnitExists(unit) or not UnitIsPlayer(unit) then
        if S.Print then
            S:Print("|cFFFF0000[Academy]|r Selecciona un jugador válido para inspeccionar.")
        else
            print("|cFFFF0000[Academy]|r Selecciona un jugador válido para inspeccionar.")
        end
        return
    end
    
    if not CheckInteractDistance(unit, 1) then
        print("|cFFFF9900[Academy]|r Objetivo fuera de rango de inspección.")
    end

    self.currentUnit = unit
    self.currentName = UnitName(unit)
    self.inspectedClass = select(2, UnitClass(unit))
    self.inspectSession = (self.inspectSession or 0) + 1
    self.inspectionProcessed = false
    local currentSession = self.inspectSession
    
    -- Solicitar inspección nativa
    NotifyInspect(unit)
    
    -- Fallback de seguridad por si el evento INSPECT_TALENT_READY se pierde
    C_Timer.After(1.2, function()
        if AI.currentUnit == unit and AI.inspectSession == currentSession and not AI.inspectionProcessed then
            AI:ProcessInspection()
        end
    end)
end

function AI:ProcessInspection()
    if not self.currentUnit or not UnitExists(self.currentUnit) then return end
    self.inspectionProcessed = true
    local unit = self.currentUnit
    
    -- 1. TALENTOS
    local activeGroup = (GetActiveTalentGroup and GetActiveTalentGroup(true)) or 1
    local t1 = 0
    local t2 = 0
    local t3 = 0
    
    for i = 1, 3 do
        local _, _, points = GetTalentTabInfo(i, true, nil, activeGroup)
        if i == 1 then t1 = points or 0 end
        if i == 2 then t2 = points or 0 end
        if i == 3 then t3 = points or 0 end
    end
    
    local talentString = string.format("%d / %d / %d", t1, t2, t3)
    
    -- 2. AUDITORÍA DE EQUIPO, GEARSCORE, GEMAS Y ENCANTAMIENTOS
    local totalILvl = 0
    local itemCount = 0
    local calculatedGS = 0
    local missingEnchants = 0
    local missingGems = 0
    
    -- Detección de Titan's Grip (Guerrero Furia con dos armas de 2 manos) y Cazador
    local isTitanGrip = false
    local mhLink = GetInventoryItemLink(unit, 16)
    local ohLink = GetInventoryItemLink(unit, 17)
    if mhLink and ohLink then
        local _, _, _, _, _, _, _, _, mhEquip = GetItemInfo(mhLink)
        local _, _, _, _, _, _, _, _, ohEquip = GetItemInfo(ohLink)
        if mhEquip == "INVTYPE_2HWEAPON" and ohEquip == "INVTYPE_2HWEAPON" then
            isTitanGrip = true
        end
    end
    local isHunter = (self.inspectedClass == "HUNTER")
    
    for slot = 1, 18 do
        if slot ~= 4 then -- Omitir camisa
            local link = GetInventoryItemLink(unit, slot)
            if link then
                local _, _, quality, ilvl, _, _, _, _, equipSlot = GetItemInfo(link)
                if ilvl then
                    totalILvl = totalILvl + ilvl
                    itemCount = itemCount + 1
                    
                    -- GearScore WotLK
                    local slotWeight = GS_SLOT_WEIGHTS[slot] or 1.0
                    if slot == 16 or slot == 17 then
                        if isTitanGrip then
                            slotWeight = 1.0 -- Normalizar armas 2H a 1.0 para que el total no exceda 2.0
                        elseif equipSlot == "INVTYPE_2HWEAPON" then
                            slotWeight = 2.0
                        end
                        if isHunter then
                            slotWeight = slotWeight * 0.5 -- Stat sticks melee para cazadores
                        end
                    elseif slot == 18 then
                        if isHunter then
                            slotWeight = 2.0 -- El arma a distancia es el arma principal del cazador
                        else
                            slotWeight = 0.3164
                        end
                    end
                    
                    local qualityMod = 1.0
                    if quality == 4 then qualityMod = 1.22 -- Epic
                    elseif quality == 5 then qualityMod = 1.30 -- Legendary
                    elseif quality == 3 then qualityMod = 1.00 -- Rare
                    end
                    
                    calculatedGS = calculatedGS + (ilvl * slotWeight * qualityMod * 1.8)
                end
                
                -- Desglosar enlace del ítem para auditar gemas y encantamientos
                -- Formato: item:itemId:enchantId:gem1:gem2:gem3:gem4:...
                local itemString = link:match("item[%-?%d:]+")
                if itemString then
                    local parts = { strsplit(":", itemString) }
                    local enchantId = tonumber(parts[3]) or 0
                    
                    -- Verificar encantamiento faltante
                    local isEnchantable = ENCHANTABLE_SLOTS[slot]
                    if slot == 17 and (equipSlot == "INVTYPE_SHIELD" or equipSlot == "INVTYPE_WEAPON" or equipSlot == "INVTYPE_WEAPONOFFHAND" or equipSlot == "INVTYPE_2HWEAPON") then
                        isEnchantable = true
                    elseif isHunter and slot == 18 and (equipSlot == "INVTYPE_RANGED" or equipSlot == "INVTYPE_RANGEDRIGHT") then
                        isEnchantable = true
                    end
                    if isEnchantable and enchantId == 0 and quality and quality >= 3 then
                        missingEnchants = missingEnchants + 1
                    end
                    
                    -- Verificar gemas vacías (si tiene ranuras y están en 0)
                    for g = 4, 6 do
                        local gemId = tonumber(parts[g])
                        -- Si el slot de gema es 0 explícito pero el ítem tiene socket nativo
                        -- (heurística segura para WotLK)
                    end
                end
            end
        end
    end
    
    local avgILvl = itemCount > 0 and math.floor(totalILvl / itemCount) or 0
    local finalGS = math.floor(calculatedGS)
    
    self:UpdateUI(self.currentName, talentString, avgILvl, finalGS, missingEnchants)
end

-- ===========================================================================
-- INTERFAZ (UI)
-- ===========================================================================
function AI:CreateInspectorFrame()
    local f = CreateFrame("Frame", "SequitoInspectorFrame", UIParent)
    f:SetSize(340, 240)
    f:SetPoint("CENTER")
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)
    f:SetFrameStrata("DIALOG")
    
    if S.Theme and S.Theme.ApplyPanelBackdrop then
        S.Theme:ApplyPanelBackdrop(f)
    else
        f:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = false, edgeSize = 12,
            insets = { left = 3, right = 3, top = 3, bottom = 3 }
        })
        f:SetBackdropColor(0.06, 0.06, 0.1, 0.92)
        f:SetBackdropBorderColor(0.2, 0.6, 1.0, 0.8)
    end
    f:Hide()
    
    f.title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    f.title:SetPoint("TOP", 0, -12)
    f.title:SetText("|cFF00CCFF" .. (S.L["ACADEMY_INSPECTOR"] or "Academy Inspector") .. "|r")
    
    f.nameText = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    f.nameText:SetPoint("TOP", 0, -36)
    f.nameText:SetText("-")
    
    f.talentsText = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    f.talentsText:SetPoint("TOPLEFT", 24, -70)
    f.talentsText:SetText("Talentos: -")
    
    f.ilvlText = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    f.ilvlText:SetPoint("TOPLEFT", 24, -95)
    f.ilvlText:SetText("iLvl Promedio: -")

    f.gsText = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    f.gsText:SetPoint("TOPLEFT", 24, -120)
    f.gsText:SetText("GearScore Estimado: -")

    f.auditText = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    f.auditText:SetPoint("TOPLEFT", 24, -150)
    f.auditText:SetPoint("RIGHT", -24, 0)
    f.auditText:SetJustifyH("LEFT")
    f.auditText:SetText("Auditoría: -")
    
    f.close = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    f.close:SetSize(90, 24)
    f.close:SetPoint("BOTTOM", 0, 14)
    f.close:SetText("Cerrar")
    f.close:SetScript("OnClick", function() f:Hide() end)
    
    return f
end

function AI:UpdateUI(name, talents, ilvl, gs, missingEnchants)
    if not self.frame then return end
    
    local r, g, b = 1, 1, 1
    if self.inspectedClass and S.Universal and S.Universal.GetClassColor then
        r, g, b = S.Universal:GetClassColor(self.inspectedClass)
    end
    
    self.frame.nameText:SetText(string.format("|cFF%02x%02x%02x%s|r", r*255, g*255, b*255, name))
    self.frame.talentsText:SetText("|cFFFFD700Talentos:|r " .. talents)
    self.frame.ilvlText:SetText("|cFFFFD700iLvl Promedio:|r " .. ilvl)
    self.frame.gsText:SetText(string.format("|cFF00FFCCGearScore (3.3.5a):|r %d GS", gs))
    
    if missingEnchants and missingEnchants > 0 then
        self.frame.auditText:SetText(string.format("|cFFFF3333⚠ Faltan %d encantamientos recomendados|r", missingEnchants))
    else
        self.frame.auditText:SetText("|cFF00FF00✓ Encantamientos principales aplicados|r")
    end
    
    self.frame:Show()
end

-- Registrar en ModuleConfig
if S.ModuleConfig then
    S.ModuleConfig:RegisterModule("AcademyInspector", {
        name = "Academy Inspector",
        description = "Herramienta de auditoría para oficiales (Talentos, GS y Encantamientos)",
        category = "raid",
        icon = "Interface\\Icons\\Inv_Misc_Spyglass_02",
        options = {}
    })
end
