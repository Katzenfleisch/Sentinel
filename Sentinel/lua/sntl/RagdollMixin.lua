local kRagdollTime = 60 + 10

-- if Server then

--     local kSntlDeathTime = 60 + 10

--     local OldSetRagdoll = GetUpValue(RagdollMixin.OnTag, "SetRagdoll")
--     -- Disable the "We need an Infantry portal" voice warning
--     ReplaceUpValue(RagdollMixin.OnTag, "SetRagdoll",
--                    function (self, deathTime)
--                        OldSetRagdoll(self, kSntlDeathTime);
--                        return
--                    end,
--                    { LocateRecurse = false; CopyUpValues = false; } )

-- end

local function SetRagdoll(self, deathTime)

    if Server then

        if self:GetPhysicsGroup() ~= PhysicsGroup.RagdollGroup then

            self:SetPhysicsType(PhysicsType.Dynamic)

            self:SetPhysicsGroup(PhysicsGroup.RagdollGroup)

            -- Apply landing blow death impulse to ragdoll (but only if we didn't play death animation).
            if self.deathImpulse and self.deathPoint and self:GetPhysicsModel() and self:GetPhysicsType() == PhysicsType.Dynamic then

                self:GetPhysicsModel():AddImpulse(self.deathPoint, self.deathImpulse)
                self.deathImpulse = nil
                self.deathPoint = nil
                self.doerClassName = nil

            end

            if deathTime then
                self.timeToDestroy = deathTime
            end

        end

    end

end

if Server then

    --
    -- The entity could be configured to not ragdoll even if the animation tells it to.
    --
    function RagdollMixin:SetBypassRagdoll(bypass)
        self.bypassRagdoll = bypass
    end

    function RagdollMixin:OnTag(tagName)

        PROFILE("RagdollMixin:OnTag")

        if not self.GetHasClientModel or not self:GetHasClientModel() then

            if tagName == "death_end" then

                if self.bypassRagdoll then
                    self:SetModel(nil)
                else
                    SetRagdoll(self, kRagdollTime)
                end

            elseif tagName == "destroy" then
                DestroyEntitySafe(self)
            end

        end

    end

end
