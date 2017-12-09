
function SNTL_OnCommandJoinError(message)
    if message.reason == 0 then
        ChatUI_AddSystemMessage( Locale.ResolveString("SNTL_JOIN_ERROR_ALIEN") )
    end
end

Client.HookNetworkMessage("SNTL_JoinError", SNTL_OnCommandJoinError)
