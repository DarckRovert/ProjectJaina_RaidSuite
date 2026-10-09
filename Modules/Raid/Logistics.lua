--[[
    SEQUITO - Logistics Module (The Butler)
    Manejo Seguro de Inventario, Reparaciones y Fragmentos de Alma
    Version: 8.0.0 (WotLK 3.3.5a Build 12340)
]]--

local addonName, S = ...
S.Logistics = {}
local L = S.Logistics

-- Helper para obtener configuración
function S.Logistics:GetOption(key)
    if S.ModuleConfig then
        return S.ModuleConfig:GetValue("Logistics", key)
    end
    if key == "enabled" then return true end
    if key == "autoSell" then return true end
    if key == "autoRepair" then return true end
    if key == "autoTrade" then return false end
    if key == "shardLimit" then return 28 end
    return true
end

-- ===========================================================================
-- INICIALIZACIÓN
-- ===========================================================================
function S.Logistics:Initialize()
    if self.initialized then return end
    if not self:GetOption("enabled") then
        return
    end
    self.initialized = true

    local f = CreateFrame("Frame", "JainaLogisticsFrame", UIParent)
    self.eventFrame = f
    f:RegisterEvent("MERCHANT_SHOW")
    f:RegisterEvent("TRADE_SHOW")

    -- Solo registrar eventos de bolsa si somos Brujos (optimización de CPU)
    local _, class = UnitClass("player")
    if class == "WARLOCK" then
        f:RegisterEvent("BAG_UPDATE")
        self:InitBagTicker()
    end

    f:SetScript("OnEvent", function(self, event, ...)
        if event == "MERCHANT_SHOW" then
            S.Logistics:OnMerchantShow()
        elseif event == "TRADE_SHOW" then
            S.Logistics:OnTradeShow()
        elseif event == "BAG_UPDATE" then
            -- Banderola para procesar mediante ticker OnUpdate sin C_Timer (Ley II & IV)
            if S.Logistics.bagTicker then
                S.Logistics.bagTicker.pending = true
            end
        end
    end)
end

-- ===========================================================================
-- TICKER ONUPDATE SEGURO PARA BOLSAS (WARLOCK)
-- ===========================================================================
function S.Logistics:InitBagTicker()
    if self.bagTicker then return end

    local ticker = CreateFrame("Frame")
    ticker.elapsed = 0
    ticker.pending = false

    ticker:SetScript("OnUpdate", function(f, elapsed)
        if not f.pending then return end
        f.elapsed = f.elapsed + elapsed
        if f.elapsed >= 1.0 then -- Throttle de 1 segundo para agrupar ráfagas de BAG_UPDATE
            f.elapsed = 0
            f.pending = false
            S.Logistics:ManageShards()
        end
    end)

    self.bagTicker = ticker
end

-- ===========================================================================
-- MERCADER (VENTA Y REPARACIÓN)
-- ===========================================================================
function S.Logistics:OnMerchantShow()
    if not MerchantFrame or not MerchantFrame:IsShown() then return end

    if self:GetOption("autoSell") then
        self:SellJunk()
    end
    if self:GetOption("autoRepair") then
        self:Repair()
    end
end

function S.Logistics:SellJunk()
    if not MerchantFrame or not MerchantFrame:IsShown() then return end

    local profit = 0
    local countSold = 0

    for bag = 0, 4 do
        for slot = 1, GetContainerNumSlots(bag) do
            local texture, count, locked, quality, readable = GetContainerItemInfo(bag, slot)
            local link = GetContainerItemLink(bag, slot)

            -- Calidad 0 = Gris (Poor)
            if quality == 0 and link and not locked then
                local _, _, _, _, _, _, _, _, _, _, itemSellPrice = GetItemInfo(link)
                if itemSellPrice and itemSellPrice > 0 then
                    profit = profit + (itemSellPrice * (count or 1))
                    countSold = countSold + 1
                    UseContainerItem(bag, slot)
                end
            end
        end
    end

    if profit > 0 then
        local coinStr = GetCoinTextureString and GetCoinTextureString(profit) or (profit .. " cobre")
        print("|cFF00FF00[Jaina]|r Basura vendida (" .. countSold .. " objetos) por: " .. coinStr)
    end
end

function S.Logistics:Repair()
    if not CanMerchantRepair or not CanMerchantRepair() then return end

    local cost, canRepair = GetRepairAllCost()
    if canRepair and cost > 0 then
        local money = GetMoney()
        if money >= cost then
            RepairAllItems()
            local coinStr = GetCoinTextureString and GetCoinTextureString(cost) or (cost .. " cobre")
            print("|cFF00FF00[Jaina]|r Equipo reparado por: " .. coinStr)
        else
            local coinStr = GetCoinTextureString and GetCoinTextureString(cost) or (cost .. " cobre")
            print("|cFFFF0000[Jaina]|r Fondos insuficientes para reparar (" .. coinStr .. " necesarios).")
        end
    end
end

