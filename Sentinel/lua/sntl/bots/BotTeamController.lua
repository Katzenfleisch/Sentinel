function BotTeamController:GetMaxBots()
    return self.MaxBots
end

--[[
-- Adds/removes a bot if needed, calling this method will trigger a recursive loop
-- over the PostJoinTeam method rebalancing the bots.
 ]]
function BotTeamController:UpdateBots()
    PROFILE("BotTeamController:UpdateBots")

    if self.MaxBots < 1 then return end --BotTeamController is disabled

    local team1HumanNum, team1BotsNum = self:GetPlayerNumbersForTeam(kTeam1Index)
    local team2HumanNum, team2BotsNum = self:GetPlayerNumbersForTeam(kTeam2Index)
    local team2Count = team2BotsNum + team2HumanNum

    local humanCount = team1HumanNum + team1BotsNum
    local maxTeamBots = math.ceil(self.MaxBots)

    -- Update Team 1
    -- No bots for team 1

    -- Update Team 2
    if (team2Count > maxTeamBots or humanCount == 0) and team2BotsNum > 0 then
        if humanCount == 0 or not self.addCommander or team2BotsNum > 1 or not self:GetCommanderBot(kTeam2Index) then
            self:RemoveBot(kTeam2Index)
        end
    elseif team2Count < maxTeamBots and humanCount > 0 then
        self:AddBot(kTeam2Index)
    end

end
