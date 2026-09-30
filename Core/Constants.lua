--[[
    SEQUITO - Constants & Config
]]--

local addonName, S = ...

S.Constants = {
    SPHERE_SIZE = 64,
    BUTTON_SIZE = 32,
}

S.Classes = {} -- Module Registry

-- ===========================================================================
-- POLYFILLS FOR WOTLK 3.3.5a
-- ===========================================================================
if not C_Timer then
    C_Timer = {}
    local timerFrame = CreateFrame("Frame")
    timerFrame.tickers = {}
    timerFrame:Hide()
    
    timerFrame:SetScript("OnUpdate", function(self, elapsed)
        for i = #self.tickers, 1, -1 do
            local ticker = self.tickers[i]
            if ticker.cancelled then
                table.remove(self.tickers, i)
            else
                ticker.delay = ticker.delay - elapsed
                if ticker.delay <= 0 then
                    local success, err = pcall(ticker.callback)
                    if not success then
                        geterrorhandler()(err)
                    end
                    
                    if ticker.iterations then
                        ticker.iterations = ticker.iterations - 1
                        if ticker.iterations <= 0 then
                            table.remove(self.tickers, i)
                            ticker.cancelled = true
                        else
                            ticker.delay = ticker.duration
                        end
                    else
                        table.remove(self.tickers, i)
                        ticker.cancelled = true
                    end
                end
            end
        end
        if #self.tickers == 0 then
            self:Hide()
        end
    end)

    function C_Timer.After(duration, callback)
        table.insert(timerFrame.tickers, {
            delay = duration,
            callback = callback,
            duration = duration,
            iterations = nil
        })
        timerFrame:Show()
    end
    
    function C_Timer.NewTicker(duration, callback, iterations)
        local ticker = {
            delay = duration,
            callback = callback,
            duration = duration,
            iterations = iterations 
        }
        table.insert(timerFrame.tickers, ticker)
        timerFrame:Show()
        return ticker
    end
    
    function C_Timer.CancelTimer(ticker)
        if ticker then
            ticker.cancelled = true
        end
    end
    
    _G.C_Timer = C_Timer
end

-- Polyfill universal para Texture:SetTexture(r,g,b,a) y SetColorTexture (Ley II en WotLK 3.3.5a)
local dummyTex = CreateFrame("Frame"):CreateTexture()
local texMeta = getmetatable(dummyTex) and getmetatable(dummyTex).__index
if texMeta and texMeta.SetTexture then
    local orig_SetTexture = texMeta.SetTexture
    texMeta.SetTexture = function(self, ...)
        local arg1 = ...
        if type(arg1) == "number" then
            local r, g, b, a = ...
            orig_SetTexture(self, "Interface\\Buttons\\WHITE8X8")
            if self.SetVertexColor then
                self:SetVertexColor(r or 1, g or 1, b or 1, a or 1)
            end
        else
            return orig_SetTexture(self, ...)
        end
    end
    if not texMeta.SetColorTexture then
        texMeta.SetColorTexture = function(self, r, g, b, a)
            orig_SetTexture(self, "Interface\\Buttons\\WHITE8X8")
            if self.SetVertexColor then
                self:SetVertexColor(r or 1, g or 1, b or 1, a or 1)
            end
        end
    end
end

-- In WotLK 3.3.5a, COMBAT_LOG_EVENT_UNFILTERED passes args directly to OnEvent(self, event, ...).
-- CombatLogGetCurrentEventInfo does not exist natively and is not needed; individual modules consume arguments directly.

