--[[
    SEQUITO - Minimap Button
    Botón de acceso rápido al Dashboard Unificado (v10.0)
]]

local addonName, S = ...
S.MinimapButton = {}
local MB = S.MinimapButton

-- DB for position
SequitoPositionsDB = SequitoPositionsDB or {}

function MB:Initialize()
    self:CreateButton()
    print("|cFFFF00FFSequito|r: [GUI] Botón de minimapa iniciado.")
end

function MB:CreateButton()
    local btn = CreateFrame("Button", "SequitoMinimapButton", Minimap)
    btn:SetSize(32, 32)
    btn:SetFrameStrata("MEDIUM")
    btn:SetFrameLevel(8)
    
    -- Icon
    btn.icon = btn:CreateTexture(nil, "BACKGROUND")
    btn.icon:SetTexture("Interface\\Icons\\Spell_Holy_MagicalSentry") -- Sequito Eye
    btn.icon:SetSize(20, 20)
    btn.icon:SetPoint("CENTER")
    
    -- Border (Circular look)
    btn.border = btn:CreateTexture(nil, "OVERLAY")
    btn.border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    btn.border:SetSize(52, 52)
    btn.border:SetPoint("TOPLEFT", 0, 0)
    
    -- Interaction
    btn:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    btn:SetScript("OnClick", function(self, button)
        if button == "LeftButton" then
            if S.Dashboard then S.Dashboard:Toggle() else print("Dashboard no cargado.") end
        else
            -- Context Menu?
            if S.Menu then S.Menu:Toggle() end
        end
    end)
    
    btn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:SetText("Sequito v" .. (S.Version or "?"))
        GameTooltip:AddLine("Click Izquierdo: Abrir Dashboard", 1, 1, 1)
        GameTooltip:AddLine("Click Derecho: Menú Rápido", 1, 1, 1)
        GameTooltip:Show()
    end)
    btn:SetScript("OnLeave", function() GameTooltip:Hide() end)
    
    -- Dragging Logic (Orbit around Minimap)
    btn:SetMovable(true)
    btn:RegisterForDrag("LeftButton")
    
    btn:SetScript("OnDragStart", function(self)
        self:SetScript("OnUpdate", function()
            local x, y = GetCursorPosition()
            local scale = Minimap:GetEffectiveScale()
            local cx, cy = Minimap:GetCenter()
            
            x, y = x/scale, y/scale
            
            local dx, dy = x - cx, y - cy
            local dist = math.sqrt(dx*dx + dy*dy)
            
            -- Normalize to radius
            local radius = 80
            local nx = dx / dist * radius
            local ny = dy / dist * radius
            
            self:ClearAllPoints()
            self:SetPoint("CENTER", Minimap, "CENTER", nx, ny)
            
            -- Save Angle for persistence
            self.angle = math.atan2(ny, nx)
        end)
    end)
    
    btn:SetScript("OnDragStop", function(self)
        self:SetScript("OnUpdate", nil)
        -- Save to DB
        if not SequitoPositionsDB.Minimap then SequitoPositionsDB.Minimap = {} end
        SequitoPositionsDB.Minimap.angle = self.angle
    end)
    
    -- Restore Position
    if SequitoPositionsDB.Minimap and SequitoPositionsDB.Minimap.angle then
        local angle = SequitoPositionsDB.Minimap.angle
        local radius = 80
        local x = math.cos(angle) * radius
        local y = math.sin(angle) * radius
        btn:SetPoint("CENTER", Minimap, "CENTER", x, y)
        local defaultAngle = math.rad(15)
        btn:SetPoint("CENTER", Minimap, "CENTER", math.cos(defaultAngle) * 80, math.sin(defaultAngle) * 80) -- Default position (15 deg)
    end
    
    self.frame = btn
end
