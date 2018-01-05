
Script.Load("lua/bots/CommonActions.lua")
Script.Load("lua/bots/BrainSenses.lua")


local kUpgrades = {
    {
        progress = 0.0, upgrades = {
            kTechId.Regeneration,   kTechId.Crush,          kTechId.Crush,
            kTechId.Aura,           kTechId.Aura,           kTechId.Aura,
            kTechId.Adrenaline,     kTechId.Adrenaline,     kTechId.Adrenaline
        }
    },
    {
        progress = 0.3,     upgrades = {
            kTechId.Carapace,       kTechId.Carapace,       kTechId.Carapace,
            kTechId.Focus,          kTechId.Aura,           kTechId.Aura,
            kTechId.Adrenaline,     kTechId.Adrenaline,     kTechId.Adrenaline
        }
    },
    {
        progress = 0.5,     upgrades = {
            kTechId.Regeneration,   kTechId.Regeneration,   kTechId.Regeneration,
            kTechId.Vampirism,      kTechId.Vampirism,      kTechId.Vampirism,
            kTechId.Silence,        kTechId.Celerity,       kTechId.Celerity
        }
    },
    {
        progress = 0.7,     upgrades = {
            kTechId.Carapace,       kTechId.Regeneration,   kTechId.Regeneration,
            kTechId.Focus,          kTechId.Focus,          kTechId.Vampirism,
            kTechId.Silence,        kTechId.Celerity,       kTechId.Celerity
        }
    }
}

local kEvolutions = {
    kTechId.Lerk,
    kTechId.Fade,
    kTechId.Onos
}


-- local function AIA_NearestSafeOrig(bot);
-- local function AIA_IsCoverBetween(alienOrig, targetOrig, filteredEnt);
-- local function AIA_GetDirToNearestWall(bot);
-- local function GetAttackUrgency(bot, mem);
-- local function AIA_WallJumpToTarget(bot, move, targetPos);
-- function AIA_Alien_engage(bot, brain, move, target);
-- local function PerformAttackEntity( eyePos, bestTarget, bot, brain, move );
-- local function AIA_PerformRetreat( eyePos, mem, bot, brain, move );
-- function AIA_IsLookingAt(attacker, targetPos);
-- local function AIA_CallForSupport(bot, target);
-- local function AIA_SneakToTarget(bot, move, target);
-- local function PerformAttack( eyePos, mem, bot, brain, move );

local kState = enum({'explore', 'sneak', 'attack', 'retreat'})
local kStateStr   = {'explore', 'sneak', 'attack', 'retreat'}

local function SetState(bot, st)

    local skulk = bot:GetPlayer()
    if not skulk.kSpawnOrigin then
        skulk.kSpawnOrigin = skulk:GetOrigin()
    end

    if skulk.kState ~= st then

        if st == kState.retreat then
            skulk.kRetreatDest = skulk.kSpawnOrigin
            -- local dist = 0
            -- local idx = bot:GetMotion():GetPathIndex()

            -- skulk.kRetreatDest = bot:GetMotion():GetPath()[1]
            -- for i = idx - 1, 1, -1 do
            --     local p1 = bot:GetMotion():GetPath()[i]
            --     local p2 = bot:GetMotion():GetPath()[i + 1]
            --     dist = dist + p1:GetDistanceTo(p2)

            --     if dist >= kAIA_sneak_dist then
            --         skulk.kRetreatDest = p1
            --         break
            --     end
            -- end
        end

        Log("%s setting state to %s", skulk, kStateStr[st])
        skulk.kState = st
        skulk.kStateChanged = Shared.GetTime()

        -- for _, s in ipairs(GetEntitiesWithinRange("Skulk", skulk:GetOrigin(), 6))
        -- do
        --     s.kState = st
        --     s.kStateChanged = skulk.kStateChanged
        --     s.kRetreatDest = skulk.kRetreatDest
        -- end
    end
end

local function AIA_NearestSafeOrig(bot)
   local alien = bot:GetPlayer()
   local memories = GetTeamMemories(alien:GetTeamNumber())
   local closest_orig = nil
   local closest_dist = nil

   for _, ent in pairs(memories) do
      if ent.btype == kMinimapBlipType.Hive or ent.btype == kMinimapBlipType.Crag
          or ent.btype == kMinimapBlipType.Egg
          or ent.btype == kMinimapBlipType.Gorge
      then
         local dist = ent.lastSeenPos:GetDistanceTo(alien:GetOrigin())
         if not closest_orig or closest_dist > dist then
            closest_orig = ent.lastSeenPos
            closest_dist = dist
         end
      end
   end

   return closest_orig
   -- -- Respawn at nearest built command station
   -- local origin = nil
   -- local bestHealer = nil

   -- bestHealer = FindBestHealerInRange(alien, 9999)
   -- -- local nearest = GetNearest(alien:GetOrigin(), "Hive", alien:GetTeamNumber(),
   -- --                            function(ent)
   -- --                               return ent:GetIsBuilt() and ent:GetIsAlive()
   -- --                            end)

   -- -- if nearest then
   -- --    origin = nearest:GetModelOrigin()
   -- -- end
   -- if bestHealer then
   --    origin = bestHealer:GetOrigin()
   -- end
   -- return origin
