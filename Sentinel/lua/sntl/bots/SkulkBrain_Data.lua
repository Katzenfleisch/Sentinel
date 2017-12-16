
Script.Load("lua/bots/CommonActions.lua")
Script.Load("lua/bots/BrainSenses.lua")

local kUpgrades = {
    kTechId.Crush,
    kTechId.Regeneration,
    kTechId.Adrenaline,

    kTechId.Vampirism,
    kTechId.Aura,
    kTechId.Celerity,

    kTechId.Silence,
    kTechId.Focus,
    kTechId.Carapace,
}

local kEvolutions = {
    kTechId.Lerk,
    kTechId.Fade,
    kTechId.Onos
}


local function AIA_GetDirToNearestWall(bot)
    local skulk = bot:GetPlayer()
    local eyePos = skulk:GetEyePos()
    local viewCoords = skulk:GetViewCoords()
    local direction = bot:GetMotion().currMoveDir or viewCoords.zAxis

    local leftWall = nil
    local rightWall = nil
    local moveDir = nil

    local z = 4
    local y = 6

    leftWall = Shared.TraceRay(eyePos, eyePos + y * viewCoords.xAxis + z * direction,
                               CollisionRep.Move, PhysicsMask.Bullets, EntityFilterOne(skulk))
    if 0.2 < leftWall.fraction and leftWall.fraction < 0.9 then
        moveDir = (leftWall.endPoint - eyePos):GetUnit() --direction + viewCoords.xAxis / 4
    end

    if not moveDir then
        rightWall = Shared.TraceRay(eyePos, eyePos + -y * viewCoords.xAxis + z * direction,
                                    CollisionRep.Move, PhysicsMask.Bullets, EntityFilterOne(skulk))
        if 0.2 < rightWall.fraction and rightWall.fraction < 0.9 then
            moveDir = (rightWall.endPoint - eyePos):GetUnit() --direction - viewCoords.xAxis / 4
        end
    end

    if moveDir then
        -- local p1 = skulk:GetOrigin() + direction * 10

        -- local perpVect = Vector(-p1.x, p1.y, p1.z)
        -- local p2 = p1 + perpVect * 1


        if rightWall then
            return ((eyePos + -4 * viewCoords.xAxis + 100 * direction) - eyePos):GetUnit()
        else
            return ((eyePos +  4 * viewCoords.xAxis + 100 * direction) - eyePos):GetUnit()
        end

        -- local p2 = skulk:GetOrigin() + moveDir * 100
        -- local pDist = p1:GetDistanceTo(p2)

        -- local p3 = p1 + (p2 - p1):GetUnit() * (pDist / 9)
        -- local dir1 = (p3 - skulk:GetOrigin()):GetUnit()

        -- return dir1

    end
    -- local dist_between_both_end = p2 + (p1 - p2):GetUnit() * (pDist / 2)

    -- dist_between_both_end = dist_between_both_end

    -- return moveDir
    return moveDir
end

