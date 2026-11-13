local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")
local shared = game:GetService("ReplicatedStorage"):WaitForChild("Juggle")
local Balance = require(shared:WaitForChild("Balance"))
local GoalRules = require(shared:WaitForChild("GoalRules"))

local Motion = require(script.Parent:WaitForChild("KickMotion"))

local Effects = {}
Effects.__index = Effects

local lime = Color3.fromRGB(180, 244, 88)
local gold = Color3.fromRGB(255, 203, 65)
local cyan = Color3.fromRGB(93, 228, 224)
local ink = Color3.fromRGB(18, 33, 42)
local white = Color3.fromRGB(248, 255, 247)
local cool = Color3.fromRGB(155, 255, 248)
local mint = Color3.fromRGB(152, 246, 121)
local amber = Color3.fromRGB(255, 154, 54)
local shotStyles = {
	{ color = white, tail = cool, life = 0.058, width = 0.42, opacity = 0.64,
		contact = 2, impact = 3, speed = 4, pitch = 1.14, volume = 0.24, arc = 1.12 },
	{ color = cool, tail = cyan, life = 0.10, width = 0.72, opacity = 0.41,
		contact = 4, impact = 6, speed = 7, pitch = 1.03, volume = 0.32, arc = 1.48 },
	{ color = mint, tail = cyan, life = 0.15, width = 0.96, opacity = 0.29,
		contact = 6, impact = 9, speed = 10, pitch = 0.91, volume = 0.40, arc = 1.78 },
	{ color = gold, tail = amber, life = 0.19, width = 1, opacity = 0.19,
		contact = 8, impact = 11, speed = 12, pitch = 0.81, volume = 0.48, arc = 1.98 },
}

local function shotStyle(power)
	return shotStyles[power == 2 and 4 or (power == 1.5 and 3 or (power == 1 and 2 or 1))]
end

local function piece(parent, name, size, color, shape)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.Color = color
	part.Shape = shape or Enum.PartType.Block
	part.Anchored = true
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = false
	part.CastShadow = false
	part.Parent = parent
	return part
end

local panelNormals = {
	Vector3.xAxis, -Vector3.xAxis, Vector3.yAxis, -Vector3.yAxis, Vector3.zAxis, -Vector3.zAxis,
	Vector3.new(1, 1, 1).Unit, Vector3.new(-1, -1, -1).Unit,
}

local function makeBall(parent, name, home)
	local model = Instance.new("Model")
	model.Name = name
	local center = piece(model, "Leather", Vector3.one * (2 * GoalRules.BallRadius), white, Enum.PartType.Ball)
	model.PrimaryPart = center
	local panels = {}
	for _, normal in panelNormals do
		local tangent = math.abs(normal.Y) > 0.8 and Vector3.zAxis or Vector3.yAxis
		local panel = piece(model, "Panel", Vector3.new(0.026, 0.30, 0.30), ink, Enum.PartType.Cylinder)
		panel.CFrame = CFrame.fromMatrix(normal * 0.423, normal, tangent:Cross(normal).Unit)
		table.insert(panels, panel)
	end
	local a = Instance.new("Attachment")
	a.Position = Vector3.new(0, 0.17, 0)
	a.Parent = center
	local b = Instance.new("Attachment")
	b.Position = Vector3.new(0, -0.17, 0)
	b.Parent = center
	local trail = Instance.new("Trail")
	trail.Attachment0 = a
	trail.Attachment1 = b
	trail.Color = ColorSequence.new(cyan, lime)
	trail.Transparency = NumberSequence.new(0.18, 1)
	trail.Lifetime = 0.20
	trail.FaceCamera = true
	trail.Enabled = false
	trail.Parent = center
	local frame = CFrame.new(home)
	model:PivotTo(frame)
	model.Parent = parent
	return { model = model, home = home, frame = frame, trail = trail, center = center, panels = panels }
end

local function dressTrainingBall(ball, isGold)
	if ball.gold == isGold then return end
	ball.gold = isGold
	ball.center.Color = isGold and gold or white
	ball.center.Material = isGold and Enum.Material.Neon or Enum.Material.SmoothPlastic
	for _, panel in ball.panels do
		panel.Color = isGold and Color3.fromRGB(112, 73, 20) or ink
	end
	ball.trail.Color = ColorSequence.new(gold, Color3.fromRGB(255, 143, 42))
