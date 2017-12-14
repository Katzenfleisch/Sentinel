
-- Hack to make everything visible when working on the mod offline

local old_LOSMixin_GetIsSighted = LOSMixin.GetIsSighted
function LOSMixin:GetIsSighted()
    if not GetGameInfoEntity():GetIsDedicated() then
        return true
    end
    if self:isa("Egg") then
        return true
    end
    return old_LOSMixin_GetIsSighted(self)
end
