
local kMinDistToSpawnEgg = 40
local networkVars =
{
        sntl_numEggs = "integer",
        sntl_noMoreEggs = "boolean"
}

function AlienTeam:GetBioMassLevel()
    if GetGameInfoEntity():GetWarmUpActive() then return 9 end

    local desiredEggFraction = GetGameInfoEntity():GetNumEggs() / GetGameInfoEntity():GetNumMaxEggs()

    return (1 - desiredEggFraction) * 9
    -- return self.bioMassLevel
end

function AlienTeam:GetBioMassFraction()
    if GetGameInfoEntity():GetWarmUpActive() then return 9 end

    local desiredEggFraction = GetGameInfoEntity():GetNumEggs() / GetGameInfoEntity():GetNumMaxEggs()

    return (1 - desiredEggFraction) * 9
    -- return self.bioMassFraction
end


local function GetSpawnLocationCandidates(maxCount)
    local count = 0
    local candidates = {}
    local spawnNearEntities = {"ResourcePoint"}

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

local function SpawnRandomEggs(numGroup, numEggPerGroup, nearOrigin)
    local eggs = {}
    local candidatePos = 1
    local spawnCandidates = GetSpawnLocationCandidates()

    if nearOrigin then
        local newSpawnCandidates = {}

        Shared.SortEntitiesByDistance(nearOrigin, spawnCandidates)
        for i = 1, math.min(#spawnCandidates, numGroup + 2) do
            table.insert(newSpawnCandidates, spawnCandidates[i])
        end

        -- Shuffle only the spawn location far from marines to get some variety
        spawnCandidates = SNTL_ShuffleArray(newSpawnCandidates)
    else
        spawnCandidates = SNTL_ShuffleArray(spawnCandidates)
    end
    if #spawnCandidates == 0 then
        Log("[sntl] Unable to find an egg spawn location (marines nearby)")
        return false
    end

    for i = 1, numGroup do
        local pos = spawnCandidates[candidatePos]:GetOrigin()

        local new_eggs = SNTL_SpawnEggsAroundPos(pos, numEggPerGroup)

        if new_eggs then
            for _, egg in ipairs(new_eggs) do
                table.insert(eggs, egg)
            end
        end
        candidatePos = 1 + (candidatePos % #spawnCandidates)
    end

    return true, eggs
end

local old_AlienTeam_OnResetComplete = AlienTeam.OnResetComplete
function AlienTeam:OnResetComplete(teamName, teamNumber)
    if old_AlienTeam_OnResetComplete then
        old_AlienTeam_OnResetComplete(self, teamName, teamNumber)
    end

    self.sntl_numEggs = 0
    self.sntl_noMoreEggs = false
end

function AlienTeam:UpdateHiddenEggSpawn(timePassed)

    if SNTL_LimitCallFrequency(AlienTeam.UpdateHiddenEggSpawn, 4) then return end
    if #GetEntitiesForTeam("Egg", kAlienTeamType) >= 50 then return end

    local st, eggs = SpawnRandomEggs(1, 1)

    if st and eggs then
        for _, egg in ipairs(eggs) do
            egg.sntl_hidden_egg = true
            egg:SetModel( nil )
        end
    end
    return
end


function AlienTeam:UpdateFillerBots()

    if SNTL_LimitCallFrequency(AlienTeam.UpdateFillerBots, 1) then return end

    local gamerules = GetGamerules()
    local botTeamController = gamerules:GetBotTeamController()
    local marineTeam = gamerules:GetTeam(kMarineTeamType)
    local numPlayers = marineTeam:GetNumPlayers() -- marineTeam:GetHumanPlayerCount()
    local botCount = numPlayers * 0.7 + math.ceil(numPlayers * 1.10)

    gamerules:SetMaxBots(botCount, false)
end

function AlienTeam:GetNumEggs()
    return self.sntl_numEggs
end

function AlienTeam:UpdateNoMoreEggs()

    local numEggs = 0

    for _, egg in ipairs(GetEntitiesForTeam("Egg", kAlienTeamType)) do
        numEggs = numEggs + ((egg:GetIsAlive() and not egg.sntl_hidden_egg) and 1 or 0)
    end
    self.sntl_numEggs = numEggs

    GetGameInfoEntity():SetNumEggs(self.sntl_numEggs)
    if not self.sntl_noMoreEggs and self:GetNumEggs() == 0 then
        local pgs = GetEntitiesForTeam("PhaseGate", kMarineTeamType)
        local marineTeam = GetGamerules():GetTeam(kMarineTeamType)

        self.sntl_noMoreEggs = true
        local function giveOrderBackToBase(p)
            if p and #pgs > 0 and HasMixin(p, "Live") and HasMixin(p, "Orders") and p:GetIsAlive()
            then
                p:GiveOrder(kTechId.Move, pgs[1]:GetId(), pgs[1]:GetOrigin(), nil, true, true)
            end
        end

        marineTeam:ForEachPlayer(giveOrderBackToBase)
        SendTeamMessage(marineTeam, kTeamMessageTypes.ReturnToBase)
    end
end

local old_AlienTeam_Update = AlienTeam.Update
function AlienTeam:Update(timePassed)
    local rval = old_AlienTeam_Update and old_AlienTeam_Update(self, timePassed)

    if GetGamerules():GetGameStarted() then
        self:UpdateNoMoreEggs()
        self:UpdateFillerBots()
        self:UpdateHiddenEggSpawn()
    else
        GetGamerules():SetMaxBots(0, false)
    end
    return rval
end

local old_AlienTeam_SpawnInitialStructures = AlienTeam.SpawnInitialStructures
function AlienTeam:SpawnInitialStructures(techPoint)
    local kNumEggGroup = 4
    local kNumEggPerGroup = 6
    SpawnRandomEggs(kNumEggGroup, kNumEggPerGroup, techPoint:GetOrigin())
    GetGameInfoEntity():SetNumMaxEggs(kNumEggGroup * kNumEggPerGroup)

    local spawnCandidates = GetSpawnLocationCandidates()

    local buildings = {
                       Veil.kMapName, Veil.kMapName, Veil.kMapName,
                       Spur.kMapName, Spur.kMapName, Spur.kMapName,
                       Hydra.kMapName, Hydra.kMapName, Whip.kMapName,
                       Clog.kMapName, Clog.kMapName, Clog.kMapName,
                       Shell.kMapName, Shell.kMapName, Shell.kMapName,
                       Shade.kMapName
    }

    local origins = SNTL_SpreadedPlacementFromOrigin(GetExtents(kTechId.Shade), techPoint:GetOrigin(), 1, 2, 5)
    local origins = SNTL_SpreadedPlacementFromOrigin(GetExtents(kTechId.Shade), origins[1], #buildings, 0, 3)

    local b = CreateEntity(TunnelEntrance.kMapName, techPoint:GetOrigin(), kAlienTeamType)
    b:SetConstructionComplete()
    for i, orig in ipairs(origins) do
        b = CreateEntity(buildings[i], orig, kAlienTeamType)

        if not b:isa("Clog") and not b:isa("Whip") and not b:isa("Hydra") then
            local c = CreateEntity(Cyst.kMapName, orig, kAlienTeamType)
            if b.SetConstructionComplete then
                b:SetConstructionComplete()
            end
            b:SetModel(nil)
            c:SetModel(nil)
            c:SetConstructionComplete()
        end
    end

    Shared.SortEntitiesByDistance(techPoint:GetOrigin(), spawnCandidates)
    for i = 1, #spawnCandidates do
        local orig = spawnCandidates[i]:GetOrigin()
        if #GetEntitiesWithMixinForTeamWithinRange("Live", kAlienTeamType, orig, 10) == 0 then

            local spawnPoint = SNTL_SpreadedPlacementFromOrigin(GetExtents(kTechId.Armory), orig, 1, 1, 5)
            if (spawnPoint) then
                spawnPoint = spawnPoint[1]
            end

            local a = CreateEntity(Armory.kMapName, spawnPoint, kMarineTeamType)

            if a then
                -- local location = GetLocationForPoint(a:GetModelOrigin())
                -- local powerNode = location ~= nil and GetPowerPointForLocation(location:GetName())

                -- if powerNode then
                --     powerNode:SocketPowerNode()
                --     Log("[sntl] PowerPoint in %s correclty socked", location and location:GetName())
                -- else
                --     Log("[sntl] No powerpoint found for location %s", location and location:GetName())
                -- end

                -- a:AddTimedCallback(ConstructMixin.SetConstructionComplete, 0.1)
                a:SetConstructionComplete()
            end
            break
        end
    end

    return -- Disable, do not spawn any alien base
end

-- local old_AlienTeam_GetHasTeamLost = AlienTeam.GetHasTeamLost
function AlienTeam:GetHasTeamLost()

    PROFILE("AlienTeam:GetHasTeamLost")

    if GetGamerules():GetGameStarted() and not Shared.GetCheatsEnabled() then
        local marineTeam = GetGamerules():GetTeam(kMarineTeamType)
        local marineHaveActivePlayers = marineTeam:GetHasActivePlayers()
        local aliensHaveActivePlayers = self:GetHasActivePlayers()
        local numEggs = self:GetNumEggs()
        local marinesEndGates = GetEntitiesForTeam("PhaseGate", kMarineTeamType)
        local totalPhasedMarines = 0

        for _, pg in ipairs(marinesEndGates) do
            totalPhasedMarines = totalPhasedMarines + pg:GetPhasedMarinesCount()
        end

        if (not aliensHaveActivePlayers and numEggs == 0) or self:GetHasConceded() or
            (not marineHaveActivePlayers and totalPhasedMarines > 0)
        then
            return true
        end
    end

    return false

end

Shared.LinkClassToMap("AlienTeam", nil, networkVars)