end

local function showBall(ball, frame, trailOn)
	if ball.trail.Enabled ~= trailOn then
		ball.trail.Enabled = trailOn
		if not trailOn then ball.trail:Clear() end
	end
	if ball.frame ~= frame then
		ball.frame = frame
		ball.model:PivotTo(frame)
	end
end

local function shotEmitter(parent, name, position, impact)
	local anchor = piece(parent, name, Vector3.one * 0.05, white)
	anchor.CFrame = CFrame.new(position)
	anchor.Transparency = 1
	local particles = Instance.new("ParticleEmitter")
	particles.Name = "Sparks"
	particles.Enabled = false
	particles.Rate = 0
	particles.LightEmission = 0.65
	particles.LightInfluence = 0
	particles.Drag = 4
	particles.EmissionDirection = impact and Enum.NormalId.Back or Enum.NormalId.Top
	particles.SpreadAngle = Vector2.one * (impact and 75 or 60)
	particles.Lifetime = NumberRange.new(0.12, impact and 0.38 or 0.25)
	particles.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.06), NumberSequenceKeypoint.new(0.45, 0.25), NumberSequenceKeypoint.new(1, 1),
	})
	particles.Parent = anchor
	local sound = Instance.new("Sound")
	sound.SoundId = "rbxasset://sounds/action_jump_land.mp3"
	sound.RollOffMinDistance = impact and 15 or 7
	sound.RollOffMaxDistance = 55
	sound.Parent = anchor
	local flash = piece(parent, name .. "Flash", Vector3.one * 0.16, white, Enum.PartType.Ball)
	flash.Material = Enum.Material.Neon
	flash.Transparency = 1
	flash.CFrame = anchor.CFrame
	return { particles = particles, sound = sound, flash = flash }
end

local function emitShot(self, source, style, count, size, speed, pitch, volume, flashSize)
	local emitter = source.particles
	emitter.Color = ColorSequence.new(style.color, style.tail)
	emitter.Size = NumberSequence.new(size, 0.02)
	emitter.Speed = NumberRange.new(speed * 0.5, speed)
	emitter:Emit(self.quiet and math.min(2, count) or count)
	if not self.muted then
		local sound = source.sound
		sound.PlaybackSpeed, sound.Volume, sound.TimePosition = pitch, volume, 0
		sound:Play()
	end
	if flashSize and not self.quiet then
		if source.fade then source.fade:Cancel() end
		local flash = source.flash
		flash.Color, flash.Size, flash.Transparency = style.color, Vector3.one * 0.17, 0.28
		source.fade = TweenService:Create(flash, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Size = Vector3.one * flashSize, Transparency = 1,
		})
		source.fade:Play()
	end
end

