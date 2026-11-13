local TweenService = game:GetService("TweenService")
local Art = require(script.Parent.Art)

local Components = {}
local rgb = Color3.fromRGB
local white = rgb(255, 252, 250)
local ink = rgb(36, 24, 49)
local black = rgb(21, 16, 32)

Components.tones = {
	gold = { rgb(255, 218, 96), rgb(246, 146, 33), rgb(164, 75, 25) },
	cyan = { rgb(105, 225, 255), rgb(38, 151, 234), rgb(28, 80, 161) },
	red = { rgb(255, 122, 121), rgb(240, 62, 93), rgb(146, 31, 71) },
	blue = { rgb(104, 167, 255), rgb(53, 104, 233), rgb(43, 53, 148) },
	purple = { rgb(200, 138, 255), rgb(145, 69, 229), rgb(86, 43, 144) },
	green = { rgb(154, 247, 79), rgb(64, 177, 39), rgb(38, 105, 39) },
	gray = { rgb(177, 187, 217), rgb(107, 113, 155), rgb(66, 58, 97) },
	dark = { rgb(84, 65, 111), rgb(49, 34, 74), rgb(27, 19, 44) },
}
Components.white = white
Components.ink = ink

function Components.new(class, parent, props)
	local object = Instance.new(class)
	for key, value in props do object[key] = value end
	object.Parent = parent
	return object
end

local new = Components.new

local function round(object, radius)
	new("UICorner", object, { CornerRadius = UDim.new(0, radius) })
end

local function outline(object, width, color)
	return new("UIStroke", object, {
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		Color = color or ink,
		Thickness = width,
	})
end

local function gradient(object, a, b)
	return new("UIGradient", object, { Color = ColorSequence.new(a, b), Rotation = 90 })
end

local function tween(object, seconds, properties)
	local animation = TweenService:Create(object, TweenInfo.new(seconds, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), properties)
	animation:Play()
	return animation
end

function Components.label(parent, name, value, size, pos, extent, options)
	options = options or {}
	local label = new("TextLabel", parent, {
		Name = name, Text = value, BackgroundTransparency = 1,
		Position = pos, Size = extent, TextColor3 = options.color or white,
		TextXAlignment = options.align or Enum.TextXAlignment.Left, TextSize = size, TextScaled = true,
		Font = options.heavy == false and Enum.Font.GothamBold or Enum.Font.GothamBlack,
		ZIndex = options.z or 4, TextWrapped = options.wrap == true,
		TextTruncate = options.wrap and Enum.TextTruncate.None or Enum.TextTruncate.AtEnd,
	})
	new("UITextSizeConstraint", label, { MinTextSize = options.min or math.min(size, 11), MaxTextSize = size })
	if options.stroke ~= false then
		new("UIStroke", label, { ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual, Color = ink,
			Thickness = options.stroke or 1.6 })
	end
	return label
end

Components.tween = tween
Components.gradient = gradient
Components.round = round
Components.outline = outline

function Components.Panel(parent, name, toneName, radius)
	local tone = Components.tones[toneName]
	local root = new("Frame", parent, { Name = name, BackgroundTransparency = 1 })
	local shadow = new("Frame", root, {
		Name = "Shadow", Position = UDim2.fromOffset(1, 7), Size = UDim2.new(1, 0, 1, -3),
		BackgroundColor3 = black, BackgroundTransparency = .56, BorderSizePixel = 0, ZIndex = 1,
	})
	round(shadow, radius)
	local lip = new("Frame", root, {
		Name = "Depth", Position = UDim2.fromOffset(0, 4), Size = UDim2.new(1, 0, 1, -4),
		BackgroundColor3 = tone[3], BorderSizePixel = 0, ZIndex = 2,
	})
	round(lip, radius)
	outline(lip, 2.5)
	local face = new("Frame", root, { Name = "Face", Size = UDim2.new(1, 0, 1, -5),
		BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, ZIndex = 3 })
	round(face, radius)
	local edge = outline(face, 2.5)
	local shading = gradient(face, tone[1], tone[2])
	local gleam = new("Frame", face, { Name = "Glint", Position = UDim2.fromOffset(9, 4),
		Size = UDim2.new(1, -18, 0, 3), BackgroundColor3 = white, BackgroundTransparency = .57,
		BorderSizePixel = 0, ZIndex = 4 })
	round(gleam, 4)
	new("UIGradient", gleam, { Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, .30), NumberSequenceKeypoint.new(.49, .62), NumberSequenceKeypoint.new(1, 1),
	}) })
	return root, face, edge, shading, lip
end

