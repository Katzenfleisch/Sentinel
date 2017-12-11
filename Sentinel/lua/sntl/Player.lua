-- if Server then

--     local old_Player_OnJoinTeam = Player.OnJoinTeam
--     function Player:OnJoinTeam(team)
--         local rval = old_Player_OnJoinTeam and old_Player_OnJoinTeam(self, team)

--         if self:GetTeamNumber() == kMarineTeamType then

--         end
--         return rval
--     end

-- end


local function ClearGUIScripts(self)
    if (Client) then
        if self.GUIEggLeft then GetGUIManager():DestroyGUIScript(self.GUIEggLeft) end
        if self.GUISpawnLeft then GetGUIManager():DestroyGUIScript(self.GUISpawnLeft) end
        if self.GUIObjective then GetGUIManager():DestroyGUIScript(self.GUIObjective) end
    end
end

local function CreateGUISripts(self)
    ClearGUIScripts(self)
    if (Client and self == Client.GetLocalPlayer()) then
        self.GUIEggLeft = GetGUIManager():CreateGUIScript("sntl/GUIEggLeft")
        self.GUISpawnLeft = GetGUIManager():CreateGUIScript("sntl/GUIRespawnLeft")
        self.GUIObjective = GetGUIManager():CreateGUIScript("sntl/GUIObjective")
    end
end

local old_Player_OnInitialized = Player.OnInitialized
function Player:OnInitialized()
    if old_Player_OnInitialized then
        old_Player_OnInitialized(self)
    end

    CreateGUISripts(self)
end


local old_Player_OnKill = Player.OnKill
function Player:OnKill()
    ClearGUIScripts(self)
    old_Player_OnKill(self)
end

local old_Player_OnDestroy = Player.OnDestroy
function Player:OnDestroy()
    ClearGUIScripts(self)
    old_Player_OnDestroy(self)
end

-- local old_Player_CopyPlayerDataFrom = Player.CopyPlayerDataFrom
-- function Player:CopyPlayerDataFrom(player)

--     ClearGUIScripts(self)
--     old_Player_CopyPlayerDataFrom(self, player)
--     CreateGUISripts(player)
-- end
