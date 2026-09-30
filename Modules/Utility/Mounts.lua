--[[
    SEQUITO - Smart Mount
    Lógica de montura inteligente (Voladora/Terrestre/Acuática).
    Compatible con WotLK 3.3.5a (esES/esMX/enUS) y sincronizado con MacroGenerator.
]]--

local addonName, S = ...
S.Mounts = {}

-- Helper para obtener configuración
function S.Mounts:GetOption(key)
    if S.ModuleConfig then
        return S.ModuleConfig:GetValue("Mounts", key)
    end
    return true
end

function S.Mounts:Initialize()
    if self.initialized then return end
    if not self:GetOption("enabled") then
        return
    end
    self.initialized = true
    
    -- Inicializar configuración de monturas en DB
    if S.db and S.db.profile and not S.db.profile.Mounts then
        S.db.profile.Mounts = {
            FlyingMount = nil,  -- Nombre de montura voladora favorita
            GroundMount = nil,  -- Nombre de montura terrestre favorita
            AquaticMount = nil, -- Nombre de montura acuática favorita
            UseRandom = true,   -- Usar monturas aleatorias si no hay favoritas
        }
    end
    
    -- Marco de eventos reactivo para actualización en caliente
    if not self.eventFrame then
        self.eventFrame = CreateFrame("Frame")
        self.eventFrame:RegisterEvent("COMPANION_LEARNED")
        self.eventFrame:RegisterEvent("COMPANION_UPDATE")
        self.eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
        self.eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
        
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
    
    -- Escaneo inicial diferido
    self:ScanMounts()
end

function S.Mounts:ScanMounts()
    self.AvailableMounts = {
        Flying = {},
        Ground = {},
        Aquatic = {},
    }
    
    local numCompanions = GetNumCompanions("MOUNT") or 0
    for i = 1, numCompanions do
        local creatureID, creatureName, spellID, icon, issummoned = GetCompanionInfo("MOUNT", i)
        if creatureName then
            local name = creatureName:lower()
            
            -- Detección bilingüe (Español / Inglés)
            local isFlying = name:find("drake") or name:find("draco") or name:find("proto") or
                             name:find("wyrm") or name:find("dracolich") or name:find("dracoliche") or
                             name:find("wind rider") or name:find("jinete del viento") or
                             name:find("gryphon") or name:find("grifo") or
                             name:find("hippogryph") or name:find("hipogrifo") or
                             name:find("dragonhawk") or name:find("dracohalcón") or
                             name:find("nether ray") or name:find("raya abisal") or
                             name:find("flying") or name:find("volador") or name:find("voladora") or
                             name:find("carpet") or name:find("alfombra") or
                             name:find("phoenix") or name:find("fénix") or name:find("al'ar") or
                             name:find("rocket") or name:find("cohete") or
                             name:find("machine") or name:find("máquina") or
                             name:find("invincible") or name:find("invencible") or
                             name:find("mimiron") or name:find("mimirón") or
                             name:find("pegaso") or name:find("celestial")

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
end

