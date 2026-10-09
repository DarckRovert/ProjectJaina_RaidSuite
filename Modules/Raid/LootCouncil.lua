--[[
    SEQUITO - LootCouncil Module (Definitive Edition)
    Versión: 10.2.0 (Definitive Edition)
    Autor: DarckRovert (Ingame: Elnazzareno) & Antigravity (Mythos 5)
    Servidor: Project Jaina - Project Jaina (projectjaina.com)
    
    Sistema integral de Concilio de Botín para World of Warcraft 3.3.5a:
    - Cola automática de múltiples piezas épicas (Loot Queue).
    - Entrega directa en el juego para el Maestro Despojador (GiveMasterLoot).
    - Temporizador regresivo visual con alerta de expiración.
    - Respuestas estándar WotLK: Main Spec (MS), Off Spec (OS), Mejora Menor, Pase.
    - Intercepción automática de tiradas de dados (/azar 100 y /roll) para pugs.
    - Auditoría de idoneidad: tipos de armadura y marcas de santificación (tier tokens).
    - Desempate automático por tirada de dados.
    - Integridad de 1 voto transferible exclusivo para oficiales.
]]--

local addonName, S = ...
local L = S.L or {}
S.LootCouncil = S.LootCouncil or {}
local LC = S.LootCouncil

-- Variables de Estado
local currentSession = nil
local votes = {}
local candidates = {}
local councilMembers = {}
LC.LootQueue = {}

-- ============================================================================
-- BASE DE DATOS DE IDONEIDAD DE CLASE, ARMADURA Y TOKENS DE TIER (WotLK 3.3.5a)
-- ============================================================================
local CLASS_ARMOR = {
    PLATE = { WARRIOR = true, PALADIN = true, DEATHKNIGHT = true },
    MAIL = { HUNTER = true, SHAMAN = true, WARRIOR = true, PALADIN = true, DEATHKNIGHT = true },
    LEATHER = { ROGUE = true, DRUID = true, HUNTER = true, SHAMAN = true, WARRIOR = true, PALADIN = true, DEATHKNIGHT = true },
    CLOTH = { MAGE = true, WARLOCK = true, PRIEST = true, ROGUE = true, DRUID = true, HUNTER = true, SHAMAN = true, WARRIOR = true, PALADIN = true, DEATHKNIGHT = true }
}

-- Clases primarias óptimas por armadura
local PRIMARY_ARMOR = {
    PLATE = { WARRIOR = true, PALADIN = true, DEATHKNIGHT = true },
    MAIL = { HUNTER = true, SHAMAN = true },
    LEATHER = { ROGUE = true, DRUID = true },
    CLOTH = { MAGE = true, WARLOCK = true, PRIEST = true }
}

-- Marcas de Santificación de ICC / Trofeos de ToC / Tier Tokens
local TIER_TOKENS = {
    -- Vencedor (Vanquisher)
    ["vencedor"] = { ROGUE = true, DEATHKNIGHT = true, MAGE = true, DRUID = true },
    ["vanquisher"] = { ROGUE = true, DEATHKNIGHT = true, MAGE = true, DRUID = true },
    -- Protector (Protector)
    ["protector"] = { WARRIOR = true, HUNTER = true, SHAMAN = true },
    -- Conquistador (Conqueror)
    ["conquistador"] = { PALADIN = true, PRIEST = true, WARLOCK = true },
    ["conqueror"] = { PALADIN = true, PRIEST = true, WARLOCK = true }
}

-- ============================================================================
-- CONFIGURACIÓN Y AYUDANTES
-- ============================================================================
function LC:GetOption(key)
    if S.ModuleConfig then
        return S.ModuleConfig:GetValue("LootCouncil", key)
    end
    return true
end

function LC:Initialize()
    if not self:GetOption("enabled") then
        return
    end
    
    self.frame = self:CreateFrame()
    self:RegisterEvents()
end

function LC:IsOfficer(name)
    if not name then return false end
    if name == UnitName("player") then
        return IsRaidLeader() or IsRaidOfficer() or (GetNumPartyMembers() > 0 and UnitIsPartyLeader("player"))
    end
    for i = 1, GetNumRaidMembers() do
        local n, rank = GetRaidRosterInfo(i)
        if n == name then
            return rank >= 1
        end
    end
    if GetNumPartyMembers() > 0 and UnitIsPartyLeader(name) then
        return true
    end
    return false
