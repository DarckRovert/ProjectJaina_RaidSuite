--[[
    SEQUITO - Smart Mount
    Lógica de montura inteligente (Voladora/Terrestre/Acuática).
    Compatible con WotLK 3.3.5a (Build 12340) | Español (esES/esMX) & Inglés (enUS)
]]--

local addonName, S = ...
S.Mounts = {}

-- Hechizos de monturas de clase en WotLK 3.3.5a
local CLASS_MOUNT_SPELLS = {
    -- Paladín
    { id = 23214, type = "Ground", name = "Charger" },                  -- Destrero (100%)
    { id = 13819, type = "Ground", name = "Warhorse" },                 -- Caballo de guerra (60%)
    -- Brujo
    { id = 23161, type = "Ground", name = "Dreadsteed" },               -- Corcel de la muerte (100%)
    { id = 5784,  type = "Ground", name = "Felsteed" },                 -- Corcel vil (60%)
    -- Caballero de la Muerte
    { id = 48778, type = "Ground", name = "Acherus Deathcharger" },     -- Destrero de la Muerte de Acherus (100%)
    { id = 54729, type = "Flying", name = "Winged Steed of the Ebon Blade" }, -- Corcel alado de la Espada de Ébano
}

-- Normalizador de cadenas contra fallas de tolower en UTF-8
local function CleanString(str)
    if not str then return "" end
    local s = str:lower()
    s = s:gsub("á", "a"):gsub("é", "e"):gsub("í", "i"):gsub("ó", "o"):gsub("ú", "u"):gsub("ñ", "n")
    return s
end

-- Helper para obtener configuración
function S.Mounts:GetOption(key)
    if S.ModuleConfig then
        local val = S.ModuleConfig:GetValue("Mounts", key)
        if val ~= nil then return val end
    end
    return true
end

function S.Mounts:Initialize()
    if self.initialized then return end
    if not self:GetOption("enabled") then return end
    self.initialized = true
    
    if S.db and S.db.profile and not S.db.profile.Mounts then
        S.db.profile.Mounts = {
            FlyingMount = nil,
            GroundMount = nil,
            AquaticMount = nil,
            UseRandom = true,
        }
    end
    
    if not self.eventFrame then
        self.eventFrame = CreateFrame("Frame")
        self.eventFrame:RegisterEvent("COMPANION_LEARNED")
        self.eventFrame:RegisterEvent("COMPANION_UPDATE")
        self.eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
        self.eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
        self.eventFrame:RegisterEvent("SPELLS_CHANGED")
        
        self.eventFrame:SetScript("OnEvent", function(frame, event, ...)
            if event == "PLAYER_REGEN_ENABLED" then
                if S.Mounts.pendingMacroUpdate then
                    S.Mounts.pendingMacroUpdate = false
                    S.Mounts:Refresh()
                end
            else
                S.Mounts:ScanMounts()
                S.Mounts:Refresh()
            end
        end)
    end
    
    self:ScanMounts()
end

function S.Mounts:ScanMounts()
    self.AvailableMounts = {
        Flying = {},
        Ground = {},
        Aquatic = {},
    }
    self.SpellMounts = {} -- Registro de monturas de clase aprendidas
    
    -- 1. Escanear monturas de colección (Companions)
    local numCompanions = GetNumCompanions("MOUNT") or 0
    for i = 1, numCompanions do
        local creatureID, creatureName, spellID, icon, issummoned = GetCompanionInfo("MOUNT", i)
        if creatureName then
            local name = CleanString(creatureName)
            
            local isFlying = name:find("drake") or name:find("draco") or name:find("proto") or
                             name:find("wyrm") or name:find("dracolich") or name:find("dracoliche") or
                             name:find("wind rider") or name:find("jinete del viento") or
                             name:find("gryphon") or name:find("grifo") or
                             name:find("hippogryph") or name:find("hipogrifo") or
                             name:find("dragonhawk") or name:find("dracohalcon") or
                             name:find("nether ray") or name:find("raya abisal") or
                             name:find("flying") or name:find("volador") or name:find("voladora") or
                             name:find("carpet") or name:find("alfombra") or
                             name:find("phoenix") or name:find("fenix") or name:find("al'ar") or
                             name:find("rocket") or name:find("cohete") or
                             name:find("machine") or name:find("maquina") or
                             name:find("invincible") or name:find("invencible") or
                             name:find("mimiron") or name:find("pegaso") or name:find("celestial")

            local isAquatic = not isFlying and (
                name:find("turtle") or name:find("tortuga") or
                name:find("seahorse") or name:find("caballito") or
                name:find("kalu'ak")
            )

            if isFlying then
                table.insert(self.AvailableMounts.Flying, creatureName)
            elseif isAquatic then
                table.insert(self.AvailableMounts.Aquatic, creatureName)
            else
                table.insert(self.AvailableMounts.Ground, creatureName)
            end
        end
    end
    
    -- 2. Escanear monturas del libro de hechizos (Paladín, Brujo, DK)
    for _, spellData in ipairs(CLASS_MOUNT_SPELLS) do
        if IsSpellKnown(spellData.id) then
            local realSpellName = GetSpellInfo(spellData.id)
            if realSpellName then
                self.SpellMounts[realSpellName] = spellData.id
                if spellData.type == "Flying" then
                    table.insert(self.AvailableMounts.Flying, realSpellName)
                else
                    table.insert(self.AvailableMounts.Ground, realSpellName)
                end
            end
        end
    end
