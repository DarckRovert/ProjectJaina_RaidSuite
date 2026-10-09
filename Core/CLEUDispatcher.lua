--[[
    SEQUITO - Combat Log Event Unfiltered (CLEU) Dispatcher
    Centralized high-performance event dispatcher for combat log parsing in WotLK 3.3.5a.
    Reduces CPU usage by replacing multiple independent listeners with a hash-mapped router.
]]--

local addonName, S = ...
S.CLEU = {}
local CLEU = S.CLEU

CLEU.Subscribers = {}
CLEU.AllSubscribers = {}

local eventFrame = CreateFrame("Frame", "JainaCLEUDispatcherFrame", UIParent)

-- Registrar un módulo a un sub-evento específico (ej. "UNIT_DIED", "SPELL_AURA_APPLIED")
function CLEU:Register(subEvent, callback)
    if not subEvent or type(callback) ~= "function" then return end
    
    if subEvent == "*" or subEvent == "ALL" then
        table.insert(self.AllSubscribers, callback)
        return
    end
    
    if not self.Subscribers[subEvent] then
        self.Subscribers[subEvent] = {}
    end
    table.insert(self.Subscribers[subEvent], callback)
end

-- Desregistrar un callback
function CLEU:Unregister(subEvent, callback)
    if not subEvent then return end
    
    local list = (subEvent == "*" or subEvent == "ALL") and self.AllSubscribers or self.Subscribers[subEvent]
    if list then
        for i = #list, 1, -1 do
            if list[i] == callback then
                table.remove(list, i)
                break
            end
        end
    end
end

-- Handler principal de CLEU optimizado
local function OnCombatLogEvent(self, event, ...)
    local timestamp, subEvent, sourceGUID, sourceName, sourceFlags, destGUID, destName, destFlags = ...
    if not subEvent then return end

    -- 1. Notificar a los suscriptores específicos de este sub-evento
    local subs = CLEU.Subscribers[subEvent]
    if subs then
        for i = 1, #subs do
            subs[i](...)
        end
    end

    -- 2. Notificar a suscriptores globales
    local all = CLEU.AllSubscribers
    if #all > 0 then
        for i = 1, #all do
            all[i](...)
        end
    end
end

function CLEU:Initialize()
    eventFrame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
    eventFrame:SetScript("OnEvent", OnCombatLogEvent)
end

-- Inicializar automáticamente
CLEU:Initialize()
