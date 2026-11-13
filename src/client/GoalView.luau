local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local shared = game:GetService("ReplicatedStorage"):WaitForChild("Juggle")
local Balance = require(shared:WaitForChild("Balance"))
local Rules = require(shared:WaitForChild("GoalRules"))
local ballStations = shared:WaitForChild("BallStations")
local Ui = require(script.Parent:WaitForChild("UiKit"))
local ShotGauge = require(script.Parent:WaitForChild("ShotGauge"))

local GoalView = {}
GoalView.__index = GoalView

local palette = Ui.palette
local center = Enum.TextXAlignment.Center
local bold = Enum.Font.GothamBlack
local cream = Color3.fromRGB(245, 255, 232)
local frameGlow = Color3.fromRGB(255, 191, 60)
local hpRed = Color3.fromRGB(255, 76, 106)
local origin = ballStations:GetAttribute("GoalOrigin") or CFrame.new(Rules.X, Rules.GroundY, Rules.GoalZ)
local target = ballStations:GetAttribute("GoalTarget") or origin:PointToWorldSpace(Vector3.new(0, Rules.TargetHeight, 0))
local goalTemplate = if ballStations:GetAttribute("GoalOrigin") then shared:WaitForChild("StadiumGoalVisual") else nil
local accents = { palette.cyan, palette.lime, palette.gold, Color3.fromRGB(168, 160, 255) }

local function formatHP(value)
	local fraction = math.round((value % 1) * 10)
	return Ui.amount(value) .. (fraction > 0 and value < 1e6 and ("." .. fraction) or "")
end

local function part(parent, name, size, cf, tint, transparency, shape)
	return Ui.create("Part", parent, {
		Name = name, Size = size, CFrame = cf, Color = tint, Shape = shape or Enum.PartType.Block,
		Transparency = transparency or 0, Material = Enum.Material.SmoothPlastic, Anchored = true,
		CanCollide = false, CanTouch = false, CanQuery = false, CastShadow = false,
	})
end

local function bar(parent, name, a, b, width, tint, transparency, pipe)
	local direction = b - a
	local up = math.abs(direction.Unit.Y) > 0.99 and Vector3.zAxis or Vector3.yAxis
	local cf = origin * CFrame.lookAt((a + b) / 2, b, up)
	local length = direction.Magnitude
	if pipe then
		return part(parent, name, Vector3.new(length, width, width), cf * CFrame.Angles(0, math.pi / 2, 0),
			tint, transparency, Enum.PartType.Cylinder)
	end
	return part(parent, name, Vector3.new(width, width, length), cf, tint, transparency)
end

local function buildFrame(model, tint)
	local width, height, depth = 8.15, 7.05, -3.7
	for _, x in { -width, width } do
		local post = bar(model, "Post", Vector3.new(x, 0.18, 0), Vector3.new(x, height, 0), 0.52, cream, 0, true)
		post.Material = Enum.Material.Metal
		bar(model, "PostLight", Vector3.new(x, 0.94, 0.27), Vector3.new(x, height, 0.27),
			0.125, frameGlow, 0, true).Material = Enum.Material.Neon
		bar(model, "PostCuff", Vector3.new(x, 0.25, 0), Vector3.new(x, 1.12, 0), 0.64, tint, 0, true)
		for _, y in { 1.22, height - 0.50 } do
			bar(model, "TrimRing", Vector3.new(x, y - 0.055, 0), Vector3.new(x, y + 0.055, 0), 0.57, tint, 0, true)
		end
		bar(model, "SideSupport", Vector3.new(x, height, 0), Vector3.new(x, 0.35, depth), 0.17, tint, 0.10, true)
		bar(model, "BaseRail", Vector3.new(x, 0.28, 0), Vector3.new(x, 0.28, depth), 0.20, cream, 0.15, true)
		part(model, "Joint", Vector3.one * 0.50, origin * CFrame.new(x, height, 0), cream, 0, Enum.PartType.Ball)
		for step = 1, 3 do
			local z = depth * step / 4
			bar(model, "NetSide", Vector3.new(x, 0.3, z), Vector3.new(x, height * (1 - step / 4), z), 0.045, cream, 0.39)
		end
	end
	local crossbar = bar(model, "Crossbar", Vector3.new(-width, height, 0), Vector3.new(width, height, 0), 0.52, cream, 0, true)
	crossbar.Material = Enum.Material.Metal
	bar(model, "CrossbarStripe", Vector3.new(-width, height, 0.27), Vector3.new(width, height, 0.27), 0.125, frameGlow, 0, true).Material = Enum.Material.Neon
	bar(model, "RearRail", Vector3.new(-width, 0.30, depth), Vector3.new(width, 0.30, depth), 0.19, tint, 0, true)
	for step = 0, 18 do
		local x = -width + step / 18 * width * 2
		bar(model, "NetWeave", Vector3.new(x, height, 0), Vector3.new(x, 0.30, depth), 0.060, cream, 0.23)
	end
	for step = 1, 8 do
		local f = step / 9
		local y, z = 0.30 + f * (height - 0.30), depth * (1 - f)
		bar(model, "NetWeave", Vector3.new(-width, y, z), Vector3.new(width, y, z), 0.061, cream, 0.23)
	end
