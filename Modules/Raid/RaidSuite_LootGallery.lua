--[[
    SEQUITO - Loot Gallery
    Galería visual de botín épico/legendario obtenido.
    Parte del sistema "Economy & Gamification" (v9.0)
]]

local addonName, S = ...
S.LootGallery = {}
local LG = S.LootGallery

SequitoLootDB = SequitoLootDB or {}

-- ===========================================================================
-- CONFIGURACIÓN
-- ===========================================================================
LG.MinRarity = 4 -- Epic (4) and Legendary (5)

function LG:Initialize()
    self.frame = self:CreateGalleryFrame()
    self:RegisterEvents()
    self:RegisterCommands()
    print("|cFFFF00FFSequito|r: [Gamification] Galería de Loot activa.")
end

function LG:RegisterEvents()
    local f = CreateFrame("Frame")
    f:RegisterEvent("CHAT_MSG_LOOT")
    f:SetScript("OnEvent", function(self, event, msg)
        LG:ParseLoot(msg)
    end)
end

function LG:RegisterCommands()
    SLASH_SEQUITOGALLERY1 = "/sgallery"
    SLASH_SEQUITOGALLERY2 = "/seqlg"
    SlashCmdList["SEQUITOGALLERY"] = function() 
        LG.frame:Show()
        LG:UpdateGallery() 
    end
end

-- ===========================================================================
-- LOOT PARSING
-- ===========================================================================
function LG:ParseLoot(msg)
    -- Format: "You receive loot: [Item Link]." or "X receives loot: [Item Link]."
    -- Simple extraction strategy
    local link = string.match(msg, "|Hitem:.-|h")
    if not link then return end
    
    local name, itemLink, quality, iLevel, reqLevel, class, subclass, maxStack, equipSlot, texture, vendorPrice = GetItemInfo(link)
    
    if quality and quality >= self.MinRarity then
        -- We found epic loot!
        -- Check if it's for player (simplified: save all raid epics seen to build a "Guild History")
        -- Or strictly personal? Let's make it Guild History for the Hive Mind feel.
        
        table.insert(SequitoLootDB, {
            link = itemLink,
            icon = texture,
            date = date("%d/%m"),
            receiver = "Raid" -- Parsing receiver name from msg needs locale patterns, skipping for robust simplicity
        })
        
        -- Cap DB size (last 50 items)
        if #SequitoLootDB > 50 then
            table.remove(SequitoLootDB, 1)
        end
        
        -- Notification
        print(string.format("|cFFFFD700[Sequito] %s|r", S.L["LOOT_LEGENDARY"] or "Loot Epico Registrado"))
    end
end

-- ===========================================================================
-- UI: GALLERY (GRID)
-- ===========================================================================
function LG:CreateGalleryFrame()
    local f = CreateFrame("Frame", "SequitoGalleryFrame", UIParent)
    f:SetSize(400, 300)
    f:SetPoint("CENTER")
    f:SetBackdrop({bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background", edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border", edgeSize = 16, insets = {left = 4, right = 4, top = 4, bottom = 4}})
    f:Hide()
    
    f.title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    f.title:SetPoint("TOP", 0, -15)
    f.title:SetText(S.L["LOOT_GALLERY"] or "Galería de Tesoros")
    
    f.container = CreateFrame("ScrollFrame", nil, f)
    f.container:SetSize(360, 240)
    f.container:SetPoint("TOP", 0, -40)
    
    f.icons = {}
    
    f.close = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    f.close:SetSize(80, 25)
    f.close:SetPoint("BOTTOM", 0, 10)
    f.close:SetText("Cerrar")
    f.close:SetScript("OnClick", function() f:Hide() end)
    
    return f
end

function LG:UpdateGallery()
    -- Simple Grid Render
    local x, y = 10, -10
    local size = 32
    local gap = 5
    local perRow = 8
    
    for i, data in ipairs(self.icons) do data:Hide() end -- Clear old
    
    -- Show latest last? No, latest first (reverse iterate)
    local idx = 1
    for i = #SequitoLootDB, 1, -1 do
        local item = SequitoLootDB[i]
        
        if not self.icons[idx] then
            local icon = CreateFrame("Button", nil, self.frame.container)
            icon:SetSize(size, size)
            icon:SetNormalTexture(item.icon)
            icon:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square")
            
            icon:SetScript("OnEnter", function(self)
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                GameTooltip:SetHyperlink(self.link)
                GameTooltip:Show()
            end)
            icon:SetScript("OnLeave", function() GameTooltip:Hide() end)
            
            self.icons[idx] = icon
        end
        
        local btn = self.icons[idx]
        btn:SetNormalTexture(item.icon)
        btn.link = item.link
        btn:SetPoint("TOPLEFT", x, y)
        btn:Show()
        
        x = x + size + gap
        if (idx % perRow) == 0 then
            x = 10
            y = y - size - gap
        end
        
        idx = idx + 1
    end
end

-- Registrar en ModuleConfig
if S.ModuleConfig then
    S.ModuleConfig:RegisterModule("LootGallery", {
        name = "Loot Gallery",
        description = "Historial visual de botín épico",
        category = "general",
        icon = "Interface\\Icons\\Inv_Box_01",
        options = {}
    })
end