-- Polyfill for IsSpellKnown (doesn't exist in 3.3.5)
if not IsSpellKnown then
    function IsSpellKnown(spellID, isPet)
        local targetName = type(spellID) == "string" and spellID or GetSpellInfo(spellID)
        if not targetName then return false end
        
        local bookType = isPet and (BOOKTYPE_PET or "pet") or (BOOKTYPE_SPELL or "spell")
        
        -- Exact upper bound calculation via spellbook tabs
        local totalSpells = 0
        if not isPet and GetNumSpellTabs and GetSpellTabInfo then
            local numTabs = GetNumSpellTabs()
            if numTabs and numTabs > 0 then
                local _, _, offset, numSpells = GetSpellTabInfo(numTabs)
                totalSpells = (offset or 0) + (numSpells or 0)
            end
        end
        
        if totalSpells > 0 then
            for i = 1, totalSpells do
                local spellName = GetSpellName(i, bookType)
                if spellName == targetName then return true end
            end
        else
            local i = 1
            while true do
                local spellName = GetSpellName(i, bookType)
                if not spellName then break end
                if spellName == targetName then return true end
                i = i + 1
            end
        end
        
        -- Fallback to pet spellbook if checking general spell and player has pets (Warlock/Hunter/DK)
        if not isPet and HasPetSpells and HasPetSpells() then
            local numPetSpells = select(1, HasPetSpells()) or 0
            if numPetSpells > 0 then
                for i = 1, numPetSpells do
                    local spellName = GetSpellName(i, BOOKTYPE_PET or "pet")
                    if spellName == targetName then return true end
                end
            else
                local i = 1
                while true do
                    local spellName = GetSpellName(i, BOOKTYPE_PET or "pet")
                    if not spellName then break end
                    if spellName == targetName then return true end
                    i = i + 1
                end
            end
        end
        
        return false
    end
    _G.IsSpellKnown = IsSpellKnown
end

-- Polyfill for RegisterAddonMessagePrefix (doesn't exist in 3.3.5)
-- In WotLK 3.3.5, addon messages work without registration
if not RegisterAddonMessagePrefix then
    function RegisterAddonMessagePrefix(prefix)
        -- No-op in 3.3.5, messages work automatically
        return true
    end
    _G.RegisterAddonMessagePrefix = RegisterAddonMessagePrefix
end

-- Polyfill for UnitInRaid (doesn't exist in 3.3.5)
if not UnitInRaid then
    function UnitInRaid(unit)
        if GetNumRaidMembers() == 0 then return nil end
        for i = 1, GetNumRaidMembers() do
            if UnitIsUnit(unit, "raid"..i) then
                return i
            end
        end
        return nil
    end
    _G.UnitInRaid = UnitInRaid
end

-- Polyfill for IsInRaid (doesn't exist in 3.3.5)
if not IsInRaid then
    function IsInRaid()
        return GetNumRaidMembers() > 0
    end
    _G.IsInRaid = IsInRaid
end

-- Polyfill for IsInGroup (doesn't exist in 3.3.5)
if not IsInGroup then
    function IsInGroup()
        return GetNumPartyMembers() > 0 or GetNumRaidMembers() > 0
    end
    _G.IsInGroup = IsInGroup
end

-- Polyfill for GetNumGroupMembers (doesn't exist in 3.3.5)
if not GetNumGroupMembers then
    function GetNumGroupMembers()
        if GetNumRaidMembers() > 0 then
            return GetNumRaidMembers()
        else
            return GetNumPartyMembers()
        end
    end
    _G.GetNumGroupMembers = GetNumGroupMembers
end

-- Polyfill for GetServerTime (doesn't exist in 3.3.5)
if not GetServerTime then
    function GetServerTime()
        return time()
    end
    _G.GetServerTime = GetServerTime
end

-- Polyfill for BackdropTemplateMixin (doesn't exist in 3.3.5)
-- In WotLK, SetBackdrop is called directly on frames, not via template
-- This provides compatibility for code that uses "BackdropTemplate"
if not BackdropTemplateMixin then
    BackdropTemplateMixin = {}
    function BackdropTemplateMixin:OnBackdropLoaded()
        -- No-op, backdrop handled differently in 3.3.5
    end
    function BackdropTemplateMixin:SetupBackdrop()
        -- No-op
    end
    _G.BackdropTemplateMixin = BackdropTemplateMixin
end

-- Polyfill for wipe (should exist but just in case)
if not wipe then
    function wipe(t)
        for k in pairs(t) do
            t[k] = nil
        end
        return t
    end
    _G.wipe = wipe
end

-- Polyfill for GetContainerItemID (doesn't exist in 3.3.5)
-- In WotLK, we parse the item ID from the item link
if not GetContainerItemID then
    function GetContainerItemID(bag, slot)
        local link = GetContainerItemLink(bag, slot)
        if not link then return nil end
        local id = link:match("item:(%d+)")
        return id and tonumber(id) or nil
    end
    _G.GetContainerItemID = GetContainerItemID
end

-- Polyfill for UnitIsGroupLeader (doesn't exist in 3.3.5)
if not UnitIsGroupLeader then
    function UnitIsGroupLeader(unit)
        if GetNumRaidMembers() > 0 then
            for i = 1, GetNumRaidMembers() do
                local name, rank = GetRaidRosterInfo(i)
                if UnitIsUnit(unit, "raid"..i) then
                    return rank == 2
                end
            end
        else
            return IsPartyLeader()
        end
        return false
    end
    _G.UnitIsGroupLeader = UnitIsGroupLeader
end

-- Spell Name/ID Cache and Helpers
S.SpellCache = {}

function S.GetSpellNameByID(spellID)
    if not S.SpellCache[spellID] then
        S.SpellCache[spellID] = GetSpellInfo(spellID)
    end
    return S.SpellCache[spellID]
end

function S.GetSpellIDByName(spellName)
    -- Reverse lookup in cache
    for id, name in pairs(S.SpellCache) do
        if name == spellName then
            return id
        end
    end
    return nil
end

-- ===========================================================================
-- CHUNKED ADDON MESSAGING (Safe multi-packet transport for WoW 3.3.5a)
-- ===========================================================================
function S:SendChunkedAddonMessage(prefix, message, channel, target, chunkSize)
    if not message or message == "" then return end
    chunkSize = chunkSize or 190
    
    if RegisterAddonMessagePrefix then
        RegisterAddonMessagePrefix(prefix)
    end
    
    if #message <= chunkSize then
        SendAddonMessage(prefix, "RAW:" .. message, channel, target)
        return
    end
    
    local msgID = tostring(time()) .. "_" .. math.random(1000, 9999)
    local totalChunks = math.ceil(#message / chunkSize)
    
    for i = 1, totalChunks do
        local startIdx = (i - 1) * chunkSize + 1
        local endIdx = math.min(i * chunkSize, #message)
        local chunk = string.sub(message, startIdx, endIdx)
        -- Protocol: CHK:ID:INDEX:TOTAL:PAYLOAD
        local packet = string.format("CHK:%s:%d:%d:%s", msgID, i, totalChunks, chunk)
        SendAddonMessage(prefix, packet, channel, target)
    end
end

S.ChunkBuffers = S.ChunkBuffers or {}

function S:ReceiveChunkedAddonMessage(prefix, message, sender, onCompleteCallback)
    if not message or not onCompleteCallback then return end
    
    if message:sub(1, 4) == "RAW:" then
        onCompleteCallback(message:sub(5), sender)
        return
    end
    
    if message:sub(1, 4) == "CHK:" then
        local _, id, idx, total, payload = strsplit(":", message, 5)
        idx = tonumber(idx)
        total = tonumber(total)
        if not id or not idx or not total or not payload then return end
        
        local bufferKey = prefix .. "_" .. tostring(sender) .. "_" .. id
        if not S.ChunkBuffers[bufferKey] then
            S.ChunkBuffers[bufferKey] = { parts = {}, count = 0, total = total, time = GetTime() }
        end
        
        local buf = S.ChunkBuffers[bufferKey]
        if not buf.parts[idx] then
            buf.parts[idx] = payload
            buf.count = buf.count + 1
        end
        
        if buf.count == buf.total then
            local completePayload = table.concat(buf.parts, "")
            S.ChunkBuffers[bufferKey] = nil
            onCompleteCallback(completePayload, sender)
        end
    else
        -- Fallback for un-prefixed/legacy payloads
        onCompleteCallback(message, sender)
    end
end

