if Server then

    -- local orig_NS2Gamerules_CheckEndGame = NS2Gamerules.CheckEndGame
    -- function NS2Gamerules:CheckEndGame(winningTeam, autoConceded)
    --     local rval = orig_NS2Gamerules_CheckEndGame(self, winningTeam, autoConceded)

    --     return rval
    -- end

    function NS2Gamerules:GetCanJoinTeamNumber(player, teamNumber)
        if teamNumber ~= kAlienTeamType or SNTL_IsPlayerVirtual(player) then
            return true
        end
        Server.SendNetworkMessage(player, "SNTL_JoinError", SNTL_BuildJoinErrorMessage(0), true)
        return false
    end

    function NS2Gamerules:GetBotTeamController()
        return self.botTeamController
    end

    function NS2Gamerules:CheckForNoCommander(onTeam, commanderType)
        -- Remove the "no com" message
    end

    function NS2Gamerules:CheckGameStart()
        if self:GetGameState() <= kGameState.PreGame then
            local team1NumPlayer = self.team1:GetNumPlayers()

            if team1NumPlayer > 0 or Shared.GetCheatsEnabled() then
                if self:GetGameState() < kGameState.PreGame then
                    self:SetGameState(kGameState.PreGame)
                end
            else

                if self:GetGameState() == kGameState.PreGame then
                    self:SetGameState(kGameState.NotStarted)
                end

            end
        end
    end

    local old_NS2Gamerules_CheckGameEnd = NS2Gamerules.CheckGameEnd
    function NS2Gamerules:CheckGameEnd()
        return old_NS2Gamerules_CheckGameEnd(self)
    end

    function NS2Gamerules:UpdateWarmUp()
        -- No warmup
    end

    local old_NS2Gamerules_GetGameStarted = NS2Gamerules.GetGameStarted
    function NS2Gamerules:GetGameStarted()
        return old_NS2Gamerules_GetGameStarted(self)
    end

    local old_NS2Gamerules_OnCreate = NS2Gamerules.OnCreate
    function NS2Gamerules:OnCreate()
        local rval = old_NS2Gamerules_OnCreate(self)

        -- filler_bots are only enable on dedicated servers, force them to be there always
        -- self:SetMaxBots(Server.GetConfigSetting("filler_bots"), false)

        self:SetMaxBots(0, false) -- Force the filler bot setting to be 0
        return rval
    end
end