local function makePartner(parent, rank, styleNameplate)
	local tier = Balance.tier(rank)
	local model = Instance.new("Model")
	model.Name = "Teammate"
	local skin = ({ Color3.fromRGB(246, 191, 139), Color3.fromRGB(169, 111, 75),
		Color3.fromRGB(221, 154, 107), Color3.fromRGB(112, 69, 55) })[(rank - 1) % 4 + 1]
	local jersey = tier.tint:Lerp(Color3.fromHSV((rank * 0.077) % 1, 0.72, 0.93), 0.20)
	local body = {}
	local function limb(name, size, color, x, y, z)
		local object = piece(model, name, size, color)
		body[name] = { part = object, at = CFrame.new(x, y, z) }
	end
	limb("Jersey", Vector3.new(1.38, 1.12, 0.70), jersey, 0, 2.02, 0)
	limb("Stripe", Vector3.new(0.19, 1.09, 0.06), white, -0.34, 2.02, -0.36)
	limb("Shorts", Vector3.new(1.35, 0.36, 0.71), ink, 0, 1.34, 0)
	limb("Head", Vector3.new(0.88, 0.82, 0.73), skin, 0, 3.00, 0)
	limb("Hair", Vector3.new(0.91, 0.25 + (rank % 3) * 0.04, 0.76), ink, 0, 3.40, 0.04)
	limb("LeftArm", Vector3.new(0.31, 0.96, 0.40), skin, -0.86, 2.02, 0)
	limb("RightArm", Vector3.new(0.31, 0.96, 0.40), skin, 0.86, 2.02, 0)
	for _, side in { -1, 1 } do
		local prefix = side == -1 and "Left" or "Right"
		limb(prefix .. "Thigh", Vector3.new(0.46, 0.54, 0.49), jersey, side * 0.35, 1.01, 0)
		limb(prefix .. "Shin", Vector3.new(0.36, 0.46, 0.40), white, side * 0.35, 0.55, 0)
	end
	limb("LeftBoot", Vector3.new(0.50, 0.26, 0.68), white, -0.35, 0.19, -0.11)
	limb("RightBoot", Vector3.new(0.50, 0.26, 0.68), white, 0.35, 0.19, -0.11)

	local name = Instance.new("BillboardGui")
	name.Name = "PlayerNumber"
	name.Adornee = body.Head.part
	name.Size = UDim2.fromOffset(112, 24)
	name.StudsOffsetWorldSpace = Vector3.new(0, 1.07, 0)
	name.MaxDistance = 30
	name.AlwaysOnTop = false
	name.Parent = model
	if styleNameplate then
		styleNameplate(name, "№" .. (31 - rank) .. "  " .. Balance.playerName(rank))
	else
		local title = Instance.new("TextLabel")
		title.Size = UDim2.fromScale(1, 1)
		title.BackgroundColor3 = ink
		title.BackgroundTransparency = 0.12
		title.Text = "№" .. (31 - rank) .. "  " .. Balance.playerName(rank)
		title.Font = Enum.Font.GothamBold
		title.TextColor3 = tier.tint
		title.TextSize = 13
		title.Parent = name
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 7)
		corner.Parent = title
	end
	model.Parent = parent
	return { model = model, body = body, rank = rank, entered = os.clock() }
end

local function groundFrame(root, humanoid)
	local direction = Vector3.new(root.CFrame.LookVector.X, 0, root.CFrame.LookVector.Z)
	local height = humanoid.HipHeight + root.Size.Y / 2
	if humanoid.RigType == Enum.HumanoidRigType.R6 then
		local leg = humanoid.Parent:FindFirstChild("Left Leg")
		height += leg and leg.Size.Y or 2
	end
	local foot = root.Position - Vector3.new(0, height, 0)
	return CFrame.lookAlong(foot, direction.Magnitude > 0.01 and direction or -Vector3.zAxis)
end

local function cleanup(record)
	if record.rig then
		Motion.restore(record.rig)
	end
	if record.container then
		record.container:Destroy()
	end
	record.character = nil
	record.container = nil
	record.partner = nil
	record.rig = nil
	record.started = nil
	record.trick = nil
	record.pending = nil
	record.contact = nil
	record.motionKind = nil
	record.nextSide = "Right"
	record.cancelledAt = nil
	record.lastGoalStart = nil
	record.rewardGui = nil
	record.priorityUntil = nil
end

local function startKick(record, now, trick, kind)
	record.started = now
	record.trick = trick
	record.motionKind = kind
	record.contact = nil
	record.cancelledAt = nil
	record.side = kind == "goal" and "Right" or record.nextSide
	if kind ~= "goal" then record.nextSide = record.side == "Right" and "Left" or "Right" end
end

local function enqueueKick(record, now, trick, kind)
	if not record.container or record.motionKind == "goal" then return end
	if record.started then
		if trick > 0 or record.pending == nil then
			record.pending = trick
		end
	else
		startKick(record, now, trick, kind)
	end
end

