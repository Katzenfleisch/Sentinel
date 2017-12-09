function MarineTeam:SpawnInitialStructures(techPoint)

    assert(techPoint ~= nil)

    local ip = CreateEntity(InfantryPortal.kMapName, techPoint:GetOrigin(), kMarineTeamType)
    ip:SetConstructionComplete()

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
