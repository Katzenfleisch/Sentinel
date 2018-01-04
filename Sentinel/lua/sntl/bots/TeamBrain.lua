
kSntlSoundRange = 40

function TeamBrain:GetIsSoundAudible(sound)

    -- find all our players inside a 20m range
    -- we only do this call for sounds that belong to enemy players that are actually playing, so this
    -- should not be horribly expensive.
    for _, friend in ipairs( GetEntitiesForTeamWithinRange("Player", self.teamNumber, sound:GetWorldOrigin(), kSntlSoundRange) ) do
        if friend:GetIsAlive() then
            return true
        end

    end

    return false
end
