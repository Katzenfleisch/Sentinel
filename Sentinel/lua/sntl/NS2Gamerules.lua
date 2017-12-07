if Server then

    local orig_NS2Gamerules_EndGame = NS2Gamerules.EndGame
    function NS2Gamerules:EndGame(winningTeam, autoConceded)
        local rval = orig_NS2Gamerules_EndGame(self, winningTeam, autoConceded)

        Log("We won !!!")
        return rval
    end

end
