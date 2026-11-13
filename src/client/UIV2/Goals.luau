local C = require(script.Parent.Components)
local Art = require(script.Parent.Art)
local Rules = require(game:GetService("ReplicatedStorage").Juggle.GoalRules)
local amount = require(script.Parent.Parent.UiKit).amount

local Goals = {}
local mid = Enum.TextXAlignment.Center
local bands = { "red", "gold", "blue", "green", "purple" }

function Goals.gauge(field, quiet)
	local root, face = C.Panel(field, "ShotPower", "dark", 15)
	root.AnchorPoint, root.Visible = Vector2.new(1, 0), false
	local title = C.label(face, "Title", "МОЩНОСТЬ", 14, UDim2.fromOffset(5, 5),
		UDim2.new(1, -10, 0, 19), { align = mid, min = 9 })
	local value = C.label(face, "Multiplier", "×1", 18, UDim2.fromOffset(4, 24),
		UDim2.new(1, -8, 0, 23), { align = mid })
	local rail = C.new("Frame", face, { Name = "Scale", Position = UDim2.fromOffset(9, 53),
		Size = UDim2.new(1, -18, 1, -64), BackgroundTransparency = 1, ZIndex = 4 })
	for i, band in Rules.PowerBands do
		local upper = Rules.PowerBands[i + 1] and Rules.PowerBands[i + 1].minimum or 1
		local extent = upper - band.minimum
		local tone = C.tones[bands[i]]
		local zone = C.new("Frame", rail, { Name = "Band" .. i, Position = UDim2.new(0, 0, 1 - upper, 0),
			Size = UDim2.new(1, 0, extent, -1), BackgroundColor3 = C.white, BorderSizePixel = 0, ZIndex = 5 })
		C.round(zone, 5)
		C.outline(zone, 1.1)
		C.gradient(zone, tone[1], tone[2])
		C.label(zone, "Value", "×" .. band.multiplier, 12, UDim2.fromOffset(4, 0), UDim2.new(1, -7, 1, 0),
			{ align = mid, min = 8, z = 6 })
	end
	local pointer = C.new("Frame", rail, { Name = "Pointer", AnchorPoint = Vector2.new(0, .5),
		Size = UDim2.new(1, 8, 0, 4), BackgroundColor3 = C.white, BorderSizePixel = 0, ZIndex = 8 })
	C.round(pointer, 3)
	C.outline(pointer, 1.4)
	local scale = C.new("UIScale", face, { Scale = 1 })
	local function layout()
		local bounds = field.AbsoluteSize
		local compact = bounds.Y < 400 or bounds.X < 500
		root.Position = UDim2.new(1, compact and -12 or -16, 0, compact and 67 or 78)
		root.Size = UDim2.fromOffset(compact and 78 or 124, math.clamp(bounds.Y * .53, 165, 292))
		title.Text = compact and "УДАР" or "МОЩНОСТЬ"
	end
	field:GetPropertyChangedSignal("AbsoluteSize"):Connect(layout)
	layout()
	local animation
	return {
		update = function(_, elapsed)
			local height = Rules.powerHeight(elapsed)
			local multiplier = Rules.powerBand(height)
			pointer.Position = UDim2.new(0, -4, 1 - height, 0)
			value.Text = "×" .. multiplier
			value.TextColor3 = multiplier == 2 and C.tones.gold[1] or C.white
		end,
		show = function(_, visible)
			if animation then animation:Cancel() end
			root.Visible = visible
			scale.Scale = visible and not quiet() and .95 or 1
			if visible and scale.Scale < 1 then animation = C.tween(scale, .16, { Scale = 1 }) end
		end,
	}
end

function Goals.health(gui, level, finished, quiet)
	gui.Size = UDim2.fromScale(15.5, 3.9)
	local panel, face = C.Panel(gui, "Health", "dark", 10)
	panel.Size = UDim2.fromScale(1, 1)
	Art.icon(face, finished and "Progress" or "Ball", UDim2.fromScale(.025, .035), UDim2.fromScale(.16, .76), 5)
	C.label(face, "Goal", finished and "ПЛОЩАДКА ПРОЙДЕНА" or ("ВОРОТА  ·  УР. " .. amount(level)), 22,
		UDim2.fromScale(.20, .04), UDim2.fromScale(.77, .33), { min = 7 })
	local hp = C.label(face, "HP", "", 17, UDim2.fromScale(.20, .38), UDim2.fromScale(.76, .27), { min = 7 })
	local track, fill = C.ProgressBar(face, "Life", finished and "gold" or "red", quiet)
	track.Position, track.Size = UDim2.fromScale(.20, .72), UDim2.fromScale(.74, .15)
	return function(value, maximum)
		hp.Text = finished and (amount(level) .. " / " .. amount(Rules.MaxLevel))
			or (tostring(value) .. " / " .. amount(maximum) .. " HP")
		fill(finished and 1 or value / maximum)
	end
end

function Goals.impact(notify, shot, damage)
	local broken = shot.remaining == 0
	local text = "−" .. damage .. " HP  ·  ×" .. shot.multiplier
	if shot.multiplier == 2 then text = "PERFECT!  " .. text end
	if broken then
		text = "Ворота разбиты!  +" .. amount(shot.reward) .. " монет"
		if shot.nextHP > 0 then text ..= "  ·  Следующие: ур. " .. amount(shot.nextLevel) end
		if shot.multiplier == 2 then text = "PERFECT!  " .. text end
	end
	notify(text, broken and "gold" or "red", broken and "Coins" or "Ball", true)
end

return Goals
