Script.Load("lua/InfestationMixin.lua")

local kEggInfestDuration = 60
local kEggInfestationRadius = 3
local kEggInfestationGrowthDuration = kEggInfestationRadius / kEggInfestDuration


local networkVars =
{
}

AddMixinNetworkVars(InfestationMixin, networkVars)

function SNTL_SpawnEggsAroundPos(pos, numEgg)
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
end

function Egg:GetInfestationRadius()
    return kEggInfestationRadius
end

function Egg:GetInfestationMaxRadius()
    return kEggInfestationRadius
end

function Egg:GetInfestationGrowthRate()
    return kEggInfestationGrowthDuration
end

local old_Egg_OnInitialized = Egg.OnInitialized
function Egg:OnInitialized()

    InitMixin(self, InfestationMixin)

    local rval = old_Egg_OnInitialized and old_Egg_OnInitialized(self)
    return rval

end

local old_Egg_SpawnPlayer = Egg.SpawnPlayer
function Egg:SpawnPlayer(player)

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
        SNTL_SpawnEggsAroundPos(position, 1)

    end

    return rval, new_player

end


Shared.LinkClassToMap("Egg", nil, networkVars)
