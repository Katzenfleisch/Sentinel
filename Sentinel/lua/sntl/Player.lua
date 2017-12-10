-- if Server then

--     local old_Player_OnJoinTeam = Player.OnJoinTeam
--     function Player:OnJoinTeam(team)
--         local rval = old_Player_OnJoinTeam and old_Player_OnJoinTeam(self, team)

--         if self:GetTeamNumber() == kMarineTeamType then

--         end
--         return rval
--     end

-- end

local old_Player_OnInitialized = Player.OnInitialized
function Player:OnInitialized()
    if old_Player_OnInitialized then
        old_Player_OnInitialized(self)
    end
    if (Client) then
        self.GUIEggLeft = GetGUIManager():CreateGUIScript("sntl/GUIEggLeft")
        self.GUISpawnLeft = GetGUIManager():CreateGUIScript("sntl/GUIRespawnLeft")
    end
end

local old_Player_OnDestroy = Player.OnDestroy
function Player:OnDestroy()
    old_Player_OnDestroy(self)
    if (Client) then
        if self.GUIEggLeft then GetGUIManager():DestroyGUIScript(self.GUIEggLeft) end
        if self.GUISpawnLeft then GetGUIManager():DestroyGUIScript(self.GUISpawnLeft) end
    end
end
