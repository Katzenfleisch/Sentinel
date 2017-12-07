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

Shared.LinkClassToMap("Egg", nil, networkVars)