end

-- Determinar si el jugador realmente PUEDE volar en la zona actual (WotLK 3.3.5a)
function S.Mounts:CanFlyInCurrentArea()
    if not IsFlyableArea() then
        return false
    end
    
    -- Verificación de Rasganorte (Continente 4)
    local continent = GetCurrentMapContinent()
    if continent == 4 then
        -- En Rasganorte es indispensable "Vuelo en clima frío" (Spell 54197)
        if not IsSpellKnown(54197) then
            return false
        end
        
        -- Dalaran: vuelo prohibido excepto en El Alto de Krasus
        local zone = CleanString(GetZoneText())
        if zone:find("dalaran") then
            local subzone = CleanString(GetSubZoneText())
            if not (subzone:find("krasus") or subzone:find("alto")) then
                return false
            end
        end
        
        -- Conquista del Invierno (Wintergrasp)
        if zone:find("conquista del invierno") or zone:find("wintergrasp") then
            return false
        end
    end
    
    return true
end

function S.Mounts:GetBestMount()
    local flyable = self:CanFlyInCurrentArea()
    local swimming = IsSwimming()
    local mountName = nil
    
    local mountsProfile = (S.db and S.db.profile and S.db.profile.Mounts) or {}
    
    if swimming and mountsProfile.AquaticMount then
        mountName = mountsProfile.AquaticMount
    elseif flyable and mountsProfile.FlyingMount then
        mountName = mountsProfile.FlyingMount
    elseif not flyable and mountsProfile.GroundMount then
        mountName = mountsProfile.GroundMount
    else
        local useRandom = self:GetOption("useRandom")
        if useRandom or mountsProfile.UseRandom then
            if swimming and self.AvailableMounts.Aquatic and #self.AvailableMounts.Aquatic > 0 then
                mountName = self.AvailableMounts.Aquatic[math.random(#self.AvailableMounts.Aquatic)]
            elseif flyable and self.AvailableMounts.Flying and #self.AvailableMounts.Flying > 0 then
                mountName = self.AvailableMounts.Flying[math.random(#self.AvailableMounts.Flying)]
            elseif self.AvailableMounts.Ground and #self.AvailableMounts.Ground > 0 then
                mountName = self.AvailableMounts.Ground[math.random(#self.AvailableMounts.Ground)]
            end
        end
    end
    
    return mountName
end

function S.Mounts:GenerateMountMacro()
    if not self.AvailableMounts then
        self:ScanMounts()
    end
    
    local body = "#showtooltip\n/dismount [mounted]\n/leavevehicle [vehicleui]\n"
    
    -- Cancelar formas de Druida o Lobo Fantasma si aplica
    local _, class = UnitClass("player")
    if class == "DRUID" or class == "SHAMAN" then
        body = body .. "/cancelform [form]\n"
    end
    
    local mountsProfile = (S.db and S.db.profile and S.db.profile.Mounts) or {}
    
    local flyingMount = mountsProfile.FlyingMount
    if not flyingMount and self.AvailableMounts.Flying and #self.AvailableMounts.Flying > 0 then
        flyingMount = self.AvailableMounts.Flying[1]
    end
    
    local aquaticMount = mountsProfile.AquaticMount
    if not aquaticMount and self.AvailableMounts.Aquatic and #self.AvailableMounts.Aquatic > 0 then
        aquaticMount = self.AvailableMounts.Aquatic[1]
    end
    
    local groundMount = mountsProfile.GroundMount
    if not groundMount and self.AvailableMounts.Ground and #self.AvailableMounts.Ground > 0 then
        groundMount = self.AvailableMounts.Ground[1]
    end
    
    local castConditions = {}
    if aquaticMount then
        table.insert(castConditions, "[swimming] " .. aquaticMount)
    end
    if flyingMount then
        table.insert(castConditions, "[flyable] " .. flyingMount)
    end
    if groundMount then
        table.insert(castConditions, groundMount)
    end
    
    if #castConditions > 0 then
        body = body .. "/cast " .. table.concat(castConditions, "; ")
    end
    
    return body
end

function S.Mounts:Refresh()
    if InCombatLockdown and InCombatLockdown() then
        self.pendingMacroUpdate = true
        return
    end
    
    if S.Sphere and S.Sphere.SetAttribute then
        local mountMacro = self:GenerateMountMacro()
        local finalMacro = "/cleartarget [dead]\n/targetenemy [noexists][dead]\n/cast [combat] !Auto Attack\n" .. mountMacro
        S.Sphere:SetAttribute("macrotext1", finalMacro)
    end
    
    if S.MacroGen and S.MacroGen.GenerateClassMacros then
        S.MacroGen:GenerateClassMacros()
    end
end

function S.Mounts:MountUp()
    if InCombatLockdown and InCombatLockdown() then return end
    
    -- Desmontar si ya está montado
    if IsMounted() then
        Dismount()
        return
    end
    
    -- Cancelar formas de metamorfosis en 3.3.5a
    if GetShapeshiftForm and GetShapeshiftForm() > 0 and CancelShapeshiftForm then
        CancelShapeshiftForm()
    end
    
    local mountName = self:GetBestMount()
    if not mountName then return end
    
    -- Caso A: Es un hechizo de montura de clase (Paladín, Brujo, DK)
    if self.SpellMounts and self.SpellMounts[mountName] then
        if CastSpellByName then
            CastSpellByName(mountName)
        end
        return
    end
    
    -- Caso B: Es una montura de colección (Companion)
    local numCompanions = GetNumCompanions("MOUNT") or 0
    for i = 1, numCompanions do
        local _, name = GetCompanionInfo("MOUNT", i)
        if name == mountName then
            CallCompanion("MOUNT", i)
            return
        end
    end
    
    -- Fallback final por nombre de hechizo
    if CastSpellByName then
        CastSpellByName(mountName)
    end
end

function S.Mounts:Summon()
    self:MountUp()
end

function S.Mounts:SetFavorite(mountType, mountName)
    if not S.db or not S.db.profile then return end
    if not S.db.profile.Mounts then S.db.profile.Mounts = {} end
    
    if mountType == "flying" then
        S.db.profile.Mounts.FlyingMount = mountName
        print("|cFFFF00FFSequito|r: Montura voladora favorita: " .. (mountName or "Ninguna"))
    elseif mountType == "ground" then
        S.db.profile.Mounts.GroundMount = mountName
        print("|cFFFF00FFSequito|r: Montura terrestre favorita: " .. (mountName or "Ninguna"))
    elseif mountType == "aquatic" then
        S.db.profile.Mounts.AquaticMount = mountName
        print("|cFFFF00FFSequito|r: Montura acuática favorita: " .. (mountName or "Ninguna"))
    end
    
    self:Refresh()
end

function S.Mounts:ListMounts()
    print("|cFFFF00FFSequito|r - Monturas Disponibles:")
    if self.AvailableMounts.Flying and #self.AvailableMounts.Flying > 0 then
        print("|cFF00FFFFVoladoras:|r")
        for _, name in ipairs(self.AvailableMounts.Flying) do
            print("  - " .. name)
        end
    end
    if self.AvailableMounts.Ground and #self.AvailableMounts.Ground > 0 then
        print("|cFF00FFFFTerrestres:|r")
        for _, name in ipairs(self.AvailableMounts.Ground) do
            print("  - " .. name)
        end
    end
    if self.AvailableMounts.Aquatic and #self.AvailableMounts.Aquatic > 0 then
        print("|cFF00FFFFAcuáticas:|r")
        for _, name in ipairs(self.AvailableMounts.Aquatic) do
            print("  - " .. name)
        end
    end
    
    local mountsProfile = (S.db and S.db.profile and S.db.profile.Mounts) or {}
    print(" ")
    print("|cFFFFFF00Favoritas:|r")
    print("  Voladora: " .. (mountsProfile.FlyingMount or "Ninguna"))
    print("  Terrestre: " .. (mountsProfile.GroundMount or "Ninguna"))
    print("  Acuática: " .. (mountsProfile.AquaticMount or "Ninguna"))
end

-- Registro en ModuleConfig
if S.ModuleConfig then
    S.ModuleConfig:RegisterModule("Mounts", {
        name = "Monturas Inteligentes",
        description = "Selección automática de monturas adaptada a Rasganorte, Dalaran y monturas de clase",
        category = "utility",
        icon = "Interface\\Icons\\Ability_Mount_RidingHorse",
        options = {
            { type = "checkbox", key = "enabled", label = "Habilitar Monturas", default = true },
            { type = "checkbox", key = "useRandom", label = "Usar Aleatorias", default = true },
            { type = "checkbox", key = "preferFlying", label = "Preferir Voladoras", default = true },
        }
    })
end
