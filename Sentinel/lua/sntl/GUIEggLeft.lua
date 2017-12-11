
class 'GUIEggLeft' (GUIScript)

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

local kPadActiveColor =  kAlienTeamColorFloat--Color(0.8, 0.9, 0, 0.8)
local kPadInactiveColor = Color(0.0, 0.0, 0.1, 0.4)

local kBackgroundPadding

local kBackgroundColor = Color(0.8, 0.9, 1, 0.1)

local kNumPads = 22

local function UpdateItemsGUIScale(self)
    kBackgroundSize = GUIScale(Vector(256, 70, 0))
    kBackgroundOffset = GUIScale(Vector(0, 12, 0))
    kPadding = math.max(1, math.round( GUIScale(3) ))

    kPadWidth = math.round( GUIScale(13) )
    kPadHeight = GUIScale(9)

    kBackgroundPadding = GUIScale(10)
end

function GUIEggLeft:OnResolutionChanged(oldX, oldY, newX, newY)
    UpdateItemsGUIScale(self)

    self:Uninitialize()
    self:Initialize()
end

function GUIEggLeft:Initialize()

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

    self.eggFraction = GetGameInfoEntity():GetNumEggs() / GetGameInfoEntity():GetNumMaxEggs()

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

    self.visible = false

   self.eggFractionTitle = GetGUIManager():CreateTextItem()
   self.eggFractionTitle:SetFontName("fonts/AgencyFB_small.fnt")
   self.eggFractionTitle:SetFontIsBold(false)
   self.eggFractionTitle:SetFontSize(8)
   self.eggFractionTitle:SetAnchor(GUIItem.Left, GUIItem.Middle)
   self.eggFractionTitle:SetPosition(Vector(0, -(kPadHeight / 1.25), 0))
   self.eggFractionTitle:SetTextAlignmentX(GUIItem.Align_Max)
   self.eggFractionTitle:SetTextAlignmentY(GUIItem.Align_Center)
   self.eggFractionTitle:SetColor(kAlienTeamColorFloat)

   self.eggFractionTitle:SetText("Egg count")

   self.background:AddChild(self.eggFractionTitle)

end

function GUIEggLeft:SetIsVisible(state)

    self.visible = state

    for i=1, #self.pads do
        self.pads[i]:SetIsVisible(state)
    end
    self.background:SetIsVisible(state)

end

function GUIEggLeft:GetIsVisible()

    return self.visible

end

function GUIEggLeft:Uninitialize()

    if self.background then

        GUI.DestroyItem(self.background)
        self.background = nil

    end

    self.pads = nil

end

function GUIEggLeft:Update(deltaTime)

    PROFILE("GUIEggLeft:Update")

    local player = Client.GetLocalPlayer()
    local desiredEggFraction = GetGameInfoEntity():GetNumEggs() / GetGameInfoEntity():GetNumMaxEggs()

    if not player or not player:GetIsAlive() or
        (player:GetTeamNumber() ~= kMarineTeamType and not player:isa("Spectator"))
    then
        self:SetIsVisible(false)
        return
    end

    --1--(player and player.GetFuel) and player:GetFuel() or 0

    self.eggFraction = Slerp(self.eggFraction, desiredEggFraction, deltaTime)

    for i = 1, kNumPads do

        local padFraction = i / kNumPads
        self.pads[i]:SetColor(padFraction <= self.eggFraction and kPadActiveColor or kPadInactiveColor )

    end

    -- Hack/Fix to ensure we have at least 1 pad displayed until we killed all the eggs
    if GetGameInfoEntity():GetNumEggs() > 0 then
        self.pads[1]:SetColor( kPadActiveColor )
    end

    if GetGameInfoEntity():GetGameStarted() then
        self:SetIsVisible(true)
    else
        self:SetIsVisible(false)
    end

end
