--[[
    SEQUITO - Minimap Button
    Botón de acceso rápido al Dashboard Unificado (v10.0)
]]

local addonName, S = ...
S.MinimapButton = S.MinimapButton or {}
local MB = S.MinimapButton

-- DB for position
JainaPositionsDB = JainaPositionsDB or {}

function MB:Initialize()
    self:CreateButton()
end

function MB:UpdateVisibility()
    if not self.frame then return end
    local shouldShow = true
    if S.db and S.db.profile and S.db.profile.ShowMinimap ~= nil then
        shouldShow = S.db.profile.ShowMinimap
    end
    if shouldShow then
        self.frame:Show()
    else
        self.frame:Hide()
    end
end

function MB:CreateButton()
    if self.frame or _G["JainaMinimapButton"] then
        self.frame = self.frame or _G["JainaMinimapButton"]
        return self.frame
    end

    local btn = CreateFrame("Button", "JainaMinimapButton", Minimap)
    btn:SetSize(32, 32)
    btn:SetFrameStrata("MEDIUM")
    btn:SetFrameLevel(8)
    btn:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
    
    -- Icono oficial Jaina Eye
    btn.icon = btn:CreateTexture(nil, "BACKGROUND")
    btn.icon:SetTexture("Interface\\Icons\\Spell_Holy_MagicalSentry")
    btn.icon:SetSize(20, 20)
    btn.icon:SetPoint("CENTER")
    
    -- Borde circular estándar de minimapa
    btn.border = btn:CreateTexture(nil, "OVERLAY")
    btn.border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    btn.border:SetSize(52, 52)
    btn.border:SetPoint("TOPLEFT", 0, 0)
    
    -- Interacciones
    btn:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    btn:SetScript("OnClick", function(self, button)
        if button == "LeftButton" then
            if S.Dashboard and S.Dashboard.Toggle then
                S.Dashboard:Toggle()
            elseif S.Menu and S.Menu.Toggle then
                S.Menu:Toggle()
            end
        else
            if S.Menu and S.Menu.Toggle then
                S.Menu:Toggle()
            elseif S.Options and S.Options.Toggle then
                S.Options:Toggle()
            end
        end
    end)
    
    btn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:SetText("|cFFFFD437Jaina|r v" .. (S.Version or "11.2"))
        GameTooltip:AddLine("Click Izquierdo: Abrir Dashboard", 1, 1, 1)
        GameTooltip:AddLine("Click Derecho: Menú Rápido", 1, 1, 1)
        GameTooltip:Show()
    end)
    btn:SetScript("OnLeave", function() GameTooltip:Hide() end)
    
    -- Lógica de arrastre orbital alrededor del Minimapa
    btn:SetMovable(true)
    btn:RegisterForDrag("LeftButton")
    
    btn:SetScript("OnDragStart", function(self)
        self:LockHighlight()
        self:SetScript("OnUpdate", function()
            local x, y = GetCursorPosition()
            local scale = Minimap:GetEffectiveScale()
            local cx, cy = Minimap:GetCenter()
            
            x, y = x/scale, y/scale
            local dx, dy = x - cx, y - cy
            local dist = math.sqrt(dx*dx + dy*dy)
            if dist == 0 then dist = 1 end
            
            local radius = 80
            local nx = (dx / dist) * radius
            local ny = (dy / dist) * radius
            
            self:ClearAllPoints()
            self:SetPoint("CENTER", Minimap, "CENTER", nx, ny)
            self.angle = math.atan2(ny, nx)
        end)
    end)
    
    btn:SetScript("OnDragStop", function(self)
        self:UnlockHighlight()
        self:SetScript("OnUpdate", nil)
        if not JainaPositionsDB.Minimap then JainaPositionsDB.Minimap = {} end
        JainaPositionsDB.Minimap.angle = self.angle
    end)
    
    -- Restaurar posición guardada o anclar en posición inicial (15 grados)
    local angle = (JainaPositionsDB.Minimap and JainaPositionsDB.Minimap.angle) or math.rad(15)
    local radius = 80
    local x = math.cos(angle) * radius
    local y = math.sin(angle) * radius
    btn:ClearAllPoints()
    btn:SetPoint("CENTER", Minimap, "CENTER", x, y)
    
    self.frame = btn
    if S.GUI then
        S.GUI.MinimapBtn = btn
    end

    self:UpdateVisibility()
    return btn
end
