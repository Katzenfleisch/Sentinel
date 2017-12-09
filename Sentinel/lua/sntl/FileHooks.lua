local function ModLoader_SetupFileHook(file, replace_type)
    local sntl_file = string.gsub(file, "lua/", "lua/sntl/", 1)

    Log("ModLoader.SetupFileHook(\"%s\",  \"%s\", \"%s\")", file,  sntl_file, replace_type)
    ModLoader.SetupFileHook(file,  sntl_file, replace_type)
end

ModLoader_SetupFileHook("lua/NS2Gamerules.lua", "post")

ModLoader_SetupFileHook("lua/Team.lua", "post")
ModLoader_SetupFileHook("lua/AlienTeam.lua", "post")
ModLoader_SetupFileHook("lua/PlayingTeam.lua", "post")

ModLoader_SetupFileHook("lua/Egg.lua", "post")
ModLoader_SetupFileHook("lua/Player.lua", "post")
ModLoader_SetupFileHook("lua/bots/BotTeamController.lua", "post")
ModLoader_SetupFileHook("lua/LOSMixin.lua", "post")

ModLoader_SetupFileHook("lua/NetworkMessages.lua", "post")
ModLoader_SetupFileHook("lua/NetworkMessages_Client.lua", "post")

ModLoader_SetupFileHook("lua/Shared.lua", "post")