local function button(parent, name, toneName, quiet, callback, radius)
	local root, face, edge, shading, lip = Components.Panel(parent, name, toneName, radius)
	local hit = new("TextButton", root, { Name = "Hit", Size = UDim2.fromScale(1, 1),
		Text = "", BackgroundTransparency = 1, AutoButtonColor = false, Selectable = true, ZIndex = 8 })
	local scale = new("UIScale", face, { Scale = 1 })
	local handle = { root = root, face = face, hit = hit }
	local hovered, focused, pressed, enabled, selected = false, false, false, true, false
	local currentTone = toneName
	local motion
	local function update()
		local tone = Components.tones[(enabled or selected) and currentTone or "gray"]
		edge.Color = (focused and enabled or selected) and rgb(255, 246, 162) or ink
		edge.Thickness = (focused and enabled or selected) and 3.5 or 2.5
		lip.BackgroundColor3 = tone[3]
		shading.Color = ColorSequence.new(hovered and enabled and tone[1]:Lerp(white, .21) or tone[1], tone[2])
		local factor = enabled and (pressed and .965 or (hovered and 1.015 or 1)) or 1
		if motion then motion:Cancel() end
		if quiet() then scale.Scale = 1 else motion = tween(scale, .10, { Scale = factor }) end
	end
	hit.MouseEnter:Connect(function() hovered = true update() end)
	hit.MouseLeave:Connect(function() hovered, pressed = false, false update() end)
	hit.SelectionGained:Connect(function() focused = true update() end)
	hit.SelectionLost:Connect(function() focused, pressed = false, false update() end)
	hit.MouseButton1Down:Connect(function() pressed = true update() end)
	hit.MouseButton1Up:Connect(function() pressed = false update() end)
	hit.Activated:Connect(function() if enabled then callback() end end)
	function handle:setActive(active, tone, marked)
		marked = marked == true
		if enabled == active and selected == marked and (not tone or tone == currentTone) then return end
		enabled, currentTone, selected = active, tone or currentTone, marked
		hit.Active, hit.Selectable = active, active
		if not active then pressed = false end
		update()
	end
	return handle
end

function Components.Action(parent, name, text, tone, quiet, callback)
	local item = button(parent, name, tone, quiet, callback, 12)
	item.title = Components.label(item.face, "Label", text, 15, UDim2.fromOffset(6, 1),
		UDim2.new(1, -12, 1, -2), { align = Enum.TextXAlignment.Center, min = 9 })
	return item
end

function Components.Toggle(parent, name, quiet, callback)
	local item = Components.Action(parent, name, "", "gray", quiet, callback)
	return item, function(enabled, waiting, saving)
		item.title.Text = saving and "СОХРАНЯЕМ…" or (enabled and "●  ВКЛ." or "○  ВЫКЛ.")
		item:setActive(not waiting, enabled and "green" or "gray", enabled and not saving)
	end
end

function Components.PrimaryButton(parent, name, text, icon, quiet, callback)
	local item = button(parent, name, "green", quiet, callback, 17)
	Art.icon(item.face, icon, UDim2.new(0, 8, .5, -24), UDim2.fromOffset(48, 48), 5)
	item.title = Components.label(item.face, "Action", text, 23, UDim2.fromOffset(57, 1),
		UDim2.new(1, -64, 1, -2), { align = Enum.TextXAlignment.Center, min = 12, stroke = 2 })
	return item
end

function Components.IconButton(parent, name, text, icon, tone, quiet, callback)
	local item = button(parent, name, tone, quiet, callback, 14)
	local image = Art.icon(item.face, icon, UDim2.new(.5, 0, 0, 3), UDim2.new(1, -8, 1, -23), 5)
	image.AnchorPoint = Vector2.new(.5, 0)
	item.title = Components.label(item.face, "Caption", text, 14, UDim2.new(0, 2, 1, -20),
		UDim2.new(1, -4, 0, 18), { align = Enum.TextXAlignment.Center, min = 9 })
	return item
end

function Components.CurrencyCounter(parent, name, caption, icon, tone, quiet, formatter)
	local root, face = Components.Panel(parent, name, tone, 14)
	local inset = new("Frame", face, { Name = "ValueWell", Position = UDim2.fromOffset(38, 7),
		Size = UDim2.new(1, -44, 1, -14), BackgroundColor3 = ink, BackgroundTransparency = .23,
		BorderSizePixel = 0, ZIndex = 4 })
	round(inset, 8)
	Art.icon(face, icon, UDim2.new(0, -5, .5, -24), UDim2.fromOffset(48, 48), 6)
	local title = Components.label(inset, "Caption", caption, 10, UDim2.fromOffset(7, 0), UDim2.new(1, -13, 0, 14), { stroke = false, min = 8 })
	local value = Components.label(inset, "Value", "—", 23, UDim2.fromOffset(7, 12),
		UDim2.new(1, -13, 1, -12), { min = 12 })
	local scale = new("UIScale", value, { Scale = 1 })
	local shown, animation
	return root, function(number)
		if number == shown then return end
		local previous = shown
		shown = number
		value.Text = number and formatter(number) or "—"
		if animation then animation:Cancel() end
		scale.Scale = previous ~= nil and not quiet() and 1.075 or 1
		if scale.Scale ~= 1 then animation = tween(scale, .20, { Scale = 1 }) end
	end, title
end

