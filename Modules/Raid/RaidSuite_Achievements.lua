--[[
    SEQUITO - Achievements & Gamification
    Sistema de logros internos para gamificar la experiencia de guild.
    Parte del sistema "Economy & Gamification" (v9.0)
]]

local addonName, S = ...
S.Achievements = {}
local SA = S.Achievements

-- ===========================================================================
-- BASE DE DATOS DE LOGROS
-- ===========================================================================
SA.AchievementList = {
    [1] = { 
        id = 1, 
        title = S.L["ACH_INITIATE"] or "Iniciado", 
        desc = S.L["ACH_INITIATE_DESC"] or "Inicia sesión con el addon Sequito activo en tu hermandad.", 
        icon = "Interface\\Icons\\Inv_Misc_Book_09", 
        points = 10 
    },
    [2] = { 
        id = 2, 
        title = S.L["ACH_MACRO_MASTER"] or "Maestro de Macros", 
        desc = S.L["ACH_MACRO_MASTER_DESC"] or "Genera un conjunto de macros automáticas optimizadas para tu clase.", 
        icon = "Interface\\Icons\\Spell_Holy_Dizzy", 
        points = 10 
    },
    [3] = { 
        id = 3, 
        title = S.L["ACH_WIPE_SAVIOR"] or "Salvador de Banda", 
        desc = S.L["ACH_WIPE_SAVIOR_DESC"] or "Lanza un hechizo crucial de salvamento (Himno Divino, Tranquilidad o Renacer) en combate.", 
        icon = "Interface\\Icons\\Spell_Holy_DivineHymn", 
        points = 20 
    },
    [4] = { 
        id = 4, 
        title = "Alpha Striker", 
        desc = "Participa en la orden de combate Alpha Strike ejecutada por el líder de banda.", 
        icon = "Interface\\Icons\\Ability_Warrior_SavageBlow", 
        points = 15 
    },
    [5] = { 
        id = 5, 
        title = S.L["ACH_CANNON_FODDER"] or "Carne de Cañón", 
        desc = S.L["ACH_CANNON_FODDER_DESC"] or "Caer en combate durante una estancia o encuentro desafiante.", 
        icon = "Interface\\Icons\\Ability_Creature_Cursed_03", 
        points = 5 
    },
    [6] = { 
        id = 6, 
        title = "Coleccionista de Botín", 
        desc = "Recibir una asignación de pieza de botín a través del Consejo Sequito LootCouncil.", 
        icon = "Interface\\Icons\\INV_Box_01", 
        points = 15 
    },
    [7] = { 
        id = 7, 
        title = "Estratega de Cónclave", 
        desc = "Emitir tu voto en una encuesta activa del sistema democrático Sequito VotingSystem.", 
        icon = "Interface\\Icons\\INV_Scroll_03", 
        points = 10 
    },
    [8] = { 
        id = 8, 
        title = "Convocador del Coven", 
        desc = "Gestionar o iniciar una invocación colectiva utilizando el ritual SequitoCoven.", 
        icon = "Interface\\Icons\\Spell_Shadow_Twilight", 
        points = 15 
    },
}

-- ===========================================================================
-- INICIALIZACIÓN
-- ===========================================================================
function SA:Initialize()
    -- DB Check
    if not SequitoStatsDB then SequitoStatsDB = {} end
    if not SequitoStatsDB.Achievements then SequitoStatsDB.Achievements = {} end
    
    self.db = SequitoStatsDB.Achievements
    self:CreateToastFrame()
    self:RegisterEvents()
    
    -- Check "First Login" Achievement
    self:Unlock(1)
    
    -- Slash commands
    SLASH_SEQUITOACH1 = "/sach"
    SlashCmdList["SEQUITOACH"] = function()
        SA:ToggleBrowser()
    end
end

-- ===========================================================================
-- LOGICA DE DESBLOQUEO
-- ===========================================================================
function SA:Unlock(id)
    if not self.db then return end
    if self.db[id] then return end -- Ya desbloqueado
    
    local ach = self.AchievementList[id]
    if not ach then return end
    
    -- Marcar como completado
    self.db[id] = { 
        date = date("%d/%m/%y"), 
        timestamp = time() 
    }
    
    -- Notificación Toast y Sonido
    self:ShowToast(ach)
    PlaySound("LFG_RoleCheck") 
    
    -- Si el navegador está abierto, refrescarlo
    if self.BrowserFrame and self.BrowserFrame:IsShown() then
        self:UpdateBrowser()
    end

    if S.SendMessage then
        S:SendMessage("ACHIEVEMENT_UNLOCKED", id, ach)
    end
