
function Team:GetHumanPlayerCount()
    local team = self
    local humanNum = 0

    local function count(player)
        if not SNTL_IsPlayerVirtual(player) then
            humanNum = humanNum + 1
        end
    end
    team:ForEachPlayer(count)
    return humanNum
end