end

function LC:GetPlayerClass(playerName)
    if not playerName then return nil end
    if playerName == UnitName("player") then
        local _, class = UnitClass("player")
        return class
    end
    for i = 1, GetNumRaidMembers() do
        local n, _, _, _, _, class = GetRaidRosterInfo(i)
        if n == playerName then
            return class
        end
    end
    for i = 1, GetNumPartyMembers() do
        if UnitName("party" .. i) == playerName then
            local _, class = UnitClass("party" .. i)
            return class
        end
    end
    return nil
end

-- ============================================================================
-- RESOLUCIÓN CONTEXTUAL DE CANAL DE RED Y CHAT (WotLK 3.3.5a)
-- ============================================================================
function LC:GetGroupChannel()
    if IsInInstance then
        local inInstance, instanceType = IsInInstance()
        if inInstance and instanceType == "pvp" then
            return "BATTLEGROUND"
        end
    end
    if GetNumRaidMembers and GetNumRaidMembers() > 0 then
        return "RAID"
    elseif GetNumPartyMembers and GetNumPartyMembers() > 0 then
        return "PARTY"
    end
    return nil
end

function LC:SendChat(msg)
    local channel = self:GetGroupChannel()
    if channel then
        SendChatMessage(msg, channel)
    else
        local f = DEFAULT_CHAT_FRAME or ChatFrame1
        if f and f.AddMessage then
            f:AddMessage(msg)
        end
    end
end

function LC:SendComm(msg)
    local channel = self:GetGroupChannel()
    if channel then
        SendAddonMessage("SeqLC", msg, channel)
    end
end

-- ============================================================================
-- AUDITORÍA DE IDONEIDAD DE ÍTEM / TOKEN
-- ============================================================================
function LC:CheckItemSuitability(itemLink, playerClass)
    if not itemLink or not playerClass then return true, "" end
    
    local itemName, _, _, _, _, itemType, itemSubType = GetItemInfo(itemLink)
    if not itemName then return true, "" end
    
    local lowerName = itemName:lower()
    
    -- Comprobar si es un token de tier (Marca de Santificación)
    for tokenKey, classes in pairs(TIER_TOKENS) do
        if lowerName:find(tokenKey) then
            if classes[playerClass] then
                return true, "|cFF00FF00[Token Apto]|r"
            else
                return false, "|cFFFF2020[Token Inválido]|r"
            end
        end
    end
    
    -- Comprobar armadura
    if itemType == "Armadura" or itemType == "Armor" then
        local sub = (itemSubType or ""):lower()
        local armorKey = nil
        if sub:find("placa") or sub:find("plate") then armorKey = "PLATE"
        elseif sub:find("malla") or sub:find("mail") then armorKey = "MAIL"
        elseif sub:find("cuero") or sub:find("leather") then armorKey = "LEATHER"
        elseif sub:find("tela") or sub:find("cloth") then armorKey = "CLOTH"
        end
        
        if armorKey then
            if PRIMARY_ARMOR[armorKey] and PRIMARY_ARMOR[armorKey][playerClass] then
                return true, "|cFF00FF00[Armadura Óptima]|r"
            elseif CLASS_ARMOR[armorKey] and CLASS_ARMOR[armorKey][playerClass] then
                return true, "|cFFFFFF00[Equipable]|r"
            else
                return false, "|cFFFF2020[No Equipable]|r"
            end
        end
    end
    
    return true, ""
end

