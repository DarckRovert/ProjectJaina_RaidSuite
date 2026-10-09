--[[
    SEQUITO - Loot Gallery
    Galería visual de botín épico/legendario obtenido.
    Parte del sistema "Economy & Gamification" (v9.0)
]]

local addonName, S = ...
S.LootGallery = {}
local LG = S.LootGallery

JainaLootDB = JainaLootDB or {}

-- ===========================================================================
-- CONFIGURACIÓN
-- ===========================================================================
LG.MinRarity = 4 -- Epic (4) and Legendary (5)

function LG:Initialize()
    self.frame = self:CreateGalleryFrame()
    self:RegisterEvents()
    self:RegisterCommands()
    print("|cFFFF00FFJaina|r: [Gamification] Galería de Loot activa.")
end

function LG:RegisterEvents()
    local f = CreateFrame("Frame")
    f:RegisterEvent("CHAT_MSG_LOOT")
    f:SetScript("OnEvent", function(self, event, msg)
        LG:ParseLoot(msg)
    end)

    -- Escuchar asignaciones directas del Concilio de Botín
    if S.RegisterMessage then
        S:RegisterMessage("LOOT_AWARDED", function(event, itemLink, winner)
            LG:RecordLoot(itemLink, winner or "Raid")
        end)
    end
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
-- LOOT RECORDING & PARSING ROBUSTO (WotLK 3.3.5a)
-- ===========================================================================
function LG:RecordLoot(itemInput, receiver)
    if not itemInput then return end
    
    local name, itemLink, quality, iLevel, reqLevel, class, subclass, maxStack, equipSlot, texture = GetItemInfo(itemInput)
    if not quality or quality < self.MinRarity then return end

    -- Prevenir registros duplicados de la misma pieza en una ventana de 5 segundos
    local now = GetTime()
    for _, entry in ipairs(JainaLootDB) do
        if entry.link == (itemLink or itemInput) and entry.timestamp and (now - entry.timestamp) < 5 then
            return
        end
    end

    table.insert(JainaLootDB, {
        link = itemLink or itemInput,
        icon = texture or "Interface\\Icons\\INV_Misc_QuestionMark",
        date = date("%d/%m %H:%M"),
        receiver = receiver or "Raid",
        timestamp = now
    })

    -- Mantener historial limitado a las últimas 50 piezas
    if #JainaLootDB > 50 then
        table.remove(JainaLootDB, 1)
    end

    if S.L and S.L["LOOT_LEGENDARY"] then
        print(string.format("|cFFFFD700[Jaina] %s: %s|r", S.L["LOOT_LEGENDARY"], itemLink or name or "Objeto"))
    end

    if self.frame and self.frame:IsShown() then
        self:UpdateGallery()
    end
end

function LG:ParseLoot(msg)
    if not msg then return end
    
    -- Extracción válida de hipervínculo completo o cadena de ítem nativa
    local fullLink = msg:match("(|c%x+|Hitem:.-|h%[.-%]|h|r)")
    local itemKey = fullLink or msg:match("(item:[%d:-]+)")
    if not itemKey then return end

    -- Extracción contextual del receptor (esES, esMX, enUS)
    local receiver = "Raid"
    local myName = UnitName("player")
    if msg:find("Has recibido") or msg:find("You receive") then
        receiver = myName
    else
        local who = msg:match("^([^%s]+) recibe") or msg:match("^([^%s]+) receives")
        if who then receiver = who end
    end

    self:RecordLoot(itemKey, receiver)
end

-- ===========================================================================
-- UI: GALLERY CON SCROLLCHILD
-- ===========================================================================
function LG:CreateGalleryFrame()
    local f = CreateFrame("Frame", "JainaGalleryFrame", UIParent)
    f:SetSize(400, 320)
    f:SetPoint("CENTER")
    f:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        edgeSize = 16,
        insets = {left = 4, right = 4, top = 4, bottom = 4}
    })
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)
    f:Hide()

    f.title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    f.title:SetPoint("TOP", 0, -15)
    f.title:SetText(S.L and S.L["LOOT_GALLERY"] or "Galería de Tesoros")

    -- ScrollFrame y ScrollChild nativos
    local scroll = CreateFrame("ScrollFrame", "JainaGalleryScrollFrame", f, "UIPanelScrollFrameTemplate")
    scroll:SetSize(340, 240)
    scroll:SetPoint("TOP", 0, -40)

    local content = CreateFrame("Frame", "JainaGalleryContent", scroll)
    content:SetSize(340, 240)
    scroll:SetScrollChild(content)

    f.container = scroll
    f.content = content
    f.icons = {}

    f.close = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    f.close:SetSize(80, 24)
    f.close:SetPoint("BOTTOM", 0, 10)
    f.close:SetText("Cerrar")
    f.close:SetScript("OnClick", function() f:Hide() end)

    return f
end

function LG:UpdateGallery()
    local x, y = 6, -6
    local size = 34
    local gap = 6
    local perRow = 8

    for _, btn in ipairs(self.icons) do btn:Hide() end

    local idx = 1
    for i = #JainaLootDB, 1, -1 do
        local item = JainaLootDB[i]
        local btn = self.icons[idx]

        if not btn then
            btn = CreateFrame("Button", nil, self.frame.content)
            btn:SetSize(size, size)
            btn:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square")

            btn:SetScript("OnEnter", function(self)
                if self.link then
                    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                    GameTooltip:SetHyperlink(self.link)
                    if self.receiver then
                        GameTooltip:AddLine("Obtenido por: |cFFFFD700" .. self.receiver .. "|r", 0.8, 0.8, 0.8)
                    end
                    GameTooltip:Show()
                end
            end)
            btn:SetScript("OnLeave", function() GameTooltip:Hide() end)
            self.icons[idx] = btn
        end

        btn:SetNormalTexture(item.icon or "Interface\\Icons\\INV_Misc_QuestionMark")
        btn.link = item.link
        btn.receiver = item.receiver
        btn:ClearAllPoints()
        btn:SetPoint("TOPLEFT", self.frame.content, "TOPLEFT", x, y)
        btn:Show()

        x = x + size + gap
        if (idx % perRow) == 0 then
            x = 6
            y = y - size - gap
        end
        idx = idx + 1
    end

    local totalRows = math.ceil((#JainaLootDB) / perRow)
    self.frame.content:SetHeight(math.max(240, totalRows * (size + gap) + 12))
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
