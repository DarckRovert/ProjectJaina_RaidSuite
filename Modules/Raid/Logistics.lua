--[[
    SEQUITO - Logistics Module (The Butler)
    Manejo de inventario, reparaciones y comercio.
]]--

local addonName, S = ...
S.Logistics = {}
local L = S.Logistics

-- Helper para obtener configuración
function S.Logistics:GetOption(key)
    if S.ModuleConfig then
        return S.ModuleConfig:GetValue("Logistics", key)
    end
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
    
    local f = CreateFrame("Frame")
    f:RegisterEvent("MERCHANT_SHOW")
    f:RegisterEvent("TRADE_SHOW")
    
    -- Solo registrar eventos de bolsa si somos Brujos (optimización)
    local _, class = UnitClass("player")
    if class == "WARLOCK" then
        f:RegisterEvent("BAG_UPDATE")
    end
    
    f:SetScript("OnEvent", function(self, event, ...)
        if event == "MERCHANT_SHOW" then
            S.Logistics:OnMerchantShow()
        elseif event == "TRADE_SHOW" then
            S.Logistics:OnTradeShow()
        elseif event == "BAG_UPDATE" then
            -- Throttle para no spammear CPU al mover items
            if not self.bagTimer then
                self.bagTimer = C_Timer.After(1, function()
                    S.Logistics:ManageShards()
                    self.bagTimer = nil
                end)
            end
        end
    end)
    

end

-- ===========================================================================
-- MERCADER (VENTA Y REPARACIÓN)
-- ===========================================================================
function S.Logistics:OnMerchantShow()
    if self:GetOption("autoSell") then
        self:SellJunk()
    end
    if self:GetOption("autoRepair") then
        self:Repair()
    end
end

function S.Logistics:SellJunk()
    local profit = 0
    local countSold = 0
    
    for bag = 0, 4 do
        for slot = 1, GetContainerNumSlots(bag) do
            local texture, count, locked, quality, readable = GetContainerItemInfo(bag, slot)
            -- Retrieve Link explicitly (WotLK API compatibility)
            local link = GetContainerItemLink(bag, slot)
            
            -- Quality 0 = Poor (Gris)
            if quality == 0 and link and not locked then 
                local _, _, _, _, _, _, _, _, _, _, itemSellPrice = GetItemInfo(link)
                if itemSellPrice and itemSellPrice > 0 then
                    profit = profit + (itemSellPrice * count)
                    countSold = countSold + 1
                    UseContainerItem(bag, slot)
                end
            end
        end
    end
    
    if profit > 0 then
        -- Usar GetCoinTextureString para formatear oro/plata/cobre
        print("|cFF00FF00Sequito|r: Basura vendida (" .. countSold .. " items) por: " .. GetCoinTextureString(profit))
    end
end

function S.Logistics:Repair()
    if CanMerchantRepair() then
        local cost, canRepair = GetRepairAllCost()
        if canRepair and cost > 0 then
            local money = GetMoney()
            if money >= cost then
                RepairAllItems()
                print("|cFF00FF00Sequito|r: Equipo reparado por: " .. GetCoinTextureString(cost))
            else
                print("|cFFFF0000Sequito|r: Fondos insuficientes para reparar (" .. GetCoinTextureString(cost) .. " necesarios).")
            end
        end
    end
end

-- ===========================================================================
-- COMERCIO (AUTO-TRADE)
-- ===========================================================================
function S.Logistics:OnTradeShow()
    if not self:GetOption("autoTrade") then return end
    
    -- Identificar destinatario de comercio legítimo
    local tradePartner = (TradeFrameRecipientNameText and TradeFrameRecipientNameText:GetText()) or (UnitExists("target") and UnitIsPlayer("target") and UnitName("target"))
    if not tradePartner or tradePartner == "" or tradePartner == UnitName("player") then return end
    
    if tradePartner then
        -- Warlock: Healthstone
        -- Mage: Water/Food
        local _, class = UnitClass("player")
        local itemID = nil
        
        if class == "WARLOCK" then
            -- Prioridad de Piedras (Nivel 80 -> Bajas)
            local stones = {36892, 36893, 36894, 22103, 22104, 22105} -- IDs aproximados WotLK
            itemID = self:FindItemAny(stones)
        elseif class == "MAGE" then
            -- Prioridad Agua (Maná Strudel o Glacial Water)
            local water = {43523, 65500, 65499} 
            itemID = self:FindItemAny(water)
        end
        
        if itemID then
             -- Slot 1 de trade
             local name, _, _, _, _, _, _ = GetTradePlayerItemInfo(1)
             if not name then
                 local bag, slot = self:FindItemLocation(itemID)
                 if bag and slot then
                     PickupContainerItem(bag, slot)
                     ClickTradeButton(1)
                     print("|cFF00FFFFSequito|r: Auto-Trade -> " .. (GetItemInfo(itemID) or "Item"))
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
-- GESTIÓN DE FRAGMENTOS (WARLOCK)
-- ===========================================================================
function S.Logistics:ManageShards()
    local shardID = 6265 -- Soul Shard
    local count = GetItemCount(shardID)
    local limit = self:GetOption("shardLimit") or 28
    
    -- Detectar ganancia/pérdida para sonido
    if not self.lastShardCount then self.lastShardCount = count end
    
    if count > self.lastShardCount then
        -- ¡Ganamos un fragmento! (Necrosis sound)
        PlaySoundFile("Sound\\Spells\\SoulDrain.wav")
    elseif count < self.lastShardCount then
        -- Perdimos/Usamos un fragmento
        -- PlaySoundFile("Sound\\Spells\\DrainSoulLoop.wav") -- Opcional
    end
    self.lastShardCount = count

    if count > limit then
        if InCombatLockdown() or CursorHasItem() then return end
        local toDelete = count - limit
        local deleted = 0
        
        for bag = 4, 0, -1 do
            for slot = GetContainerNumSlots(bag), 1, -1 do
                if deleted >= toDelete then break end
                if CursorHasItem() then break end
                
                local id = GetContainerItemID(bag, slot)
                if id == shardID then
                    PickupContainerItem(bag, slot)
                    if CursorHasItem() then
                        DeleteCursorItem()
                        deleted = deleted + 1
                    end
                end
            end
        end
        
        if deleted > 0 then
            print("|cFF888888Sequito: " .. deleted .. " Fragmentos de Alma purgados (Límite: " .. limit .. ")|r")
            PlaySoundFile("Sound\\Spells\\SoulShatter.wav") -- Sonido de destrucción
            self.lastShardCount = limit -- Reset para evitar falsas detecciones en la siguiente bolsa
        end
    end
end

-- Registrar módulo en ModuleConfig
if S.ModuleConfig then
    S.ModuleConfig:RegisterModule("Logistics", {
        name = "Logistics",
        description = "Gestión automática de inventario, reparaciones y comercio",
        category = "utility",
        icon = "Interface\\\\Icons\\\\INV_Misc_Bag_08",
        options = {
            {key = "enabled", type = "checkbox", label = "Habilitar Logistics", default = true},
            {key = "autoSell", type = "checkbox", label = "Vender basura automáticamente", default = true},
            {key = "autoRepair", type = "checkbox", label = "Reparar automáticamente", default = true},
            {key = "autoTrade", type = "checkbox", label = "Auto-trade (Healthstone/Water)", default = false},
            {key = "shardLimit", type = "slider", label = "Límite de Soul Shards", min = 10, max = 32, step = 1, default = 28},
        }
    })
end