-- ============================================================================
-- INTERFAZ VISUAL MODERNA Y ROBUSTA
-- ============================================================================
function LC:CreateFrame()
    local f = CreateFrame("Frame", "JainaLootCouncilFrame", UIParent)
    f:SetSize(480, 360)
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
    
    -- Título
    f.title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    f.title:SetPoint("TOP", 0, -12)
    f.title:SetText("|cFFFFD100Jaina Loot Council|r")
    
    -- Icono del Ítem con Tooltip
    f.itemIcon = CreateFrame("Button", nil, f)
    f.itemIcon:SetSize(44, 44)
    f.itemIcon:SetPoint("TOPLEFT", 18, -40)
    f.itemTexture = f.itemIcon:CreateTexture(nil, "ARTWORK")
    f.itemTexture:SetAllPoints()
    
    f.itemIcon:SetScript("OnEnter", function(self)
        if currentSession and currentSession.item then
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetHyperlink(currentSession.item)
            GameTooltip:Show()
        end
    end)
    f.itemIcon:SetScript("OnLeave", function() GameTooltip:Hide() end)
    
    -- Nombre del Ítem
    f.itemName = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    f.itemName:SetPoint("TOPLEFT", f.itemIcon, "TOPRIGHT", 12, -2)
    f.itemName:SetJustifyH("LEFT")
    f.itemName:SetText("Esperando botín...")
    
    -- Subtítulo / Cola y Temporizador
    f.statusText = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    f.statusText:SetPoint("TOPLEFT", f.itemName, "BOTTOMLEFT", 0, -6)
    f.statusText:SetText("")
    
    -- Scroll frame para candidatos
    f.scroll = CreateFrame("ScrollFrame", "JainaLCLootScroll", f, "UIPanelScrollFrameTemplate")
    f.scroll:SetPoint("TOPLEFT", 18, -95)
    f.scroll:SetPoint("BOTTOMRIGHT", -35, 75)
    
    f.content = CreateFrame("Frame", nil, f.scroll)
    f.content:SetSize(425, 200)
    f.scroll:SetScrollChild(f.content)
    
    -- Botón Cerrar
    f.close = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    f.close:SetPoint("TOPRIGHT", -5, -5)
    
    -- ========================================================================
    -- BOTONES DE RESPUESTA DE USUARIO (MS / OS / MEJORA / PASAR)
    -- ========================================================================
    f.msBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    f.msBtn:SetSize(85, 24)
    f.msBtn:SetPoint("BOTTOMLEFT", 18, 42)
    f.msBtn:SetText("|cFF00FF00Main Spec|r")
    f.msBtn:SetScript("OnClick", function() LC:Respond("MS") end)
    
    f.osBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    f.osBtn:SetSize(85, 24)
    f.osBtn:SetPoint("LEFT", f.msBtn, "RIGHT", 6, 0)
    f.osBtn:SetText("|cFF3399FFOff Spec|r")
    f.osBtn:SetScript("OnClick", function() LC:Respond("OS") end)
    
    f.minorBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    f.minorBtn:SetSize(85, 24)
    f.minorBtn:SetPoint("LEFT", f.osBtn, "RIGHT", 6, 0)
    f.minorBtn:SetText("|cFFFFFF00Mejora|r")
    f.minorBtn:SetScript("OnClick", function() LC:Respond("MINOR") end)
    
    f.passBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    f.passBtn:SetSize(75, 24)
    f.passBtn:SetPoint("LEFT", f.minorBtn, "RIGHT", 6, 0)
    f.passBtn:SetText("Pasar")
    f.passBtn:SetScript("OnClick", function() LC:Respond("PASS") end)
    
    -- ========================================================================
    -- CONTROLES DEL MAESTRO DESPOJADOR / OFICIALES (LÍNEA INFERIOR)
    -- ========================================================================
    f.nextBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    f.nextBtn:SetSize(130, 24)
    f.nextBtn:SetPoint("BOTTOMLEFT", 18, 12)
    f.nextBtn:SetText("Siguiente en Cola")
    f.nextBtn:SetScript("OnClick", function()
        if LC:IsOfficer(UnitName("player")) then
            LC:EndSession(nil)
        end
    end)
    
    f.announceBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    f.announceBtn:SetSize(130, 24)
    f.announceBtn:SetPoint("LEFT", f.nextBtn, "RIGHT", 8, 0)
    f.announceBtn:SetText("Anunciar Estado")
    f.announceBtn:SetScript("OnClick", function()
        LC:AnnounceStatus()
    end)

    -- Control de Temporizador en OnUpdate
    f.elapsedTimer = 0
    f:SetScript("OnUpdate", function(self, elapsed)
        self.elapsedTimer = self.elapsedTimer + elapsed
        if self.elapsedTimer >= 0.25 then
            self.elapsedTimer = 0
            LC:OnUpdateTimer()
        end
    end)
    
    return f
