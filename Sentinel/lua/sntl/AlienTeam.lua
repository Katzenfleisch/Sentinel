
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
            -- else
                -- local minDistance = math.huge

                -- Shared.SortEntitiesByDistance(entity:GetOrigin(), marines)
                -- for _, marine in ipairs(marines) do
                --     local dist = GetPathDistance(marine:GetOrigin(), entity:GetOrigin())

                --     minDistance = dist < minDistance and dist or minDistance
                --     if dist < kMinDistToSpawnEgg then
                --         break -- One is close, don't bother trying the others
                --     end
                -- end

                -- if minDistance > kMinDistToSpawnEgg then
                --     table.insert(candidates, entity)
                -- end
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
    local botCount = math.ceil(numPlayers * 0.55 + math.ceil(numPlayers * 1.10))

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

local function GetPositionForStructure(startPosition, direction)

    local validPosition = false
    local origin = startPosition + direction * 1000

    -- Trace short distance in front
    local trace = Shared.TraceRay(startPosition, origin, CollisionRep.Default, PhysicsMask.AllButPCsAndRagdolls)

    local displayOrigin = trace.endPoint

    -- If it hits something, position on this surface (must be the world or another structure)
    if trace.fraction < 1 then

        if trace.entity == nil then
            validPosition = true

        elseif trace.entity:isa("Infestation") or trace.entity:isa("Clog") then
            validPosition = true
        end

        displayOrigin = trace.endPoint

    end

    -- Don't allow dropped structures to go too close to techpoints and resource nozzles
    if GetPointBlocksAttachEntities(displayOrigin) then
        validPosition = false
    end

    if trace.surface == "nocling" then
        validPosition = false
    end

    -- Don t allow placing above or below us and don't draw either
    local structureFacing = Vector(direction)

    if math.abs(Math.DotProduct(trace.normal, structureFacing)) > 0.9 then
        structureFacing = trace.normal:GetPerpendicular()
    end

    -- Coords.GetLookIn will prioritize the direction when constructing the coords,
    -- so make sure the facing direction is perpendicular to the normal so we get
    -- the correct y-axis.
    local perp = Math.CrossProduct( trace.normal, structureFacing )
    structureFacing = Math.CrossProduct( perp, trace.normal )

    local coords = Coords.GetLookIn( displayOrigin, structureFacing, trace.normal )

    return coords, validPosition, trace.entity

end

local old_AlienTeam_SpawnInitialStructures = AlienTeam.SpawnInitialStructures
function AlienTeam:SpawnInitialStructures(techPoint)
    local numHydras = 3
    local numWebs = 20
    local babblerEggs = 5
    local kNumEggGroup = 4
    local kNumEggPerGroup = 6
    local _, eggs = SpawnRandomEggs(kNumEggGroup, kNumEggPerGroup, techPoint:GetOrigin())
    GetGameInfoEntity():SetNumMaxEggs(kNumEggGroup * kNumEggPerGroup)

    for i = 1, numHydras + numWebs + babblerEggs do
        local randEgg = eggs[math.random(1, #eggs)]

        for j = 1, 10 do
            local origins = SNTL_SpreadedPlacementFromOrigin(GetExtents(kTechId.Hydra), randEgg:GetOrigin(), 1, 1, 4)
            local hydraOrig = origins and #origins > 0 and origins[1]

            if hydraOrig then
                local coords, valid = GetPositionForStructure(hydraOrig, Vector(math.random()-0.5,
                                                                                math.random(),
                                                                                math.random()-0.5))
                if coords and valid then
                    local h = nil
                    if i <= numHydras then
                        h = CreateEntity(Hydra.kMapName, coords.origin, kAlienTeamType)
                        if h then
                            local angles = Angles()

                            h:SetConstructionComplete()
                            angles:BuildFromCoords(coords)
                            h:SetAngles(angles)
                        end
                    elseif i <= numHydras + numWebs then
                        if coords.origin:GetDistanceTo(hydraOrig) < kMaxWebLength then
                            h = CreateEntity(Web.kMapName, coords.origin, kAlienTeamType)
                            if h then
                                h:SetEndPoint(hydraOrig)
                            end
                        end
                    else
                        h = CreateEntity(BabblerEgg.kMapName, coords.origin, kAlienTeamType)
                        if h then
                            local angles = Angles()
                            angles:BuildFromCoords(coords)
                            h:SetAngles(angles)
                        end
                    end

                    if h then
                        break
                    end
                end
            end
        end
    end

    local spawnCandidates = GetSpawnLocationCandidates()

    local buildings = {
                       Veil.kMapName, Veil.kMapName, Veil.kMapName,
                       Spur.kMapName, Spur.kMapName, Spur.kMapName,
                       Hydra.kMapName, Hydra.kMapName, Whip.kMapName,
                       Clog.kMapName, Clog.kMapName, Clog.kMapName,
                       Shell.kMapName, Shell.kMapName, Shell.kMapName,
                       Crag.kMapName
    }

    local origins = SNTL_SpreadedPlacementFromOrigin(GetExtents(kTechId.Shade), techPoint:GetOrigin(), #buildings, 1, 4)

    local b = CreateEntity(TunnelEntrance.kMapName, techPoint:GetOrigin(), kAlienTeamType)
    b:SetConstructionComplete()
    for i, orig in ipairs(origins) do
        b = CreateEntity(buildings[i], orig, kAlienTeamType)

        if not b:isa("Clog") and not b:isa("Whip") and not b:isa("Hydra") then
            local c = CreateEntity(Cyst.kMapName, orig, kAlienTeamType)
            if b.SetConstructionComplete then
                b:SetConstructionComplete()
            end
            -- b:SetModel(nil)
            -- c:SetModel(nil)
            c:SetConstructionComplete()
        end
    end

    Shared.SortEntitiesByDistance(techPoint:GetOrigin(), spawnCandidates)
    for i = 1, #spawnCandidates do
        local orig = spawnCandidates[i]:GetOrigin()
        local spawnPoint = nil
        local spawnPoints = SNTL_SpreadedPlacementFromOrigin(GetExtents(kTechId.Armory), orig, 10, 1, 6)

        for _, sp in ipairs(spawnPoints) do
            if sp and #GetEntitiesWithMixinForTeamWithinRange("Live", kAlienTeamType, sp, 10) == 0
            then
                spawnPoint = sp
                break
            end
        end

        if spawnPoint then

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

        -- TODO: if there are no more eggs, need at least X kill to win
        if (not aliensHaveActivePlayers and numEggs == 0) or
            self:GetHasConceded() or totalPhasedMarines > 0
        then
            return true
        end
    end

    return false

end

Shared.LinkClassToMap("AlienTeam", nil, networkVars)
