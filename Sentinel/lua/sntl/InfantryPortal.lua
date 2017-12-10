
local networkVars =
    {
        respawnLeft = "integer"
    }

if Server then

    local old_InfantryPortal_OnInitialized = InfantryPortal.OnInitialized
    function InfantryPortal:OnInitialized()
        old_InfantryPortal_OnInitialized(self)

        self.respawnLeft = 1
    end

    local old_InfantryPortal_GetIsPowered = InfantryPortal.GetIsPowered or PowerConsumerMixin.GetIsPowered
    function InfantryPortal:GetIsPowered()
        if self.respawnLeft == 0 then
            return false
        end
        return old_InfantryPortal_GetIsPowered(self)
    end

    local InfantryPortal_FinishSpawn = InfantryPortal.FinishSpawn
    function InfantryPortal:FinishSpawn()
        InfantryPortal_FinishSpawn(self)
        self.respawnLeft = math.max(0, self.respawnLeft - 1)
    end

end

if Client then
    local old_InfantryPortal_OnUpdate = InfantryPortal.OnUpdate
    function InfantryPortal:OnUpdate(deltatime)

        if old_InfantryPortal_OnUpdate then
            old_InfantryPortal_OnUpdate(self, deltatime)
        end

        if GetGameInfoEntity() and GetGameInfoEntity():GetGameStarted() and GetIsUnitActive(self) then

            if SNTL_LimitCallFrequency(InfantryPortal.OnUpdate, kWorldMessageLifeTime + 5) then return end

            local msg = self.respawnLeft > 0
                and string.format("+%d respawn left", self.respawnLeft)
                or  string.format("No more respawn *;..;*")

            Client.AddWorldMessage(kWorldTextMessageType.Resources,
                                   msg,
                                   self:GetOrigin() + Vector(0,2,0))
        end

    end
end

Shared.LinkClassToMap("InfantryPortal", nil, networkVars)