end

-- ============================================================================
-- TEMPORIZADOR REGRESIVO
-- ============================================================================
function LC:OnUpdateTimer()
    if not currentSession then return end
    
    local maxTime = tonumber(self:GetOption("votingTime")) or 60
    local elapsed = GetTime() - (currentSession.startTime or GetTime())
    local remaining = math.max(0, maxTime - elapsed)
    
    local queueCount = #self.LootQueue
    local queueText = (queueCount > 0) and (" | |cFF00FF00" .. queueCount .. " en cola|r") or ""
    
    local timeColor = (remaining > 15) and "|cFFFFFFFF" or "|cFFFF2020"
    self.frame.statusText:SetText(string.format("Tiempo restante: %s%ds|r%s", timeColor, math.ceil(remaining), queueText))
    
    -- Auto-expiración
    if remaining <= 0 and not currentSession.timeExpired then
        currentSession.timeExpired = true
        if self:IsOfficer(UnitName("player")) then
            local topCand, topVotes, isTie = self:GetTopCandidate()
            if topCand and topVotes > 0 then
                self:SendChat(string.format("[Jaina] Tiempo agotado. Ganador sugerido: %s (%d votos)", topCand, topVotes))
            else
                self:SendChat("[Jaina] Tiempo de votación agotado.")
            end
        end
    end
end

-- ============================================================================
-- RESPUESTAS Y REGISTRO DE EVENTOS
-- ============================================================================
function LC:Respond(response)
    if not currentSession then return end
    self:SendComm(response .. ":" .. currentSession.item)
    self.frame.msBtn:Disable()
    self.frame.osBtn:Disable()
    self.frame.minorBtn:Disable()
    self.frame.passBtn:Disable()
end

function LC:RegisterEvents()
    local events = CreateFrame("Frame")
    events:RegisterEvent("LOOT_OPENED")
    events:RegisterEvent("CHAT_MSG_ADDON")
    events:RegisterEvent("CHAT_MSG_SYSTEM")
    events:SetScript("OnEvent", function(_, event, ...)
        if event == "LOOT_OPENED" then
            LC:OnLootOpened()
        elseif event == "CHAT_MSG_ADDON" then
            LC:OnAddonMessage(...)
        elseif event == "CHAT_MSG_SYSTEM" then
            LC:OnSystemMessage(...)
        end
    end)
    if RegisterAddonMessagePrefix then
        RegisterAddonMessagePrefix("SeqLC")
    end
end

function LC:OnSystemMessage(msg)
    if not currentSession or not msg then return end
    
    -- Interceptar tiradas de dados en esMX, esES y enUS:
    local roller, minR, maxR, rollVal = msg:match("([^%s]+)%s+tira los dados%s+%(?(%d+)%-(%d+)%)?%s+y obtiene%s+(%d+)")
    if not roller then
        roller, rollVal, minR, maxR = msg:match("([^%s]+)%s+rolls%s+(%d+)%s+%(?(%d+)%-(%d+)%)?")
    end
    
    if roller and rollVal then
        local rNum = tonumber(rollVal) or 0
        candidates[roller] = candidates[roller] or { response = "Roll: " .. rNum, voteCount = 0 }
        candidates[roller].response = "Roll: " .. rNum
        candidates[roller].roll = rNum
        self:UpdateDisplay()
    end
end

-- ============================================================================
-- COLA DE BOTÍN (LOOT QUEUE) Y GESTIÓN DE SESIONES
-- ============================================================================
function LC:AddToQueue(link, slot)
    for _, item in ipairs(self.LootQueue) do
        if item.slot == slot and item.link == link then
            return
        end
    end
    table.insert(self.LootQueue, { link = link, slot = slot })
end

function LC:ProcessNextInQueue()
    if #self.LootQueue > 0 then
        local nextItem = table.remove(self.LootQueue, 1)
        self:StartSession(nextItem.link, nextItem.slot)
    end
end

