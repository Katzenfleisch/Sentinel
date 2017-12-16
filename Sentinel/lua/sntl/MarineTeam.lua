
local function SetRandomAngle(ent)
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

    local pg_origin = SNTL_SpreadedPlacementFromOrigin(GetExtents(kTechId.PhaseGate), origin, 1, 2, 5)
    local pg = pg_origin and CreateEntity(PhaseGate.kMapName, pg_origin[1], kMarineTeamType)
    if pg then pg:SetConstructionComplete() ; SetRandomAngle(pg) end

    local armslab_origin = SNTL_SpreadedPlacementFromOrigin(GetExtents(kTechId.ArmsLab), origin, 1, 2, 5)
    local armslab = armslab_origin and CreateEntity(ArmsLab.kMapName, armslab_origin[1], kMarineTeamType)
    if armslab then armslab:SetConstructionComplete() ; SetRandomAngle(armslab) end

    local armory_origin = SNTL_SpreadedPlacementFromOrigin(GetExtents(kTechId.AdvancedArmory), origin, 1, 2, 5)
    local armory = armory_origin and CreateEntity(AdvancedArmory.kMapName, armory_origin[1], kMarineTeamType)
    if armory then armory:SetConstructionComplete() ; SetRandomAngle(armory) end

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
        kTechId.Weapons1,
        kTechId.Weapons2,
        kTechId.Armor1
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
        kTechId.GrenadeTech
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


-- -- Disable the "We need an Infantry portal" voice warning
-- ReplaceUpValue(MarineTeam.Update, "CheckForNoIPs",
--                function (self) return end,
--                { LocateRecurse = true; CopyUpValues = true; } )
