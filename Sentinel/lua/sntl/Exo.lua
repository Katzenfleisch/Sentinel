-- function Exo:InitExoModel()

--     local modelName = kModelName
--     local graphName = kAnimationGraph
--     -- if self.layout == "MinigunMinigun" then

--     --     modelName = kDualModelName
--     --     graphName = kDualAnimationGraph
--     --     self.hasDualGuns = true

--     if self.layout == "ClawRailgun" then

--         modelName = kClawRailgunModelName
--         graphName = kClawRailgunAnimationGraph

--     elseif self.layout == "RailgunRailgun" then

--         modelName = kClawRailgunModelName
--         graphName = kClawRailgunAnimationGraph
--         -- modelName = kDualRailgunModelName
--         -- graphName = kDualRailgunAnimationGraph
--         -- self.hasDualGuns = true

--     end

--     -- SetModel must be called before Player.OnInitialized is called so the attach points in
--     -- the Exo are valid to attach weapons to. This is far too subtle...
--     self:SetModel(modelName, graphName)

-- end

-- function Exo:InitWeapons()

--     Player.InitWeapons(self)

--     local weaponHolder = self:GetWeapon(ExoWeaponHolder.kMapName)

--     if not weaponHolder then
--         weaponHolder = self:GiveItem(ExoWeaponHolder.kMapName, false)
--     end

--     if self.layout == "ClawMinigun" then
--         weaponHolder:SetWeapons(Claw.kMapName, Minigun.kMapName)
--     elseif self.layout == "MinigunMinigun" then
--         weaponHolder:SetWeapons(Claw.kMapName, Minigun.kMapName)
--         -- weaponHolder:SetWeapons(Minigun.kMapName, Minigun.kMapName)
--     elseif self.layout == "ClawRailgun" then
--         weaponHolder:SetWeapons(Claw.kMapName, Railgun.kMapName)
--     elseif self.layout == "RailgunRailgun" then
--         weaponHolder:SetWeapons(Claw.kMapName, Railgun.kMapName)
--         -- weaponHolder:SetWeapons(Railgun.kMapName, Railgun.kMapName)
--     else

--         Print("Warning: incorrect layout set for exosuit")
--         weaponHolder:SetWeapons(Claw.kMapName, Minigun.kMapName)

--     end

--     weaponHolder:TriggerEffects("exo_login")
--     self.inventoryWeight = weaponHolder:GetInventoryWeight(self)
--     self:SetActiveWeapon(ExoWeaponHolder.kMapName)
--     StartSoundEffectForPlayer(kDeploy2DSound, self)

-- end
