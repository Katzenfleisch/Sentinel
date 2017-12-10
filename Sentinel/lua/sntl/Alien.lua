
if Server then

    -- Unstuck check, need to move for at least 2m in any direction after spawn on the next Xs
    local function AlienCheckStuck(self)

        local now = Shared.GetTime()
        local stuckMaxDelay = 2

        if self.sntl_createOrig:GetDistanceTo(self:GetOrigin()) > 1 then
            self.sntl_stuck = false
            if self.sntl_unstucked then
                Log("[sntl] %s is now correctly unstucked (dist: %s)",  self, self.sntl_createOrig:GetDistanceTo(self:GetOrigin()))
            end
            return false
        else
            if now > self.sntl_createTime + stuckMaxDelay then
                local location = GetLocationForPoint(self:GetOrigin())
                local locationName = location and location:GetName() or "(unknown pos)"

                Log("[sntl] %s is stuck in %s (%s), moving it ...",  self, locationName, self:GetOrigin())

                local extents = LookupTechData(self:GetTechId(), kTechDataMaxExtents) --* 1.25
                local position = self:GetOrigin()
                local positions = SNTL_SpreadedPlacementFromOrigin(extents, position, 5, 2, 5)

                for i = 1, #positions do
                    position = SNTL_GetGroundAtPosition(positions[i], nil, PhysicsMask.AllButPCs, extents)
                    if position ~= self:GetOrigin() then
                        break
                    end
                end

                self:SetOrigin(position)
                self.sntl_createOrig = position
                self.sntl_createTime = now
                self.sntl_unstucked = true

            end
        end

        return self:GetIsAlive()
    end

    local old_Alien_OnInitialized = Alien.OnInitialized or Player.OnInitialized
    function Alien:OnInitialized()
        local rval = old_Alien_OnInitialized and old_Alien_OnInitialized(self)

        self.sntl_stuck = true
        self.sntl_createOrig = self:GetOrigin()
        self.sntl_createTime = Shared.GetTime()
        if SNTL_IsPlayerVirtual(self) then
            self:AddTimedCallback(AlienCheckStuck, 0.1)
        end
        return rval
    end

end