end

local function AIA_IsCoverBetween(alienOrig, targetOrig, filteredEnt)
   local trace = Shared.TraceRay(alienOrig, targetOrig, CollisionRep.Move, PhysicsMask.Bullets, EntityFilterOnly(filteredEnt))

   -- Hit nothing?
   if trace.fraction == 1 then
      return false
      -- Hit the world?
   elseif not trace.entity then
      return true
   else
      if not trace.entity:isa("Player") then
         return true
      end
   end
   return false
end



local function AIA_GetDirToNearestWall(bot, _z, _y)
    local skulk = bot:GetPlayer()
    local eyePos = skulk:GetEyePos()
    local viewCoords = skulk:GetViewCoords()
    local direction = bot:GetMotion().currMoveDir or viewCoords.zAxis

    local leftWall = nil
    local rightWall = nil
    local moveDir = nil
    local endPoint = nil

    local z = _z or 6
    local y = _y or 4

    leftWall = Shared.TraceRay(eyePos, eyePos + y * viewCoords.xAxis + z * direction,
                               CollisionRep.Move, PhysicsMask.Bullets, EntityFilterOne(skulk))
    rightWall = Shared.TraceRay(eyePos, eyePos + -y * viewCoords.xAxis + z * direction,
                                CollisionRep.Move, PhysicsMask.Bullets, EntityFilterOne(skulk))

    if 0.2 < leftWall.fraction and leftWall.fraction < 0.9 then
        moveDir = (leftWall.endPoint - eyePos):GetUnit() --direction + viewCoords.xAxis / 4
        endPoint = leftWall.endPoint
    end

    if 0.2 < rightWall.fraction and rightWall.fraction < 0.9 then
        if eyePos:GetDistanceTo(rightWall.endPoint) < eyePos:GetDistanceTo(leftWall.endPoint) then
            moveDir = (rightWall.endPoint - eyePos):GetUnit() --direction - viewCoords.xAxis / 4
            endPoint = rightWall.endPoint
        end
    end

    if moveDir then
        -- local p1 = skulk:GetOrigin() + direction * 10

        -- local perpVect = Vector(-p1.x, p1.y, p1.z)
        -- local p2 = p1 + perpVect * 1


        -- if rightWall then
        --     return ((eyePos + -4 * viewCoords.xAxis + 100 * direction) - eyePos):GetUnit(), rightWall.endPoint
        -- else
        --     return ((eyePos +  4 * viewCoords.xAxis + 100 * direction) - eyePos):GetUnit(), leftWall.endPoint
        -- end

        return moveDir, endPoint

        -- local p2 = skulk:GetOrigin() + moveDir * 100
        -- local pDist = p1:GetDistanceTo(p2)

        -- local p3 = p1 + (p2 - p1):GetUnit() * (pDist / 9)
        -- local dir1 = (p3 - skulk:GetOrigin()):GetUnit()

        -- return dir1

    end
    -- local dist_between_both_end = p2 + (p1 - p2):GetUnit() * (pDist / 2)

    -- dist_between_both_end = dist_between_both_end

    -- return moveDir
    -- if not _z and not _y then
    --     return AIA_GetDirToNearestWall(bot, 4, 4)
    -- elseif _z == 4 and _y == 4 then
    --     return AIA_GetDirToNearestWall(bot, 2, 4)
    -- -- elseif _z == 2 and _y == 4 then
    -- --     return AIA_GetDirToNearestWall(bot, 0, 4)
    -- else
    --     return nil
    -- end
    if z > 1 then
        return AIA_GetDirToNearestWall(bot, z - 0.5, y)
    end

    return nil
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

    -- -- No immediate threat - load balance!
    -- local numOthers = bot.brain.teamBrain:GetNumAssignedTo( mem,
    --         function(otherId)
    --             if otherId ~= bot:GetPlayer():GetId() then
    --                 return true
    --             end
    --             return false
    --         end)

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

