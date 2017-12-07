

function AlienTeam:UpdateRandomEggSpawn(timePassed)
    return
end

local old_AlienTeam_Update = AlienTeam.Update
function AlienTeam:Update(timePassed)
    local rval = old_AlienTeam_Update and old_AlienTeam_Update(self, timePassed)

    self:UpdateRandomEggSpawn(timePassed)
    return rval
end
