

local kMinDistToSpawnEgg = 30

local function GetSpawnLocationCandidates(maxCount)
    local count = 0
    local candidates = {}
    local spawnNearEntities = {"TechPoint", "ResourcePoint", "PowerPoint"}

    -- Use direct distance (faster)
    maxCount = maxCount or math.huge
    for _, entName in ipairs(spawnNearEntities) do
        for _, entity in ientitylist(Shared.GetEntitiesWithClassname(entName)) do
            local marines = GetEntitiesForTeamWithinRange("Marine", kMarineTeamType, entity:GetOrigin(), kMinDistToSpawnEgg)

            if #marines == 0 then
                table.insert(candidates, entity)
            else
                local minDistance = math.huge

                Shared.SortEntitiesByDistance(entity:GetOrigin(), marines)
                for _, marine in ipairs(marines) do
                    local dist = GetPathDistance(marine:GetOrigin(), entity:GetOrigin())

                    minDistance = dist < minDistance and dist or minDistance
                    if dist < kMinDistToSpawnEgg then
                        break -- One is close, don't bother trying the others
                    end
                end

                if minDistance > kMinDistToSpawnEgg then
                    table.insert(candidates, entity)
                end
            end

            if #candidates >= maxCount then
                return candidates
            end
        end
    end

    -- -- Use pathing distance
    -- if #candidates == 0 then
    --     for _, entName in ipairs(spawnNearEntities) do
    --         for _, entity in ientitylist(Shared.GetEntitiesWithClassname(entName)) do
    --         end
    --     end
    -- end
    return candidates
end


local function SpawnRandomEggs(numGroup, numEggPerGroup)
    local randSeed = 1
    local candidatePos = 1
    local spawnCandidates = GetSpawnLocationCandidates()
    local eggExtents = GetExtents(kTechId.Egg)

    spawnCandidates = SNTL_ShuffleArray(spawnCandidates, randSeed)
    if #spawnCandidates == 0 then
        Log("[sntl] Unable to find an egg spawn location (marines nearby)")
        return false
    end

    for i = 1, numGroup do
        local pos = spawnCandidates[candidatePos]:GetOrigin()
        local spawnedEggs = 0
        local origins = SNTL_SpreadedPlacementFromOrigin(eggExtents, pos, numEggPerGroup, 1, 6)

        local location = GetLocationForPoint(pos)
        local locationName = location and location:GetName() or "(unknown pos)"

        -- Loop over each spreaded location found, otherwise just ignore if it fails to find a spot
        for j = 1, #origins do
            local position = origins[j]
            local validForEgg = true --position and GetCanEggFit(position)
            local egg = validForEgg and CreateEntity(Egg.kMapName, position, kAlienTeamType)

            if not egg then
                Log("[sntl] Unable to create entity (valid pos : %s, egg : %s)", validForEgg, egg)
            else

                if validForEgg then

                    -- Randomize starting angles
                    local angles = egg:GetAngles()
                    angles.yaw = math.random() * math.pi * 2
                    egg:SetAngles(angles)

                    -- To make sure physics model is updated without waiting a tick
                    egg:UpdatePhysicsModel()
                    spawnedEggs = spawnedEggs + 1
                end

            end
        end

        if spawnedEggs then
            Log("[sntl] * (%s/%s) A group of %s egg(s) were spawned in %s", i, numGroup, spawnedEggs, locationName)
        end
        candidatePos = 1 + ((candidatePos + 1) % #spawnCandidates)
    end

    return true
end


function AlienTeam:UpdateRandomEggSpawn(timePassed)

    if SNTL_LimitCallFrequency(AlienTeam.UpdateRandomEggSpawn, 5) then return end

    SpawnRandomEggs(1, 3)
    return
end

function AlienTeam:UpdateFillerBots()

    if SNTL_LimitCallFrequency(AlienTeam.UpdateFillerBots, 1) then return end

    local gamerules = GetGamerules()
    local botTeamController = gamerules:GetBotTeamController()
    local marineTeam = gamerules:GetTeam(kMarineTeamType)
    local botCount = marineTeam:GetHumanPlayerCount() * 3

    gamerules:SetMaxBots(botCount, false)
end

local old_AlienTeam_Update = AlienTeam.Update
function AlienTeam:Update(timePassed)
    local rval = old_AlienTeam_Update and old_AlienTeam_Update(self, timePassed)

    if GetGamerules():GetGameStarted() then
        self:UpdateRandomEggSpawn(timePassed)
    end
    self:UpdateFillerBots()
    return rval
end

local old_AlienTeam_SpawnInitialStructures = AlienTeam.SpawnInitialStructures
function AlienTeam:SpawnInitialStructures(techPoint)
    SpawnRandomEggs(3, 5)
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