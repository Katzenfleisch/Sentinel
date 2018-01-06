
function SetRandomAngle(ent)
    -- Randomize starting angles
    local angles = ent:GetAngles()
    angles.yaw = math.random() * math.pi * 2
    ent:SetAngles(angles)

    -- To make sure physics model is updated without waiting a tick
    ent:UpdatePhysicsModel()
end

local old_MarineTeam_OnResetComplete = MarineTeam.OnResetComplete or Team.OnResetComplete
function MarineTeam:OnResetComplete()
    if old_MarineTeam_OnResetComplete then
        old_MarineTeam_OnResetComplete(self)
    end

    for index, powerPoint in ientitylist(Shared.GetEntitiesWithClassname("PowerPoint")) do

        if powerPoint:HasConsumerRequiringPower() and powerPoint:GetPowerState() == PowerPoint.kPowerState.unsocketed
        then
            powerPoint:SocketPowerNode()
        end

    end

end

function MarineTeam:SpawnInitialStructures(techPoint)
    local weapons = {
        -- Shotgun.kMapName, Shotgun.kMapName, Shotgun.kMapName,
        -- GrenadeLauncher.kMapName,
        -- Flamethrower.kMapName,
        -- HeavyMachineGun.kMapName,
        LayMines.kMapName, LayMines.kMapName, LayMines.kMapName,
        LayMines.kMapName, LayMines.kMapName, LayMines.kMapName
    }

    if not GetGameInfoEntity():GetIsDedicated() then
        table.insert(weapons, Jetpack.kMapName)
    end

    assert(techPoint ~= nil)

    local origin = techPoint:GetOrigin()

    local ip = CreateEntity(InfantryPortal.kMapName, origin, kMarineTeamType)
    if ip then ip:SetConstructionComplete() ; SetRandomAngle(ip) end

    -- local pg_origin = SNTL_SpreadedPlacementFromOrigin(GetExtents(kTechId.PhaseGate), origin, 1, 2, 5)
    -- local pg = pg_origin and CreateEntity(PhaseGate.kMapName, pg_origin[1], kMarineTeamType)
    -- if pg then pg:SetConstructionComplete() ; SetRandomAngle(pg) end

    for i = 1, 2 do
        local armslab_origin = SNTL_SpreadedPlacementFromOrigin(GetExtents(kTechId.ArmsLab), origin, 1, 2, 5)
        local armslab = armslab_origin and CreateEntity(ArmsLab.kMapName, armslab_origin[1], kMarineTeamType)
        if armslab then armslab:SetConstructionComplete() ; SetRandomAngle(armslab) end
    end

    local armory_origin = SNTL_SpreadedPlacementFromOrigin(GetExtents(kTechId.Armory), origin, 1, 2, 5)
    local armory = armory_origin and CreateEntity(Armory.kMapName, armory_origin[1], kMarineTeamType)
    if armory then armory:SetConstructionComplete() ; SetRandomAngle(armory) end

    local proto_origin = SNTL_SpreadedPlacementFromOrigin(GetExtents(kTechId.PrototypeLab), origin, 1, 2, 5)
    local proto = proto_origin and CreateEntity(PrototypeLab.kMapName, proto_origin[1], kMarineTeamType)
    if proto then proto:SetConstructionComplete() ; SetRandomAngle(proto) end

    -- Spawn a few weapons as well
    local weapons_origins = SNTL_SpreadedPlacementFromOrigin(GetExtents(kTechId.Shotgun), origin, 1, 2, 5)
    local weapons_origins = SNTL_SpreadedPlacementFromOrigin(GetExtents(kTechId.Shotgun), weapons_origins[1], #weapons, 0, 2)

    for i, orig in ipairs(weapons_origins) do
        local weapon = CreateEntity(weapons[i], orig + Vector(0, 0.5, 0), kMarineTeamType)

        if weapon and weapon.GetVariantModel and weapon.SetModel then
            weapon:SetModel( weapon:GetVariantModel() )
        end

    end



    -- -------------------

    local unlockedResearches = {
        -- kTechId.Weapons1,
        -- kTechId.Weapons2,
        -- kTechId.Armor1
    }

    local marinetechtree = GetTechTree(kTeam1Index)
    for _, up in ipairs(unlockedResearches) do
        if (up and marinetechtree:GetTechNode(up) and not marinetechtree:GetTechNode(up):GetResearched())
        then -- Unlock if not already on
            local armslab = GetEntitiesForTeam("ArmsLab", kMarineTeamType)
            if (#armslab > 0) then
                marinetechtree:GetTechNode(up):SetResearched(true)
                marinetechtree:QueueOnResearchComplete(up, armslab[1])
            end
        end
    end


    local unlockedWeapons = {
        -- kTechId.GrenadeTech
    }

    for _, up in ipairs(unlockedWeapons) do
        if (up and marinetechtree:GetTechNode(up) and not marinetechtree:GetTechNode(up):GetResearched())
        then -- Unlock if not already on
            local AA = GetEntitiesForTeam("AdvancedArmory", kMarineTeamType)
            if (#AA > 0) then
                marinetechtree:GetTechNode(up):SetResearched(true)
                marinetechtree:QueueOnResearchComplete(up, AA[1])
            end
        end
    end

    return

end

function MarineTeam:GetHasTeamLost()

    PROFILE("PlayingTeam:GetHasTeamLost")

    if GetGamerules():GetGameStarted() and not Shared.GetCheatsEnabled() then

        -- Team can't respawn if they don't have any more ips, and lose if they are all dead
        local activePlayers = self:GetHasActivePlayers()
        local abilityToRespawn = self:GetHasAbilityToRespawn()
        local numGates = 0

        for _, pg in ipairs(GetEntitiesForTeam("PhaseGate", kMarineTeamType)) do
            if pg and pg:GetIsAlive() then
                numGates = numGates + 1
            end
        end

        if  (not activePlayers and not abilityToRespawn) or
            (self:GetNumPlayers() == 0) or (numGates == 0) or self:GetHasConceded() then

            return true

        end

    end

    return false

end


function getRtPoints(classname)
    local rt = {}
    local cl = classname
    if (cl == nil) then
        cl = "ResourcePoint"
    end
    if (cl == "TechPoint" or cl == "ResourcePoint" or cl == "PowerPoint") then
        local rts = Shared.GetEntitiesWithClassname(cl)
        for index, entity in ientitylist(rts) do
            table.insert(rt, entity)
        end
    else
        for index, entity in ipairs(GetEntities(cl)) do
            table.insert(rt, entity)
        end
    end

    return rt
end

function getRandomRT()
    local rt = getRtPoints()
    if (#rt == 0) then
        rt = getRtPoints("TechPoint")
   end

    rt_nb = math.random(1, #rt)
    return rt[rt_nb]
end


function getRandomPowerNode()
    local rt = GetEntities("PowerPoint")
    rt_nb = math.random(1, #rt)
    return rt[rt_nb]
end

function MarineTeam:randomBonusDrop()

    if SNTL_LimitCallFrequency(MarineTeam.randomBonusDrop, 5) then return end

    local nb_drop = #GetEntities("AmmoPack")-- + #GetEntities("MedPack") + #GetEntities("CatPack")
    if (nb_drop < 13) then
        local ent = nil
        local rt = nil

        rt = nil--getRandomRT()

        for i = 0, 10 do -- Choose a RT with no drop if possible
            local hasRtDropAlready = false

            local _rt = getRandomRT()
            if (math.random() < 0.5) then
                _rt = getRandomPowerNode()
            end

            -- Prevent drop in bases
            if (_rt) then
                if #GetEntitiesForTeamWithinRange("Armory", 1, _rt:GetOrigin(), 40) == 0
                    and #GetEntitiesForTeamWithinRange("Player", 1, _rt:GetOrigin(), 30) == 0
                then
                    for _, dropName in ipairs({"AmmoPack", "MedPack", "CatPack"}) do
                        if (#GetEntitiesForTeamWithinRange(dropName, 2, _rt:GetOrigin(), 4) > 1) then
                            hasRtDropAlready = true
                            break
                        end
                    end
                    if (hasRtDropAlready == false) then
                        rt = _rt
                        break
                    end
                end
            end
        end

        if (rt) then
            local rand = math.random()
            local spawnPoint = nil
            for e = 0, 3 do
                spawnPoint = SNTL_SpreadedPlacementFromOrigin(GetExtents(kTechId.ArmsLab), rt:GetOrigin(), 1, 2, 5)
                if (spawnPoint) then
                    spawnPoint = spawnPoint[1]
                    break
                end
            end
            if (spawnPoint) then
                ent = CreateEntity(AmmoPack.kMapName, spawnPoint, 1)
            end
        end

    end
end

function MarineTeam:UpdateUpgrades(timePassed)

    if SNTL_LimitCallFrequency(MarineTeam.UpdateUpgrades, 1) then return end

    local marinetechtree = GetTechTree(kTeam1Index)

    local UnlockOrder = {
        {kTechId.Weapons1, kTechId.GrenadeTech, kTechId.ShotgunTech,
         kTechId.Armor1, kTechId.MinesTech,
         kTechId.Weapons2, kTechId.AdvancedArmoryUpgrade, kTechId.AdvancedArmoryUpgrade,
         kTechId.HeavyMachineGunTech,
         kTechId.JetpackTech, kTechId.Armor2,
         kTechId.Weapons3, kTechId.ExosuitTech,
        }
    }

    local totalUpgrades = 0
    for i, ups in ipairs(UnlockOrder) do
        for j, up in ipairs(ups) do
            totalUpgrades = totalUpgrades + 1
        end
    end

    local marines = GetEntitiesForTeam("Player", kMarineTeamType)
    local marine = #marines > 0 and marines[1]

    if not marine then
        return
    end

    local respawnLeft = GetGameInfoEntity():GetNumMarineRespawnLeft()
    local respawnMax = GetGameInfoEntity():GetNumMarineRespawnMax()
    local eggFraction = respawnLeft / respawnMax

    -- local eggFraction = GetGameInfoEntity():GetNumEggs() / GetGameInfoEntity():GetNumMaxEggs()

    local upNum = -2
    local upgradeResearching = false
    for i, ups in ipairs(UnlockOrder) do

        for j, up in ipairs(ups) do

            -- Only research if marines are actually pushing aliens
            -- X% of the tech tree is locked until the marines don't have any remaining spawn
            -- Log("%s / %s", ((totalUpgrades / 100 * 5) + upNum) / totalUpgrades, 1 - eggFraction)
            if respawnLeft > 0 then
                if ((totalUpgrades / 100 * 0) + upNum) / totalUpgrades >= 1 - eggFraction then
                    return
                end
            end

            upNum = upNum + 1

            local node = marinetechtree:GetTechNode(up)
            if node then
                -- Log("[sntl] GetCanResearch(): %s", node:GetCanResearch())

                if up == kTechId.AdvancedArmoryUpgrade then
                    upgradeResearching = true
                    for _, a in ipairs(GetEntitiesForTeam("Armory", kMarineTeamType)) do
                        if a:GetTechId() == kTechId.AdvancedArmory then
                            upgradeResearching = false
                            break
                        end
                    end
                elseif not node:GetResearched() then
                    upgradeResearching = true
                end

                if not node:GetResearched() and not node:GetResearching() and not node:GetHasTech()
                then -- Unlock if not already on

                    local ents = {"ArmsLab", "Armory", "PrototypeLab"}

                    for _, entName in ipairs(ents) do
                        local alreadyResearching = false

                        for _, ent in ipairs(GetEntitiesForTeam(entName, kMarineTeamType)) do
                            if ent:GetIsResearching() and ent:GetResearchingId() == up then
                                alreadyResearching = true
                                break
                            end
                        end

                        if alreadyResearching then
                            break
                        end

                        for _, ent in ipairs(GetEntitiesForTeam(entName, kMarineTeamType)) do
                            local techAllowed = false

                            if ent.GetTechButtons then
                                for _, tech in ipairs(ent:GetTechButtons()) do
                                    if tech == up then
                                        techAllowed = true
                                        break
                                    end
                                end
                            end

                            if techAllowed and ent:GetCanResearch() and not ent:GetIsResearching() then
                                Log("[sntl] Researching %s", EnumToString(kTechId, up))
                                ent:SetResearching(node, marine)
                                -- return
                                ent.researchProgress = 0.01 -- Hack so the GetIsResearching() will return true
                                break
                            end

                        end
                    end
                end

            end
        end
        if upgradeResearching then
            break
        end
    end


    -- local unlockedWeapons = {
    --     -- kTechId.GrenadeTech
    -- }

    -- for _, up in ipairs(unlockedWeapons) do
    --     if (up and marinetechtree:GetTechNode(up) and not marinetechtree:GetTechNode(up):GetResearched())
    --     then -- Unlock if not already on
    --         local AA = GetEntitiesForTeam("AdvancedArmory", kMarineTeamType)
    --         if (#AA > 0) then
    --             marinetechtree:GetTechNode(up):SetResearched(true)
    --             marinetechtree:QueueOnResearchComplete(up, AA[1])
    --         end
    --     end
    -- end


end


local function GetArmorLevel(self)

    local armorLevels = 0

    local techTree = self:GetTechTree()
    if techTree then

        if techTree:GetHasTech(kTechId.Armor3) then
            armorLevels = 3
        elseif techTree:GetHasTech(kTechId.Armor2) then
            armorLevels = 2
        elseif techTree:GetHasTech(kTechId.Armor1) then
            armorLevels = 1
        end

    end

    return armorLevels

end


local function SNTL_MarineTeam_Update(self, timePassed)
    if Server and GetGamerules():GetGameStarted() then
        self:randomBonusDrop()
        self:UpdateUpgrades(timePassed)
    end
end

function MarineTeam:Update(timePassed)

    PROFILE("MarineTeam:Update")

    PlayingTeam.Update(self, timePassed)

    -- Update distress beacon mask
    self:UpdateGameMasks(timePassed)

    -- if GetGamerules():GetGameStarted() then
    --     CheckForNoIPs(self)
    -- end

    local armorLevel = GetArmorLevel(self)
    for index, player in ipairs(GetEntitiesForTeam("Player", self:GetTeamNumber())) do
        player:UpdateArmorAmount(armorLevel)
    end

    SNTL_MarineTeam_Update(self, timePassed)

end

-- -- Disable the "We need an Infantry portal" voice warning
-- ReplaceUpValue(MarineTeam.Update, "CheckForNoIPs",
--                function (self) return end,
--                { LocateRecurse = true; CopyUpValues = true; } )