function LC:StartSession(itemLink, slot)
    if not self:IsOfficer(UnitName("player")) then
        if S.Print then S:Print(L["LC_ONLY_LEADER"] or "Solo oficiales pueden iniciar Loot Council.") end
        return
    end
    
    if self:GetOption("autoOpen") == false then
        return
    end
    
    currentSession = {
        item = itemLink,
        slot = slot,
        startTime = GetTime(),
        timeExpired = false
    }
    votes = {}
    candidates = {}
    
    -- Habilitar botones de respuesta
    self.frame.msBtn:Enable()
    self.frame.osBtn:Enable()
    self.frame.minorBtn:Enable()
    self.frame.passBtn:Enable()
    
    self:SendComm("START:" .. itemLink .. (slot and (":" .. slot) or ""))
    self:UpdateDisplay()
    self.frame:Show()
end

function LC:Vote(playerName, response)
    if not currentSession then return end
    if not self:IsOfficer(UnitName("player")) then
        if S.Print then S:Print("|cFFFF0000[LootCouncil] Solo oficiales verificados pueden emitir votos.|r") end
        return
    end
    self:SendComm("VOTE:" .. playerName .. ":" .. (response or "VOTE"))
end

-- ============================================================================
-- ENTREGA DIRECTA EN EL JUEGO (GiveMasterLoot) Y FINALIZACIÓN
-- ============================================================================
function LC:AwardLoot(winner)
    if not currentSession or not winner then return end
    if not self:IsOfficer(UnitName("player")) then return end
    
    -- Intentar entrega directa si es Master Looter y el cadáver sigue abierto
    local lootMethod, mlPartyId, mlRaidId = GetLootMethod()
    if lootMethod == "master" and currentSession.slot then
        local numItems = GetNumLootItems()
        if numItems and numItems > 0 and currentSession.slot <= numItems then
            for i = 1, 40 do
                local candidateName = GetMasterLootCandidate(currentSession.slot, i)
                if candidateName and candidateName == winner then
                    GiveMasterLoot(currentSession.slot, i)
                    break
                end
            end
        end
    end
    
    -- Cerrar y anunciar
    self:EndSession(winner)
end

function LC:EndSession(winner)
    if currentSession then
        self:SendComm("END:" .. (winner or ""))
        
        if self:GetOption("announceResults") and winner and winner ~= "" then
            self:SendChat("[Jaina] " .. string.format(L["LC_WINNER"] or "Ganador de %s: %s", currentSession.item, winner))
        end
        
        if S.SendMessage and winner and winner ~= "" then
            S:SendMessage("LOOT_AWARDED", currentSession.item, winner)
        end
        
        currentSession = nil
        self.frame:Hide()
        
        -- Si quedan piezas en la cola, arrancar la siguiente de inmediato
        if #self.LootQueue > 0 then
            self:ProcessNextInQueue()
        end
    end
end

-- ============================================================================
-- CÁLCULO DE CANDIDATO GANADOR Y DESEMPATE
-- ============================================================================
function LC:GetTopCandidate()
    local topCand = nil
    local topVotes = -1
    local topRoll = -1
    local isTie = false
    
    for name, data in pairs(candidates) do
        local v = data.voteCount or 0
        local r = data.roll or 0
        if v > topVotes then
            topVotes = v
            topRoll = r
            topCand = name
            isTie = false
        elseif v == topVotes and v > 0 then
            isTie = true
            -- Desempate por tirada de dados
            if r > topRoll then
                topCand = name
                topRoll = r
            end
        end
    end
    
    return topCand, topVotes, isTie
end

function LC:AnnounceStatus()
    if not currentSession then return end
    local topCand, topVotes, isTie = self:GetTopCandidate()
    if topCand and topVotes > 0 then
        local tieStr = isTie and " (Empate resuelto por dados)" or ""
        self:SendChat(string.format("[Jaina] Votación de %s: Líder %s con %d votos%s", currentSession.item, topCand, topVotes, tieStr))
    else
        self:SendChat(string.format("[Jaina] Votación en curso para %s", currentSession.item))
    end
end

