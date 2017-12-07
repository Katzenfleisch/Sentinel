
local old_Team_Initialize = Team.Initialize
function Team:Initialize(teamName, teamNumber)
    old_Team_Initialize(self, teamName, teamNumber)

    self.sntl_humanPlayerCount = 0
end

function Team:GetHumanPlayerCount()
    return self.sntl_humanPlayerCount
end

local old_Team_RemovePlayer = Team.RemovePlayer
function Team:RemovePlayer(player)
    local rval = old_Team_RemovePlayer(self, player)

    -- Team:RemovePlayer() does not return any values, assume it always succeed
    if player and player:GetClient() and not player:GetClient():GetIsVirtual() then
        self.sntl_humanPlayerCount = math.max(0, self.sntl_humanPlayerCount - 1)
    end
    return rval
end

local old_Team_AddPlayer = Team.AddPlayer
function Team:AddPlayer(player)
    rval = old_Team_AddPlayer(self, player)

    if rval then
        if player and player:GetClient() and not player:GetClient():GetIsVirtual() then
            self.sntl_humanPlayerCount = self.sntl_humanPlayerCount + 1
        end
    end
    return rval
end
