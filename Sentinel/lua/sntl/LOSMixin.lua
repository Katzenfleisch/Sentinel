
-- Hack to make everything visible when working on the mod

local old_LOSMixin_GetIsSighted = LOSMixin.GetIsSighted
function LOSMixin:GetIsSighted()
    if GetGameInfoEntity():GetIsDedicated() then
        return false
    end
    return old_LOSMixin_GetIsSighted(self)
end
