
class 'GUIObjective' (GUIScript)

local kBackgroundSize
local kBackgroundOffset
GUIMarineHUD.kCommanderNameOffset = Vector(20, 330, 0)
GUIMarineHUD.kCommanderFontName = Fonts.kAgencyFB_Small
GUIMarineHUD.kActiveCommanderColor = Color(246/255, 254/255, 37/255 )

local function UpdateItemsGUIScale(self)
    kBackgroundSize = GUIScale(Vector(256, 70, 0))
    kBackgroundOffset = GUIScale(Vector(30, 12, 0))
    kPadding = math.max(1, math.round( GUIScale(3) ))

    kPadWidth = math.round( GUIScale(13) )
    kPadHeight = GUIScale(9)

    kBackgroundPadding = GUIScale(10)
end

function GUIObjective:OnResolutionChanged(oldX, oldY, newX, newY)
    UpdateItemsGUIScale(self)

    self:Uninitialize()
    self:Initialize()
end


function GUIObjective:Initialize()

    UpdateItemsGUIScale(self)

    -- self.background = GetGUIManager():CreateGraphicItem()
    -- self.pads = {}

    local backgroundSize = Vector(10,
                                  2 * kBackgroundPadding + kPadHeight,
                                  0)

    -- self.background:SetAnchor(GUIItem.Middle, GUIItem.Top)
    -- self.background:SetSize(backgroundSize)
    -- -- self.background:SetPosition(kBackgroundOffset * 0.5)
    -- self.background:SetPosition(backgroundSize * 0.5 + kBackgroundOffset)
    -- self.background:SetColor(kBackgroundColor)

    -- self.eggFraction = GetGameInfoEntity():GetNumEggs() / GetGameInfoEntity():GetNumMaxEggs()

    -- for i = 1, kNumPads do

    --     local pos = Vector((i - 1) * (kPadding + kPadWidth) + kBackgroundPadding, -kPadHeight * 0.5, 0)
    --     local pad = GetGUIManager():CreateGraphicItem()
    --     pad:SetPosition(pos)
    --     pad:SetIsVisible(false)
    --     pad:SetColor(kPadActiveColor)
    --     pad:SetAnchor(GUIItem.Left, GUIItem.Center)
    --     pad:SetSize(Vector(kPadWidth, kPadHeight, 0))

    --     self.background:AddChild(pad)

    --     table.insert(self.pads, pad)

    -- end

    self.visible = false

    -- self.commanderName = self:CreateAnimatedTextItem()
    -- self.commanderName:SetFontName(GUIMarineHUD.kTextFontName)
    -- self.commanderName:SetTextAlignmentX(GUIItem.Align_Min)
    -- self.commanderName:SetTextAlignmentY(GUIItem.Align_Min)
    -- self.commanderName:SetAnchor(GUIItem.Left, GUIItem.Top)
    -- self.commanderName:SetLayer(kGUILayerPlayerHUDForeground1)
    -- self.commanderName:SetFontName(GUIMarineHUD.kCommanderFontName)
    -- self.commanderName:SetColor(Color(1,1,1,1))
    -- self.commanderName:SetFontIsBold(true)

   self.objectiveTitle = GetGUIManager():CreateTextItem()
   self.objectiveTitle:SetFontName("fonts/AgencyFB_small.fnt")
   self.objectiveTitle:SetFontIsBold(false)
   self.objectiveTitle:SetFontSize(8)
   self.objectiveTitle:SetAnchor(GUIItem.Left, GUIItem.Top)
   self.objectiveTitle:SetPosition(Vector(78, -1, 0))
   self.objectiveTitle:SetTextAlignmentX(GUIItem.Align_Min)
   self.objectiveTitle:SetTextAlignmentY(GUIItem.Align_Min)
   self.objectiveTitle:SetColor(kMarineTeamColorFloat)

    -- self.background:SetAnchor(GUIItem.Middle, GUIItem.Top)
    -- self.background:SetSize(backgroundSize)
    -- -- self.background:SetPosition(kBackgroundOffset * 0.5)
    -- self.background:SetPosition(backgroundSize * 0.5 + kBackgroundOffset)
    -- self.background:SetColor(kBackgroundColor)


   self.objectiveTitle:SetText("Objective: Kill all the eggs")

end

function GUIObjective:SetIsVisible(state)

    self.visible = state

    self.objectiveTitle:SetIsVisible(state)

end

function GUIObjective:GetIsVisible()

    return self.visible

end

function GUIObjective:Uninitialize()

    if self.objectiveTitle then
        GUI.DestroyItem(self.objectiveTitle)
        self.objectiveTitle = nil
    end
end

function GUIObjective:Update(deltaTime)

    PROFILE("GUIObjective:Update")

    local player = Client.GetLocalPlayer()

    if not player or not player:GetIsAlive() or
        (player:GetTeamNumber() ~= kMarineTeamType and not player:isa("Spectator"))
    then
        self:SetIsVisible(false)
        return
    end

    if GetGameInfoEntity():GetGameStarted() then
        self:SetIsVisible(true)
    else
        self:SetIsVisible(false)
    end

end