end

function SA:IsUnlocked(id)
    return self.db and self.db[id] ~= nil
end

function SA:GetTotalPoints()
    local current = 0
    local total = 0
    for id, ach in pairs(self.AchievementList) do
        total = total + (ach.points or 0)
        if self:IsUnlocked(id) then
            current = current + (ach.points or 0)
        end
    end
    return current, total
end

-- ===========================================================================
-- EVENT TRACKING
-- ===========================================================================
function SA:RegisterEvents()
    local f = CreateFrame("Frame")
    f:RegisterEvent("PLAYER_DEAD")
    
    f:SetScript("OnEvent", function(self, event, ...)
        if event == "PLAYER_DEAD" then
            SA:Unlock(5)
        end
    end)
    
    -- Hook Macro Generator
    if S.MacroGen and S.MacroGen.GenerateClassMacros then
        hooksecurefunc(S.MacroGen, "GenerateClassMacros", function()
            SA:Unlock(2)
        end)
    end

    -- Hook Voting System
    if S.VotingSystem and S.VotingSystem.Vote then
        hooksecurefunc(S.VotingSystem, "Vote", function()
            SA:Unlock(7)
        end)
    end

    -- Hook Hechizos de Salvador (Himno Divino, Tranquilidad, Rebirth)
    if S.CLEU and S.CLEU.Register then
        local saviorSpells = {
            [64843] = true, -- Divine Hymn
            [740]   = true, -- Tranquility
            [20484] = true, -- Rebirth
            [20608] = true, -- Reincarnation
        }
        S.CLEU:Register("SPELL_CAST_SUCCESS", function(timestamp, event, sourceGUID, sourceName, sourceFlags, destGUID, destName, destFlags, spellId)
            if sourceGUID == UnitGUID("player") and (saviorSpells[spellId] or (UnitAffectingCombat("player") and (spellId == 64843 or spellId == 740))) then
                SA:Unlock(3)
            end
        end)
    end

    -- Messages
    if S.RegisterMessage then
        S:RegisterMessage("COVEN_SUMMON_CLICKED", function()
            SA:Unlock(8)
        end)
        S:RegisterMessage("LOOT_AWARDED", function(event, itemLink, winner)
            local winnerName = winner or itemLink
            if winnerName and winnerName == UnitName("player") then
                SA:Unlock(6)
            end
        end)
        S:RegisterMessage("ALPHA_STRIKE_CALLED", function()
            SA:Unlock(4)
        end)
    end
end

-- ===========================================================================
-- UI: TOAST NOTIFICATION
-- ===========================================================================
function SA:CreateToastFrame()
    local f = CreateFrame("Frame", "SequitoToastFrame", UIParent)
    f:SetSize(300, 64)
    f:SetPoint("BOTTOM", 0, 180)
    f:SetFrameStrata("DIALOG")
    f:Hide()
    
    -- Background
    f.bg = f:CreateTexture(nil, "BACKGROUND")
    f.bg:SetTexture("Interface\\AchievementFrame\\UI-Achievement-Alert-Background")
    f.bg:SetTexCoord(0, 0.605, 0, 0.703)
    f.bg:SetAllPoints(f)
    
    -- Icon
    f.icon = f:CreateTexture(nil, "ARTWORK")
    f.icon:SetSize(50, 50)
    f.icon:SetPoint("LEFT", 8, 0)
    
    -- Titles
    f.title = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    f.title:SetPoint("TOPLEFT", 65, -15)
    f.title:SetText(S.L["ACHIEVEMENT_UNLOCKED"] or "Logro Desbloqueado")
    
    f.name = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    f.name:SetPoint("BOTTOMLEFT", 65, 15)
    f.name:SetWidth(220)
    f.name:SetJustifyH("LEFT")
    
    f.points = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    f.points:SetPoint("BOTTOMRIGHT", -15, 15)
    
    -- Animation
    f.anim = f:CreateAnimationGroup()
    local a1 = f.anim:CreateAnimation("Alpha")
    a1:SetChange(1)
    a1:SetDuration(0.4)
    a1:SetOrder(1)
    local a2 = f.anim:CreateAnimation("Alpha")
    a2:SetChange(-1)
    a2:SetStartDelay(3.5)
    a2:SetDuration(0.8)
    a2:SetOrder(2)
    
    f.anim:SetScript("OnFinished", function() f:Hide() end)
    
    self.toast = f
