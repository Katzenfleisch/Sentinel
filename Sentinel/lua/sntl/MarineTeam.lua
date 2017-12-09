local function SetRandomAngle(ent)
    -- Randomize starting angles
    local angles = ent:GetAngles()
    angles.yaw = math.random() * math.pi * 2
    ent:SetAngles(angles)

    -- To make sure physics model is updated without waiting a tick
    ent:UpdatePhysicsModel()
end

function MarineTeam:SpawnInitialStructures(techPoint)

    assert(techPoint ~= nil)

    local origin = techPoint:GetOrigin()
    local ip = CreateEntity(InfantryPortal.kMapName, origin, kMarineTeamType)
    ip:SetConstructionComplete()

    -- Force buildings to be on a different circle around the IP so they don't overlap
    local pg_origin      = SNTL_SpreadedPlacementFromOrigin(GetExtents(kTechId.PhaseGate),  origin, 1, 2, 3)
    local armslab_origin = SNTL_SpreadedPlacementFromOrigin(GetExtents(kTechId.ArmsLab),    origin, 1, 5, 6)
    local armory_origin  = SNTL_SpreadedPlacementFromOrigin(GetExtents(kTechId.Armory),     origin, 1, 5, 6)

    local pg      = pg_origin       and CreateEntity(PhaseGate.kMapName,    pg_origin[1],       kMarineTeamType)
    local armslab = armslab_origin  and CreateEntity(ArmsLab.kMapName,      armslab_origin[1],  kMarineTeamType)
    local armory  = armory_origin   and CreateEntity(Armory.kMapName,       armory_origin[1],   kMarineTeamType)

    if pg       then pg:SetConstructionComplete()       ; SetRandomAngle(pg)        end
    if armslab  then armslab:SetConstructionComplete()  ; SetRandomAngle(armslab)   end
    if armory   then armory:SetConstructionComplete()   ; SetRandomAngle(armory)    end

    return

end

function MarineTeam:GetHasTeamLost()

    PROFILE("PlayingTeam:GetHasTeamLost")

    if GetGamerules():GetGameStarted() and not Shared.GetCheatsEnabled() then

        -- Team can't respawn if they don't have any more ips, and lose if they are all dead
        local activePlayers = self:GetHasActivePlayers()
        local abilityToRespawn = self:GetHasAbilityToRespawn()

        if  (not activePlayers and not abilityToRespawn) or
            (self:GetNumPlayers() == 0) or
            self:GetHasConceded() then

            return true

        end

    end

    return false

end
