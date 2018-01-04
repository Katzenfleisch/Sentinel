
function Marine:GiveExo(spawnPoint)

    local exo = self:Replace(Exo.kMapName, self:GetTeamNumber(), false, spawnPoint, { layout = "ClawMinigun" })
    return exo

end

function Marine:GiveDualExo(spawnPoint)

    -- local exo = self:Replace(Exo.kMapName, self:GetTeamNumber(), false, spawnPoint, { layout = "MinigunMinigun" })
    -- return exo
    return self:GiveExo(spawnPoint)

end

function Marine:GiveClawRailgunExo(spawnPoint)

    local exo = self:Replace(Exo.kMapName, self:GetTeamNumber(), false, spawnPoint, { layout = "ClawRailgun" })
    return exo

end

function Marine:GiveDualRailgunExo(spawnPoint)

    -- local exo = self:Replace(Exo.kMapName, self:GetTeamNumber(), false, spawnPoint, { layout = "RailgunRailgun" })
    -- return exo
    return self:GiveClawRailgunExo(spawnPoint)

end
