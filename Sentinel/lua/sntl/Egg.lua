Script.Load("lua/InfestationMixin.lua")

local kEggInfestDuration = 60
local kEggInfestationRadius = 3
local kEggInfestationGrowthDuration = kEggInfestationRadius / kEggInfestDuration


local networkVars =
{
}

AddMixinNetworkVars(InfestationMixin, networkVars)

function SNTL_SpawnEggsAroundPos(pos, numEgg)
    local eggs = {}
    local spawnedEggs = 0
    local eggExtents = GetExtents(kTechId.Egg)
    local origins = SNTL_SpreadedPlacementFromOrigin(eggExtents, pos, numEgg, 1, 6)

    local location = GetLocationForPoint(pos)
    local locationName = location and location:GetName() or "(unknown pos)"

    -- Loop over each spreaded location found, otherwise just ignore if it fails to find a spot
    for j = 1, #origins do
        local position = origins[j]
        local egg = CreateEntity(Egg.kMapName, position, kAlienTeamType)

        if not egg then
            Log("[sntl] Unable to create entity (valid pos : %s, egg : %s)", validForEgg, egg)
        else

            table.insert(eggs, egg)
            -- Randomize starting angles
            local angles = egg:GetAngles()
            angles.yaw = math.random() * math.pi * 2
            egg:SetAngles(angles)

            -- To make sure physics model is updated without waiting a tick
            egg:UpdatePhysicsModel()
            spawnedEggs = spawnedEggs + 1

        end
    end

    if spawnedEggs then
        Log("[sntl] * (%s/%s) A group of %s egg(s) were spawned in %s", i, numGroup, spawnedEggs, locationName)
    end

    return eggs
end

function Egg:GetInfestationRadius()
    return self.sntl_hidden_egg and 0.0001 or kEggInfestationRadius
end

function Egg:GetInfestationMaxRadius()
    return self.sntl_hidden_egg and 0.0001 or kEggInfestationRadius
end



function Egg:GetInfestationGrowthRate()
    return self.sntl_hidden_egg and 0.0001 or kEggInfestationGrowthDuration
end

local old_Egg_OnInitialized = Egg.OnInitialized
function Egg:OnInitialized()

    InitMixin(self, InfestationMixin)

    local rval = old_Egg_OnInitialized and old_Egg_OnInitialized(self)
    return rval

end


local old_Egg_SpawnPlayer = Egg.SpawnPlayer
function Egg:SpawnPlayer(player)

    local kStartHealthScalar = 0.50
    local eggOrigin = self:GetOrigin()
    local rval, new_player = old_Egg_SpawnPlayer(self, player)

    -- Warning, Egg:SpawnPlayer() is using DestroyEntity(self), don't use it here
    if rval then

        -- Increase the extents a bit to be REALLY SURE not to get stuck because one nail is in the ground
        local extents = LookupTechData(new_player:GetTechId(), kTechDataMaxExtents) * 1.25
        local position = new_player:GetOrigin()

        position = SNTL_GetGroundAtPosition(position, nil, PhysicsMask.AllButPCs, extents)
        new_player:SetOrigin(position)

        -- Each hatched egg leads to a new egg being created
        if not self.sntl_hidden_egg then
            SNTL_SpawnEggsAroundPos(position, 1)
        end

        new_player:SetHealth(new_player:GetMaxHealth() * kStartHealthScalar)

    end

    return rval, new_player

end


local function Egg_Noop(self)
    return false
end

function Egg:GetCanTakeDamage()
    if self.sntl_hidden_egg then
        return false
    end
    return true
end

local old_Egg_GetIsVisible = Egg.GetIsVisible or LOSMixin.GetIsVisible
function Egg:GetIsVisible()
    local rval = false

    if self.sntl_hidden_egg and not self.OnGetMapBlipInfo then
        self.OnGetMapBlipInfo = Egg_Noop
        Log("Hidden egg in %s, not showing", GetLocationForPoint(self:GetOrigin()):GetName())
    end

    if old_Egg_GetIsVisible then
        rval = old_Egg_GetIsVisible(self)
    end

    if self.sntl_hidden_egg then
        return false
    end
    return rval
end

-- local old_Egg_GetMapBlipInfo = Egg.GetMapBlipInfo or MapBlipMixin.GetMapBlipInfo
-- function Egg:GetMapBlipInfo()
--     if self.sntl_hidden_egg then
--         self.OnGetMapBlipInfo = Egg_Noop
--         Log("Hidden egg in %s, not showing", GetLocationForPoint(self:GetOrigin()):GetName())
--         return false, 
--     end
--     return old_Egg_GetMapBlipInfo(self)
-- end

if Server then

    local function RequeuePlayer(self)

        if self.queuedPlayerId then

            local player = Shared.GetEntity(self.queuedPlayerId)
            local team = self:GetTeam()
            -- There are cases when the player or team is no longer valid such as
            -- when Egg:OnDestroy() is called during server shutdown.
            if player and team then

                if not player:isa("AlienSpectator") then
                    error("AlienSpectator expected, instead " .. player:GetClassName() .. " was in queue")
                end

                player:SetEggId(Entity.invalidId)
                player:SetIsRespawning(false)
                team:PutPlayerInRespawnQueue(player)

            end

        end

        -- Don't spawn player
        self:SetEggFree()

    end

    -- NOTE: Eggs entities are destroyed here yet, otherwise infestation would immediately vanish.
    -- InfestationMixin handles allowing the entity to be destroyed, which is then handled in
    -- Cyst:OnUpdate().
    -- local RequeuePlayer = GetUpValue(Egg.OnKill, "RequeuePlayer")
    function Egg:OnKill(attacker, doer, point, direction)

        RequeuePlayer(self)
        self:TriggerEffects("egg_death")
        self:SetModel(nil)
        -- DestroyEntity(self) -- Handled my the infesation mixin


    end
end

function Egg:GetIsFree()
    if not self.sntl_hidden_egg or
        #GetEntitiesForTeamWithinRange("Player", kMarineTeamType, self:GetOrigin(), 40) == 0
    then
        return self.queuedPlayerId == nil and self:GetIsAlive() and self:GetCreationTime() + 25 < Shared.GetTime()
    else
        return false
    end
end

Shared.LinkClassToMap("Egg", nil, networkVars)
