if Server then

    -- local orig_NS2Gamerules_CheckEndGame = NS2Gamerules.CheckEndGame
    -- function NS2Gamerules:CheckEndGame(winningTeam, autoConceded)
    --     local rval = orig_NS2Gamerules_CheckEndGame(self, winningTeam, autoConceded)

    --     return rval
    -- end

    local old_NS2Gamerules_OnCreate = NS2Gamerules.OnCreate
    function NS2Gamerules:OnCreate()
        local rval = old_NS2Gamerules_OnCreate(self)

        -- filler_bots are only enable on dedicated servers, force them to be there always
        -- self:SetMaxBots(Server.GetConfigSetting("filler_bots"), false)

        self:SetMaxBots(0, false) -- Force the filler bot setting to be 0
        return rval
    end
end