-- ============================================================================
-- RENDERIZADO VISUAL
-- ============================================================================
function LC:UpdateDisplay()
    if not currentSession then return end
    
    local _, _, _, _, _, _, _, _, _, texture = GetItemInfo(currentSession.item)
    self.frame.itemTexture:SetTexture(texture or "Interface\\Icons\\INV_Misc_QuestionMark")
    self.frame.itemName:SetText(currentSession.item)
    
    local isOfficer = self:IsOfficer(UnitName("player"))
    local isML = (select(1, GetLootMethod()) == "master" and isOfficer)
    
    -- Ocultar filas previas
    if self.rows then
        for _, row in pairs(self.rows) do
            row:Hide()
        end
    end
    
    local yOffset = 0
    for name, data in pairs(candidates) do
        local row = self:GetCandidateRow(name)
        row:SetPoint("TOPLEFT", self.frame.content, "TOPLEFT", 0, -yOffset)
        
        -- Color de clase
        local playerClass = self:GetPlayerClass(name)
        local color = playerClass and RAID_CLASS_COLORS[playerClass] or {r=1, g=1, b=1}
        row.name:SetText(string.format("|cFF%02x%02x%02x%s|r", color.r*255, color.g*255, color.b*255, name))
        
        -- Formatear respuesta y compatibilidad
        local _, suitTag = self:CheckItemSuitability(currentSession.item, playerClass)
        local resp = data.response or "Pendiente"
        if resp == "MS" then resp = "|cFF00FF00[MS]|r"
        elseif resp == "OS" then resp = "|cFF3399FF[OS]|r"
        elseif resp == "MINOR" then resp = "|cFFFFFF00[Mejora]|r"
        elseif resp == "PASS" then resp = "|cFF888888[Pase]|r"
        end
        
        row.response:SetText(resp .. " " .. suitTag)
        row.votes:SetText(tostring(data.voteCount or 0) .. " votos")
        
        if isOfficer then
            row.voteBtn:Show()
            if isML then
                row.awardBtn:Show()
            else
                row.awardBtn:Hide()
            end
        else
            row.voteBtn:Hide()
            row.awardBtn:Hide()
        end
        
        row:Show()
        yOffset = yOffset + 26
    end
end

function LC:GetCandidateRow(name)
    if not self.rows then self.rows = {} end
    if not self.rows[name] then
        local row = CreateFrame("Frame", nil, self.frame.content)
        row:SetSize(425, 24)
        
        row.name = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        row.name:SetPoint("LEFT", 5, 0)
        row.name:SetWidth(95)
        row.name:SetJustifyH("LEFT")
        
        row.response = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        row.response:SetPoint("LEFT", row.name, "RIGHT", 5, 0)
        row.response:SetWidth(150)
        row.response:SetJustifyH("LEFT")
        
        row.votes = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        row.votes:SetPoint("LEFT", row.response, "RIGHT", 5, 0)
        row.votes:SetWidth(60)
        row.votes:SetJustifyH("LEFT")
        
        -- Botón Votar (Oficiales)
        row.voteBtn = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
        row.voteBtn:SetSize(48, 20)
        row.voteBtn:SetPoint("RIGHT", -52, 0)
        row.voteBtn:SetText("Votar")
        row.voteBtn:SetScript("OnClick", function() LC:Vote(name, "VOTE") end)
        
        -- Botón Entregar (Master Looter)
        row.awardBtn = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
        row.awardBtn:SetSize(48, 20)
        row.awardBtn:SetPoint("RIGHT", -2, 0)
        row.awardBtn:SetText("|cFF00FF00Dar|r")
        row.awardBtn:SetScript("OnClick", function() LC:AwardLoot(name) end)
        
        self.rows[name] = row
    end
    return self.rows[name]
end

-- ============================================================================
-- APERTURA DE BOTÍN
-- ============================================================================
function LC:OnLootOpened()
    if not self:IsOfficer(UnitName("player")) then return end
    if not self:GetOption("enabled") then return end
    
    local numItems = GetNumLootItems()
    local foundAny = false
    
    for slot = 1, numItems do
        if LootSlotIsItem(slot) then
            local link = GetLootSlotLink(slot)
            if link then
                local _, _, quality = GetItemInfo(link)
                if quality and quality >= 4 then
                    self:AddToQueue(link, slot)
                    foundAny = true
                end
            end
        end
    end
    
    if foundAny and not currentSession then
        self:ProcessNextInQueue()
    end
end

