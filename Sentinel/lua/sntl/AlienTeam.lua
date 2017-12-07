
-- local k


-- local function FindLocation()

function AlienTeam:UpdateRandomEggSpawn(timePassed)
    return
end

function AlienTeam:UpdateFillerBots()
    local gamerules = GetGamerules()
    local botTeamController = gamerules:GetBotTeamController()
    local marineTeam = gamerules:GetTeam(kMarineTeamType)
    local botCount = marineTeam:GetHumanPlayerCount() * 3

    gamerules:SetMaxBots(botCount, false)
end

local old_AlienTeam_Update = AlienTeam.Update
function AlienTeam:Update(timePassed)
    local rval = old_AlienTeam_Update and old_AlienTeam_Update(self, timePassed)

    self:UpdateRandomEggSpawn(timePassed)
    self:UpdateFillerBots()
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

local function OnClientConnect(client)
end
local function OnClientDisconnected(client)
end

Event.Hook("ClientConnect", OnClientConnect)
Event.Hook("ClientDisconnected", OnClientDisconnected)