local function AIA_WallJumpToTarget(bot, move, targetPos)
    local skulk = bot:GetPlayer()
    local canWallJump = skulk:GetCanWallJump()
    local recentlyWallJumped = skulk:GetRecentlyWallJumped()
    local eyePos = skulk:GetEyePos()
    local viewCoords = skulk:GetViewCoords()
    -- AIA: Number of walljump allowed before forcing the skulk to hit the ground.
    --      Prevents the skulks from getting stuck in ceilings
    local maxWallJump = 2

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

        if skulk:GetIsOnGround() then
            local moveDir, wallOrig = AIA_GetDirToNearestWall(bot)

            move.commands = AddMoveCommand( move.commands, Move.Jump )
            if (moveDir) then
                -- if not skulk.kClimbWallStart or skulk.kClimbWallStart + 20 < Shared.GetTime() then
                --     skulk.kClimbWallStart = Shared.GetTime()
                -- end

                -- if skulk.kClimbWallStart + 3 < Shared.GetTime() then
                --     bot:GetMotion():SetDesiredMoveDirection( moveDir + Vector(0, 0.8, 0) )
                --     bot:GetMotion():SetDesiredMoveTarget(skulk:GetOrigin() + moveDir * 3)
                -- end

                local o1 = Vector(wallOrig.x, 0, wallOrig.z)
                local o2 = Vector(skulk:GetOrigin().x, 0, skulk:GetOrigin().z)
                local currMoveDir = bot:GetMotion().currMoveDir
                local distToWall = o1:GetDistanceTo(o2) --wallOrig:GetDistanceTo(skulk:GetOrigin())
                if 0.3 <= distToWall and distToWall <= 4 then
                    Log("%s Changing move dir toward wall", skulk)
                    bot:GetMotion():SetDesiredMoveDirection( currMoveDir * 1 + moveDir )
                end
            else
                Log("%s Wall not found", skulk)
            end
        end

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


function AIA_Alien_engage(bot, brain, move, target)
    local now = Shared.GetTime()
    local player = bot:GetPlayer()
    local eyePos = player:GetEyePos()
    -- local target = Shared.GetEntity(bestMem.entId)
    local marinePos = target:GetOrigin()
    local canJumpAgain = false

    local eggFraction = GetGameInfoEntity():GetNumEggs() / GetGameInfoEntity():GetNumMaxEggs()

    -- -- Engaging that way is pretty strong, the more eggs are killed, the more skulks are allowed to use it
    -- if player.kAIA_engage_perk == nil then
    --     player.kAIA_engage_perk = false
    --     if math.random() < 1 - eggFraction then
    --         player.kAIA_engage_perk = true
    --     end
    --     Log("%s has engage skill ? %s (chances: %s)", player, player.kAIA_engage_perk, 1 - eggFraction)
    -- end

    -- if player.kAIA_engage_perk == false then
    --     return
    -- end

    AIA_WallJumpToTarget(bot, move, target:GetOrigin())

    player.last_engage = Shared.GetTime()
    if true or not GetWallBetween(target:GetEyePos(), player:GetOrigin(), player) then
        -- Occasionally jump
        if bot.AIA_sideMoveDuration == nil then
            bot.AIA_sideMoveDuration = 0
        end


        bot.timeOfEngageJump = bot.timeOfEngageJump or 0
        canJumpAgain = now - bot.timeOfEngageJump > bot.AIA_sideMoveDuration
        if canJumpAgain and bot:GetPlayer():GetIsOnGround() then
            move.commands = AddMoveCommand( move.commands, Move.Jump )

            if not (now - bot.timeOfEngageJump < bot.AIA_sideMoveDuration)  then
                -- When approaching, try to jump sideways
                bot.timeOfEngageJump = now
                bot.jumpOffset = nil
                bot.AIA_sideMoveDuration = 0.4 + math.random() / 1.4
            end
        end

        if bot.timeOfEngageJump and now - bot.timeOfEngageJump < bot.AIA_sideMoveDuration then

            if bot.jumpOffset == nil then

                local rand_val = 1 - 2 * math.random()

                if rand_val < 0 then
                    rand_val = math.min(-0.35, rand_val)
                else
                    rand_val = math.max(0.35, rand_val)
                end

                local botToTarget = GetNormalizedVectorXZ(marinePos - eyePos)
                local sideVector = botToTarget:CrossProduct(Vector(0.15, rand_val, 0))

                bot.jumpOffset = botToTarget + sideVector
                if player:GetOrigin():GetDistanceTo(target:GetOrigin()) < 3 then
                    bot:GetMotion():SetDesiredViewTarget( target:GetEngagementPoint() )
                end
                if math.random() < 0.3 then -- Leap when jumping sideway
                    move.commands = AddMoveCommand( move.commands, Move.SecondaryAttack )
                end
            end

            bot:GetMotion():SetDesiredMoveDirection( bot.jumpOffset )
        end
    end

end

