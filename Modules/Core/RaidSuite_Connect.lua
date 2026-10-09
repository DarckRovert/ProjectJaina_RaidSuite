--[[
    SEQUITO - Connect (v10.0)
    Puente de datos para herramientas externas (Discord/Web).
    Genera reportes comprimidos en texto.
]]

local addonName, S = ...
S.Connect = {}
local SC = S.Connect

-- ===========================================================================
-- UI: CONTENIDO DEL TAB
-- ===========================================================================
function SC:Initialize()
    -- Register Comm
    if RegisterAddonMessagePrefix then RegisterAddonMessagePrefix("SEQUITO_CFG") end
    
    -- Event Frame for Comm
    self.commFrame = CreateFrame("Frame")
    self.commFrame:RegisterEvent("CHAT_MSG_ADDON")
    self.commFrame:SetScript("OnEvent", function(f, event, ...) SC:OnComm(event, ...) end)
    
    -- Initialize Buffers
    self.tempBuffers = {}

    print("|cFFFF00FFJaina|r: [Connect] Módulo de sincronización listo.")
    self:RegisterCommands()
    
    -- Register Tab in Dashboard
    if S.Dashboard and S.Dashboard.RegisterTab then
        local content = CreateFrame("Frame", "JainaConnectTab", UIParent)
        content:SetSize(100, 100) 
        
        -- Title
        local title = content:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        title:SetPoint("TOPLEFT", 10, -10)
        title:SetText("|cff9966ffJaina Connect|r")
        
        -- SYNC SECTION (Top)
        local syncGroup = CreateFrame("Frame", nil, content)
        syncGroup:SetPoint("TOPLEFT", 10, -40)
        syncGroup:SetPoint("TOPRIGHT", -10, -40)
        syncGroup:SetHeight(80)
        
        local btnSync = CreateFrame("Button", nil, syncGroup, "UIPanelButtonTemplate")
        btnSync:SetSize(220, 30)
        btnSync:SetPoint("TOPLEFT", 0, 0)
        btnSync:SetText("Transmitir Configuración al Grupo")
        btnSync:SetScript("OnClick", function() 
            if IsRaidLeader() or IsRaidOfficer() or IsPartyLeader() then
                SC:BroadcastConfig()
            else
                print("|cFFFF0000Jaina:|r Solo el líder puede transmitir configuración.")
            end
        end)
        
        local syncDesc = syncGroup:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        syncDesc:SetPoint("LEFT", btnSync, "RIGHT", 10, 0)
        syncDesc:SetText("Envía tu perfil actual a todos los miembros.\nRequiere ser Líder o Ayudante.")
        syncDesc:SetJustifyH("LEFT")
        syncDesc:SetTextColor(0.7, 0.7, 0.7)

        -- EXPORT SECTION (Bottom)
        local expTitle = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        expTitle:SetPoint("TOPLEFT", syncGroup, "BOTTOMLEFT", 0, -20)
        expTitle:SetText("Exportación Manual (Discord/Web):")
        expTitle:SetTextColor(1, 0.8, 0)

        local scrollArea = CreateFrame("ScrollFrame", "JainaConnectScroll", content, "UIPanelScrollFrameTemplate")
        scrollArea:SetPoint("TOPLEFT", expTitle, "BOTTOMLEFT", 0, -10)
        scrollArea:SetPoint("BOTTOMRIGHT", -30, 10)
        
        local editBox = CreateFrame("EditBox", nil, scrollArea)
        editBox:SetMultiLine(true)
        editBox:SetFontObject(ChatFontNormal)
        editBox:SetWidth(600)
        editBox:SetHeight(400)
        editBox:SetScript("OnEscapePressed", function() editBox:ClearFocus() end)
        scrollArea:SetScrollChild(editBox)
        
        -- OnShow: Update Export Text only
        content:SetScript("OnShow", function()
             local data = {
                type = "PROFILE",
                author = UnitName("player"),
                version = S.Version or "10.1.0",
                timestamp = time(),
                config = JainaDB or {}
            }
            editBox:SetText(SC:SimpleJSON(data))
            editBox:SetCursorPosition(0)
        end)
        
        S.Dashboard:RegisterTab("Connect", "Interface\\Icons\\Spell_ChargePositive", content)
    end
end

-- ===========================================================================
-- SYNC LOGIC
-- ===========================================================================
function SC:GetBroadcastChannel()
    if IsInInstance then
        local inInstance, instanceType = IsInInstance()
        if inInstance and instanceType == "pvp" then
            return "BATTLEGROUND"
        end
    end
    if GetNumRaidMembers() > 0 then
        return "RAID"
    elseif GetNumPartyMembers() > 0 then
        return "PARTY"
    end
    return nil
end