function S.Mounts:GetBestMount()
    local flyable = IsFlyableArea()
    local swimming = IsSwimming()
    local mountName = nil
    
    if swimming and S.db.profile.Mounts.AquaticMount then
        mountName = S.db.profile.Mounts.AquaticMount
    elseif flyable and S.db.profile.Mounts.FlyingMount then
        mountName = S.db.profile.Mounts.FlyingMount
    elseif not flyable and S.db.profile.Mounts.GroundMount then
        mountName = S.db.profile.Mounts.GroundMount
    else
        if S.db.profile.Mounts.UseRandom then
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
    if not S.db.profile.Mounts then
        S.db.profile.Mounts = { UseRandom = true }
    end
    
    local body = "#showtooltip\n/dismount [mounted]\n/leavevehicle [vehicleui]\n"
    
    local flyingMount = S.db.profile.Mounts.FlyingMount
    if not flyingMount and self.AvailableMounts.Flying and #self.AvailableMounts.Flying > 0 then
        flyingMount = self.AvailableMounts.Flying[1]
    end
    
    local aquaticMount = S.db.profile.Mounts.AquaticMount
    if not aquaticMount and self.AvailableMounts.Aquatic and #self.AvailableMounts.Aquatic > 0 then
        aquaticMount = self.AvailableMounts.Aquatic[1]
    end
    
    local groundMount = S.db.profile.Mounts.GroundMount
    if not groundMount and self.AvailableMounts.Ground and #self.AvailableMounts.Ground > 0 then
        groundMount = self.AvailableMounts.Ground[1]
    end
    
    -- Detección de monturas nativas de clase si no hay favorita configurada
    if not groundMount then
        local _, class = UnitClass("player")
        if class == "PALADIN" and IsSpellKnown(23214) then
            groundMount = GetSpellInfo(23214)
        elseif class == "WARLOCK" and IsSpellKnown(23161) then
            groundMount = GetSpellInfo(23161)
        elseif class == "DEATHKNIGHT" and IsSpellKnown(48778) then
            groundMount = GetSpellInfo(48778)
        end
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
    
    -- 1. Sincronizar macro en la Esfera Sequito (GUI)
    if S.Sphere and S.Sphere.SetAttribute then
        local mountMacro = self:GenerateMountMacro()
        local finalMacro = "/cleartarget [dead]\n/targetenemy [noexists][dead]\n/cast [combat] !Auto Attack\n" .. mountMacro
        S.Sphere:SetAttribute("macrotext1", finalMacro)
    end
    
    -- 2. Sincronizar macro global SeqMount si MacroGen está cargado
    if S.MacroGen and S.MacroGen.GenerateClassMacros then
        S.MacroGen:GenerateClassMacros()
    end
end

function S.Mounts:MountUp()
    if InCombatLockdown and InCombatLockdown() then return end
    if IsMounted() then
        Dismount()
        return
    end
    
    local mountName = self:GetBestMount()
    if mountName then
        local numCompanions = GetNumCompanions("MOUNT") or 0
        for i = 1, numCompanions do
            local _, name = GetCompanionInfo("MOUNT", i)
            if name == mountName then
                CallCompanion("MOUNT", i)
                return
            end
        end
    end
    
    -- Fallback de hechizo de clase
    local _, class = UnitClass("player")
    local spellID = (class == "PALADIN" and 23214) or (class == "WARLOCK" and 23161) or (class == "DEATHKNIGHT" and 48778)
    if spellID and IsSpellKnown(spellID) then
        local spellName = GetSpellInfo(spellID)
        if spellName and CastSpellByName then
            CastSpellByName(spellName)
        end
    end
end

function S.Mounts:Summon()
    self:MountUp()
end

function S.Mounts:SetFavorite(mountType, mountName)
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
    print(" ")
    print("|cFFFFFF00Favoritas:|r")
    print("  Voladora: " .. (S.db.profile.Mounts.FlyingMount or "Ninguna"))
    print("  Terrestre: " .. (S.db.profile.Mounts.GroundMount or "Ninguna"))
    print("  Acuática: " .. (S.db.profile.Mounts.AquaticMount or "Ninguna"))
end

if S.ModuleConfig then
    S.ModuleConfig:RegisterModule({
        id = "Mounts",
        name = "Monturas Inteligentes",
        description = "Sistema de selección inteligente de monturas",
        category = "utility",
        icon = "Interface\\Icons\\Ability_Mount_RidingHorse",
        options = {
            {
                key = "enabled",
                type = "checkbox",
                name = "Habilitar Monturas",
                description = "Habilitar/deshabilitar sistema de monturas",
                default = true
            },
            {
                key = "useRandom",
                type = "checkbox",
                name = "Usar Aleatorias",
                description = "Usar monturas aleatorias si no hay favoritas",
                default = true
            },
            {
                key = "autoDetect",
                type = "checkbox",
                name = "Auto-Detectar Zona",
                description = "Detectar automáticamente si usar voladora/terrestre",
                default = true
            },
            {
                key = "preferFlying",
                type = "checkbox",
                name = "Preferir Voladoras",
                description = "Usar monturas voladoras cuando sea posible",
                default = true
            }
        }
    })
end
