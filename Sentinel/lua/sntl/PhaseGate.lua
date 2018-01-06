
local networkVars =
{
        sntl_phasedMarinesCount = "integer"
}

local kPhaseSound = PrecacheAsset("sound/NS2.fev/marine/structures/phase_gate_teleport")

local old_PhaseGate_OnInitialized = PhaseGate.OnInitialized or ScriptActor.OnInitialized
function PhaseGate:OnInitialized()
    old_PhaseGate_OnInitialized(self)

    self.sntl_phasedMarinesCount = 0
end

function PhaseGate:GetPhasedMarinesCount()
    return self.sntl_phasedMarinesCount
end

function PhaseGate:GetConnectionEndPoint()
    return self:GetConnectionStartPoint()
end

function PhaseGate:GetCanTakeDamageOverride()
    return false
end

if Server then

    local old_PhaseGate_GetIsPowered = PhaseGate.GetIsPowered or PowerConsumerMixin.GetIsPowered
    function PhaseGate:GetIsPowered()
        local alienTeam = GetGamerules():GetTeam(kAlienTeamType)

        if alienTeam and not alienTeam.sntl_noMoreEggs then
            return false
        end

        if old_PhaseGate_GetIsPowered(self) and self:GetIsAlive() and self:GetIsDeployed() then
            self.linked = true
            self.destinationEndpoint = self:GetOrigin()
            return true
        end
        return false
    end


    -- local old_PhaseGate_Update = PhaseGate.Update
    -- function PhaseGate:Update(deltaTime)
    --     local alienTeam = GetGamerules():GetTeam(kAlienTeamType)

    --     if old_PhaseGate_Update then
    --         old_PhaseGate_Update(self, deltaTime)
    --     end

    --     if GetIsUnitActive(self) and self.deployed then
    --         if alienTeam and alienTeam.sntl_noMoreEggs then
    --             self.linked = true
    --         end
    --     end
    -- end

    -- local old_PhaseGate_Phase = PhaseGate.Phase
    function PhaseGate:Phase(user)

        if HasMixin(user, "PhaseGateUser") and self.linked then

            -- Don't bother checking if destination is clear, rely on pushing away entities
            user:TriggerEffects("phase_gate_player_enter")
            user:TriggerEffects("teleport")

            StartSoundEffectAtOrigin(kPhaseSound, self:GetOrigin())

            user = user:Replace(user:GetDeathMapName())

            self.timeOfLastPhase = Shared.GetTime()

            self.sntl_phasedMarinesCount = self.sntl_phasedMarinesCount + 1
            return true

        end

        return false
    end

end

Shared.LinkClassToMap("PhaseGate", nil, networkVars)
