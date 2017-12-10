
class 'GUIRespawnLeft' (GUIScript)

local kBackgroundSize
local kBackgroundOffset
local kPadding

local kPadWidth
local kPadHeight

-- local marineColor = Color(1/255 * 10, 1/255 * 140, 1/255 * 240, 1)
-- local alienColor = Color(1/255 * 210, 1/255 * 160, 1/255 * 40, 1)
-- local neutralColor = Color(1, 1, 1, 0.6)

-- local backgroundColor = Color(1, 0.2, 0.2, 0.4)
-- local cornerColor = Color(1, 1, 1, 0.4)

local kPadActiveColor =  kMarineTeamColorFloat--Color(0.0, 0.9, 0.8, 0.8)
local kPadInactiveColor = Color(0.0, 0.0, 0.1, 0.4)

local kBackgroundPadding

local kBackgroundColor = Color(0.8, 0.9, 1, 0.1)

local kNumPads = 22

local function UpdateItemsGUIScale(self)
    kBackgroundSize = GUIScale(Vector(256, 70, 0))
    kPadding = math.max(1, math.round( GUIScale(3) ))

    kPadWidth = math.round( GUIScale(13) )
    kPadHeight = GUIScale(9)

    kBackgroundPadding = GUIScale(10)


    kBackgroundOffset = GUIScale(Vector(0, 12 + kPadHeight * 1.2, 0))
end

function GUIRespawnLeft:OnResolutionChanged(oldX, oldY, newX, newY)
    UpdateItemsGUIScale(self)

    self:Uninitialize()
    self:Initialize()
end

function GUIRespawnLeft:Initialize()

    UpdateItemsGUIScale(self)

    self.background = GetGUIManager():CreateGraphicItem()
    self.pads = {}

    local backgroundSize = Vector(kNumPads * kPadWidth + (kNumPads - 1) * kPadding + 2 * kBackgroundPadding,
                                  2 * kBackgroundPadding + kPadHeight,
                                  0)

    self.background:SetAnchor(GUIItem.Middle, GUIItem.Top)
    self.background:SetSize(backgroundSize)
    -- self.background:SetPosition(kBackgroundOffset * 0.5)
    self.background:SetPosition(backgroundSize * 0.5 + kBackgroundOffset)
    self.background:SetColor(kBackgroundColor)

    local respawnLeft = GetGameInfoEntity():GetNumMarineRespawnLeft()
    local respawnMax = GetGameInfoEntity():GetNumMarineRespawnMax()
    local desiredEggFraction = respawnLeft / respawnMax

    self.spawnFraction = desiredEggFraction

    for i = 1, kNumPads do

        local pos = Vector((i - 1) * (kPadding + kPadWidth) + kBackgroundPadding, -kPadHeight * 0.5, 0)
        local pad = GetGUIManager():CreateGraphicItem()
        pad:SetPosition(pos)
        pad:SetIsVisible(false)
        pad:SetColor(kPadActiveColor)
        pad:SetAnchor(GUIItem.Left, GUIItem.Center)
        pad:SetSize(Vector(kPadWidth, kPadHeight, 0))

        self.background:AddChild(pad)

        table.insert(self.pads, pad)

    end

    self.visible = true

   self.spawnFractionTitle = GetGUIManager():CreateTextItem()
   self.spawnFractionTitle:SetFontName("fonts/AgencyFB_small.fnt")
   self.spawnFractionTitle:SetFontIsBold(false)
   self.spawnFractionTitle:SetFontSize(8)
   self.spawnFractionTitle:SetAnchor(GUIItem.Left, GUIItem.Middle)
   self.spawnFractionTitle:SetPosition(Vector(0, kPadHeight / 2, 0))
   self.spawnFractionTitle:SetTextAlignmentX(GUIItem.Align_Max)
   self.spawnFractionTitle:SetTextAlignmentY(GUIItem.Align_Center)
   self.spawnFractionTitle:SetColor(kMarineTeamColorFloat)

   self.spawnFractionTitle:SetText("Spawn count")

   self.background:AddChild(self.spawnFractionTitle)

end

function GUIRespawnLeft:SetIsVisible(state)

    self.visible = state

    for i=1, #self.pads do
        self.pads[i]:SetIsVisible(state)
    end
    self.background:SetIsVisible(state)

end

function GUIRespawnLeft:GetIsVisible()

    return self.visible

end

function GUIRespawnLeft:Uninitialize()

    if self.background then

        GUI.DestroyItem(self.background)
        self.background = nil

    end

    self.pads = nil

end

function GUIRespawnLeft:Update(deltaTime)

    PROFILE("GUIRespawnLeft:Update")

    local player = Client.GetLocalPlayer()

    --1--(player and player.GetFuel) and player:GetFuel() or 0

    local respawnLeft = GetGameInfoEntity():GetNumMarineRespawnLeft()
    local respawnMax = GetGameInfoEntity():GetNumMarineRespawnMax()
    local desiredEggFraction = respawnLeft / respawnMax

    self.spawnFraction = Slerp(self.spawnFraction, desiredEggFraction, deltaTime)

    for i = 1, kNumPads do

        local padFraction = i / kNumPads
        self.pads[i]:SetColor(padFraction <= self.spawnFraction and kPadActiveColor or kPadInactiveColor )

    end

    if GetGameInfoEntity():GetGameStarted() and player:GetIsAlive() then
        self:SetIsVisible(true)
    else
        self:SetIsVisible(false)
    end

end