-- ============================================================================
-- COMUNICACIÓN DE RED (ADDON MESSAGES)
-- ============================================================================
function LC:OnAddonMessage(prefix, msg, channel, sender)
    if prefix ~= "SeqLC" then return end
    
    local cmd, data = strsplit(":", msg, 2)
    if cmd == "START" then
        local itemLink, slotStr = strsplit(":", data, 2)
        currentSession = {
            item = itemLink,
            slot = tonumber(slotStr),
            startTime = GetTime(),
            timeExpired = false
        }
        candidates = {}
        votes = {}
        self.frame.msBtn:Enable()
        self.frame.osBtn:Enable()
        self.frame.minorBtn:Enable()
        self.frame.passBtn:Enable()
        self:UpdateDisplay()
        self.frame:Show()
    elseif cmd == "MS" or cmd == "OS" or cmd == "MINOR" or cmd == "PASS" or cmd == "NEED" or cmd == "GREED" then
        -- Mapeo retrocompatible
        local mappedResp = cmd
        if cmd == "NEED" then mappedResp = "MS"
        elseif cmd == "GREED" then mappedResp = "OS"
        end
        candidates[sender] = candidates[sender] or {response = mappedResp, voteCount = 0}
        candidates[sender].response = mappedResp
        self:UpdateDisplay()
    elseif cmd == "VOTE" then
        if not self:IsOfficer(sender) then return end
        local target = data
        if target and candidates[target] then
            local prevTarget = votes[sender]
            if prevTarget and candidates[prevTarget] and prevTarget ~= target then
                candidates[prevTarget].voteCount = math.max(0, (candidates[prevTarget].voteCount or 1) - 1)
            end
            if prevTarget ~= target then
                votes[sender] = target
                candidates[target].voteCount = (candidates[target].voteCount or 0) + 1
            end
            self:UpdateDisplay()
        end
    elseif cmd == "END" then
        if data and data ~= "" and currentSession and S.SendMessage then
            S:SendMessage("LOOT_AWARDED", currentSession.item, data)
        end
        currentSession = nil
        self.frame:Hide()
        if #self.LootQueue > 0 then
            self:ProcessNextInQueue()
        end
    end
end

function LC:Toggle()
    if not self.frame then return end
    if self.frame:IsShown() then
        self.frame:Hide()
    else
        self.frame:Show()
    end
end

function LC:SlashCommand(msg)
    local cmd, arg = strsplit(" ", msg, 2)
    if cmd == "start" and arg then
        self:StartSession(arg)
    elseif cmd == "end" then
        self:EndSession(arg)
    elseif cmd == "next" then
        self:EndSession(nil)
    else
        self:Toggle()
    end
end

-- ============================================================================
-- REGISTRO EN CONFIGURACIÓN
-- ============================================================================
if S.ModuleConfig then
    S.ModuleConfig:RegisterModule("LootCouncil", {
        name = "Loot Council",
        icon = "Interface\\Icons\\INV_Misc_Coin_01",
        description = "Sistema automatizado de votación y distribución de botín con cola y GiveMasterLoot.",
        category = "raid",
        options = {
            {
                type = "checkbox",
                key = "enabled",
                label = "Habilitar Loot Council",
                tooltip = "Activa/desactiva el sistema de loot council",
                default = true,
            },
            {
                type = "checkbox",
                key = "autoOpen",
                label = "Abrir Automáticamente",
                tooltip = "Abre la ventana y encola automáticamente las piezas épicas al despojar jefes",
                default = true,
            },
            {
                type = "checkbox",
                key = "announceResults",
                label = "Anunciar Resultados",
                tooltip = "Anuncia los resultados y ganadores en el chat de banda",
                default = true,
            },
            {
                type = "slider",
                key = "votingTime",
                label = "Tiempo de Votación (seg)",
                tooltip = "Tiempo límite para emitir votos antes de la expiración",
                min = 15,
                max = 180,
                step = 15,
                default = 60,
            },
        },
    })
end

-- Inicializar módulo
if S.RegisterModule then
    S:RegisterModule("LootCouncil", LC)
else
    local loader = CreateFrame("Frame")
    loader:RegisterEvent("PLAYER_LOGIN")
    loader:SetScript("OnEvent", function() LC:Initialize() end)
end