local function AIA_WallJumpToTarget(bot, move, targetPos)
    local skulk = bot:GetPlayer()
    local canWallJump = skulk:GetCanWallJump()
    local recentlyWallJumped = skulk:GetRecentlyWallJumped()
    local eyePos = skulk:GetEyePos()
    local viewCoords = skulk:GetViewCoords()
    -- AIA: Number of walljump allowed before forcing the skulk to hit the ground.
    --      Prevents the skulks from getting stuck in ceilings
    local maxWallJump = 4

    -- Make another trace to see where to walljump to
    local moveDir = bot:GetMotion().currMoveDir
    local dist = skulk:GetOrigin():GetDistance(targetPos)

    -- if bot.LeaveTunnelTowardDest and bot:LeaveTunnelTowardDest(targetPos) then
    --     return
    -- end

    -- if skulk.AIA_waitRegroup then
    --    local sighted = skulk:GetIsSighted()
    --    if not sighted then
    --       move.commands = AddMoveCommand( move.commands, Move.MovementModifier ) -- Wait a bit
    --    end
    --    skulk.AIA_waitRegroup = nil
    -- end
    if bot.AIA_WallJumped == nil then
        bot.AIA_WallJumped = 0
    end

    bot:GetMotion():SetDesiredViewTarget(nil)
    -- bot:GetMotion():SetDesiredViewTarget(viewCoords.origin + bot:GetMotion().currMoveDir * 4 + viewCoords.xAxis + viewCoords.yAxis)
    -- bot:GetMotion():SetDesiredViewTarget(viewCoords.origin + viewCoords.xAxis + viewCoords.yAxis + viewCoords.zAxis*4)
    bot:GetMotion():SetDesiredMoveTarget(targetPos)

    -- if bot.jumpOffset == nil then

    --     local botToTarget = GetNormalizedVectorXZ( - eyePos)
    --     local sideVector = botToTarget:CrossProduct(Vector(0, 1, 0))
    --     if math.random() < 0.5 then
    --         bot.jumpOffset = botToTarget + sideVector
    --     else
    --         bot.jumpOffset = botToTarget - sideVector
    --     end
    --     bot:GetMotion():SetDesiredViewTarget( bestTarget:GetEngagementPoint() )

    -- end

    -- bot:GetMotion():SetDesiredMoveDirection( bot.jumpOffset )

    local move_side = 1
    local move_period = 0.1
    local move_force = Vector(0, 0.4, 0)
    local now = Shared.GetTime()

    -- bot.lastWallJump = bot.lastWallJump or Shared.GetTime()
    -- bot.jumpOffset = bot.jumpOffset or Shared.GetTime()
    -- if bot.lastWallJump < now and now < bot.lastWallJump + move_period then
    --     local sideVector = moveDir:CrossProduct(move_force)
    --     -- if now < bot.lastWallJump + move_period * 1 then -- 1/3 one side, 2/3 the other
    --     if move_side == 1 then
    --         bot.jumpOffset = moveDir + sideVector        --
    --     else
    --         bot.jumpOffset = moveDir - sideVector
    --     end
    --     bot:GetMotion():SetDesiredMoveDirection( bot.jumpOffset )
    -- end

    -- if bot.lastWallJump + move_period < now then
    --     bot.lastWallJump = Shared.GetTime()
    --     move_side = move_side * -1
    -- end


    bot.timeOfJump = bot.timeOfJump or 0
    bot.jumpAfterWallJump = bot.jumpAfterWallJump or 0
    -- if (dist > kAIA_attack_dist and kAIA_wall_jump) then
    if (canWallJump) then
        -- AIA: Skulks need to touch the ground between two walljump, present stuck in ceilings
        if (not recentlyWallJumped) and bot.AIA_WallJumped < maxWallJump
        then
            move.commands = AddMoveCommand( move.commands, Move.Jump )
            bot.AIA_WallJumped = bot.AIA_WallJumped + 1
            bot.jumpAfterWallJump = 4
            bot.timeOfJump = Shared.GetTime()
        end
    else
        if skulk:GetIsOnGround() and (bot.jumpAfterWallJump > 0 or bot.timeOfJump + 5 < Shared.GetTime()) then
            bot.AIA_WallJumped = 0
            bot.jumpAfterWallJump = bot.jumpAfterWallJump - 1
            move.commands = AddMoveCommand( move.commands, Move.Jump )
            bot.timeOfJump = Shared.GetTime()
        end
    end

    if Shared.GetTime() < bot.timeOfJump + 0.5 then
        move.commands = AddMoveCommand( move.commands, Move.Crouch )
    end

    -- end
    -- moveDir = AIA_GetDirToNearestWall(bot)
    -- if moveDir then
    --     bot:GetMotion():SetDesiredMoveDirection( moveDir + Vector(0, 0.4, 0) )
    -- end
    -- move.commands = AddMoveCommand( move.commands, Move.Crouch ) -- So we do not get stuck in ceilings

    -- bot:GetMotion():SetDesiredMoveDirection(  bot:GetMotion().desiredMoveDirection )
end

