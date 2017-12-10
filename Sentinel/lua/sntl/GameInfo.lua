local networkVars =
    {
        sntl_numEggs = "integer",
        sntl_numMaxEggs = "integer",
        sntl_numRespawnLeft = "integer",
        sntl_numRespawnMax = "integer"
    }

function GameInfo:GetNumEggs()
    return self.sntl_numEggs
end

function GameInfo:GetNumMaxEggs()
    return self.sntl_numMaxEggs
end

function GameInfo:GetNumMarineRespawnLeft()
    return self.sntl_numRespawnLeft
end

function GameInfo:GetNumMarineRespawnMax()
    return self.sntl_numRespawnMax
end

if Server then
    local old_GameInfo_OnCreate = GameInfo.OnCreate
    function GameInfo:OnCreate()
        old_GameInfo_OnCreate(self)

        self.sntl_numEggs = 0
        self.sntl_numMaxEggs = 0
        self.sntl_numRespawnLeft = 0
        self.sntl_numRespawnMax = 0
    end
end

if Server then

    function GameInfo:SetNumEggs( n )
        self.sntl_numEggs = n
    end

    function GameInfo:SetNumMaxEggs( n )
        self.sntl_numMaxEggs = n
    end

    function GameInfo:SetNumMarineRespawnLeft( n )
        self.sntl_numRespawnLeft = n
    end

    function GameInfo:SetNumMarineRespawnMax( n )
        self.sntl_numRespawnMax = n
    end

end

Shared.LinkClassToMap("GameInfo", nil, networkVars)