-- ===========================================================================
-- COMERCIO SEGURO (AUTO-TRADE)
-- ===========================================================================
function S.Logistics:OnTradeShow()
    if not self:GetOption("autoTrade") then return end
    if InCombatLockdown() or CursorHasItem() then return end

    local tradePartner = (TradeFrameRecipientNameText and TradeFrameRecipientNameText:GetText()) or (UnitExists("target") and UnitIsPlayer("target") and UnitName("target"))
    if not tradePartner or tradePartner == "" or tradePartner == UnitName("player") then return end

    local _, class = UnitClass("player")
    local itemID = nil

    if class == "WARLOCK" then
        -- Healthstones WotLK (Prioridad de nivel 80 hacia abajo)
        local stones = { 36892, 36893, 36894, 22103, 22104, 22105, 5512, 5511 }
        itemID = self:FindItemAny(stones)
    elseif class == "MAGE" then
        -- Agua y comida de mago (Mana Strudel / Glacial Water)
        local water = { 43523, 65500, 65499 }
        itemID = self:FindItemAny(water)
    end

    if itemID then
        local name = GetTradePlayerItemInfo(1)
        if not name then
            local bag, slot = self:FindItemLocation(itemID)
            if bag and slot then
                ClearCursor()
                PickupContainerItem(bag, slot)
                if CursorHasItem() then
                    ClickTradeButton(1)
                    ClearCursor()
                    local itemName = GetItemInfo(itemID) or "Objeto"
                    print("|cFF00FFFF[Jaina]|r Auto-Trade colocado: " .. itemName)
                end
            end
        end
    end
end

function S.Logistics:FindItemAny(idList)
    for _, id in ipairs(idList) do
        if GetItemCount(id) > 0 then return id end
    end
    return nil
end

function S.Logistics:FindItemLocation(itemID)
    for bag = 0, 4 do
        for slot = 1, GetContainerNumSlots(bag) do
            local id = GetContainerItemID(bag, slot)
            if id == itemID then return bag, slot end
        end
    end
    return nil, nil
end

-- ===========================================================================
-- GESTIÓN SEGURA DE FRAGMENTOS DE ALMA (WARLOCK)
-- ===========================================================================
function S.Logistics:ManageShards()
    local _, class = UnitClass("player")
    if class ~= "WARLOCK" then return end

    -- Guardias de seguridad absoluta (Zero Data Loss)
    if InCombatLockdown() or CursorHasItem() then return end

    local shardID = 6265 -- Soul Shard
    local count = GetItemCount(shardID)
    local limit = tonumber(self:GetOption("shardLimit")) or 28

    if not self.lastShardCount then
        self.lastShardCount = count
    end

    if count > self.lastShardCount then
        -- Ganancia de fragmento
        PlaySoundFile("Sound\\Spells\\SoulDrain.wav")
    end
    self.lastShardCount = count

    if count > limit then
        local toDelete = count - limit
        local deleted = 0

        for bag = 4, 0, -1 do
            for slot = GetContainerNumSlots(bag), 1, -1 do
                if deleted >= toDelete then break end
                if InCombatLockdown() or CursorHasItem() then break end

                -- Doble verificación atómica de ID antes de tocar el slot
                local id = GetContainerItemID(bag, slot)
                if id == shardID then
                    ClearCursor()
                    PickupContainerItem(bag, slot)

                    -- Solo borrar si el cursor sostiene exactamente el fragmento levantado
                    if CursorHasItem() then
                        DeleteCursorItem()
                        ClearCursor()
                        deleted = deleted + 1
                    end
                end
            end
        end

        if deleted > 0 then
            print("|cFF888888[Jaina] " .. deleted .. " Fragmentos de Alma purgados (Límite: " .. limit .. ")|r")
            PlaySoundFile("Sound\\Spells\\SoulShatter.wav")
            self.lastShardCount = limit
        end
    end
end

-- ===========================================================================
-- COMANDOS SLASH
-- ===========================================================================
function S.Logistics:SlashCommand(msg)
    msg = msg and msg:lower():gsub("^%s*(.-)%s*$", "%1") or ""

    if msg == "sell" then
        self:SellJunk()
    elseif msg == "repair" then
        self:Repair()
    elseif msg == "shards" or msg == "purge" then
        self:ManageShards()
    elseif msg == "config" or msg == "options" then
        if S.ModuleConfig then
            S.ModuleConfig:OpenCategory("Logistics")
        end
    else
        print("|cFF00FFFF[Jaina Logistics]|r Comandos:")
        print("  |cFFFFFFFF/logistics sell|r - Vender objetos basura manualmente")
        print("  |cFFFFFFFF/logistics repair|r - Reparar equipo manualmente")
        print("  |cFFFFFFFF/logistics shards|r - Purgar fragmentos de alma sobrantes (Brujo)")
        print("  |cFFFFFFFF/logistics config|r - Abrir panel de configuración")
    end
end

SLASH_LOGISTICS1 = "/logistics"
SLASH_LOGISTICS2 = "/butler"
SLASH_LOGISTICS3 = "/seqlogistics"
SlashCmdList["LOGISTICS"] = function(msg)
    S.Logistics:SlashCommand(msg)
end

-- Registro dinámico en ModuleConfig
if S.ModuleConfig then
    S.ModuleConfig:RegisterModule("Logistics", {
        name = "Logistics",
        description = "Gestión automática de inventario, reparaciones y comercio",
        category = "utility",
        icon = "Interface\\Icons\\INV_Misc_Bag_08",
        options = {
            {key = "enabled", type = "checkbox", label = "Habilitar Logistics", default = true},
            {key = "autoSell", type = "checkbox", label = "Vender basura automáticamente", default = true},
            {key = "autoRepair", type = "checkbox", label = "Reparar automáticamente", default = true},
            {key = "autoTrade", type = "checkbox", label = "Auto-trade (Healthstone/Water)", default = false},
            {key = "shardLimit", type = "slider", label = "Límite de Soul Shards", min = 10, max = 32, step = 1, default = 28},
        }
    })
end

local loader = CreateFrame("Frame")
loader:RegisterEvent("PLAYER_LOGIN")
loader:SetScript("OnEvent", function()
    S.Logistics:Initialize()
end)
