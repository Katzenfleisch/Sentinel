Script.Load("lua/InfestationMixin.lua")

local kEggInfestDuration = 60
local kEggInfestationRadius = 3
local kEggInfestationGrowthDuration = kEggInfestationRadius / kEggInfestDuration


local networkVars =
{
}

AddMixinNetworkVars(InfestationMixin, networkVars)

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

    local rval, new_player = old_Egg_SpawnPlayer(self, player)

    if rval then

        -- Increase the extents a bit to be REALLY SURE not to get stuck because one nail is in the ground
        local extents = LookupTechData(new_player:GetTechId(), kTechDataMaxExtents) * 1.25
        local position = new_player:GetOrigin()

        position = SNTL_GetGroundAtPosition(position, nil, PhysicsMask.AllButPCs, extents)
        new_player:SetOrigin(position)

    end

    return rval, new_player

end


Shared.LinkClassToMap("Egg", nil, networkVars)
