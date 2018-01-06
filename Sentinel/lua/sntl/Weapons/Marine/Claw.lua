local kClawRange = 2.8 -- from 2.2

function Claw:OnTag(tagName)

    PROFILE("Claw:OnTag")

    local player = self:GetParent()
    if player then

        if tagName == "hit" then
            AttackMeleeCapsule(self, player, kClawDamage, kClawRange)
        elseif tagName == "claw_attack_start" then
            player:TriggerEffects("claw_attack")
        end

    end

end
