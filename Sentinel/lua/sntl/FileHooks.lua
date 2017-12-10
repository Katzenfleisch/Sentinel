local function ModLoader_SetupFileHook(file, replace_type)
    local sntl_file = string.gsub(file, "lua/", "lua/sntl/", 1)

    Log("[sntl] ModLoader.SetupFileHook(\"%s\",  \"%s\", \"%s\")", file,  sntl_file, replace_type)
    ModLoader.SetupFileHook(file,  sntl_file, replace_type)
end

ModLoader_SetupFileHook("lua/Globals.lua", "post")
ModLoader_SetupFileHook("lua/NS2Gamerules.lua", "post")

ModLoader_SetupFileHook("lua/Alien.lua", "post")
ModLoader_SetupFileHook("lua/Ragdoll.lua", "post")
ModLoader_SetupFileHook("lua/RagdollMixin.lua", "post")
ModLoader_SetupFileHook("lua/DissolveMixin.lua", "post")

ModLoader_SetupFileHook("lua/Team.lua", "post")
ModLoader_SetupFileHook("lua/AlienTeam.lua", "post")
ModLoader_SetupFileHook("lua/MarineTeam.lua", "post")
ModLoader_SetupFileHook("lua/PlayingTeam.lua", "post")

ModLoader_SetupFileHook("lua/PhaseGate.lua", "post")
ModLoader_SetupFileHook("lua/InfantryPortal.lua", "post")

ModLoader_SetupFileHook("lua/Balance.lua", "post")
ModLoader_SetupFileHook("lua/BalanceHealth.lua", "post")

ModLoader_SetupFileHook("lua/GameInfo.lua", "post")

ModLoader_SetupFileHook("lua/Egg.lua", "post")
ModLoader_SetupFileHook("lua/Player.lua", "post")
ModLoader_SetupFileHook("lua/bots/BotTeamController.lua", "post")
ModLoader_SetupFileHook("lua/LOSMixin.lua", "post")

ModLoader_SetupFileHook("lua/NetworkMessages.lua", "post")
ModLoader_SetupFileHook("lua/NetworkMessages_Client.lua", "post")

ModLoader_SetupFileHook("lua/Shared.lua", "post")

if Locale then
    local sntl_strings = {
        ["SNTL_JOIN_ERROR_ALIEN"] = "You can only join the marine team",
        -- --
        ["MARINE_TEAM_GAME_STARTED"] = "Objective: Kill all the eggs",
        ["RETURN_TO_BASE"] = "Objective: Return to base"
    }

    local old_Locale_ResolveString = Locale.ResolveString
    function Locale.ResolveString(text)
        return sntl_strings[text] or old_Locale_ResolveString(text)
    end
end
