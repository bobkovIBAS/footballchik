local Ui = require(script.Parent:WaitForChild("UiKit"))
local Rules = require(game:GetService("ReplicatedStorage"):WaitForChild("Juggle"):WaitForChild("GoalRules"))
local UserInputService = game:GetService("UserInputService")

local ShotGauge = {}
ShotGauge.__index = ShotGauge

local center = Enum.TextXAlignment.Center
local bold = Enum.Font.GothamBlack
local ink = Color3.fromRGB(13, 22, 43)
local white = Color3.fromRGB(247, 252, 255)
local gold = Color3.fromRGB(255, 222, 100)
local colors = {
	Color3.fromRGB(255, 102, 137), Color3.fromRGB(255, 156, 95), Color3.fromRGB(103, 165, 255),
	Color3.fromRGB(97, 243, 192), gold,
}

function ShotGauge.new(parent, dock, effects)
	local self = setmetatable({ effects = effects }, ShotGauge)
	local panel = Ui.create("CanvasGroup", parent, {
		Name = "ShotPower", AnchorPoint = Vector2.new(1, 0), BackgroundColor3 = ink,
		BorderSizePixel = 0, GroupTransparency = 1, Visible = false,
	})
	self.panel = panel
	Ui.rounded(panel, 15)
	Ui.outline(panel, Color3.fromRGB(86, 110, 158))
	local title = Ui.place(panel, "СИЛА УДАРА", 14, white, UDim2.fromOffset(8, 7), UDim2.new(1, -16, 0, 24), center, bold)
	Ui.fit(title, 10, 14)
	local track = Ui.create("Frame", panel, {
		Name = "Track", Position = UDim2.fromOffset(14, 38), Size = UDim2.new(1, -28, 1, -52),
		BackgroundTransparency = 1,
	})
	for index, band in Rules.PowerBands do
		local nextBand = Rules.PowerBands[index + 1]
		local upper = nextBand and nextBand.minimum or 1
		local color = colors[index]
		local zone = Ui.create("Frame", track, {
			Position = UDim2.new(0, 0, 1 - upper, 0), Size = UDim2.new(0.55, 0, upper - band.minimum, -1),
			BackgroundColor3 = color, BorderSizePixel = 0,
		})
		Ui.gradient(zone, white, Color3.fromRGB(189, 197, 224), 0)
		if not nextBand then
			Ui.outline(zone, gold)
		end
		local label = Ui.place(track, "×" .. band.multiplier, 15, color,
			UDim2.fromScale(0.59, 1 - upper), UDim2.fromScale(0.41, upper - band.minimum), center, bold)
		Ui.fit(label, 8, 15)
	end
	self.marker = Ui.create("Frame", track, {
		Name = "Indicator", AnchorPoint = Vector2.new(0, 0.5), Size = UDim2.new(0.62, 0, 0, 4),
		BackgroundColor3 = white, BorderSizePixel = 0, ZIndex = 3,
	})
	Ui.rounded(self.marker, 2)
	Ui.outline(self.marker, ink)

	local perfect = Ui.create("CanvasGroup", parent, {
		Name = "PerfectShot", AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0.20, 0),
		Size = UDim2.fromOffset(212, 46), BackgroundColor3 = ink, GroupTransparency = 1, Visible = false,
	})
	Ui.rounded(perfect, 12)
	Ui.outline(perfect, gold)
	Ui.place(perfect, "PERFECT SHOT!", 19, gold, UDim2.fromScale(0, 0), UDim2.fromScale(1, 1), center, bold)
	self.perfect = perfect
	self.perfectScale = Ui.create("UIScale", perfect, {})

	local function layout()
		local size = parent.AbsoluteSize
		local short = size.Y < 400 and size.X > size.Y
		local compact = short and UserInputService.TouchEnabled
		local width = compact and 74 or (size.X < 580 and 114 or 146)
		local top = short and 61 or 81
		local height = compact and math.clamp(math.floor(size.Y * 0.43), 112, 172)
			or math.clamp(math.floor(size.Y * 0.42), 164, 304)
		local edge = short and not compact and (dock.Size.X.Offset - dock.Position.X.Offset + 10) or 12
		panel.Position = UDim2.new(1, -edge, 0, top)
		panel.Size = UDim2.fromOffset(width, height)
		title.Text = compact and "МОЩНОСТЬ" or "СИЛА УДАРА"
		title.Position = UDim2.fromOffset(5, compact and 4 or 7)
		title.Size = UDim2.new(1, -10, 0, compact and 17 or 24)
		local padding = compact and 8 or 14
		track.Position = UDim2.fromOffset(padding, compact and 25 or 38)
		track.Size = UDim2.new(1, -2 * padding, 1, compact and -34 or -52)
	end
	parent:GetPropertyChangedSignal("AbsoluteSize"):Connect(layout)
	dock:GetPropertyChangedSignal("Size"):Connect(layout)
	dock:GetPropertyChangedSignal("Position"):Connect(layout)
	layout()
	return self
end

function ShotGauge:update(elapsed)
	local height = Rules.powerHeight(elapsed)
	self.marker.Position = UDim2.new(0, -3, 1 - height, 0)
	self.marker.BackgroundColor3 = height >= Rules.PowerBands[#Rules.PowerBands].minimum and gold or white
end

function ShotGauge:show(visible)
	if self.animation then self.animation:Cancel() end
	local transparency = visible and 0 or 1
	if self.effects.quiet then
		self.panel.Visible, self.panel.GroupTransparency = visible, transparency
		return
	end
	if visible then self.panel.Visible = true end
	self.animation = Ui.tween(self.panel, visible and 0.15 or 0.13, { GroupTransparency = transparency })
	if not visible then
		self.animation.Completed:Once(function(state)
			if state == Enum.PlaybackState.Completed then self.panel.Visible = false end
		end)
	end
end

function ShotGauge:flashPerfect()
	if self.perfectTween then self.perfectTween:Cancel() end
	if self.perfectHold then task.cancel(self.perfectHold) end
	self.perfect.Visible = true
	self.perfect.GroupTransparency = 0
	self.perfectScale.Scale = self.effects.quiet and 1 or 0.83
	if not self.effects.quiet then
		self.perfectTween = Ui.tween(self.perfectScale, 0.17, { Scale = 1 })
	end
	self.perfectHold = task.delay(0.62, function()
		self.perfectHold = nil
		self.perfectTween = Ui.tween(self.perfect, 0.20, { GroupTransparency = 1 })
		self.perfectTween.Completed:Once(function(state)
			if state == Enum.PlaybackState.Completed then self.perfect.Visible = false end
		end)
	end)
end

return ShotGauge
