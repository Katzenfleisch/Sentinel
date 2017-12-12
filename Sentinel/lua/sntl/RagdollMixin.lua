if Server then

    local kSntlDeathTime = 60 + 10

    local OldSetRagdoll = GetUpValue(RagdollMixin.OnTag, "SetRagdoll")
    -- Disable the "We need an Infantry portal" voice warning
    ReplaceUpValue(RagdollMixin.OnTag, "SetRagdoll",
                   function (self, deathTime)
                       OldSetRagdoll(self, kSntlDeathTime);
                       return
                   end,
                   { LocateRecurse = false; CopyUpValues = false; } )

end
