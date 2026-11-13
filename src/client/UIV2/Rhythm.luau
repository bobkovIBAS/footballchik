local RunService = game:GetService("RunService")
local shared = game:GetService("ReplicatedStorage").Juggle
local Rules = require(shared.ClubRules)
local C = require(script.Parent.Components)
local Art = require(script.Parent.Art)
local amount = require(script.Parent.Parent.UiKit).amount

local Rhythm = {}
Rhythm.__index = Rhythm

local mid = Enum.TextXAlignment.Center
local tones = { Perfect = "gold", Good = "green", Miss = "red" }

function Rhythm.new(parent, quiet)
	local self = setmetatable({ quiet = quiet }, Rhythm)
	local root, face = C.Panel(parent, "Rhythm", "dark", 16)
	root.AnchorPoint, root.Visible = Vector2.new(.5, 1), false
	self.root, self.face = root, face
	self.beat = C.label(face, "Beat", "", 17, UDim2.fromOffset(11, 5), UDim2.new(.5, -12, 0, 25))
	self.combo = C.label(face, "Combo", "", 14, UDim2.new(.5, 0, 0, 5), UDim2.new(.5, -11, 0, 25),
		{ align = Enum.TextXAlignment.Right })
	local track = C.new("Frame", face, { Name = "Timing", BackgroundColor3 = C.white, BorderSizePixel = 0,
		Position = UDim2.fromOffset(12, 34), Size = UDim2.new(1, -24, 0, 22), ZIndex = 4 })
	C.round(track, 8)
	C.outline(track, 2)
	C.gradient(track, C.tones.red[2], C.tones.red[3])
	local function zone(name, tone, ratio)
		local region = C.new("Frame", track, { Name = name, AnchorPoint = Vector2.new(.5, .5),
			Position = UDim2.fromScale(.5, .5), Size = UDim2.fromScale(ratio, 1),
			BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, ZIndex = name == "Perfect" and 6 or 5 })
		C.round(region, 7)
		C.gradient(region, C.tones[tone][1], C.tones[tone][2])
		C.outline(region, 1.1)
		return region
	end
	self.good = zone("Good", "green", .5)
	zone("Perfect", "gold", 2 * Rules.PerfectWindow / Rules.BeatInterval)
	self.cursor = C.new("Frame", track, { Name = "Cursor", AnchorPoint = Vector2.new(.5, .5),
		Size = UDim2.fromOffset(6, 29), BackgroundColor3 = C.white, BorderSizePixel = 0, ZIndex = 8 })
	C.round(self.cursor, 3)
	C.outline(self.cursor, 1.8)
	self.track = track
	self.legend = C.new("Frame", face, { Name = "Legend", Position = UDim2.fromOffset(8, 61),
		Size = UDim2.new(1, -16, 0, 14), BackgroundTransparency = 1, ZIndex = 5 })
	for i, grade in { "Miss", "Good", "Perfect" } do
		C.label(self.legend, grade, grade:upper(), 10, UDim2.fromScale((i - 1) / 3, 0),
			UDim2.fromScale(1 / 3, 1), { align = mid, min = 8, color = C.tones[tones[grade]][1] })
	end
	self.feedback = C.label(face, "Judgement", "", 16, UDim2.fromOffset(11, 78), UDim2.new(.53, -16, 0, 23))
	self.power = C.label(face, "Power", "", 15, UDim2.new(.53, 21, 0, 78), UDim2.new(.47, -32, 0, 23),
		{ align = Enum.TextXAlignment.Right })
	self.gainIcon = Art.icon(face, "Power", UDim2.new(.53, 0, 0, 80), UDim2.fromOffset(18, 18), 5)
	self.scale = C.new("UIScale", face, { Scale = 1 })
	RunService.RenderStepped:Connect(function()
		if self.root.Visible then self:draw() end
	end)
	return self
end

function Rhythm:setSuppressed(suppressed)
	self.suppressed = suppressed
	self:draw()
end

function Rhythm:draw()
	local round = self.round
	local now = workspace:GetServerTimeNow()
	local active = self.page == nil and round ~= nil and round.start ~= nil
	local result = not self.suppressed and self.page == nil and round ~= nil and round.ended ~= nil and now < (self.resultUntil or 0)
	self.root.Visible = active or result
	if not self.root.Visible then return end
	self.track.Visible, self.legend.Visible = active, active
	self.power.Text = "+" .. amount(round.gained) .. " СИЛЫ"
	if active then
		self.root.Size = UDim2.fromOffset(self.root.Size.X.Offset, 113)
		self.feedback.Position = UDim2.fromOffset(11, 78)
		self.power.Position, self.gainIcon.Position = UDim2.new(.53, 21, 0, 78), UDim2.new(.53, 0, 0, 80)
		local raw = Rules.beatIndex(round, now)
		local beat = math.clamp(raw, 1, Rules.BeatCount)
		local offset = now - (round.start + (beat - 1) * Rules.BeatInterval)
		self.beat.Text = ("ТАКТ  %d / %d"):format(beat, Rules.BeatCount)
		self.combo.Text = "КОМБО ×" .. round.combo
		self.good.Size = UDim2.fromScale(2 * round.window / Rules.BeatInterval, 1)
		self.cursor.Position = UDim2.fromScale(math.clamp(.5 + offset / Rules.BeatInterval, 0, 1), .5)
		if round.last and now < (self.feedbackUntil or 0) then
			self.feedback.Text = round.last.grade:upper() .. "  +" .. round.last.gain
			self.feedback.TextColor3 = C.tones[tones[round.last.grade]][1]
		else
			self.feedback.Text = raw < 1 and "Приготовься" or raw > Rules.BeatCount and "Считаем очки"
				or beat >= round.nextBeat and math.abs(offset) <= round.window and "СЕЙЧАС!" or "Держи ритм"
			self.feedback.TextColor3 = C.white
		end
	else
		self.root.Size = UDim2.fromOffset(self.root.Size.X.Offset, 69)
		self.feedback.Position = UDim2.fromOffset(11, 32)
		self.power.Position, self.gainIcon.Position = UDim2.new(.53, 21, 0, 32), UDim2.new(.53, 0, 0, 34)
		self.beat.Text = round.cancelled and "РАУНД ПРЕРВАН" or ("РЕЗУЛЬТАТ  %d / %d"):format(round.score, Rules.BeatCount)
		self.combo.Text = "МАКС. ×" .. round.bestCombo
		self.feedback.Text = round.cancelled and "Ритм" or round.score >= 8 and "ЗОЛОТО"
			or round.score >= 6 and "СЕРЕБРО" or round.score >= 4 and "БРОНЗА" or "БЕЗ МЕДАЛИ"
		self.feedback.TextColor3 = C.tones.gold[1]
	end
end

function Rhythm:update(round, page)
	local previous = self.round
	self.round, self.page = round, page
	if round and round.last and (not previous or previous.id ~= round.id or not previous.last
		or previous.last.index ~= round.last.index) then
		self.feedbackUntil = workspace:GetServerTimeNow() + .54
		if not self.quiet() then
			if self.pulse then self.pulse:Cancel() end
			self.scale.Scale = 1.025
			self.pulse = C.tween(self.scale, .16, { Scale = 1 })
		end
	end
	if round and round.ended and (not previous or previous.ended ~= round.ended) then
		self.resultUntil = workspace:GetServerTimeNow() + 3
	end
	self:draw()
end

return Rhythm
