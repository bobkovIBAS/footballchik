local TweenService = game:GetService("TweenService")

local Ui = {}
Ui.palette = {
	dark = Color3.fromRGB(11, 22, 30),
	panel = Color3.fromRGB(16, 32, 42),
	tile = Color3.fromRGB(24, 43, 53),
	line = Color3.fromRGB(52, 75, 85),
	white = Color3.fromRGB(245, 250, 248),
	soft = Color3.fromRGB(166, 190, 197),
	lime = Color3.fromRGB(187, 247, 101),
	gold = Color3.fromRGB(255, 205, 92),
	cyan = Color3.fromRGB(106, 230, 219),
	warn = Color3.fromRGB(255, 166, 116),
}

Ui.space = { small = 6, gap = 8, pad = 12, outer = 16 }
Ui.radius = { small = 8, button = 12, panel = 18 }
Ui.type = { micro = 11, body = 13, button = 14, section = 17, title = 24, hero = 28 }

function Ui.create(class, parent, props)
	local object = Instance.new(class)
	for name, value in props do
		object[name] = value
	end
	object.Parent = parent
	return object
end

function Ui.rounded(parent, radius)
	return Ui.create("UICorner", parent, { CornerRadius = UDim.new(0, radius or Ui.radius.button) })
end

function Ui.outline(parent, color)
	return Ui.create("UIStroke", parent, {
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Color = color or Ui.palette.line, Thickness = 1,
	})
end

function Ui.label(parent, text, size, color, align)
	return Ui.create("TextLabel", parent, {
		BackgroundTransparency = 1, Font = Enum.Font.GothamMedium,
		Text = text, TextSize = size or Ui.type.body, TextColor3 = color or Ui.palette.white,
		TextXAlignment = align or Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd,
	})
end

function Ui.button(parent, text, size, color, ink)
	local object = Ui.create("TextButton", parent, {
		BackgroundColor3 = color, BorderSizePixel = 0, Font = Enum.Font.GothamBold,
		Text = text, TextSize = size or Ui.type.button, TextColor3 = ink, AutoButtonColor = true,
		TextTruncate = Enum.TextTruncate.AtEnd,
	})
	Ui.rounded(object)
	return object
end

function Ui.panel(parent, name, color, radius)
	local object = Ui.create("Frame", parent, { Name = name, BackgroundColor3 = color or Ui.palette.panel, BorderSizePixel = 0 })
	Ui.rounded(object, radius or Ui.radius.panel)
	Ui.outline(object)
	return object
end

function Ui.card(parent, order, height, tint)
	local frame = Ui.panel(parent, "Card", Ui.palette.tile, 14)
	frame.LayoutOrder = order
	frame.Size = UDim2.new(1, -6, 0, height)
	local border = frame:FindFirstChildOfClass("UIStroke")
	if tint then
		border.Color = tint:Lerp(Ui.palette.line, 0.67)
		Ui.gradient(frame, Color3.new(1, 1, 1), Color3.fromRGB(183, 211, 214), 20)
	end
	return frame, border
end

function Ui.meter(parent, position, size, tint)
	local track = Ui.create("Frame", parent, {
		Position = position, Size = size, BackgroundColor3 = Ui.palette.dark, BorderSizePixel = 0, ClipsDescendants = true,
	})
	Ui.rounded(track, 5)
	local fill = Ui.create("Frame", track, { Size = UDim2.fromScale(0, 1), BackgroundColor3 = tint, BorderSizePixel = 0 })
	Ui.rounded(fill, 5)
	return fill
end

function Ui.gradient(parent, from, to, angle)
	return Ui.create("UIGradient", parent, { Color = ColorSequence.new(from, to), Rotation = angle or 0 })
end

function Ui.place(parent, text, size, color, position, extent, align, font)
	local object = Ui.label(parent, text, size, color, align)
	object.Position, object.Size = position, extent
	object.Font = font or object.Font
	return object
end

function Ui.fit(label, min, max)
	label.TextScaled = true
	Ui.create("UITextSizeConstraint", label, { MinTextSize = min, MaxTextSize = max })
end

function Ui.setAction(button, text, enabled, tint, selected)
	local p = Ui.palette
	button.Text = text
	button.Active = enabled
	button.Selectable = enabled
	button.AutoButtonColor = enabled
	button.BackgroundColor3 = enabled and tint or p.dark
	button.TextColor3 = enabled and p.dark or (selected and tint or p.soft)
end

function Ui.amount(value)
	for _, unit in { { 1e15, "квд" }, { 1e12, "трлн" }, { 1e9, "млрд" }, { 1e6, "млн" } } do
		if value >= unit[1] then
			return string.format("%.2f %s", value / unit[1], unit[2])
		end
	end
	local digits = tostring(math.floor(value))
	local spaced = digits:reverse():gsub("(%d%d%d)", "%1 "):reverse():gsub("^ ", "")
	return spaced
end

function Ui.tween(object, seconds, props)
	local animation = TweenService:Create(object, TweenInfo.new(seconds, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props)
	animation:Play()
	return animation
end

return Ui