function Effects.new(player)
	local root = Instance.new("Folder")
	root.Name = "LocalJuggleEffects"
	root.Parent = workspace
	local sound = Instance.new("Sound")
	sound.Name = "JuggleKick"
	sound.SoundId = "rbxasset://sounds/action_jump_land.mp3"
	sound.Volume = 0.28
	sound.Parent = SoundService
	local stations = shared:WaitForChild("BallStations")
	local origin = stations:GetAttribute("GoalOrigin")
	local inward = origin and -origin.LookVector or Vector3.zAxis
	local goalHome = stations:GetAttribute("GoalHome")
	local goalTarget = stations:GetAttribute("GoalTarget") or Vector3.new(GoalRules.X, GoalRules.GroundY + GoalRules.TargetHeight, GoalRules.GoalZ)
	local self = setmetatable({
		player = player, root = root, sound = sound, actors = {}, stations = stations, quiet = false, muted = false,
		trainingBall = makeBall(root, "TrainingBall", stations:GetAttribute("RhythmHome")),
		goalBall = makeBall(root, "GoalBall", goalHome),
		goalTarget = goalTarget,
		contactFX = shotEmitter(root, "ShotContact", goalHome + inward * GoalRules.BallRadius, false),
		impactFX = shotEmitter(root, "ShotImpact", goalTarget + inward * 0.15, true),
	}, Effects)
	local function track(actor)
		self.actors[actor] = { seen = actor:GetAttribute("JuggleMotion") or 0 }
	end
	Players.PlayerAdded:Connect(track)
	Players.PlayerRemoving:Connect(function(actor)
		local record = self.actors[actor]
		if record then
			cleanup(record)
			self.actors[actor] = nil
		end
	end)
	for _, actor in Players:GetPlayers() do
		track(actor)
	end
	RunService.PreAnimation:Connect(function()
		for _, record in self.actors do
			if record.rig and next(record.rig.applied) then
				Motion.restore(record.rig)
			end
		end
	end)
	RunService.PreSimulation:Connect(function()
		local now = os.clock()
		for _, record in self.actors do
			if record.rig and record.started then
				local isShot = record.motionKind == "goal"
				local duration = isShot and Motion.ShotDuration or Motion.duration(record.trick)
				local age = isShot and workspace:GetServerTimeNow() - record.started or (record.cancelledAt or now) - record.started
				local phase = math.max(0, age / duration)
				if phase < 1 then
					local weight = record.cancelledAt and 1 - Motion.smooth((now - record.cancelledAt) / 0.13) or 1
					local rootPart = record.character:FindFirstChild("HumanoidRootPart")
					Motion.apply(record.rig, phase, record.trick, record.side, weight, rootPart and rootPart.CFrame,
						isShot and rootPart and self.goalBall.home)
				end
			end
		end
	end)
	RunService:BindToRenderStep("JugglePresentation", Enum.RenderPriority.Character.Value + 1, function()
		self:render()
	end)
	return self
end

function Effects:settings(muted, quiet)
	self.muted = muted
	self.quiet = quiet
end

