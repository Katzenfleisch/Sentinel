
-- local kRagdollTime = 20 * 1
-- local kRagdollDissolveDelay = kRagdollTime - 5

-- function Ragdoll:OnCreate()

--     Entity.OnCreate(self)

--     local now = Shared.GetTime()
--     self.dissolveStart = now + kRagdollDissolveDelay
--     self.dissolveAmount = 0

--     if Server then
--         self:AddTimedCallback(Ragdoll.TimeUp, kRagdollTime)
--     end

--     self:SetUpdates(true)

--     InitMixin(self, BaseModelMixin)
--     InitMixin(self, ModelMixin)

--     self:SetRelevancyDistance(kMaxRelevancyDistance)
-- end
