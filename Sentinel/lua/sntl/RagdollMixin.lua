Script.Load("lua/sntl/Elixer_Utility.lua")
Elixer.UseVersion(1.8)

-- SetRagdoll(self, kRagdollTime)


if Server then

    local kDeathTime = 60 + 1.5

    local OldSetRagdoll = GetUpValue(RagdollMixin.OnTag, "SetRagdoll")
    -- Disable the "We need an Infantry portal" voice warning
    ReplaceUpValue(RagdollMixin.OnTag, "SetRagdoll",
                   function (self, deathTime)
                       OldSetRagdoll(self, kDeathTime);
                       return
                   end,
                   { LocateRecurse = true; CopyUpValues = true; } )

end
