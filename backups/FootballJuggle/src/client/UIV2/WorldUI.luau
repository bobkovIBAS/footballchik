local ProximityPromptService = game:GetService("ProximityPromptService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local WorldUI = {}

local function circleGlow(prompt)
	local anchor = prompt.Parent and prompt.Parent.Parent
	if anchor and anchor:GetAttribute("CircleRadius") and anchor.Parent then
		return anchor.Parent:FindFirstChild("InteractionGlow")
	end
end

function WorldUI.bind(hud, ui)
	if hud.bindWorldPrompts then hud:bindWorldPrompts() return end
	local active
	local function activate()
		local prompt = active
		if not prompt or not prompt.Parent or hud.page or hud.menuOpen then return end
		prompt:InputHoldBegin()
		task.defer(function() if prompt.Parent then prompt:InputHoldEnd() end end)
	end
	local button = ui.button(hud.field, "", 15, ui.palette.panel, ui.palette.white)
	button.Name = "AcademyPrompt"
	button.AnchorPoint = Vector2.new(.5, 0)
	button.Position, button.Size = UDim2.new(.5, 0, 0, 85), UDim2.new(1, -36, 0, 44)
	button.Visible, button.Selectable, button.ZIndex = false, false, 3
	ui.create("UISizeConstraint", button, { MaxSize = Vector2.new(248, 44) })
	local border = ui.outline(button, ui.palette.cyan)
	ui.fit(button, 11, 15)
	button.Activated:Connect(activate)
	local function render(text, color)
		button.Visible = text ~= nil
		if text then button.Text, border.Color = text, color end
	end
	local function highlight(glow, nearby)
		local alpha = nearby and .04 or .35
		if hud.data and hud.data.quiet then
			glow.Transparency = alpha
		else
			TweenService:Create(glow, TweenInfo.new(.18), { Transparency = alpha }):Play()
		end
	end
	ProximityPromptService.PromptShown:Connect(function(prompt, input)
		local glow = circleGlow(prompt)
		if not glow then return end
		active = prompt
		local shortcut = input == Enum.ProximityPromptInputType.Gamepad and "X  ·  "
			or input == Enum.ProximityPromptInputType.Keyboard and not UserInputService.TouchEnabled and "E  ·  " or ""
		render(shortcut .. prompt.ActionText, glow.Color)
		highlight(glow, true)
	end)
	ProximityPromptService.PromptHidden:Connect(function(prompt)
		local glow = circleGlow(prompt)
		if glow then highlight(glow, false) end
		if active == prompt then
			active = nil
			render(nil)
		end
	end)
end

return WorldUI
