
local kSntlDissolveDelay = 60

local old_DissolveMixin_OnKill = DissolveMixin.OnKill
function DissolveMixin:OnKill(attacker, doer, point, direction)
    local now = Shared.GetTime()

    old_DissolveMixin_OnKill(self, attacker, doer, point, direction)
    self.dissolveStart = now + kSntlDissolveDelay
end
