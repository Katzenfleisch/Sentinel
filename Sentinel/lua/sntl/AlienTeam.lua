

function AlienTeam:UpdateRandomEggSpawn(timePassed)
    return
end

local old_AlienTeam_Update = AlienTeam.Update
function AlienTeam:Update(timePassed)
    local rval = old_AlienTeam_Update and old_AlienTeam_Update(self, timePassed)

    self:UpdateRandomEggSpawn(timePassed)
    return rval
end

local old_AlienTeam_SpawnInitialStructures = AlienTeam.SpawnInitialStructures
function AlienTeam:SpawnInitialStructures(techPoint)
    return -- Disable, do not spawn any alien base
end

local old_AlienTeam_GetHasTeamLost = AlienTeam.GetHasTeamLost
function AlienTeam:GetHasTeamLost()

    PROFILE("AlienTeam:GetHasTeamLost")

    -- Aliens just don't lose

    -- if GetGamerules():GetGameStarted() and not Shared.GetCheatsEnabled() then

        -- -- Team can't respawn or last Command Station or Hive destroyed
        -- local activePlayers = self:GetHasActivePlayers()
        -- local abilityToRespawn = self:GetHasAbilityToRespawn()
        -- local numAliveCommandStructures = self:GetNumAliveCommandStructures()

        -- if  (not activePlayers and not abilityToRespawn) or
        --     (numAliveCommandStructures == 0) or
        --     (self:GetNumPlayers() == 0) or
        --     self:GetHasConceded() then

        --     return true

        -- end

    -- end

    return false

end
