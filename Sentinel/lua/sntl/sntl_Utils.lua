
local kLimitCallFrequency = {}

function LimitCallFrequency(id, frequency)
    local now = Shared.GetTime()

    kLimitCallFrequency[id] = kLimitCallFrequency[id] or 0
    if kLimitCallFrequency[id] >= now then
        return true
    end
    kLimitCallFrequency[id] = now + frequency

    return false
end
