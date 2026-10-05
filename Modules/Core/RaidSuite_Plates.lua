--[[
    Sequito - SequitoPlates.lua
    Mejoras ligeras para Nameplates default de Blizzard (3.3.5)
    Version: 10.2.0
]]

local addonName, S = ...
S.Plates = {}
S.SequitoPlates = S.Plates
local P = S.Plates

P.Frame = CreateFrame("Frame")
P.Plates = {} -- Cache de frames procesados
P.ScanInterval = 0.1
P.TimeSinceLastScan = 0
P.NumChildren = 0

function P:Initialize()
    if not self:GetOption("enabled") then return end
    
    self.Frame:SetScript("OnUpdate", function(self, elapsed)
        P:OnUpdate(elapsed)
    end)
    
    print("|cFF00FFFFSequito|r: Plates module initiated.")
end

function P:GetOption(key)
    if S.ModuleConfig then
        return S.ModuleConfig:GetValue("SequitoPlates", key) or true
    end
    return true
end

function P:OnUpdate(elapsed)
    self.TimeSinceLastScan = self.TimeSinceLastScan + elapsed
    if self.TimeSinceLastScan < self.ScanInterval then return end
    self.TimeSinceLastScan = 0
    
    self:ScanPlates()
end

function P:ScanPlates()
    local numChildren = WorldFrame:GetNumChildren()
    if numChildren ~= self.NumChildren then
        self.NumChildren = numChildren
        for i = 1, numChildren do
            local frame = select(i, WorldFrame:GetChildren())
            if frame and not frame.seqProcessed and self:IsNameplate(frame) then
                self:ProcessPlate(frame)
            end
        end
    end
    
    -- Actualizar placas visibles
    for frame, _ in pairs(self.Plates) do
        if frame:IsShown() then
            self:UpdatePlate(frame)
        end
    end
end

function P:IsNameplate(frame)
    local name = frame:GetName()
    if name and string.find(name, "NamePlate") then return true end
    
    -- Check for Threat Glow Texture which is standard on 3.3.5 plates
    local regions = {frame:GetRegions()}
    local threatTexture = regions[2] -- Usually region 2 is threat texture
    
    if threatTexture and threatTexture:GetObjectType() == "Texture" and threatTexture:GetTexture() == "Interface\\TargetingFrame\\UI-TargetingFrame-Flash" then
        return true
    end
    
    return false
end

function P:ProcessPlate(frame)
    frame.seqProcessed = true
    self.Plates[frame] = true
    
    -- Health Bar Reference
    local children = {frame:GetChildren()}
    for _, child in ipairs(children) do
        if child:GetObjectType() == "StatusBar" then
            frame.healthBar = child
            break
        end
    end
    
    -- Name Reference
    local regions = {frame:GetRegions()}
    for _, region in ipairs(regions) do
        if region:GetObjectType() == "FontString" then
            frame.nameText = region
            break
        end
    end
    
    -- Crear Icono CC
    local scaleIdx = self:GetOption("scale")
    local scale = (type(scaleIdx) == "number" and scaleIdx) or 1.0
    frame.ccIcon = frame:CreateTexture(nil, "OVERLAY")
    frame.ccIcon:SetSize(25 * scale, 25 * scale)
    frame.ccIcon:SetPoint("BOTTOM", frame, "TOP", 0, 5)
    frame.ccIcon:SetTexture("Interface\\Icons\\Spell_Nature_Polymorph") -- Placeholder
    frame.ccIcon:Hide()
    
    -- Crear Threat Glow (Borde)
    frame.threatGlow = frame:CreateTexture(nil, "BACKGROUND")
    frame.threatGlow:SetPoint("TOPLEFT", frame, "TOPLEFT", -5, 5)
    frame.threatGlow:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 5, -5)
    frame.threatGlow:SetTexture("Interface\\Tooltips\\UI-Tooltip-Border")
    frame.threatGlow:Hide()
end

function P:UpdatePlate(frame)
    -- Obtener nombre
    if not frame.nameText then return end
    local name = frame.nameText:GetText()
    if not name then return end
    
    -- 1. CC Icons (from CCCoordinator)
    if S.CCCoordinator and S.CCCoordinator.ActiveCCs then
         local foundCC = false
         for guid, data in pairs(S.CCCoordinator.ActiveCCs) do
             local targetName = data.targetName or (S.CCCoordinator.GetNameFromGUID and S.CCCoordinator:GetNameFromGUID(guid))
             if targetName == name then
                  -- Found active CC on this unit name
                  frame.ccIcon:SetTexture(GetSpellTexture(data.spellId) or "Interface\\Icons\\INV_Misc_QuestionMark")
                  frame.ccIcon:Show()
                  foundCC = true
                  break
             end
         end
         
         if not foundCC then
             frame.ccIcon:Hide()
         end
    end
    
    -- 2. Threat (via Threat Region or Unit)
    -- Since we can't reliably get unit without mouseover, use the built-in threat texture region
    local regions = {frame:GetRegions()}
    local threatRegion = regions[2]
    if threatRegion and threatRegion:IsShown() then
        -- Native threat glow is shown, so we assume aggro
        local r, g, b = threatRegion:GetVertexColor()
        if r > 0.9 then -- Red (Aggro)
             frame.threatGlow:SetVertexColor(1, 0, 0)
             frame.threatGlow:Show()
        elseif r > 0.9 and g > 0.9 then -- Yellow (Warning)
             frame.threatGlow:SetVertexColor(1, 1, 0)
             frame.threatGlow:Show()
        else
             frame.threatGlow:Hide()
        end
    else
        frame.threatGlow:Hide()
    end
end

-- Config registration moved to ModuleConfig.lua

-- Init
if S.RegisterModule then
    S:RegisterModule("SequitoPlates", P)
else
    -- Fallback
    local f = CreateFrame("Frame")
    f:RegisterEvent("PLAYER_LOGIN")
    f:SetScript("OnEvent", function() P:Initialize() end)
end