function Components.ProgressBar(parent, name, tone, quiet)
	local track = new("Frame", parent, { Name = name, BackgroundColor3 = ink, BorderSizePixel = 0,
		ClipsDescendants = true, ZIndex = 4 })
	round(track, 9)
	local colors = Components.tones[tone]
	local fill = new("Frame", track, { Name = "Fill", Size = UDim2.fromScale(0, 1),
		BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, ZIndex = 5 })
	round(fill, 9)
	gradient(fill, colors[1], colors[2])
	local current, animation
	return track, function(ratio)
		ratio = math.clamp(ratio, 0, 1)
		if current == ratio then return end
		if animation then animation:Cancel() end
		local extent = UDim2.fromScale(ratio, 1)
		if current == nil or quiet() then fill.Size = extent else animation = tween(fill, .18, { Size = extent }) end
		current = ratio
	end
end

function Components.StatusBadge(parent, name, text, tone)
	local root, face = Components.Panel(parent, name, tone, 10)
	local label = Components.label(face, "Label", text, 13, UDim2.fromOffset(6, 0),
		UDim2.new(1, -12, 1, 0), { align = Enum.TextXAlignment.Center, min = 9 })
	return root, label
end

function Components.Notification(parent, quiet)
	local root, face = Components.Panel(parent, "Notification", "dark", 15)
	root.Visible = false
	local accent = new("Frame", face, { Name = "Accent", Position = UDim2.fromOffset(7, 7),
		Size = UDim2.new(0, 5, 1, -14), BorderSizePixel = 0, ZIndex = 5 })
	round(accent, 3)
	local icons = {}
	for _, icon in { "Coins", "Power", "Progress", "Team", "Shop", "Ball", "GoldBall", "Settings" } do
		local image = Art.icon(face, icon, UDim2.fromOffset(13, 4), UDim2.fromOffset(34, 34), 6)
		image.Visible = false
		icons[icon] = image
	end
	local label = Components.label(face, "Message", "", 15, UDim2.fromOffset(53, 3),
		UDim2.new(1, -62, 1, -6), { wrap = true, min = 11, stroke = false })
	local scale = new("UIScale", face, { Scale = 1 })
	local id, animation, lock = 0, nil, 0
	return root, function(text, tone, icon, priority)
		if not priority and os.clock() < lock then return end
		if priority then lock = os.clock() + 1.1 end
		id += 1
		local revision = id
		for key, image in icons do image.Visible = key == (icon or "Progress") end
		if animation then animation:Cancel() end
		accent.BackgroundColor3 = Components.tones[tone or "blue"][1]
		label.Text, root.Visible = text, true
		scale.Scale = quiet() and 1 or .94
		if scale.Scale ~= 1 then animation = tween(scale, .17, { Scale = 1 }) end
		task.delay(priority and 2.7 or 1.15, function() if revision == id then root.Visible = false end end)
	end
end

function Components.ItemCard(parent, name, title, detail, icon, tone)
	local root, face = Components.Panel(parent, name, tone, 14)
	Art.icon(face, icon, UDim2.fromOffset(8, 7), UDim2.fromOffset(43, 43), 5)
	Components.label(face, "Title", title, 19, UDim2.fromOffset(57, 5), UDim2.new(1, -65, 0, 25))
	Components.label(face, "Detail", detail, 13, UDim2.fromOffset(57, 29), UDim2.new(1, -65, 0, 20), { stroke = 1 })
	return root, face
end

function Components.Modal(parent, name, title, quiet, onClose)
	local layer = new("Frame", parent, { Name = name, Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1, Visible = false, ZIndex = 14 })
	local dim = new("TextButton", layer, { Name = "Scrim", Size = UDim2.fromScale(1, 1), Text = "",
		BackgroundColor3 = black, BackgroundTransparency = .43, AutoButtonColor = false, Selectable = false, ZIndex = 1 })
	local panel, face = Components.Panel(layer, "Window", "dark", 21)
	panel.AnchorPoint, panel.Position = Vector2.new(.5, .5), UDim2.fromScale(.5, .5)
	local scale = new("UIScale", panel, { Scale = 1 })
	local heading = Components.label(face, "Title", title, 23, UDim2.fromOffset(15, 7), UDim2.new(1, -64, 0, 35))
	local close = button(face, "Close", "gray", quiet, onClose, 11)
	close.root.Position, close.root.Size = UDim2.new(1, -46, 0, 7), UDim2.fromOffset(38, 37)
	Components.label(close.face, "Cross", "×", 23, UDim2.fromScale(0, 0), UDim2.fromScale(1, 1),
		{ align = Enum.TextXAlignment.Center })
	dim.Activated:Connect(onClose)
	local motion, revision
	return {
		layer = layer, panel = panel, face = face, close = close.hit, heading = heading,
		setOpen = function(open)
			revision = (revision or 0) + 1
			local expected = revision
			if motion then motion:Cancel() end
			if quiet() then
				layer.Visible, scale.Scale = open, 1
			elseif open then
				layer.Visible, scale.Scale = true, .94
				motion = tween(scale, .16, { Scale = 1 })
			else
				motion = tween(scale, .12, { Scale = .95 })
				motion.Completed:Once(function(state)
					if revision == expected and state == Enum.PlaybackState.Completed then layer.Visible = false end
				end)
			end
		end,
	}
end

return Components
