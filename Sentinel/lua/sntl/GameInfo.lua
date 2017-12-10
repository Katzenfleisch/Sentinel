local networkVars =
    {
        sntl_numEggs = "integer",
        sntl_numRespawnLeft = "integer"
    }

function GameInfo:GetNumEggs( n )
    return self.sntl_numEggs
end

function GameInfo:GetNumMarineRespawnLeft( n )
    return self.sntl_numRespawnLeft
end

if Server then
    local old_GameInfo_OnCreate = GameInfo.OnCreate
    function GameInfo:OnCreate()
        old_GameInfo_OnCreate(self)

        self.sntl_numEggs = 0
        self.sntl_numRespawnLeft = 0
    end
end

if Server then

    function GameInfo:SetNumEggs( n )
        self.sntl_numEggs = n
    end

    function GameInfo:SetNumMarineRespawnLeft( n )
        self.sntl_numRespawnLeft = n
    end

end

Shared.LinkClassToMap("GameInfo", nil, networkVars)
