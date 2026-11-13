local ProximityPromptService = game:GetService("ProximityPromptService")
local UserInputService = game:GetService("UserInputService")
local C = require(script.Parent.Components)
local Art = require(script.Parent.Art)

local Prompts = {}
local specs = {
	ShopSign = { "Shop", "red" },
	TeamBench = { "Team", "blue" },
	DailyBoard = { "Progress", "purple" },
	TrickBoard = { "GoldBall", "purple" },
	RhythmStation = { "Power", "cyan" },
}
local gamepadKeys = { ButtonX = "X", ButtonL1 = "LB" }

local function getAnchor(prompt)
	local attachment = prompt.Parent
	local anchor = attachment and attachment.Parent
	if anchor and specs[anchor.Name] and anchor:IsDescendantOf(workspace)
		and anchor:FindFirstAncestor("FootballCampus") then
		return anchor
	end
end

local function shortcut(prompt)
	local input = UserInputService.PreferredInput
	if input == Enum.PreferredInput.Gamepad then return gamepadKeys[prompt.GamepadKeyCode.Name] or "" end
	if input == Enum.PreferredInput.Touch then return "" end
	return prompt.KeyboardKeyCode.Name
end

function Prompts.bind(hud)
	local root = C.new("Frame", hud.field, { Name = "InteractionPrompts", BackgroundTransparency = 1, Visible = false })
	local shown, watched, active = {}, {}, {}
	local buttons = {}
	local function activate(index)
		local prompt = active[index]
		if not prompt or not prompt.Parent or not prompt.Enabled or hud.page or hud.menuOpen then return end
		prompt:InputHoldBegin()
		task.defer(function() if prompt.Parent then prompt:InputHoldEnd() end end)
	end
	for i = 1, 2 do
		local button = C.Action(root, "Prompt" .. i, "", "blue", hud.quiet, function() activate(i) end)
		button.title.Position = UDim2.fromOffset(33, 1)
		button.title.Size = UDim2.new(1, -38, 1, -2)
		button.title.TextXAlignment = Enum.TextXAlignment.Left
		button.hit.Selectable = false
		button.icons = {}
		for _, name in { "Shop", "Team", "Progress", "GoldBall", "Power", "Ball" } do
			local icon = Art.icon(button.face, name, UDim2.fromOffset(3, 4), UDim2.fromOffset(28, 28), 5)
			icon.Visible = false
			button.icons[name] = icon
		end
		buttons[i] = button
	end
	local controller = {}
	function controller:layout(short, portrait, bottom, dockWidth)
		local busy = hud:isTraining() or hud.freePractice or hud.rhythmOverlay.root.Visible
		local stacked = short and busy
		local height = 43
		local width = stacked and 155 or math.min(dockWidth + 44, hud.field.AbsoluteSize.X - 22, 380)
		local half = #active > 1 and not stacked
		root.Size = UDim2.fromOffset(width, stacked and 90 or height)
		root.AnchorPoint = stacked and Vector2.zero or Vector2.new(.5, 1)
		root.Position = stacked and UDim2.fromOffset(12, 71)
			or UDim2.new(.5, 0, 1, -bottom - (busy and 188 or 13))
		if portrait and busy then
			root.Position, root.AnchorPoint = UDim2.new(.5, 0, 0, 82), Vector2.new(.5, 0)
		end
		for i, button in buttons do
			button.root.Size = UDim2.new(half and .5 or 1, half and -3 or 0, 0, height)
			button.root.Position = half and UDim2.new((i - 1) * .5, (i - 1) * 3, 0, 0)
				or UDim2.fromOffset(0, stacked and (i - 1) * 47 or 0)
		end
	end
	local function refresh()
		table.clear(active)
		local character = game:GetService("Players").LocalPlayer.Character
		local origin = character and character:GetPivot().Position
		local nearest, distance = nil, math.huge
		for prompt, anchor in shown do
			if prompt.Enabled and prompt.Parent then
				local d = origin and (origin - anchor.Position).Magnitude or 0
				if d < distance then nearest, distance = anchor, d end
			end
		end
		for prompt, anchor in shown do
			if anchor == nearest and prompt.Enabled and prompt.Parent then table.insert(active, prompt) end
		end
		if #active > 1 and active[1].Name == "FreePracticePrompt" then active[1], active[2] = active[2], active[1] end
		for i, button in buttons do
			local prompt = active[i]
			button.root.Visible = prompt ~= nil
			if prompt then
				local anchor = shown[prompt]
				local spec = specs[anchor.Name]
				local icon = prompt.Name == "FreePracticePrompt" and "Ball" or spec[1]
				local tone = prompt.Name == "FreePracticePrompt" and "green" or spec[2]
				for name, image in button.icons do image.Visible = name == icon end
				local key = shortcut(prompt)
				button.title.Text = (key ~= "" and key .. " · " or "") .. prompt.ActionText
				button:setActive(true, tone)
				button.hit.Selectable = UserInputService.PreferredInput == Enum.PreferredInput.Gamepad
			end
		end
		hud.worldPromptActive = #active > 0
		hud:updateDock()
	end
	local function glow(anchor, nearby)
		local part = anchor:FindFirstChild("InteractionGlow", true)
			or (anchor.Parent and anchor.Parent:FindFirstChild("InteractionGlow"))
		if not part or not part:IsA("BasePart") then return end
		local transparency = nearby and .04 or .35
		if hud.quiet() then part.Transparency = transparency
		else C.tween(part, .18, { Transparency = transparency }) end
	end
	function controller:update()
		root.Visible = #active > 0 and not hud.page and not hud.menuOpen and not hud.goalVisible and hud.phase == "ready"
		controller:layout(hud.shortLayout, hud.portraitLayout, hud.dockBottom, hud.dockWidth)
	end
	local function watch(prompt)
		if not prompt:IsA("ProximityPrompt") or watched[prompt] or not getAnchor(prompt) then return end
		prompt.Style = Enum.ProximityPromptStyle.Custom
		watched[prompt] = prompt:GetPropertyChangedSignal("ActionText"):Connect(function()
			if shown[prompt] then refresh() end
		end)
	end
	ProximityPromptService.PromptShown:Connect(function(prompt)
		local anchor = getAnchor(prompt)
		if anchor then
			shown[prompt] = anchor
			glow(anchor, true)
			refresh()
		end
	end)
	ProximityPromptService.PromptHidden:Connect(function(prompt)
		local anchor = shown[prompt]
		if anchor then shown[prompt] = nil glow(anchor, false) refresh() end
	end)
	workspace.DescendantAdded:Connect(watch)
	workspace.DescendantRemoving:Connect(function(object)
		local connection = watched[object]
		if connection then connection:Disconnect() watched[object] = nil end
		if shown[object] then shown[object] = nil refresh() end
	end)
	UserInputService:GetPropertyChangedSignal("PreferredInput"):Connect(refresh)
	local campus = workspace:FindFirstChild("FootballCampus")
	if campus then for _, object in campus:GetDescendants() do watch(object) end end
	return controller
end

return Prompts
