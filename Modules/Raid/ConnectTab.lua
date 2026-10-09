--[[
    Jaina - ConnectTab.lua (Renombrado: RaidCmd)
    Pestaña de Comando de Raid (Hive Mind)
    Herramientas de gestión y estrategia para líderes.
]]

local addonName, S = ...
local CT = {}
S.RaidCmd = CT
local L = S.L or {}

function CT:Initialize()
    if not S.Dashboard then return end
    
    self.frame = self:CreateFrame()
    S.Dashboard:RegisterTab("Hive Mind", "Interface\\Icons\\Spell_Shadow_Charm", self.frame)
    
    print("|cFF00FF00Jaina|r: [RaidCmd] Tab Hive Mind registrado.")
end

function CT:CreateFrame()
    local f = CreateFrame("Frame", "JainaHiveMindFrame", UIParent)
    f:SetSize(600, 450) -- Tamaño ajustado al Dashboard
    f:Hide()
    
    -- Título
    local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 20, -20)
    title:SetText("Centro de Mando (Hive Mind)")
    
    -- Subtítulo de estado
    f.status = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    f.status:SetPoint("LEFT", title, "RIGHT", 10, 0)
    f.status:SetText("- Estado: " .. (S.RaidSync and "Activo" or "Inactivo"))
    f.status:SetTextColor(0, 1, 0)
    
    -- =======================================================================
    -- SECCIÓN 1: REMOTE CONFIG (Oficiales)
    -- =======================================================================
    local grp1 = self:CreateGroup(f, "Configuración Remota (Solo Oficiales)", 60)
    
    local btnSyncProfile = CreateFrame("Button", nil, grp1, "UIPanelButtonTemplate")
    btnSyncProfile:SetSize(180, 25)
    btnSyncProfile:SetPoint("TOPLEFT", 10, -10)
    btnSyncProfile:SetText("Transmitir mi Perfil")
    btnSyncProfile:SetScript("OnClick", function() 
        if S.RaidSync then 
            -- Confirmación antes de enviar
            StaticPopupDialogs["SEQUITO_SEND_PROFILE"] = {
                text = "¿Estás seguro de transmitir tu perfil completo a TODOS los oficiales de la raid?",
                button1 = "Sí, transmitir",
                button2 = "Cancelar",
                OnAccept = function()
                    S.RaidSync:BroadcastProfile()
                end,
                timeout = 0,
                whileDead = true,
                hideOnEscape = true,
            }
            StaticPopup_Show("SEQUITO_SEND_PROFILE")
        end 
    end)
    
    local btnResetMeters = CreateFrame("Button", nil, grp1, "UIPanelButtonTemplate")
    btnResetMeters:SetSize(180, 25)
    btnResetMeters:SetPoint("LEFT", btnSyncProfile, "RIGHT", 10, 0)
    btnResetMeters:SetText("Resetear Recounts (Raid)")
    btnResetMeters:SetScript("OnClick", function()
        if S.RaidSync then S.RaidSync:Broadcast("RESET_METERS") end
    end)
    
    -- =======================================================================
    -- SECCIÓN 2: ESTRATEGIAS
    -- =======================================================================
    local grp2 = self:CreateGroup(f, "Estrategias de Boss", 140)
    
    local lblBoss = grp2:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    lblBoss:SetPoint("TOPLEFT", 10, -10)
    lblBoss:SetText("Boss:")
    
    local editBoss = CreateFrame("EditBox", nil, grp2, "InputBoxTemplate")
    editBoss:SetSize(150, 20)
    editBoss:SetPoint("LEFT", lblBoss, "RIGHT", 10, 0)
    editBoss:SetAutoFocus(false)
    editBoss.bg = editBoss:CreateTexture(nil, "BACKGROUND")
    editBoss.bg:SetAllPoints()
    editBoss.bg:SetTexture(0, 0, 0, 0.5)
    
    local lblStrat = grp2:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    lblStrat:SetPoint("TOPLEFT", 10, -40)
    lblStrat:SetText("Nota:")
    
    local editStrat = CreateFrame("EditBox", nil, grp2, "InputBoxTemplate")
    editStrat:SetSize(300, 20)
    editStrat:SetPoint("LEFT", lblStrat, "RIGHT", 10, 0)
    editStrat:SetAutoFocus(false)
    editStrat.bg = editStrat:CreateTexture(nil, "BACKGROUND")
    editStrat.bg:SetAllPoints()
    editStrat.bg:SetTexture(0, 0, 0, 0.5)
    
    local btnSendStrat = CreateFrame("Button", nil, grp2, "UIPanelButtonTemplate")
    btnSendStrat:SetSize(120, 25)
    btnSendStrat:SetPoint("TOPRIGHT", -10, -10)
    btnSendStrat:SetText("Enviar Nota")
    btnSendStrat:SetScript("OnClick", function()
        local boss = editBoss:GetText()
        local note = editStrat:GetText()
        if boss ~= "" and note ~= "" and S.RaidSync then
            S.RaidSync:SendBossStrat(boss, note)
            editStrat:SetText("")
        else
            print("Escribe nombre de boss y nota.")
        end
    end)
    
    -- =======================================================================
    -- SECCIÓN 3: HERRAMIENTAS DE RAID
    -- =======================================================================
    local grp3 = self:CreateGroup(f, "Utilidades Rápidas", 220)
    
    local btnPull = CreateFrame("Button", nil, grp3, "UIPanelButtonTemplate")
    btnPull:SetSize(100, 25)
    btnPull:SetPoint("TOPLEFT", 10, -10)
    btnPull:SetText("Pull 10s")
    btnPull:SetScript("OnClick", function()
        if S.RaidAssist then S.RaidAssist:StartPullTimer(10) end
    end)
    
    local btnBreak = CreateFrame("Button", nil, grp3, "UIPanelButtonTemplate")
    btnBreak:SetSize(100, 25)
    btnBreak:SetPoint("LEFT", btnPull, "RIGHT", 10, 0)
    btnBreak:SetText("Break 5m")
    btnBreak:SetScript("OnClick", function()
        if S.RaidAssist then S.RaidAssist:StartPullTimer(300) end
    end)
    
    local btnReady = CreateFrame("Button", nil, grp3, "UIPanelButtonTemplate")
    btnReady:SetSize(100, 25)
    btnReady:SetPoint("LEFT", btnBreak, "RIGHT", 10, 0)
    btnReady:SetText("Ready Check")
    btnReady:SetScript("OnClick", function()
        if IsRaidLeader() or IsRaidOfficer() or (GetNumPartyMembers() > 0 and IsPartyLeader()) then
            DoReadyCheck()
        else
            print("|cFFFF0000Jaina:|r Debes ser líder o ayudante para iniciar un Ready Check.")
        end
    end)
    
    return f
end



function CT:CreateGroup(parent, titleText, yOffset)
    local g = CreateFrame("Frame", nil, parent)
    g:SetSize(560, 70)
    g:SetPoint("TOPLEFT", 20, -yOffset)
    
    -- Background with Border
    g:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    g:SetBackdropColor(0.1, 0.1, 0.1, 0.5)
    g:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)
    
    g.title = g:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    g.title:SetPoint("TOPLEFT", 10, 10) -- Moved up slightly
    g.title:SetText(titleText)
    g.title:SetTextColor(1, 0.8, 0)
    
    return g
end