function Effects:pop(record, text, color)
	if not record or not record.container then
		return
	end
	local priority = color == gold or color == cyan
	if record.rewardGui then
		if not priority and (record.priorityUntil or 0) > os.clock() then
			return
		end
		record.rewardGui:Destroy()
	end
	local pop = Instance.new("BillboardGui")
	record.rewardGui = pop
	record.priorityUntil = priority and os.clock() + 0.26 or nil
	pop.Name = "Reward"
	pop.Adornee = record.character:FindFirstChild("Head") or record.character:FindFirstChild("HumanoidRootPart")
	pop.Size = UDim2.fromOffset(127, 30)
	pop.StudsOffsetWorldSpace = Vector3.new(0, 0.55, 0)
	pop.MaxDistance = 36
	pop.AlwaysOnTop = false
	pop.Parent = record.container

	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = text
	label.Font = Enum.Font.GothamBlack
	label.TextSize = self.quiet and 17 or 22
	label.TextColor3 = color
	label.TextStrokeColor3 = ink
	label.TextStrokeTransparency = 0.12
	label.Parent = pop
	local info = TweenInfo.new(self.quiet and 0.30 or 0.53, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	TweenService:Create(pop, info, { StudsOffsetWorldSpace = Vector3.new(0, self.quiet and 0.92 or 1.38, 0) }):Play()
	TweenService:Create(label, info, { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
	task.delay(info.Time, function()
		if record.rewardGui == pop then
			record.rewardGui = nil
		end
		pop:Destroy()
	end)
end

function Effects:playSound(speed)
	if not self.muted then
		self.sound.PlaybackSpeed = speed
		self.sound.TimePosition = 0
		self.sound:Play()
	end
end

function Effects:goalImpact(multiplier, broken)
	local style = broken and shotStyles[4] or shotStyle(multiplier)
	local size = broken and 0.30 or (multiplier >= 1.5 and 0.21 or 0.15)
	emitShot(self, self.impactFX, style, broken and 16 or style.impact, size,
		broken and 16 or style.speed, broken and 0.68 or style.pitch * 0.95,
		broken and 0.52 or style.volume * 0.84, broken and 2.5 or (multiplier >= 1.5 and 1.27 or nil))
	return style.color
end

function Effects:reward(effect, hudFeedback)
	local record = self.actors[self.player]
	if effect.kind == "kick" and record then
		local suffix = effect.gold and ("  ×" .. effect.multiplier) or ""
		if not hudFeedback then self:pop(record, "+" .. effect.coins .. suffix, effect.gold and gold or lime) end
	elseif effect.kind == "sign" then
		self:playSound(1.72)
		if not hudFeedback then self:pop(record, "НОВЫЙ ИГРОК!", cyan) end
	else
		self:playSound(1.25)
	end
end

local function setup(record, character, root)
	cleanup(record)
	local container = Instance.new("Folder")
	container.Name = character.Name
	container.Parent = root
	record.container = container
	record.character = character
	record.rig = Motion.bind(character)
	record.nextRigScan = os.clock() + 0.25
end

local function animatePartner(partner, frame, now, quiet)
	local arrival = quiet and 1 or math.clamp((now - partner.entered) / 0.55, 0, 1)
	local base = frame * CFrame.new(4.5 + (1 - arrival) ^ 2 * 4.5, 0, 0.45)
	for _, member in partner.body do
		member.part.CFrame = base * member.at
	end
end

function Effects:render()
	local now = os.clock()
	local serverTime = workspace:GetServerTimeNow()
	local camera = workspace.CurrentCamera
	local rhythmOwner = self.stations:GetAttribute("RhythmOwner")
	local practiceMode = self.stations:GetAttribute("PracticeMode")
	local goalOwner = self.stations:GetAttribute("GoalOwner")
	local goalStart = self.stations:GetAttribute("GoalStart")
	local goalAge = serverTime - goalStart
	local shot = self.activeShot
	if goalOwner ~= 0 and (not shot or shot.start ~= goalStart) then
		local power = self.stations:GetAttribute("GoalPower")
		shot = { start = goalStart, owner = goalOwner, power = power, style = shotStyle(power) }
		self.activeShot = shot
	elseif shot and goalOwner == 0 and (not shot.contacted or goalAge > GoalRules.ShotWindup + GoalRules.FlightDuration + 0.04) then
		shot = nil
		self.activeShot = nil
	end
	local trainingFrame = CFrame.new(self.trainingBall.home)
	local goldTraining, trainingTrail, animatingTraining = false, false, false
	for actor, record in self.actors do
		local character = actor.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		local nearby = root and (actor == self.player or (camera and (camera.CFrame.Position - root.Position).Magnitude < 52))
		if not nearby or not humanoid or humanoid.Health <= 0 then
			record.seen = actor:GetAttribute("JuggleMotion") or 0
			if record.container then
				cleanup(record)
			end
			continue
		end
		if character ~= record.character then
			setup(record, character, self.root)
		elseif now >= record.nextRigScan then
			local hip = record.rig.joints.RightHip
			local right, left = record.rig.feet.Right, record.rig.feet.Left
			if not hip or not hip.motor.Parent or not right or not left or not right.Parent or not left.Parent then
				Motion.restore(record.rig)
				record.rig = Motion.bind(character)
			end
			record.nextRigScan = now + 0.35
		end

		local practicing = rhythmOwner == actor.UserId
		local takingShot = goalOwner == actor.UserId and goalAge < Motion.ShotDuration
		if (record.motionKind == "rhythm" or record.motionKind == "free")
			and (not practicing or record.motionKind ~= practiceMode) and not record.cancelledAt then
			record.pending, record.cancelledAt = nil, now
			self.trainingReturn = { from = self.trainingBall.frame, at = now }
		end
		if takingShot and record.lastGoalStart ~= goalStart then
			record.lastGoalStart = goalStart
			record.pending = nil
			startKick(record, goalStart, 0, "goal")
		end
		local packed = actor:GetAttribute("JuggleMotion") or 0
		local motionChanged = record.seen ~= packed
		record.seen = packed

		if record.started then
			local kind = record.motionKind
			local complete = if record.cancelledAt then now - record.cancelledAt >= 0.13
				elseif kind == "goal" then serverTime - record.started >= Motion.ShotDuration
				else now - record.started >= Motion.duration(record.trick)
			if complete then
				local pending = record.pending
				record.started, record.motionKind, record.pending, record.cancelledAt = nil, nil, nil, nil
				if pending and practicing and practiceMode == kind then startKick(record, now, pending, kind) end
			end
		end
		if motionChanged and practicing and practiceMode ~= "" then
			if record.cancelledAt then record.started, record.pending = nil, nil end
			enqueueKick(record, now, packed % 4, practiceMode)
		end
		local frame = groundFrame(root, humanoid)
		if record.started and practicing and not record.cancelledAt and record.motionKind == practiceMode then
			animatingTraining = true
			local trick = record.trick
			local phase = math.clamp((now - record.started) / Motion.duration(trick), 0, 1)
			local contactPhase = Motion.contact(trick)
			local contact = record.contact or Motion.trainingContact(record.rig, record.side, frame, trick)
			if phase >= contactPhase and not record.contact then
				record.contact = contact
				if actor == self.player then
					self:playSound(trick > 0 and 1.43 or 1.05)
				end
			end
			local lift = self.quiet and 0.83 or (trick > 0 and 1.66 or 1.18)
			local position, spin = Motion.ball(phase, self.trainingBall.home, contact, lift, trick, record.side, frame)
			local roll = frame.Rotation * CFrame.Angles(-spin, 0, 0) * frame.Rotation:Inverse()
			trainingFrame = CFrame.new(position) * roll
			goldTraining = trick > 0
			trainingTrail = goldTraining and phase >= contactPhase and not self.quiet
		end

		local rank = actor:GetAttribute("JugglePartner") or 0
		if record.partner and record.partner.rank ~= rank then
			record.partner.model:Destroy()
			record.partner = nil
		end
		if rank > 0 then
			if not record.partner then
				record.partner = makePartner(record.container, rank, self.styleNameplate)
			end
			animatePartner(record.partner, frame, now, self.quiet)
		end
	end
	if self.trainingReturn then
		local settle = (now - self.trainingReturn.at) / 0.14
		if not animatingTraining and settle < 1 then
			trainingFrame = self.trainingReturn.from:Lerp(trainingFrame, Motion.smooth(settle))
		else
			self.trainingReturn = nil
		end
	end
	dressTrainingBall(self.trainingBall, goldTraining)
	showBall(self.trainingBall, trainingFrame, trainingTrail)

	local goalFrame = CFrame.new(self.goalBall.home)
	local flying = false
	if shot and goalAge >= GoalRules.ShotWindup then
		local progress = (goalAge - GoalRules.ShotWindup) / GoalRules.FlightDuration
		local style = shot.style
		if not shot.contacted then
			shot.contacted = true
			local trail = self.goalBall.trail
			trail.Color, trail.Lifetime = ColorSequence.new(style.color, style.tail), style.life
			trail.WidthScale = NumberSequence.new(style.width, 0)
			trail.Transparency = NumberSequence.new(style.opacity, 1)
			if progress < 1 then
				emitShot(self, self.contactFX, style, style.contact, shot.power == 2 and 0.22 or 0.15,
					style.speed, style.pitch, style.volume, shot.power == 2 and 1.25 or nil)
				if shot.owner == self.player.UserId and self.onShotContact then self.onShotContact(shot.power) end
			end
		end
		if progress <= 1 + 0.04 / GoalRules.FlightDuration then
			flying = progress <= 1
			progress = math.min(1, progress)
			local height = self.quiet and 0.95 or style.arc
			local position = self.goalBall.home:Lerp(self.goalTarget, progress)
				+ Vector3.yAxis * (4 * progress * (1 - progress) * height)
			goalFrame = CFrame.new(position) * CFrame.Angles(-progress * 11, progress * 2.2, 0)
		end
	end
	showBall(self.goalBall, goalFrame, flying and not self.quiet)
end

return Effects
