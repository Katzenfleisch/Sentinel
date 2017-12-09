
local kLimitCallFrequency = {}

function SNTL_LimitCallFrequency(id, frequency)
    local now = Shared.GetTime()

    if kLimitCallFrequency[id] then
        if kLimitCallFrequency[id] >= now then
            return true
        end
        kLimitCallFrequency[id] = now + frequency
    else
        kLimitCallFrequency[id] = 0
    end
    return false
end

function SNTL_IsPlayerVirtual(ent)
    if (ent and ent.GetClient and ent:GetClient() and not ent:GetClient():GetIsVirtual()) then
      return false
   else
      return true
   end
end

if (Client) then
    local sntl_strings = {
        ["SNTL_JOIN_ERROR_ALIEN"] = "You can only join the marine team"
    }

    local old_Locale_ResolveString = Locale.ResolveString
    function Locale.ResolveString(text)
        return sntl_strings[text] or old_Locale_ResolveString(text)
    end
end

-- Needed for bots to have a uniq ID, otherwise they would cound as '1' player.
-- This will, for example, make all bot gorges shared the same tunnel/hydras/clogs pool.
if Server then
    local botsClientIdIt = -1
    local botsClientIds = {}
    local ServerClientGetUserId = ServerClient.GetUserId
    local function SNTL_GetUserId(self)
        local userId = ServerClientGetUserId(self)
        if userId == 0 then
            local player = self:GetControllingPlayer()

            if player then
                if not botsClientIds[player:GetName()] then
                    botsClientIds[player:GetName()] = botsClientIdIt
                    botsClientIdIt = botsClientIdIt - 1
                end
                return botsClientIds[player:GetName()]
            end
        end
        return userId
    end

    ServerClient.GetUserId = SNTL_GetUserId
end