function SC:BroadcastConfig()
    local channel = self:GetBroadcastChannel()
    if not channel then
        print("|cFFFF0000Jaina:|r Debes estar en un grupo o banda para transmitir configuración.")
        return
    end

    -- Serialize CONFIG ONLY (Safety: Don't send entire DB if it has other stuff)
    local cfg = JainaDB or {}
    local serialized = SC:TableToLua(cfg)
    local msgID = tostring(time())
    local chunks = {}
    local chunkSize = 180 -- Safe limit for SendAddonMessage (Ley III: 255 bytes max)
    
    for i=1, #serialized, chunkSize do
        table.insert(chunks, string.sub(serialized, i, i+chunkSize-1))
    end
    
    local total = #chunks
    print("|cFF00FFFFJaina:|r Iniciando transmisión hacia " .. channel .. " ("..total.." paquetes)...")
    
    if not self.queueFrame then
        self.queueFrame = CreateFrame("Frame")
    end
    
    local queue = {}
    for i, chunk in ipairs(chunks) do
        local packet = string.format("%s:%d:%d:%s", msgID, i, total, chunk)
        table.insert(queue, packet)
    end
    
    local queueIndex = 1
    local elapsedThrottle = 0
    self.queueFrame:SetScript("OnUpdate", function(f, elapsed)
        elapsedThrottle = elapsedThrottle + elapsed
        if elapsedThrottle >= 0.05 then -- 20 paquetes/segundo maximo (Ley III & IV)
            elapsedThrottle = 0
            if queueIndex <= #queue then
                SendAddonMessage("SEQUITO_CFG", queue[queueIndex], channel)
                queueIndex = queueIndex + 1
            else
                f:SetScript("OnUpdate", nil)
                print("|cFF00FF00Jaina:|r Transmisión completada exitosamente.")
            end
        end
    end)
end

function SC:OnComm(event, prefix, msg, channel, sender)
    if prefix ~= "SEQUITO_CFG" then return end
    if sender == UnitName("player") then return end
    
    -- Parse: ID:INDEX:TOTAL:PAYLOAD
    local id, idx, tot, payload = strsplit(":", msg, 4)
    idx = tonumber(idx)
    tot = tonumber(tot)
    
    if not id or not idx or not tot then return end
    
    -- Init Buffer
    if not self.tempBuffers[id] then
        self.tempBuffers[id] = { parts = {}, count = 0, total = tot, sender = sender }
        print("|cFF00FFFFJaina:|r Recibiendo configuración de " .. sender .. "...")
    end
    
    local buf = self.tempBuffers[id]
    buf.parts[idx] = payload
    buf.count = buf.count + 1
    
    -- Check Complete
    if buf.count >= buf.total then
        local fullData = table.concat(buf.parts)
        self:OfferConfig(fullData, buf.sender)
        self.tempBuffers[id] = nil -- Clear
    end
end

function SC:OfferConfig(dataString, sender)
    -- Show Popup
    StaticPopupDialogs["SEQUITO_CONFIRM_SYNC"] = {
        text = "|cFF00FFFFJaina|r\n\n" .. sender .. " ha enviado una configuración de Raid.\n¿Deseas aplicarla? (Recargará la UI)",
        button1 = "Aceptar",
        button2 = "Cancelar",
        OnAccept = function()
            -- Deserialize safely con Sandbox aislado (Ley V)
            local func = loadstring("return " .. dataString)
            if func then
                setfenv(func, {}) -- Entorno cerrado sin acceso a _G
                local ok, newConfig = pcall(func)
                if ok and newConfig and type(newConfig) == "table" then
                    JainaDB = newConfig
                    ReloadUI()
                else
                    print("|cFFFF0000Jaina:|r Error: Configuración inválida o rechazada.")
                end
            else
                print("|cFFFF0000Jaina:|r Error: Datos corruptos.")
            end
        end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
    }
    StaticPopup_Show("SEQUITO_CONFIRM_SYNC")
end

-- ===========================================================================
-- SERIALIZERS
-- ===========================================================================
function SC:TableToLua(val)
    local t = type(val)
    if t == "number" or t == "boolean" then 
        return tostring(val)
    elseif t == "string" then 
        return string.format("%q", val)
    elseif t == "table" then
        local parts = {"{"}
        for k,v in pairs(val) do
            -- Only sync string keys to avoid array index mess in sparse tables
            if type(k) == "string" then
                table.insert(parts, "["..string.format("%q", k).."]="..SC:TableToLua(v)..",")
            elseif type(k) == "number" then
                table.insert(parts, "["..k.."]="..SC:TableToLua(v)..",")
            end
        end
        table.insert(parts, "}")
        return table.concat(parts)
    else
        return "nil"
    end
end

function SC:RegisterCommands()
    -- Commands handled by global handler in Jaina.lua
end

-- ===========================================================================
-- GENERADOR DE REPORTES
-- ===========================================================================
function SC:GenerateReport()
    -- Obtener asistencia desde RaidSync si está disponible, sino, escanear local
    local roster = {}
    if S.RaidSync and S.RaidSync.RaidData then
        for name, data in pairs(S.RaidSync.RaidData) do
            table.insert(roster, {name = name, class = data.class, role = data.role})
        end
    else
        -- Fallback simple
        local num = GetNumRaidMembers()
        for i=1, num do
            local name, _, _, _, _, class = GetRaidRosterInfo(i)
            if name then
                table.insert(roster, {name = name, class = class, role = "UNKNOWN"})
            end
        end
    end

    local data = {
        type = "REPORT",
        date = date("%Y-%m-%d %H:%M:%S"),
        zone = GetRealZoneText(),
        author = UnitName("player"),
        version = S.Version or "10.1.0",
        wipes = S.WipeAnalyzer and S.WipeAnalyzer.Wipes or {},
        loot = JainaLootDB or {},
        attendance = roster,
    }
    self:OpenWindow(S.L["EXPORT_REPORT"] or "Reporte de Raid", self:SimpleJSON(data))
end

function SC:ExportConfig()
    local data = {
        type = "PROFILE",
        author = UnitName("player"),
        version = S.Version or "10.1.0",
        timestamp = time(),
        config = JainaDB or {} -- The main config table
    }
    self:OpenWindow("Perfil de Configuración", self:SimpleJSON(data))
end

-- ===========================================================================
-- UI: EXPORT WINDOW
-- ===========================================================================
function SC:OpenWindow(title, text)
    if self.frame then 
        self.frame:Show()
        self.frame.title:SetText("Jaina Connect - " .. title)
        self.frame.editBox:SetText(text)
        return 
    end

    local f = CreateFrame("Frame", "JainaExportFrame", UIParent)
    f:SetSize(500, 450) -- Taller for buttons
    f:SetPoint("CENTER")
    f:SetBackdrop({bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background", edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border", edgeSize = 16, insets = {left = 4, right = 4, top = 4, bottom = 4}})
    
    f.title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    f.title:SetPoint("TOP", 0, -15)
    f.title:SetText("Jaina Connect - " .. title)
    
    -- Mode Buttons
    local btnReport = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    btnReport:SetSize(120, 25)
    btnReport:SetPoint("TOPLEFT", 20, -40)
    btnReport:SetText("Reporte Raid")
    btnReport:SetScript("OnClick", function() SC:GenerateReport() end)
    
    local btnConfig = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    btnConfig:SetSize(120, 25)
    btnConfig:SetPoint("LEFT", btnReport, "RIGHT", 10, 0)
    btnConfig:SetText("Exportar Perfil")
    btnConfig:SetScript("OnClick", function() SC:ExportConfig() end)
    
    -- Scroll Area
    local scroll = CreateFrame("ScrollFrame", "JainaExportScroll", f, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 20, -80)
    scroll:SetPoint("BOTTOMRIGHT", -40, 50)
    
    local editBox = CreateFrame("EditBox", nil, scroll)
    editBox:SetMultiLine(true)
    editBox:SetFontObject(ChatFontNormal)
    editBox:SetWidth(440)
    editBox:SetText(text)
    editBox:HighlightText()
    
    scroll:SetScrollChild(editBox)
    f.editBox = editBox
    
    f.close = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    f.close:SetSize(100, 30)
    f.close:SetPoint("BOTTOM", 0, 15)
    f.close:SetText("Cerrar")
    f.close:SetScript("OnClick", function() f:Hide() end)
    
    self.frame = f
end

-- ===========================================================================
-- UTILS (Simple JSON Serializer because WotLK has no native JSON)
-- ===========================================================================
function SC:SimpleJSON(val)
    local t = type(val)
    if t == "number" then
        return tostring(val)
    elseif t == "string" then
        return string.format("%q", val)
    elseif t == "boolean" then
        return val and "true" or "false"
    elseif t == "table" then
        local parts = {}
        local isArray = (#val > 0)
        
        if isArray then
            for _, v in ipairs(val) do
                table.insert(parts, self:SimpleJSON(v))
            end
            return "[" .. table.concat(parts, ",") .. "]"
        else
            for k, v in pairs(val) do
                table.insert(parts, string.format("%q:%s", k, self:SimpleJSON(v)))
            end
            return "{" .. table.concat(parts, ",") .. "}"
        end
    else
        return "null"
    end
end

-- Registrar
if S.ModuleConfig then
    S.ModuleConfig:RegisterModule("Connect", {
        name = "Jaina Connect",
        description = "Exportación de datos a web/discord",
        category = "general",
        icon = "Interface\\Icons\\Spell_ChargePositive",
        options = {}
    })
end
