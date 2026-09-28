--[[
    SEQUITO - Trade Manager
    Auto-inserta piedras de salud en la ventana de trade.
]]--

local addonName, S = ...
S.Trade = {}
local T = S.Trade

function T:Initialize()
    if not S.db.profile.AutoTrade then return end
    
    self.Frame = CreateFrame("Frame")
    self.Frame:RegisterEvent("TRADE_SHOW")
    self.Frame:SetScript("OnEvent", function(self, event)
        T:OnTradeShow()
    end)
end

function T:OnTradeShow()
    if not S.db.profile.AutoTrade then return end
    
    local _, class = UnitClass("player")
    if class == "WARLOCK" then
        self:HandleWarlockTrade()
    end
end

function T:HandleWarlockTrade()
    -- IDs de Piedras de Salud (WotLK)
    local hsIDs = {
        47878, -- Master Healthstone (Rank 6)
        47877, -- Master Healthstone (Rank 5)
        47876, -- Master Healthstone (Rank 4)
        47875, -- Master Healthstone (Rank 3)
        47871, -- Master Healthstone (Rank 2)
        19001, -- Master Healthstone (Rank 1)
        36894, -- Fel Healthstone
        36893, -- Fel Healthstone
        36892, -- Fel Healthstone
        22105, -- Major Healthstone
        22104, -- Major Healthstone
        22103, -- Major Healthstone
        14803, -- Greater Healthstone
        14802, -- Greater Healthstone
        14801, -- Greater Healthstone
        5512,  -- Healthstone
        5511,  -- Healthstone
        5510,  -- Healthstone
        5509,  -- Lesser Healthstone
        5508,  -- Lesser Healthstone
        5507,  -- Lesser Healthstone
        19013, -- Minor Healthstone
        19012, -- Minor Healthstone
        19011, -- Minor Healthstone
    }
    
    for _, id in ipairs(hsIDs) do
        local count = GetItemCount(id)
        if count > 0 then
            -- Encontrar el item en las bolsas
            for bag = 0, 4 do
                for slot = 1, GetContainerNumSlots(bag) do
                    if GetContainerItemID(bag, slot) == id then
                        -- Poner en el primer slot de trade
                        PickupContainerItem(bag, slot)
                        ClickTradeButton(1)
                        print("|cFF9900FFSequito:|r Piedra de Salud ofrecida.")
                        return
                    end
                end
            end
        end
    end
end

-- Config
if S.ModuleConfig then
    S.ModuleConfig:RegisterModule("Trade", {
        name = "Gestor de Trade",
        description = "Auto-insertar piedras de salud y utilidades al comerciar.",
        category = "utility",
        icon = "Interface\\Icons\\INV_Misc_Coin_01",
        options = {
            {key = "AutoTrade", type = "checkbox", label = "Habilitar Auto-Trade", default = true}
        }
    })
end