end

function SA:ShowToast(ach)
    local f = self.toast
    if not f then return end
    f:Show()
    f:SetAlpha(0)
    
    f.icon:SetTexture(ach.icon)
    f.name:SetText(ach.title)
    f.points:SetText("+" .. tostring(ach.points) .. " pts")
    
    f.anim:Stop()
    f.anim:Play()
    
    if S.Print then
        S:Print(string.format("|cFFFFD700¡Logro Desbloqueado!|r %s (+%d pts)", ach.title, ach.points))
    end
end

-- ===========================================================================
-- UI: ACHIEVEMENT BROWSER FRAME (Panel Visual Completo)
-- ===========================================================================
function SA:CreateBrowserFrame()
    if self.BrowserFrame then return self.BrowserFrame end

    local f = CreateFrame("Frame", "SequitoAchievementBrowser", UIParent)
    f:SetSize(620, 500)
    f:SetPoint("CENTER", UIParent, "CENTER", 0, 20)
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)
    f:SetFrameStrata("HIGH")

    -- Aplicar estilo y tema
    if S.Theme and S.Theme.ApplyPanelBackdrop then
        S.Theme:ApplyPanelBackdrop(f)
    else
        f:SetBackdrop({
            bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true, tileSize = 16, edgeSize = 16,
            insets = { left = 4, right = 4, top = 4, bottom = 4 }
        })
        f:SetBackdropColor(0.08, 0.08, 0.12, 0.95)
    end

    -- Header Title
    local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 20, -16)
    title:SetText("|cFFFFD700Logros de Hermandad & Proezas|r")
    f.title = title

    local subtitle = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    subtitle:SetPoint("TOPLEFT", 20, -38)
    subtitle:SetText("Gamificación interna del cónclave Sequito. ¡Desbloquea proezas en raid y eventos!")
    subtitle:SetTextColor(0.7, 0.7, 0.7)

    -- Close Button
    local closeBtn = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    closeBtn:SetPoint("TOPRIGHT", -8, -8)
    closeBtn:SetScript("OnClick", function() f:Hide() end)

    -- Summary Bar Container
    local barContainer = CreateFrame("Frame", nil, f)
    barContainer:SetSize(580, 28)
    barContainer:SetPoint("TOP", 0, -62)
    barContainer:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = false, edgeSize = 10,
        insets = { left = 2, right = 2, top = 2, bottom = 2 }
    })
    barContainer:SetBackdropColor(0.04, 0.04, 0.06, 0.8)
    barContainer:SetBackdropBorderColor(0.25, 0.25, 0.35, 0.7)

    local progressBar = CreateFrame("StatusBar", nil, barContainer)
    progressBar:SetPoint("TOPLEFT", 4, -4)
    progressBar:SetPoint("BOTTOMRIGHT", -4, 4)
    progressBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    progressBar:SetStatusBarColor(0.85, 0.65, 0.1, 0.85)

    local progressText = progressBar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    progressText:SetPoint("CENTER", progressBar, "CENTER", 0, 0)
    progressText:SetText("Puntos: 0 / 0 (0%)")
    f.progressText = progressText
    f.progressBar = progressBar

    -- Scroll Area
    local scrollFrame = CreateFrame("ScrollFrame", "SequitoAchScrollFrame", f, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", 18, -100)
    scrollFrame:SetPoint("BOTTOMRIGHT", -38, 16)

    local content = CreateFrame("Frame", nil, scrollFrame)
    content:SetSize(560, 10)
    scrollFrame:SetScrollChild(content)
    f.content = content

    self.BrowserFrame = f
    self.cardPool = {}

    self:UpdateBrowser()
    f:Hide()
    return f
end

function SA:UpdateBrowser()
    if not self.BrowserFrame then return end
    local f = self.BrowserFrame
    local content = f.content

    local currentPts, totalPts = self:GetTotalPoints()
    local pct = totalPts > 0 and math.floor((currentPts / totalPts) * 100) or 0

    if f.progressBar then
        f.progressBar:SetMinMaxValues(0, math.max(1, totalPts))
        f.progressBar:SetValue(currentPts)
    end
    if f.progressText then
        f.progressText:SetText(string.format("Puntuación Total: |cFFFFFFFF%d / %d|r Puntos (%d%%)", currentPts, totalPts, pct))
    end

    local cardHeight = 54
    local cardSpacing = 6
    local yOffset = 0

    local sortedList = {}
    for id, ach in pairs(self.AchievementList) do
        table.insert(sortedList, ach)
    end
    table.sort(sortedList, function(a, b)
        local aDone = SA:IsUnlocked(a.id) and 1 or 0
        local bDone = SA:IsUnlocked(b.id) and 1 or 0
        if aDone ~= bDone then
            return aDone > bDone
        end
        return a.id < b.id
    end)

    for i, ach in ipairs(sortedList) do
        local card = self.cardPool[i]
        if not card then
            card = CreateFrame("Frame", nil, content)
            card:SetSize(560, cardHeight)
            card:SetBackdrop({
                bgFile = "Interface\\Buttons\\WHITE8x8",
                edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
                tile = false, edgeSize = 10,
                insets = { left = 2, right = 2, top = 2, bottom = 2 }
            })

            local icon = card:CreateTexture(nil, "ARTWORK")
            icon:SetSize(38, 38)
            icon:SetPoint("LEFT", 8, 0)
            card.icon = icon

            local title = card:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            title:SetPoint("TOPLEFT", 54, -8)
            card.title = title

            local points = card:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            points:SetPoint("TOPRIGHT", -12, -8)
            card.points = points

            local desc = card:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            desc:SetPoint("TOPLEFT", 54, -26)
            desc:SetPoint("BOTTOMRIGHT", -120, 6)
            desc:SetJustifyH("LEFT")
            card.desc = desc

            local status = card:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            status:SetPoint("BOTTOMRIGHT", -12, 8)
            card.status = status

            self.cardPool[i] = card
        end

        card:SetPoint("TOPLEFT", 0, -yOffset)
        card:Show()

        local isUnlocked = self:IsUnlocked(ach.id)
        local info = self.db and self.db[ach.id]

        card.icon:SetTexture(ach.icon)
        card.desc:SetText(ach.desc or "")
        card.points:SetText(string.format("|cFFFFD700+%d pts|r", ach.points))

        if isUnlocked then
            card:SetBackdropColor(0.1, 0.22, 0.12, 0.85)
            card:SetBackdropBorderColor(0.25, 0.7, 0.3, 0.9)
            card.icon:SetDesaturated(false)
            card.title:SetText(string.format("|cFF40FF40%s|r", ach.title))
            local dateStr = info and info.date or "Completado"
            card.status:SetText(string.format("|cFF55FF55Desbloqueado (%s)|r", dateStr))
        else
            card:SetBackdropColor(0.06, 0.06, 0.08, 0.8)
            card:SetBackdropBorderColor(0.2, 0.2, 0.25, 0.6)
            card.icon:SetDesaturated(true)
            card.title:SetText(string.format("|cFF888888%s|r", ach.title))
            card.status:SetText("|cFF666666Bloqueado|r")
        end

        yOffset = yOffset + cardHeight + cardSpacing
    end

    -- Ocultar cards sobrantes
    for j = #sortedList + 1, #self.cardPool do
        self.cardPool[j]:Hide()
    end

    content:SetHeight(math.max(100, yOffset))
end

function SA:ToggleBrowser()
    local f = self:CreateBrowserFrame()
    if f:IsShown() then
        f:Hide()
    else
        self:UpdateBrowser()
        f:Show()
    end
end

-- Registrar en ModuleConfig
if S.ModuleConfig then
    S.ModuleConfig:RegisterModule("SequitoAchievements", {
        name = "Achievements",
        description = "Logros de Guild y Gamificación",
        category = "general",
        icon = "Interface\\Icons\\Inv_Misc_Wreath_01",
        options = {}
    })
end