local function PerformAttackEntity( eyePos, bestTarget, bot, brain, move )

    assert( bestTarget )

    local targetPos = bestTarget:GetOrigin()
    local engagementPoint = bestTarget:GetEngagementPoint()
    local distance = GetDistanceToTouch(eyePos, bestTarget) -- eyePos:GetDistance(targetPos)
    local player = bot:GetPlayer()
    local now = Shared.GetTime()

    if player.AIA_attack_inertia_until and now < player.AIA_attack_inertia_until then
        bot:GetMotion():SetDesiredViewTarget( nil )
        bot:GetMotion():SetDesiredMoveTarget( targetPos )
        bot:GetMotion():SetDesiredMoveDirection( player.AIA_attack_inertia_direction )
        return
    end

    bot:GetMotion():SetDesiredMoveTarget( targetPos )
    bot:GetMotion():SetDesiredViewTarget( engagementPoint )
    bot:GetPlayer():SetActiveWeapon(BiteLeap.kMapName, true)
    if bestTarget:isa("Player") then
        -- Attacking a player
        engagementPoint = engagementPoint + Vector( math.random(), math.random(), math.random() ) * 0.5
        if bot:GetPlayer():GetIsOnGround() and bestTarget:isa("Player") and distance > 1.5 then
            if math.random() < kAIA_jump_in_combat then
                move.commands = AddMoveCommand( move.commands, Move.Jump )
            end
        end
    else
        -- Attacking a structure
        if distance < 1 then
            -- Stop running at the structure when close enough
            bot:GetMotion():SetDesiredMoveTarget(nil)
        end
    end

    -- AIA: 2.6 seems fine, a bit too far so it allows the skulks to miss sometime the first byte
    if distance < 2.6 then
        move.commands = AddMoveCommand( move.commands, Move.PrimaryAttack )
        if bestTarget:isa("Player") then
            local max_group_size = kAIA_fully_unerf_at
            local group_size = Clamp(#GetEntitiesForTeamWithinRange("Player", kMarineTeamType, bestTarget:GetOrigin(), 10), 0, max_group_size)

            local min = kAIA_attack_inertia_min
            local max = kAIA_attack_inertia_max
            local min_dev = kAIA_attack_acc_min_deviation
            local max_dev = kAIA_attack_acc_max_deviation
            local acc_deviation = 0

            max     = min +     (1 - (group_size - 1) / (max_group_size - 1)) * (max     - min)
            max_dev = min_dev + (1 - (group_size - 1) / (max_group_size - 1)) * (max_dev - min_dev)

            acc_deviation = AIA_SetDesiredViewTarget_deviation(min_dev, max_dev)
            bot:GetMotion():SetDesiredViewTarget( engagementPoint + acc_deviation )
            player.AIA_attack_inertia_direction = (engagementPoint - eyePos):GetUnit()
            player.AIA_attack_inertia_until = now + min + (max - min) * math.random()
        end

    else

        AIA_Alien_engage(bot, brain, move, bestTarget)

    end

end

local function AIA_PerformRetreat( eyePos, mem, bot, brain, move )
    local skulk = bot:GetPlayer()
    local safeSpot = AIA_NearestSafeOrig(bot)
    local target = Shared.GetEntity(mem.entId)

    if not target then
        local memories = GetTeamMemories(skulk:GetTeamNumber())
        local bestUrgency, bestMem = GetMaxTableEntry( memories,
                                                       function( mem )
                                                           return GetAttackUrgency( bot, mem )
                                                       end)

        mem = bestMem
        target = Shared.GetEntity(mem.entId)
    end

    if safeSpot and skulk:GetOrigin():GetDistanceTo(safeSpot) < 10 and skulk.lastParasiteTry
        or #GetEntitiesForTeamWithinRange("Player", kMarineTeamType, skulk:GetOrigin(), 20)
    then
        skulk.retreatReached = Shared.GetTime()
    end

    if target and
        (target:GetOrigin():GetDistanceTo(skulk:GetOrigin()) < kAIA_retreat_dist
             or #GetEntitiesForTeamWithinRange("Alien", kAlienTeamType, skulk:GetOrigin(), 5) >=
             #GetEntitiesForTeamWithinRange("Player", kMarineTeamType, target:GetOrigin(), 5) + 1
             or #GetEntitiesWithinRange("Egg", target:GetOrigin(), 15) > 0
             or (skulk.last_engage and skulk.last_engage + 10 > Shared.GetTime()))
    then
        -- for _, alien in ipairs(GetEntitiesForTeamWithinRange("Alien", kAlienTeamType, target:GetOrigin(), 21)) do
        --     alien:GiveOrder(kTechId.Attack, target:GetId(), target:GetOrigin(),nil,true,true)
        -- end
        PerformAttackEntity( eyePos, target, bot, brain, move )
        return
    end

    if safeSpot and target and (not skulk.retreatReached or skulk.retreatReached + 10 < Shared.GetTime()) then

        AIA_WallJumpToTarget(bot, move, safeSpot)

        skulk.lastParasiteTry = skulk.lastParasiteTry or 0
        -- 60% of the time, parasite the marine on retreat
        if not target:GetIsParasited() and skulk.lastParasiteTry + 5 < Shared.GetTime() then
            skulk.lastParasiteTry = Shared.GetTime()
            bot:GetPlayer():SetActiveWeapon(Parasite.kMapName, true)
            move.commands = AddMoveCommand( move.commands, Move.PrimaryAttack )
            bot:GetMotion():SetDesiredViewTarget( target:GetEngagementPoint() )
            bot:GetMotion():SetDesiredMoveDirection( (target:GetEngagementPoint() - eyePos):GetUnit() )
        end

        -- if not bot.AIA_retreat_until or Shared.GetTime() > bot.AIA_retreat_until + 5
        -- then
        --    bot.AIA_retreat_until = Shared.GetTime() + kAIA_retreateDuration
        -- end
        return
    end
end


function AIA_IsLookingAt(attacker, targetPos)

   local toTarget = GetNormalizedVector(targetPos - attacker:GetEyePos())
   return toTarget:DotProduct(attacker:GetViewCoords().zAxis) > 0

end

local function AIA_CallForSupport(bot, target)

   -- Don't spam orders
   if bot.AIA_last_support_call and bot.AIA_last_support_call + 2 < Shared.GetTime() then
      return
   end

   local current_skulk = bot:GetPlayer()
   local allAliens = GetEntitiesForTeamWithinRange("Alien", current_skulk:GetTeamNumber(),
                                                   current_skulk:GetOrigin(), 30)
   for _, ent in ipairs(allAliens) do
      if HasMixin(ent, "Orders") then
         local order = ent:GetHasOrder()
         if ent and ent:GetIsAlive() and AIA_IsPlayerVirtual(ent) and not order and ent ~= current_skulk
         then
            ent:GiveOrder(kTechId.Move, skulk:GetId(), current_skulk:GetOrigin(),nil,true,true)
         end
      end
   end

   bot.AIA_last_support_call = Shared.GetTime()
end

local function AIA_SneakToTarget(bot, move, target)
    local skulk = bot:GetPlayer()
    local eyePos = skulk:GetEyePos()
    local viewCoords = skulk:GetViewCoords()
    local direction = viewCoords.zAxis
    local targetEyePos = target:GetEyePos()

    -- Sneak or ambush
    local dist = GetDistanceToTouch( eyePos, target )
    local sighted = kAIA_UseSight and skulk:GetIsSighted() or skulk:GetIsDetected()
    local is_in_combat = skulk.GetIsInCombat == nil or skulk:GetIsInCombat()
    local is_cloaked = skulk:GetIsCloaked()

    local trace = nil
    local wait = false
    local zAxis = viewCoords.zAxis

    zAxis.y = 0 -- Look straight

    local nextPos = eyePos + 4 * zAxis-- + Vector(0, 0.5, 0)
    local targetPos = target:GetEyePos()
    local isNextPosCovered = false
    local is_cloaked = skulk:GetIsCloaked()
    local path = bot:GetMotion():GetPath()

    bot.AIA_last_sneak = Shared.GetTime()
    if path and (not bot.AIA_sneak_refresh or bot.AIA_sneak_refresh + 0.2 < Shared.GetTime()) then
        local idx = bot:GetMotion():GetPathIndex()
        local pathDist = 0
        local maxIdx = #path

        for i = idx, #path do
            if i < #path then
                pathDist = pathDist + (path[i]:GetDistanceTo(path[i + 1]))
                if pathDist > 7 then
                    maxIdx = i
                    break
                end
            end
        end

        pathDist = 0
        bot.AIA_sneak_wait = false
        -- If we are already out of cover, continue to move forward
        if path and idx and (AIA_IsCoverBetween(targetEyePos, eyePos, target)) then
            for i = idx, maxIdx, 1 do
                local nextPos = nil

                if i < #path then
                    pathDist = pathDist + (path[i]:GetDistanceTo(path[i + 1]))
                end

                nextPos = path[i]
                -- nextPos = eyePos + (i * zAxis)
                if nextPos:GetDistanceTo(targetPos) < (20 - pathDist) then
                    if not GetWallBetween(targetEyePos, nextPos, target) then
                        if pathDist <= 4 then
                            bot.AIA_sneak_wait = true
                        else
                            local dist1 = target:GetOrigin():GetDistanceTo(nextPos)
                            local dist2 = skulk:GetOrigin():GetDistanceTo(nextPos)
                            if dist1 < dist2
                            then
                                SetState(bot, kState.retreat)
                            end
                        end
                        break
                        -- Only wait if are at the corner already
                        -- if GetHasVampirismUpgrade(skulk) or (i <= 7 and AIA_IsLookingAt(target, nextPos))
                        -- then
                        --     if eyePos:GetDistanceTo(targetPos) > 4 then
                        --         bot.AIA_sneak_wait = true
                        --            if #GetEntitiesForTeamWithinRange("Alien",
                        --                                              skulk:GetTeamNumber(), skulk:GetOrigin(), kAIAI_needSupportRange) == 1
                        --            then
                        --                SetState(bot, kState.retreat)
                        --               -- AIA_CallForSupport(bot, target)

                        --               -- local memories = GetTeamMemories(skulk:GetTeamNumber())
                        --               -- local bestUrgency, bestMem = GetMaxTableEntry( memories,
                        --               --                                                function( mem )
                        --               --                                                    return GetAttackUrgency( bot, mem )
                        --               --                                                end)

                        --               -- AIA_PerformRetreat(skulk:GetEyePos(), bestMem, bot, brain, move)
                        --            end
                        --     end
                        -- end
                        -- break
                    end
                end
            end
            -- else
            --    Log("Wall between us and target already, can we continue ? NOOO STOP")
            -- end
        else -- No wall
            if GetHasVampirismUpgrade(skulk) then
                bot.AIA_sneak_wait = true
            end
        end

        -- Log("Waiting on the corner : " .. tostring(bot.AIA_sneak_wait))
        -- for i = 1, 15, 5 do
        --    DebugWireSphere(nextPos + nextPos + (targetPos - nextPos):GetUnit() * i, 0.06,
        --                    2,
        --                    0, 0.8, 0, 0.15) -- r, g, b, a
        -- end

        bot.AIA_sneak_refresh = Shared.GetTime()
    end

    wait = bot.AIA_sneak_wait

    -- -- If we do not have silence, walk slowly not to make noise
    -- if not GetHasSilenceUpgrade(skulk) then
    --    move.commands = AddMoveCommand( move.commands, Move.MovementModifier )
    -- end

    -- TODO: fix vampirism ambush not working anymore

    nextPos = nextPos + Vector(0, 0.5, 0)
    if (wait == true) then
        -- local targetInCombat = false
        -- if target.GetIsInCombat and target:GetIsInCombat() then
        --     targetInCombat = true
        -- end
        -- if not targetInCombat then
        --     local aliens = GetEntitiesForTeamWithinRange("Alien", skulk:GetTeamNumber(), targetPos, 8)
        --     for _, ent in ipairs(aliens) do
        --         if ent and ent:GetIsAlive() and ent:GetIsInCombat() then
        --             targetInCombat = true
        --             break
        --         end
        --     end
        -- end

        -- -- Log("Waiting on the corner")
        -- -- Don't move forward, we could be seen, wait on the corner
        -- if not targetInCombat then -- if target is already attacked, don't wait, support our friend !
        --     bot:GetMotion():SetDesiredMoveTarget(nil)
        -- end
        -- bot:GetMotion():SetDesiredViewTarget(nextPos)

        bot:GetMotion():SetDesiredMoveTarget(nil)
        bot:GetMotion():SetDesiredViewTarget(nil)

        local moveDir, wallOrig = AIA_GetDirToNearestWall(bot)

        if (moveDir) then -- Climb to ceiling
            -- if not skulk.kClimbWallStart or skulk.kClimbWallStart + 20 < Shared.GetTime() then
            --     skulk.kClimbWallStart = Shared.GetTime()
            -- end

            -- if skulk.kClimbWallStart + 3 < Shared.GetTime() then
            --     bot:GetMotion():SetDesiredMoveDirection( moveDir + Vector(0, 0.8, 0) )
            --     bot:GetMotion():SetDesiredMoveTarget(skulk:GetOrigin() + moveDir * 3)
            -- end

            move.commands = AddMoveCommand( move.commands, Move.MovementModifier )
            if wallOrig:GetDistanceTo(skulk:GetOrigin()) >= 0.2 then
                bot:GetMotion():SetDesiredMoveDirection( moveDir )
                bot:GetMotion():SetDesiredMoveTarget(wallOrig)
            end

        end

    else

        -- bot:GetMotion():SetDesiredMoveDirection( (nextPos - skulk:GetOrigin()):GetUnit() )
        if not GetHasSilenceUpgrade(skulk) and dist <= kAIA_sneak_dist then
            move.commands = AddMoveCommand( move.commands, Move.MovementModifier )
        end
        bot:GetMotion():SetDesiredMoveTarget(targetPos)

        -- TODO: here change state if needed or retreat
        if (is_in_combat or sighted or dist < kAIA_retreat_dist) then
            SetState(bot, dist < kAIA_retreat_dist and kState.attack or kState.retreat)
        end
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
                             SetState(bot, kState.explore)
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

        local desiredEggFraction = GetGameInfoEntity():GetNumEggs() / GetGameInfoEntity():GetNumMaxEggs()

        if not player.kAIA_CanEvolve then
            player.kAIA_CanEvolve = false
            -- The more egg killed, the more upgrades we have
            if math.random() < 1 - desiredEggFraction then
                player.kAIA_CanEvolve = true
            end
        end

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

                local ups = nil

                for _, u in ipairs(kUpgrades)
                do
                    if u.progress <= (1 - desiredEggFraction) then
                        ups = u.upgrades
                        break
                    end
                end

                table.insert(avaibleUpgrades, ups[math.random(1,3)])

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

    -- --[[
    -- -- -- Save eggs under attack
    -- --]]
    -- function(bot, brain)
    --     local skulk = bot:GetPlayer()
    --     local teamNumber = skulk:GetTeamNumber()

    --     -- TODO: change that to check for eggs instead
    --     local eggUnderAttack
    --     bot.eggprotector = bot.eggprotector or math.random()
    --     if bot.eggprotector > 0.15 then
    --         for _, egg in ipairs(GetEntitiesForTeam("Egg", teamNumber)) do
    --             if egg:GetHealthScalar() <= 0.95 then
    --                 eggUnderAttack = egg
    --                 break
    --             end
    --         end
    --     end

    --     local weight = eggUnderAttack and 1.1 or 0
    --     local name = "eggunderattack"

    --     return { name = name, weight = weight,
    --         perform = function(move)
    --             AIA_WallJumpToTarget(bot, move, eggUnderAttack and eggUnderAttack:GetOrigin())
    --             -- bot:GetMotion():SetDesiredMoveTarget(eggUnderAttack and eggUnderAttack:GetOrigin())
    --             -- bot:GetMotion():SetDesiredViewTarget(nil)
    --         end }

    -- end,

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
        local canAttack = true--weapon ~= nil and weapon:isa("BiteLeap")

        local target = nil
        local weight = 0.0
        local dist = 0.0
        local target = nil

        bot:GetMotion():SetDesiredViewTarget( nil )
        if bestMem ~= nil then

            target = Shared.GetEntity(bestMem.entId)
            if target ~= nil then
                dist = GetDistanceToTouch( eyePos, target )
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

                     local st = skulk.kState
                     local target = Shared.GetEntity(bestMem.entId)
                     local s_orig = skulk:GetOrigin()
                     local t_orig = bestMem.lastSeenPos

                     -- Safety to enforce the attack no matter in which state we are
                     if target:isa("Player") and t_orig:GetDistanceTo(s_orig) < 3 then
                         SetState(bot, kState.attack)
                     end

                     if st == kState.sneak then
                         -- Log("%s sneaking", skulk)
                         -- if distToTarget >= kAIA_sneak_dist then
                         --     AIA_WallJumpToTarget(bot, move, t_orig)
                         -- elseif distToTarget >= 1 then
                         -- AIA_WallJumpToTarget(bot, move, bestMem.lastSeenPos)
                         AIA_SneakToTarget(bot, move, target)
                         -- end
                     elseif st == kState.retreat then

                         -- Log("%s retreating", skulk)
                         -- if not bot:GetMotion().moveBackward then
                         --     Log("%s moving backward now", skulk)
                         -- end

                         -- bot:GetMotion():ReversePath()
                         -- local safeOrig = AIA_NearestSafeOrig(bot)

                         -- AIA_WallJumpToTarget(bot, move, safeOrig)

                         AIA_WallJumpToTarget(bot, move, skulk.kRetreatDest)
                         if dist >= kAIA_sneak_dist and GetWallBetween(target:GetEyePos(), s_orig + Vector(0, 1, 0), target)
                         then
                             SetState(bot, kState.sneak)
                         elseif s_orig:GetDistanceTo(skulk.kRetreatDest) <= 2 then
                             if dist <= 20 then
                                 SetState(bot, kState.attack)
                             else
                                 SetState(bot, kState.sneak)
                             end
                         end
                         -- skulk:Kill()

                     elseif st == kState.attack then
                         PerformAttackEntity( skulk:GetEyePos(), target, bot, brain, move )
                         if not target or not target:GetIsAlive() then
                             SetState(bot, kState.sneak)
                         end
                     else
                         -- Log("%s Sneak state set by default", skulk)
                         SetState(bot, kState.sneak)
                     end

                 end }
    end,

    -- function(bot, brain)
    --     local name = "attack"
    --     local skulk = bot:GetPlayer()
    --     local eyePos = skulk:GetEyePos()

    --     local memories = GetTeamMemories(skulk:GetTeamNumber())
    --     local bestUrgency, bestMem = GetMaxTableEntry( memories,
    --             function( mem )
    --                 return GetAttackUrgency( bot, mem )
    --             end)

    --     local weapon = skulk:GetActiveWeapon()
    --     local canAttack = weapon ~= nil and weapon:isa("BiteLeap")

    --     local weight = 0.0

    --     if canAttack and bestMem ~= nil then

    --         local dist = 0.0
    --         if Shared.GetEntity(bestMem.entId) ~= nil then
    --             dist = GetDistanceToTouch( eyePos, Shared.GetEntity(bestMem.entId) )
    --         else
    --             dist = eyePos:GetDistance( bestMem.lastSeenPos )
    --         end

    --         weight = EvalLPF( dist, {
    --                 { 0.0, EvalLPF( bestUrgency, {
    --                     { 0.0, 0.0 },
    --                     { 10.0, 25.0 }
    --                     })},
    --                 { 10.0, EvalLPF( bestUrgency, {
    --                         { 0.0, 0.0 },
    --                         { 10.0, 5.0 }
    --                         })},
    --                 { 100.0, 0.0 } })
    --     end

    --     return { name = name, weight = weight,
    --         perform = function(move)
    --             PerformAttack( eyePos, bestMem, bot, brain, move )
    --         end }
    -- end,

    -- ------------------------------------------
    -- --
    -- ------------------------------------------
    -- function(bot, brain)
    --     local name = "pheromone"

    --     local skulk = bot:GetPlayer()
    --     local eyePos = skulk:GetEyePos()

    --     local pheromones = EntityListToTable(Shared.GetEntitiesWithClassname("Pheromone"))
    --     local bestPheromoneLocation = nil
    --     local bestValue = 0

    --     for p = 1, #pheromones do

    --         local currentPheromone = pheromones[p]
    --         if currentPheromone then
    --             local techId = currentPheromone:GetType()

    --             if techId == kTechId.ExpandingMarker or techId == kTechId.ThreatMarker then

    --                 local location = currentPheromone:GetOrigin()
    --                 local locationOnMesh = Pathing.GetClosestPoint(location)
    --                 local distanceFromMesh = location:GetDistance(locationOnMesh)

    --                 if distanceFromMesh > 0.001 and distanceFromMesh < 2 then

    --                     local distance = eyePos:GetDistance(location)

    --                     if currentPheromone.visitedBy == nil then
    --                         currentPheromone.visitedBy = {}
    --                     end

    --                     if not currentPheromone.visitedBy[bot] then

    --                         if distance < 5 then
    --                             currentPheromone.visitedBy[bot] = true
    --                         else

    --                             -- Value goes from 5 to 10
    --                             local value = 5.0 + 5.0 / math.max(distance, 1.0) - #(currentPheromone.visitedBy)

    --                             if value > bestValue then
    --                                 bestPheromoneLocation = locationOnMesh
    --                                 bestValue = value
    --                             end

    --                         end

    --                     end

    --                 end

    --             end

    --         end

    --     end

    --     local weight = EvalLPF( bestValue, {
    --         { 0.0, 0.0 },
    --         { 10.0, 1.0 }
    --         })

    --     return { name = name, weight = weight,
    --         perform = function(move)
    --             AIA_WallJumpToTarget(bot, move, bestPheromoneLocation)
    --             -- bot:GetMotion():SetDesiredMoveTarget(bestPheromoneLocation)
    --             -- bot:GetMotion():SetDesiredViewTarget(nil)
    --         end }
    -- end,

    -- ------------------------------------------
    -- --
    -- ------------------------------------------
    -- function(bot, brain)
    --     local name = "order"

    --     local skulk = bot:GetPlayer()
    --     local order = bot:GetPlayerOrder()

    --     local weight = 0.0
    --     if order ~= nil then
    --         weight = 10.0
    --     end

    --     return { name = name, weight = weight,
    --         perform = function(move)
    --             if order then

    --                 local target = Shared.GetEntity(order:GetParam())

    --                 if target ~= nil and order:GetType() == kTechId.Attack then

    --                     PerformAttackEntity( skulk:GetEyePos(), target, bot, brain, move )

    --                 else

    --                     if brain.debug then
    --                         DebugPrint("unknown order type: %s", ToString(order:GetType()) )
    --                     end

    --                     AIA_WallJumpToTarget(bot, move, order:GetLocation())
    --                     -- bot:GetMotion():SetDesiredMoveTarget( order:GetLocation() )
    --                     -- bot:GetMotion():SetDesiredViewTarget( nil )

    --                 end
    --             end
    --         end }
    -- end,

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
