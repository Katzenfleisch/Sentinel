
local kLimitCallFrequency = {}

function SNTL_LimitCallFrequency(id, frequency)
    local now = Shared.GetTime()

    if kLimitCallFrequency[id] then
        if kLimitCallFrequency[id] >= now then
            return true
        end
        kLimitCallFrequency[id] = now + frequency
    else
        kLimitCallFrequency[id] = 0
    end
    return false
end

function SNTL_IsPlayerVirtual(ent)
    if (ent and ent.GetClient and ent:GetClient() and not ent:GetClient():GetIsVirtual()) then
      return false
   else
      return true
   end
end

function SNTL_GetGroundAtPosition(position, filter, physicsGroupMask, extents)

    local kCapsuleSize = 0.1

    local topOffset = extents.y + kCapsuleSize
    local startPosition = position + Vector(0, topOffset, 0)
    local endPosition = position - Vector(0, 1000, 0)

    local trace

    physicsGroupMask = physicsGroupMask or PhysicsMask.Movement
    if filter == nil then
        trace = Shared.TraceCapsule(startPosition, endPosition, kCapsuleSize, 0, CollisionRep.Move, physicsGroupMask)
    else
        trace = Shared.TraceCapsule(startPosition, endPosition, kCapsuleSize, 0, CollisionRep.Move, physicsGroupMask, filter)
    end

    -- If we didn't hit anything, then use our existing position. This
    -- prevents objects from constantly moving downward if they get outside
    -- of the bounds of the map.
    if trace.fraction ~= 1 then
        return trace.endPoint - Vector(0, 2 * kCapsuleSize, 0)
    else
        return position
    end
end

-- @return a list of at most @number Vector(x,y,z) spreading around a given @orig point
-- If it can't find any placement, the list still contains at least the original given point
function SNTL_SpreadedPlacementFromOrigin(extents, orig, maxCount, minRange, maxRange)
    local prePlaceOrig = {}
    local capsuleHeight, capsuleRadius = GetTraceCapsuleFromExtents(extents)
    local position = nil

    maxCount = maxCount or 1
    for i = 1, maxCount do

        local success = false
        local usedOrig = nil

        -- Persistence is the path to victory.
        for index = 1, 10 do

            -- Place the point a bit above ground, easier to find other points
            usedOrig = (#prePlaceOrig > 0 and prePlaceOrig[math.random(1, #prePlaceOrig)] or orig) + Vector(0, 1, 0)
            position = GetRandomSpawnForCapsule(capsuleHeight, capsuleRadius, usedOrig, minRange, maxRange, EntityFilterAll())
            position = position and SNTL_GetGroundAtPosition(position, nil, PhysicsMask.AllButPCs, extents)

            if position then
                success = true

                for e = 1, #prePlaceOrig do -- Only spawn away from already found origin
                    if (position:GetDistanceTo(prePlaceOrig[e]) < minRange) then
                        -- Check if we are in the same location room
                        if (GetLocationForPoint(orig) and GetLocationForPoint(orig) == GetLocationForPoint(position))
                        then
                            success = false
                            break
                        end
                    end
                end

                if (success) then
                    -- 0.1 needed somehow to get the building really on the ground
                    table.insert(prePlaceOrig, position)
                    break
                end
            end

            maxRange = maxRange * 1.10
        end

        -- if not success then
        --    Print("Create %s: Couldn't find space for entity", EnumToString(kTechId, techId))
        -- end
    end

    return prePlaceOrig
end

function SNTL_ShuffleArray(array, randomSeed)
    local new_array = {}

    if randomSeed then
        math.randomseed(randomSeed)
    end
    while #array > 0 do
        local rand_pos = math.random(1, #array)
        table.insert(new_array, array[rand_pos])
        table.remove(array, rand_pos)
    end

    if randomSeed then
        math.randomseed(os.time()) -- Reset random()
    end
    return new_array
end

-- Needed for bots to have a uniq ID, otherwise they would cound as '1' player.
-- This will, for example, make all bot gorges shared the same tunnel/hydras/clogs pool.
if Server then
    local botsClientIdIt = -1
    local botsClientIds = {}
    local ServerClientGetUserId = ServerClient.GetUserId
    local function SNTL_GetUserId(self)
        local userId = ServerClientGetUserId(self)
        if userId == 0 then
            local player = self:GetControllingPlayer()

            if player then
                if not botsClientIds[player:GetName()] then
                    botsClientIds[player:GetName()] = botsClientIdIt
                    botsClientIdIt = botsClientIdIt - 1
                end
                return botsClientIds[player:GetName()]
            end
        end
        return userId
    end

    ServerClient.GetUserId = SNTL_GetUserId
end