end

local function billboard(parent, name, at, size, distance)
	local marker = part(parent, name, Vector3.one * 0.1, CFrame.new(at), cream, 1)
	local gui = Ui.create("BillboardGui", Players.LocalPlayer.PlayerGui, {
		Name = name, Adornee = marker, Size = UDim2.fromOffset(size.X, size.Y),
		MaxDistance = distance, ResetOnSpawn = false,
	})
	marker.Destroying:Once(function() gui:Destroy() end)
	return gui, marker
end

function GoalView:show(level, hp, entering)
	if self.model then
		self.model:Destroy()
	end
	local model = Instance.new("Model")
	model.Name = "PersonalGoal"
	model:SetAttribute("GoalLevel", level)
	model:SetAttribute("GoalHP", hp)
	local tint = accents[math.floor((level - 1) / 5) % #accents + 1]
	local finished = hp == 0
	if not finished then
		if goalTemplate then
			local visual = goalTemplate:Clone()
			visual.Parent = model
		else
			buildFrame(model, tint)
		end
	end
	model.Parent = self.folder

	local gui = billboard(model, "GoalHealth", origin:PointToWorldSpace(Vector3.new(0, finished and 3.6 or 9.63, 0.40)),
		Vector2.new(190, 60), 112)
	self.model = model
	if self.hud.makeGoalHealth then
		self.renderHealth = self.hud:makeGoalHealth(gui, level, finished)
	else
		gui.Size = UDim2.fromScale(16.4, 3.55)
		local panel = Ui.panel(gui, "Panel", palette.dark, 9)
		panel.Size = UDim2.fromScale(1, 1)
		panel.BackgroundTransparency = 0.03
		panel:FindFirstChildOfClass("UIStroke").Color = frameGlow
		local title = Ui.place(panel, finished and "ПЛОЩАДКА ПРОЙДЕНА" or ("ВОРОТА · УР. " .. Ui.amount(level)), 15, palette.white,
			UDim2.fromScale(0.04, 0.06), UDim2.fromScale(0.92, 0.36), center, bold)
		self.hpLabel = Ui.place(panel, "", 15, palette.white, UDim2.fromScale(0.04, 0.43), UDim2.fromScale(0.92, 0.26), center, bold)
		for _, label in { title, self.hpLabel } do
			label.TextScaled = true
			Ui.create("UITextSizeConstraint", label, { MinTextSize = 8, MaxTextSize = 25 })
		end
		self.fill = Ui.meter(panel, UDim2.fromScale(0.065, 0.76), UDim2.fromScale(0.87, 0.13), hpRed)
	end
	self:setHP(level, hp, true)
	if finished and not self.renderHealth then
		self.hpLabel.Text = Ui.amount(level) .. " / " .. Ui.amount(Rules.MaxLevel)
		self.fill.Size = UDim2.fromScale(1, 1)
	end

	if entering and not self.effects.quiet then
		for _, piece in model:GetDescendants() do
			if piece:IsA("BasePart") and piece.Transparency < 1 then
				local rest = piece.CFrame
				piece.CFrame -= Vector3.yAxis * 0.52
				Ui.tween(piece, 0.19, { CFrame = rest })
			end
		end
	end
end

function GoalView:setHP(level, hp, immediate)
	local maximum = Rules.maxHP(level)
	self.model:SetAttribute("GoalHP", hp)
	if self.renderHealth then self.renderHealth(hp, maximum) return end
	self.hpLabel.Text = formatHP(hp) .. " / " .. Ui.amount(maximum) .. " HP"
	local size = UDim2.fromScale(hp / maximum, 1)
	if self.healthTween then
		self.healthTween:Cancel()
		self.healthTween = nil
	end
	if immediate or self.effects.quiet then
		self.fill.Size = size
	else
		self.healthTween = Ui.tween(self.fill, 0.15, { Size = size })
	end
end

function GoalView:popup(text, color, offset, size)
	local gui, marker = billboard(self.folder, "GoalFeedback", target + origin:VectorToWorldSpace(offset), Vector2.new(245, 53), 64)
	local label = Ui.place(gui, text, size, color, UDim2.fromScale(0, 0), UDim2.fromScale(1, 1), center, bold)
	label.TextStrokeColor3 = palette.dark
	label.TextStrokeTransparency = 0.1
	local duration = self.effects.quiet and 0.42 or 0.63
	if not self.effects.quiet then
		Ui.tween(marker, duration, { Position = marker.Position + Vector3.yAxis * 1.9 })
	end
	Ui.tween(label, duration, { TextTransparency = 1, TextStrokeTransparency = 1 })
	task.delay(duration, function() marker:Destroy() end)
end

function GoalView.new(hud, effects, send)
	local self = setmetatable({
		hud = hud, effects = effects, send = send, sequence = 0, nextShot = 0, respawnAt = 0, revision = 0,
	}, GoalView)
	self.folder = Ui.create("Folder", workspace, { Name = "LocalGoalCourse" })
	if hud.makeShotGauge then
		self.gauge = hud:makeShotGauge()
	else
		self.gauge = ShotGauge.new(hud.field, hud.dock, effects)
		effects.onShotContact = function(multiplier)
			if multiplier == 2 then self.gauge:flashPerfect() end
		end
	end
	if hud.makeGoalButton then
		self.renderButton = hud:makeGoalButton(function() self:requestShot() end)
	else
		self.renderButton = self:legacyButton(hud.dock)
	end

	local elapsed = 0
	RunService.Heartbeat:Connect(function(delta)
		elapsed += delta
		if elapsed >= 0.10 then
			elapsed = 0
			self:updateButton()
		end
	end)
	RunService.RenderStepped:Connect(function()
		local selection = self.selection
		if selection and selection.stage == "aiming" then
			self.gauge:update(workspace:GetServerTimeNow() - selection.startsAt)
		end
	end)
	return self
end

function GoalView:legacyButton(dock)
	local button = Ui.button(dock, "", 15, palette.cyan, palette.dark)
	button.Name = "ShootGoal"
	button.AnchorPoint = Vector2.new(0.5, 1)
	button.Position = UDim2.new(0.5, 0, 0, -35)
	button.Size = UDim2.new(1, 0, 0, 49)
	button.Visible = false
	Ui.outline(button, palette.cyan)
	local caption = Ui.place(button, "", 14, palette.dark, UDim2.fromOffset(6, 5), UDim2.new(1, -12, 0, 20), center, bold)
	Ui.fit(caption, 10, 14)
	local power = Ui.place(button, "", 11, palette.dark, UDim2.fromOffset(6, 26), UDim2.new(1, -12, 0, 16), center)
	button.Activated:Connect(function() self:requestShot() end)
	return function(visible, ready, text, powerText)
		button.Visible = visible
		if not visible then return end
		Ui.setAction(button, "", ready, palette.cyan)
		caption.Text, power.Text = text, powerText
		caption.TextColor3 = ready and palette.dark or palette.white
		power.TextColor3 = ready and palette.dark or palette.soft
	end
end

function GoalView:aimRoot()
	local character = Players.LocalPlayer.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if self.hud.page == nil and not self.hud.menuOpen and self.hud.phase == "ready" and not self.hud:isTraining() and not self.hud.freePractice and root and humanoid
		and humanoid.Health > 0 and Rules.canShoot(root.Position, origin) then
		return root
	end
end

function GoalView:isReplacing()
	return workspace:GetServerTimeNow() < self.respawnAt
		or not self.model or self.model:GetAttribute("GoalLevel") ~= self.goals.level
end

function GoalView:updateButton()
	local goals = self.goals
	local root = self:aimRoot()
	local now = workspace:GetServerTimeNow()
	local nearBall = root and Rules.canReachBall(root.Position, origin)
	local selection = self.selection
	if selection and (not nearBall or now > selection.deadline) then
		self:cancelSelection(true)
		selection = nil
	end
	local visible = goals ~= nil and root ~= nil
	if not visible then
		self.renderButton(false)
		return
	end
	local input = UserInputService.PreferredInput
	local shortcut = input == Enum.PreferredInput.Gamepad and "  ·  Y"
		or (input == Enum.PreferredInput.KeyboardAndMouse and "  ·  Q" or "")
	local waiting = self:isReplacing()
	local finished = goals.hp == 0
	local occupied = ballStations:GetAttribute("GoalOwner") ~= 0 or ballStations:GetAttribute("GoalPreparing") ~= 0
	local canLock = selection and selection.stage == "aiming" and now - selection.startsAt >= Rules.PowerMinTime
	local ready = nearBall and (canLock or (not selection and not waiting and not finished and not occupied and now >= self.nextShot))
	local caption
	if selection then
		if selection.stage == "waiting" then
			caption = "ПОДГОТОВКА…"
		elseif selection.stage == "aiming" then
			caption = "ЗАФИКСИРОВАТЬ" .. shortcut
		else
			caption = "УДАР…"
		end
	elseif waiting then
		caption = "СЛЕДУЮЩИЕ ВОРОТА…"
	elseif finished then
		caption = "ПЛОЩАДКА ПРОЙДЕНА"
	elseif not nearBall then
		caption = "ПОДОЙДИ К МЯЧУ НА ПОЛЕ"
	elseif occupied or now < self.nextShot then
		caption = "МЯЧ В ИГРЕ"
	else
		caption = "ВЫБРАТЬ МОЩНОСТЬ" .. shortcut
	end
	local power = "Сила удара  " .. Ui.amount(Balance.goalDamage(self.hud.data.boots, self.hud.data.trainingPower))
	self.renderButton(true, ready == true, caption, power)
end

function GoalView:setProfile(data)
	if not data then
		self:cancelSelection(true)
		if self.goals then
			self.revision += 1
			self.goals = nil
			self.model = nil
			self.folder:ClearAllChildren()
		end
	elseif not self.goals then
		self.goals = { level = data.goals.level, hp = data.goals.hp }
		self:show(self.goals.level, self.goals.hp, false)
	end
end

function GoalView:cancelSelection(notify)
	local selection = self.selection
	if not selection then return end
	self.selection = nil
	if selection.stage == "aiming" then self.gauge:show(false) end
	if notify then self.send("goalCancel", selection.id) end
end

function GoalView:cancelled(id)
	if self.selection and self.selection.id == id then
		self:cancelSelection(false)
		self:updateButton()
	end
end

function GoalView:ready(id, startsAt, expiresAt)
	local selection = self.selection
	if not selection or selection.id ~= id or selection.stage == "aiming" then return end
	selection.stage, selection.startsAt, selection.deadline = "aiming", startsAt, expiresAt
	self.gauge:update(workspace:GetServerTimeNow() - startsAt)
	self.gauge:show(true)
	self:updateButton()
end

function GoalView:requestShot()
	local goals = self.goals
	local now = workspace:GetServerTimeNow()
	local root = self:aimRoot()
	local selection = self.selection
	if selection then
		if not root or not Rules.canReachBall(root.Position, origin) or now > selection.deadline then
			self:cancelSelection(true)
		elseif selection.stage == "aiming" and now - selection.startsAt >= Rules.PowerMinTime then
			selection.stage, selection.deadline = "committing", now + 1.5
			self.gauge:update(now - selection.startsAt)
			self.gauge:show(false)
			self.send("goalShoot", selection.id)
		end
		self:updateButton()
		return
	end
	if not goals or goals.hp == 0 or now < self.nextShot or self:isReplacing()
		or not root or not Rules.canReachBall(root.Position, origin) or ballStations:GetAttribute("GoalOwner") ~= 0
		or ballStations:GetAttribute("GoalPreparing") ~= 0 then
		return
	end
	self.sequence += 1
	self.selection = { id = self.sequence, stage = "waiting", deadline = now + 1.5 }
	self.send("goalPrepare", self.sequence)
	self:updateButton()
end

function GoalView:confirm(shot)
	if not self.goals then
		return
	end
	self:cancelled(shot.id)
	self.nextShot = shot.startedAt + Rules.ShotInterval
	self.goals.level, self.goals.hp = shot.nextLevel, shot.nextHP
	self.respawnAt = shot.respawnAt
	local revision = self.revision
	local broken = shot.remaining == 0
	task.delay(math.max(0, shot.impactAt - workspace:GetServerTimeNow()), function()
		if self.revision ~= revision then
			return
		end
		self:setHP(shot.level, shot.remaining, broken)
		local tint = self.effects:goalImpact(shot.multiplier, broken)
		if self.hud.goalImpact then
			self.hud:goalImpact(shot, formatHP(shot.damage))
		else
			self:popup("−" .. formatHP(shot.damage), tint, Vector3.new(0, 0.65, 0.55), 31)
		end
		if broken then
			self.model:Destroy()
			self.model = nil
			if shot.reward > 0 and not self.hud.goalImpact then
				self:popup("+" .. Ui.amount(shot.reward) .. " монет", palette.lime, Vector3.new(0, 2.3, 0.70), 24)
			end
			task.delay(math.max(0, shot.respawnAt - workspace:GetServerTimeNow()), function()
				if self.revision == revision then
					self:show(shot.nextLevel, shot.nextHP, true)
				end
			end)
		end
	end)
end

return GoalView