------------------------------------------
--  More urgent == should really attack it ASAP
------------------------------------------
local function GetAttackUrgency(bot, mem)

    -- See if we know whether if it is alive or not
    local ent = Shared.GetEntity(mem.entId)
    if not HasMixin(ent, "Live") or not ent:GetIsAlive() then
        return 0.0
    end

    local botPos = bot:GetPlayer():GetOrigin()
    local targetPos = ent:GetOrigin()
    local distance = botPos:GetDistance(targetPos)

    if mem.btype == kMinimapBlipType.PowerPoint then
        local powerPoint = ent
        -- if powerPoint ~= nil and powerPoint:GetIsSocketed() then
        --     return 0.55
        -- else
        --     return 0
        -- end
        return 0
    end

    local immediateThreats = {
        [kMinimapBlipType.Marine] = true,
        [kMinimapBlipType.JetpackMarine] = true,
        [kMinimapBlipType.Exo] = true,
        [kMinimapBlipType.Sentry] = true
    }

    if immediateThreats[mem.btype] then
        -- Attack the nearest immediate threat (urgency will be 1.1 - 2)
        return 1 + 1 / math.max(distance, 1)
    end

    -- No immediate threat - load balance!
    local numOthers = bot.brain.teamBrain:GetNumAssignedTo( mem,
            function(otherId)
                if otherId ~= bot:GetPlayer():GetId() then
                    return true
                end
                return false
            end)

    -- --Other urgencies do not rank anything here higher than 1!
    -- local urgencies = {
        -- [kMinimapBlipType.ARC] =                numOthers >= 2 and 0.4 or 0.9,
        -- [kMinimapBlipType.CommandStation] =     numOthers >= 4 and 0.3 or 0.75,
        -- [kMinimapBlipType.PhaseGate] =          numOthers >= 2 and 0.2 or 0.9,
        -- [kMinimapBlipType.Observatory] =        numOthers >= 2 and 0.2 or 0.8,
        -- [kMinimapBlipType.Extractor] =          numOthers >= 2 and 0.2 or 0.7,
        -- [kMinimapBlipType.InfantryPortal] =     numOthers >= 2 and 0.2 or 0.6,
        -- [kMinimapBlipType.PrototypeLab] =       numOthers >= 1 and 0.2 or 0.55,
        -- [kMinimapBlipType.Armory] =             numOthers >= 2 and 0.2 or 0.5,
        -- [kMinimapBlipType.RoboticsFactory] =    numOthers >= 2 and 0.2 or 0.5,
        -- [kMinimapBlipType.ArmsLab] =            numOthers >= 3 and 0.2 or 0.6,
        -- [kMinimapBlipType.MAC] =                numOthers >= 1 and 0.2 or 0.4,
    -- }

    -- if urgencies[ mem.btype ] ~= nil then
    --     return urgencies[ mem.btype ]
    -- end

    return 0.0

end


local function PerformAttackEntity( eyePos, bestTarget, bot, brain, move )

    assert( bestTarget )

    local marinePos = bestTarget:GetOrigin()

    local doFire = false
    bot:GetMotion():SetDesiredMoveTarget( marinePos )

    local distance = eyePos:GetDistance(marinePos)
    if distance < 2.5 then
        doFire = true
    end

    if doFire then
        local target = bestTarget:GetEngagementPoint()

        if bestTarget:isa("Player") then
             -- Attacking a player
             target = target + Vector( math.random(), math.random(), math.random() ) * 0.3
            if bot:GetPlayer():GetIsOnGround() and bestTarget:isa("Player") then
                move.commands = AddMoveCommand( move.commands, Move.Jump )
            end
        else
            -- Attacking a structure
            if GetDistanceToTouch(eyePos, bestTarget) < 1 then
                -- Stop running at the structure when close enough
                bot:GetMotion():SetDesiredMoveTarget(nil)
            end
        end

        bot:GetMotion():SetDesiredViewTarget( target )
        move.commands = AddMoveCommand( move.commands, Move.PrimaryAttack )
    else
        bot:GetMotion():SetDesiredViewTarget( nil )

        -- Occasionally jump
        if math.random() < 0.1 and bot:GetPlayer():GetIsOnGround() then
            move.commands = AddMoveCommand( move.commands, Move.Jump )
            if distance < 15 then
                -- When approaching, try to jump sideways
                bot.timeOfJump = Shared.GetTime()
                bot.jumpOffset = nil
            end
        end
    end

    if bot.timeOfJump ~= nil and Shared.GetTime() - bot.timeOfJump < 0.5 then

        if bot.jumpOffset == nil then

            local botToTarget = GetNormalizedVectorXZ(marinePos - eyePos)
            local sideVector = botToTarget:CrossProduct(Vector(0, 0.7, 0))
            if math.random() < 0.5 then
                bot.jumpOffset = botToTarget + sideVector
            else
                bot.jumpOffset = botToTarget - sideVector
            end
            bot:GetMotion():SetDesiredViewTarget( bestTarget:GetEngagementPoint() )

        end

        bot:GetMotion():SetDesiredMoveDirection( bot.jumpOffset )
    end

