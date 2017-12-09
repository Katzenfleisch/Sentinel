local kJoinErrorMessage =
    {
        reason = "integer"
    }
function SNTL_BuildJoinErrorMessage( reason )
    return { reason = reason }
end

Shared.RegisterNetworkMessage( "SNTL_JoinError", kJoinErrorMessage )