end

local function PerformAttack( eyePos, mem, bot, brain, move )

    assert( mem )

    local target = Shared.GetEntity(mem.entId)

    if target ~= nil then

        PerformAttackEntity( eyePos, target, bot, brain, move )

    else

        -- mem is too far to be relevant, so move towards it
        -- bot:GetMotion():SetDesiredViewTarget(nil)
        AIA_WallJumpToTarget(bot, move, mem.lastSeenPos)
        -- bot:GetMotion():SetDesiredMoveTarget(mem.lastSeenPos)

    end

    brain.teamBrain:AssignBotToMemory(bot, mem)

end

------------------------------------------
--  Each want function should return the fuzzy weight,
-- along with a closure to perform the action
-- The order they are listed matters - actions near the beginning of the list get priority.
------------------------------------------
kSkulkBrainActions =
{

    -- ------------------------------------------
    -- --
    -- ------------------------------------------
    -- function(bot, brain)
    --     return { name = "debug idle", weight = 0.001,
    --             perform = function(move)
    --                 bot:GetMotion():SetDesiredMoveTarget(nil)
    --                 -- there is nothing obvious to do.. figure something out
    --                 -- like go to the marines, or defend
    --             end }
    -- end,

    ------------------------------------------
    --
    ------------------------------------------
    CreateExploreAction( 0.01, function(pos, targetPos, bot, brain, move)
                             AIA_WallJumpToTarget(bot, move, targetPos)
                             -- bot:GetMotion():SetDesiredMoveTarget(targetPos)
                             -- bot:GetMotion():SetDesiredViewTarget(nil)
                               end ),

    ------------------------------------------
    --
    ------------------------------------------
    function(bot, brain)
        local name = "evolve"

        local weight = 0.0
        local player = bot:GetPlayer()

        if not player.isHallucination and not bot.lifeformEvolution then
            local pick = math.random(1, #kEvolutions)
            bot.lifeformEvolution = kEvolutions[pick]
        end

        local allowedToBuy = player:GetIsAllowedToBuy()
        local ginfo = GetGameInfoEntity()
        if ginfo and ginfo:GetWarmUpActive() then allowedToBuy = false end

        local s = brain:GetSenses()
        local res = player:GetPersonalResources()

        local distanceToNearestThreat = s:Get("nearestThreat").distance
        local desiredUpgrades = {}

        if allowedToBuy and
           (distanceToNearestThreat == nil or distanceToNearestThreat > 15) and
           (player.GetIsInCombat == nil or not player:GetIsInCombat()) then

            -- Safe enough to try to evolve

            local existingUpgrades = player:GetUpgrades()

            local avaibleUpgrades = player.lifeformUpgrades

            if not avaibleUpgrades then
                avaibleUpgrades = {}

                if bot.lifeformEvolution then
                    table.insert(avaibleUpgrades, bot.lifeformEvolution)
                end

                for i = 0, 2 do
                    table.insert(avaibleUpgrades, kUpgrades[math.random(1,3) + i * 3])
                end

                player.lifeformUpgrades = avaibleUpgrades
            end

            local evolvingId = kTechId.Skulk

            for i = 1, #avaibleUpgrades do
                local techId = avaibleUpgrades[i]
                local techNode = player:GetTechTree():GetTechNode(techId)

                local isAvailable = false
                local cost = 0
                if techNode ~= nil then
                    isAvailable = techNode:GetAvailable(player, techId, false)
                    if isAvailable then
                        if LookupTechData(techId, kTechDataGestateName) then
                            cost = GetCostForTech(techId)
                            evolvingId = techId
                        else
                            cost = LookupTechData(techId, kTechDataUpgradeCost, 0)
                        end
                    end
                end

                if not player:GetHasUpgrade(techId) and isAvailable and res - cost > 0 and
                        GetIsUpgradeAllowed(player, techId, existingUpgrades) and
                        GetIsUpgradeAllowed(player, techId, desiredUpgrades) then
                    res = res - cost
                    table.insert(desiredUpgrades, techId)
                end
            end

            if #desiredUpgrades > 0 then
                weight = 100.0
            end
        end

        return { name = name, weight = weight,
            perform = function(move)
                player:ProcessBuyAction( desiredUpgrades )
            end }

    end,

    --[[
    --Save hives under attack
     ]]
    function(bot, brain)
        local skulk = bot:GetPlayer()
        local teamNumber = skulk:GetTeamNumber()

        -- TODO: change that to check for eggs instead
        local hiveUnderAttack
        bot.hiveprotector = bot.hiveprotector or math.random()
        if bot.hiveprotector > 0.5 then
            for _, hive in ipairs(GetEntitiesForTeam("Hive", teamNumber)) do
                if hive:GetHealthScalar() <= 0.4 then
                    hiveUnderAttack = hive
                    break
                end
            end
        end

        local weight = hiveUnderAttack and 1.1 or 0
        local name = "hiveunderattack"

        return { name = name, weight = weight,
            perform = function(move)
                AIA_WallJumpToTarget(bot, move, hiveUnderAttack and hiveUnderAttack:GetOrigin())
                -- bot:GetMotion():SetDesiredMoveTarget(hiveUnderAttack and hiveUnderAttack:GetOrigin())
                -- bot:GetMotion():SetDesiredViewTarget(nil)
            end }

    end,

    ------------------------------------------
    --
    ------------------------------------------
    function(bot, brain)
        local name = "attack"
        local skulk = bot:GetPlayer()
        local eyePos = skulk:GetEyePos()

        local memories = GetTeamMemories(skulk:GetTeamNumber())
        local bestUrgency, bestMem = GetMaxTableEntry( memories,
                function( mem )
                    return GetAttackUrgency( bot, mem )
                end)

        local weapon = skulk:GetActiveWeapon()
        local canAttack = weapon ~= nil and weapon:isa("BiteLeap")

        local weight = 0.0

        if canAttack and bestMem ~= nil then

            local dist = 0.0
            if Shared.GetEntity(bestMem.entId) ~= nil then
                dist = GetDistanceToTouch( eyePos, Shared.GetEntity(bestMem.entId) )
            else
                dist = eyePos:GetDistance( bestMem.lastSeenPos )
            end

            weight = EvalLPF( dist, {
                    { 0.0, EvalLPF( bestUrgency, {
                        { 0.0, 0.0 },
                        { 10.0, 25.0 }
                        })},
                    { 10.0, EvalLPF( bestUrgency, {
                            { 0.0, 0.0 },
                            { 10.0, 5.0 }
                            })},
                    { 100.0, 0.0 } })
        end

        return { name = name, weight = weight,
            perform = function(move)
                PerformAttack( eyePos, bestMem, bot, brain, move )
            end }
    end,

    ------------------------------------------
    --
    ------------------------------------------
    function(bot, brain)
        local name = "pheromone"

        local skulk = bot:GetPlayer()
        local eyePos = skulk:GetEyePos()

        local pheromones = EntityListToTable(Shared.GetEntitiesWithClassname("Pheromone"))
        local bestPheromoneLocation = nil
        local bestValue = 0

        for p = 1, #pheromones do

            local currentPheromone = pheromones[p]
            if currentPheromone then
                local techId = currentPheromone:GetType()

                if techId == kTechId.ExpandingMarker or techId == kTechId.ThreatMarker then

                    local location = currentPheromone:GetOrigin()
                    local locationOnMesh = Pathing.GetClosestPoint(location)
                    local distanceFromMesh = location:GetDistance(locationOnMesh)

                    if distanceFromMesh > 0.001 and distanceFromMesh < 2 then

                        local distance = eyePos:GetDistance(location)

                        if currentPheromone.visitedBy == nil then
                            currentPheromone.visitedBy = {}
                        end

                        if not currentPheromone.visitedBy[bot] then

                            if distance < 5 then
                                currentPheromone.visitedBy[bot] = true
                            else

                                -- Value goes from 5 to 10
                                local value = 5.0 + 5.0 / math.max(distance, 1.0) - #(currentPheromone.visitedBy)

                                if value > bestValue then
                                    bestPheromoneLocation = locationOnMesh
                                    bestValue = value
                                end

                            end

                        end

                    end

                end

            end

        end

        local weight = EvalLPF( bestValue, {
            { 0.0, 0.0 },
            { 10.0, 1.0 }
            })

        return { name = name, weight = weight,
            perform = function(move)
                AIA_WallJumpToTarget(bot, move, bestPheromoneLocation)
                -- bot:GetMotion():SetDesiredMoveTarget(bestPheromoneLocation)
                -- bot:GetMotion():SetDesiredViewTarget(nil)
            end }
    end,

    ------------------------------------------
    --
    ------------------------------------------
    function(bot, brain)
        local name = "order"

        local skulk = bot:GetPlayer()
        local order = bot:GetPlayerOrder()

        local weight = 0.0
        if order ~= nil then
            weight = 10.0
        end

        return { name = name, weight = weight,
            perform = function(move)
                if order then

                    local target = Shared.GetEntity(order:GetParam())

                    if target ~= nil and order:GetType() == kTechId.Attack then

                        PerformAttackEntity( skulk:GetEyePos(), target, bot, brain, move )

                    else

                        if brain.debug then
                            DebugPrint("unknown order type: %s", ToString(order:GetType()) )
                        end

                        AIA_WallJumpToTarget(bot, move, order:GetLocation())
                        -- bot:GetMotion():SetDesiredMoveTarget( order:GetLocation() )
                        -- bot:GetMotion():SetDesiredViewTarget( nil )

                    end
                end
            end }
    end,

}

------------------------------------------
--
------------------------------------------
function CreateSkulkBrainSenses()

    local s = BrainSenses()
    s:Initialize()

    s:Add("allThreats", function(db)
            local player = db.bot:GetPlayer()
            local team = player:GetTeamNumber()
            local memories = GetTeamMemories( team )
            return FilterTableEntries( memories,
                function( mem )
                    local ent = Shared.GetEntity( mem.entId )

                    if ent:isa("Player") or ent:isa("Sentry") then
                        local isAlive = HasMixin(ent, "Live") and ent:GetIsAlive()
                        local isEnemy = HasMixin(ent, "Team") and ent:GetTeamNumber() ~= team
                        return isAlive and isEnemy
                    else
                        return false
                    end
                end)
        end)

    s:Add("nearestThreat", function(db)
            local allThreats = db:Get("allThreats")
            local player = db.bot:GetPlayer()
            local playerPos = player:GetOrigin()

            local distance, nearestThreat = GetMinTableEntry( allThreats,
                function( mem )
                    local origin = mem.origin
                    if origin == nil then
                        origin = Shared.GetEntity(mem.entId):GetOrigin()
                    end
                    return playerPos:GetDistance(origin)
                end)

            return {distance = distance, memory = nearestThreat}
        end)

    return s
end
