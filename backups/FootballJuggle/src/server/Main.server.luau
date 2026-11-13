local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")

local shared = ReplicatedStorage:WaitForChild("Juggle")
local Balance = require(shared:WaitForChild("Balance"))
local ClubRules = require(shared:WaitForChild("ClubRules"))
local GoalRules = require(shared:WaitForChild("GoalRules"))
local Profiles = require(script.Parent:WaitForChild("Profiles"))
local Pitch = require(script.Parent:WaitForChild("Pitch"))
local ClubMap = require(script.Parent:WaitForChild("ClubMap"))
local CampusArt = require(script.Parent:WaitForChild("CampusArt"))
local GoalShot = require(script.Parent:WaitForChild("GoalShot"))
local campus = CampusArt.build()
local districts = campus.ClubDistricts
local pads = campus.TrainingPads

local rhythmStation = districts.Academy.RhythmStation
local rhythmInteraction = rhythmStation.Interaction
local rhythmPrompt = rhythmInteraction.ProximityPrompt
local stationPosition = rhythmInteraction.WorldPosition
local rhythmHome = Vector3.new(stationPosition.X - 2.15, (districts.Academy:GetAttribute("RhythmFloorY") or GoalRules.GroundY) + GoalRules.BallRadius, stationPosition.Z)
local goalHome = Vector3.new(GoalRules.X, GoalRules.GroundY + GoalRules.BallRadius, GoalRules.BallZ)
rhythmInteraction.Position = rhythmStation.CFrame:PointToObjectSpace(rhythmHome + Vector3.yAxis * 0.55)
rhythmPrompt.MaxActivationDistance = 5.5
rhythmPrompt.ObjectText = "ТРЕНИРОВОЧНЫЙ МЯЧ"
local freePrompt = rhythmPrompt:Clone()
freePrompt.Name = "FreePracticePrompt"
freePrompt.ActionText = "Свободное набивание"
freePrompt.KeyboardKeyCode = Enum.KeyCode.G
freePrompt.GamepadKeyCode = Enum.KeyCode.ButtonL1
freePrompt.UIOffset = Vector2.new(0, 56)
freePrompt.Parent = rhythmInteraction

local ballStations = Instance.new("Folder")
ballStations.Name = "BallStations"
ballStations:SetAttribute("RhythmHome", rhythmHome)
ballStations:SetAttribute("RhythmOwner", 0)
ballStations:SetAttribute("PracticeMode", "")
ballStations:SetAttribute("GoalPreparing", 0)
ballStations:SetAttribute("GoalOwner", 0)
ballStations:SetAttribute("GoalStart", 0)
ballStations:SetAttribute("GoalPower", 1)
ballStations.Parent = shared
local rhythmOwner, goalClaim

local remote = Instance.new("RemoteEvent")
remote.Name = "Action"
remote.Parent = shared

local records = {}
local occupied = {}
local shuttingDown = false
local coinCap = 9e15
local kickRate = 14
local kickBurst = 5

local upgrades = {
	boots = { cap = Balance.BootMax, price = Balance.bootPrice },
	frequency = { cap = Balance.FrequencyMax, price = Balance.frequencyPrice },
	multiplier = { cap = Balance.MultiplierMax, price = Balance.multiplierPrice },
}

local function status(record, message, effect)
	if record.closing or not record.player.Parent then
		return
	end
	local round = record.rhythm
	local rhythm = round and {
		id = round.id, start = round.start, finish = round.finish, window = round.window,
		nextBeat = round.nextBeat, combo = round.combo, gained = round.gained, last = round.last,
	} or record.rhythmResult
	remote:FireClient(record.player, "state", record.phase, record.data, message, effect, Profiles.studioMemory, rhythm,
		record.freePractice == true)
end

local function finishPractice(record, time, cancelled)
	if rhythmOwner ~= record then return end
	rhythmOwner = nil
	record.freePractice = nil
	ballStations:SetAttribute("RhythmOwner", 0)
	ballStations:SetAttribute("PracticeMode", "")
	rhythmPrompt.ActionText = "Начать тренировку"
	freePrompt.ActionText = "Свободное набивание"

	local round = record.rhythm
	record.rhythm = nil
	if round then
		if not cancelled then ClubRules.expireBeats(round, time) end
		local score = ClubRules.score(round)
		if not cancelled then
			local club = record.data.club
			club.rhythmBest = math.max(club.rhythmBest, score)
		end
		record.rhythmResult = {
			id = round.id, ended = time, score = score, gained = round.gained,
			bestCombo = round.bestCombo, cancelled = cancelled,
		}
	end
	status(record)
end

local function releaseGoal(claim)
	if claim and goalClaim == claim then
		goalClaim = nil
		ballStations:SetAttribute("GoalPreparing", 0)
		ballStations:SetAttribute("GoalOwner", 0)
		if claim.id and not claim.record.closing and claim.record.player.Parent then
			remote:FireClient(claim.record.player, "goalCancelled", claim.id)
		end
	end
end

local function releaseBalls(record)
	finishPractice(record, workspace:GetServerTimeNow(), true)
	if goalClaim and goalClaim.record == record then
		releaseGoal(goalClaim)
	end
end

local function canPractice(player)
	local root = ClubMap.aliveRoot(player)
	if not root or not ClubMap.inAcademy(districts, player) then return false end
	local offset = root.Position - rhythmHome
	return offset.X ^ 2 + offset.Z ^ 2 <= 6.5 ^ 2
end

local function alignToBall(root, home)
	local humanoid = root.Parent:FindFirstChildOfClass("Humanoid")
	local height = humanoid.HipHeight + root.Size.Y / 2
	if humanoid.RigType == Enum.HumanoidRigType.R6 then
		local leg = root.Parent:FindFirstChild("Left Leg")
		height += leg and leg.Size.Y or 2
	end
	-- Match the starting stance used by the procedural kick.
	local position = Vector3.new(home.X - 0.77, home.Y - GoalRules.BallRadius + height, home.Z + 1.12)
	root.CFrame = CFrame.lookAlong(position, -Vector3.zAxis)
	root.AssemblyLinearVelocity = Vector3.zero
end

local function refreshPower(record)
	local data = record.data
	record.player:SetAttribute("KickPower", Balance.goalDamage(data.boots, data.trainingPower))
end

local function refreshPartner(record)
	local data = record.data
	record.player:SetAttribute("JugglePartner", data.active)
	record.player:SetAttribute("JugglePartnerLevel", data.levels[data.active] or 0)
end

local function placeAvatar(record, character)
	local root = character:WaitForChild("HumanoidRootPart", 8)
	local humanoid = character:WaitForChild("Humanoid", 8)
	if root and humanoid and record.player.Character == character and record.character ~= character and not record.closing then
		if record.deathConnection then record.deathConnection:Disconnect() end
		record.character = character
		record.deathConnection = humanoid.Died:Connect(function()
			if record.character == character then releaseBalls(record) end
		end)
		local offset = record.slot > 30 and Vector3.new(1.7, 0, -1.7) or Vector3.zero
		character:PivotTo(record.pad.Marker.CFrame + offset)
		record.player:SetAttribute("JuggleDistrict", ClubMap.district(districts, root))
	end
end

local function load(record)
	if record.loading or record.closing then
		return
	end
	record.loading = true
	record.phase = "loading"
	status(record)
	local data = Profiles.load(record.player.UserId, record.token)
	if record.closing then
		if data then
			Profiles.save(record.player.UserId, record.token, data, true)
		end
		record.loading = false
		return
	end
	record.loading = false
	if not data then
		record.phase = "failed"
		status(record, "Не удалось загрузить прогресс. Попробуйте ещё раз.")
		return
	end
	record.data = data
	refreshPower(record)
	ClubRules.roll(data.club, ClubRules.day(os.time()))
	record.phase = "ready"
	record.lastSaved = os.clock()
	record.nextPay = os.clock() + 1
	refreshPartner(record)
	status(record)
end

local function join(player)
	if records[player] or shuttingDown then
		return
	end
	local slot = 1
	while occupied[slot] do
		slot += 1
	end
	occupied[slot] = true
	local record = {
		player = player,
		token = HttpService:GenerateGUID(false),
		phase = "loading",
		slot = slot,
		pad = Pitch.pad(pads, (slot - 1) % 30 + 1),
		hits = 0,
		motion = 0,
		tokens = kickBurst,
		lastKick = os.clock(),
		lastKickSequence = 0,
		rhythmId = 0,
		lastGoalSequence = 0,
		lastGoalCommand = -math.huge,
		nextGoalShot = 0,
		goalRespawnAt = 0,
		lastCommand = -math.huge,
		lastSync = -math.huge,
		lastPrompt = -math.huge,
	}
	records[player] = record
	player:SetAttribute("JuggleSlot", slot)
	record.characterConnection = player.CharacterAdded:Connect(function(character)
		placeAvatar(record, character)
	end)
	record.removingConnection = player.CharacterRemoving:Connect(function(character)
		if record.character == character then
			releaseBalls(record)
			record.character = nil
			record.deathConnection:Disconnect()
			record.deathConnection = nil
		end
	end)
	if player.Character then
		task.spawn(placeAvatar, record, player.Character)
	end
	task.spawn(load, record)
end

local function save(record, release)
	if record.phase ~= "ready" then
		return
	end
	if record.saving then
		if not release then
			return
		end
		repeat task.wait() until not record.saving
	end
	if record.phase ~= "ready" or (record.closing and not release) then
		return
	end
	record.saving = true
	local success, lost = Profiles.save(record.player.UserId, record.token, record.data, release)
	record.saving = false
	if success then
		record.lastSaved = os.clock()
	elseif not release and (lost or os.clock() - record.lastSaved >= 150) then
		releaseBalls(record)
		record.phase = "locked"
		record.data = nil
		status(record, "Связь с хранилищем потеряна. Перезайдите, чтобы защитить прогресс.")
	end
end

local function leave(player)
	local record = records[player]
	if not record or record.closing then
		return
	end
	record.closing = true
	record.characterConnection:Disconnect()
	record.removingConnection:Disconnect()
	if record.deathConnection then record.deathConnection:Disconnect() end
	releaseBalls(record)
	occupied[record.slot] = nil
	if record.slot <= 6 then
		Pitch.updateTrainingRing(record.pad)
	end
	while record.loading do
		task.wait()
	end
	save(record, true)
	records[player] = nil
end

local function publishKickMotion(record, trick)
	record.motion += 1
	record.player:SetAttribute("JuggleMotion", record.motion * 4 + trick)
end

local function kick(record)
	local now = os.clock()
	record.tokens = math.min(kickBurst, record.tokens + (now - record.lastKick) * kickRate)
	record.lastKick = now
	local character = record.player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if record.tokens < 1 or not humanoid or humanoid.Health <= 0 then
		return
	end
	record.tokens -= 1
	local data = record.data
	local power = Balance.kickPower(data.boots)
	data.progress += 1
	local gold = data.progress == Balance.interval(data.frequency)
	if gold then
		power *= Balance.multiplier(data.multiplier)
		data.progress = 0
	end
	data.coins = math.min(coinCap, data.coins + power)
	ClubRules.roll(data.club, ClubRules.day(os.time()))
	ClubRules.onKick(data.club, gold, data.active)
	record.hits += 1
	local trick = gold and data.club.trick or 0
	publishKickMotion(record, trick)
	record.player:SetAttribute("JuggleHit", record.hits * 2 + (gold and 1 or 0))
	status(record, nil, { kind = "kick", coins = power, gold = gold, hit = record.hits, trick = trick,
		multiplier = gold and Balance.multiplier(data.multiplier) or nil })
end

local function rhythmTap(record, id, sequence)
	local round = record.rhythm
	if not round or id ~= round.id or not ClubRules.isNewKick(sequence, round.lastSequence) then return end
	round.lastSequence = sequence
	local now = workspace:GetServerTimeNow()
	if now < round.nextTap then return end
	round.nextTap = now + ClubRules.RhythmTapInterval
	if rhythmOwner ~= record or not canPractice(record.player) then return end

	-- GetNetworkPing reports round-trip latency. Judge against the server clock.
	local result = ClubRules.beat(round, now, record.player:GetNetworkPing() / 2)
	if not result then return end
	publishKickMotion(record, 0)
	local data = record.data
	local gain = math.min(ClubRules.RhythmPower[result.grade], Balance.TrainingPowerMax - data.trainingPower)
	if gain > 0 then
		data.trainingPower += gain
		round.gained += gain
		refreshPower(record)
	end
	result.gain = gain
	status(record)
end

local function clubCommand(record, action, target, expected)
	local data = record.data
	local club = data.club
	local day = ClubRules.day(os.time())
	local rolled = ClubRules.roll(club, day)
	if action == "trick" and (target == 1 or (target == 2 and club.gold >= ClubRules.GoldForHeel)) then
		club.trick = target
		status(record, "Выбран финт: " .. ClubRules.Tricks[target])
	elseif data.owned > 0 and action == "dailyChoose" and expected == day and ClubRules.choose(club, day, target) then
		status(record, "Задание дня принято")
	elseif data.owned > 0 and action == "dailyClaim" and expected == day and ClubRules.claim(club, day) then
		status(record, "Получена клубная отметка")
	elseif rolled then
		status(record)
	end
end

local function bindPrompt(item, callback, alternate)
	local interaction = item.Interaction
	local prompt = alternate or interaction.ProximityPrompt
	local range = item:GetAttribute("CircleRadius") or prompt.MaxActivationDistance + 2
	prompt.Triggered:Connect(function(player)
		local record = records[player]
		local root = ClubMap.aliveRoot(player)
		local now = os.clock()
		if not record or record.closing or record.phase ~= "ready" or not root
			or (root.Position - interaction.WorldPosition).Magnitude > range or now - record.lastPrompt < 0.6 then
			return
		end
		record.lastPrompt = now
		callback(record, root)
	end)
end

local function requireClub(record)
	if record.data.owned > 0 then
		return true
	end
	status(record, "Подпишите первого футболиста, чтобы открыть клуб")
	return false
end

bindPrompt(districts.TeamCourt.TeamBench, function(record)
	if requireClub(record) then
		remote:FireClient(record.player, "clubOpen", "team", "contracts")
	end
end)
bindPrompt(districts.ClubAlley.DailyBoard, function(record)
	if requireClub(record) then
		remote:FireClient(record.player, "clubOpen", "club", "daily")
	end
end)
bindPrompt(districts.TrickCourt.TrickBoard, function(record)
	local data = record.data
	if data.club.gold > 0 or data.boots > 0 or data.owned > 0 then
		remote:FireClient(record.player, "clubOpen", "club", "tricks")
	else
		status(record, "Сделайте первый золотой удар, чтобы выбрать финт")
	end
end)
bindPrompt(districts.BootShop.ShopSign, function(record)
	if not record.rhythm then
		remote:FireClient(record.player, "clubOpen", "shop")
	end
end)
local function startPractice(record, root, timed)
	if rhythmOwner == record then
		local sameMode = (record.rhythm ~= nil) == timed
		finishPractice(record, workspace:GetServerTimeNow(), true)
		if sameMode then return end
	elseif rhythmOwner then
		status(record, "Тренировочный мяч занят")
		return
	end
	if not canPractice(record.player) or (goalClaim and goalClaim.record == record) then
		return
	end
	alignToBall(root, rhythmHome)
	record.rhythmResult = nil
	if timed then
		record.rhythmId += 1
		record.rhythm = ClubRules.newRhythm(workspace:GetServerTimeNow(), record.data.active, record.rhythmId)
		rhythmPrompt.ActionText = "Закончить тренировку"
	else
		record.freePractice = true
		freePrompt.ActionText = "Закончить набивание"
	end
	rhythmOwner = record
	ballStations:SetAttribute("PracticeMode", timed and "rhythm" or "free")
	ballStations:SetAttribute("RhythmOwner", record.player.UserId)
	remote:FireClient(record.player, "clubOpen")
	status(record)
end

bindPrompt(rhythmStation, function(record, root)
	startPractice(record, root, true)
end)
bindPrompt(rhythmStation, function(record, root)
	startPractice(record, root, false)
end, freePrompt)

local function command(record, action, target, expected)
	local data = record.data
	local price
	local change
	local upgrade = upgrades[action]
	if upgrade then
		local current = data[action]
		if target ~= current + 1 or current >= upgrade.cap then
			return
		end
		price = upgrade.price(current)
		change = function()
			data[action] = target
			if action == "frequency" then
				data.progress = math.min(data.progress, Balance.interval(target) - 1)
			elseif action == "boots" then
				refreshPower(record)
			end
		end
	elseif action == "sign" and target == data.owned + 1 and target <= Balance.RankMax then
		price = Balance.contractPrice(target)
		change = function()
			data.owned = target
			data.active = target
			data.levels[target] = 1
			refreshPartner(record)
		end
	elseif action == "train" and target == data.active and data.active > 0 then
		local current = data.levels[target]
		if expected ~= current + 1 or current >= Balance.PlayerLevelMax then
			return
		end
		price = Balance.playerUpgradePrice(target, current)
		change = function()
			data.levels[target] = expected
			refreshPartner(record)
		end
	elseif action == "equip" and data.levels[target] then
		data.active = target
		refreshPartner(record)
		status(record, "Футболист вышел на поле")
		return
	elseif (action == "muted" or action == "quiet") and type(target) == "boolean" then
		data[action] = target
		status(record)
		return
	else
		return
	end

	if data.coins < price then
		status(record, "Пока не хватает монет")
		return
	end
	data.coins -= price
	change()
	local message = action == "sign" and ("Подписан №" .. (31 - target) .. " · " .. Balance.playerName(target))
		or "Улучшение куплено!"
	status(record, message, { kind = action == "sign" and "sign" or "upgrade" })
end

local function goalCommand(record, action, id)
	local player = record.player
	local claim = goalClaim
	if action == "goalCancel" then
		if claim and claim.record == record and claim.id == id then releaseGoal(claim) end
		return
	end

	local now = workspace:GetServerTimeNow()
	if now - record.lastGoalCommand < 0.08 then return end
	record.lastGoalCommand = now
	if action == "goalPrepare" then
		if not ClubRules.isNewKick(id, record.lastGoalSequence) then return end
		record.lastGoalSequence = id
		local root = ClubMap.aliveRoot(player)
		if claim or record.phase ~= "ready" or rhythmOwner == record or not GoalShot.canStart(record, root, now) then
			remote:FireClient(player, "goalCancelled", id)
			return
		end
		local startsAt = now + GoalRules.PowerStartLead
		local expiresAt = startsAt + GoalRules.PowerTimeout
		goalClaim = { record = record, id = id, level = record.data.goals.level, startsAt = startsAt, expiresAt = expiresAt }
		ballStations:SetAttribute("GoalPreparing", player.UserId)
		remote:FireClient(player, "goalReady", id, startsAt, expiresAt)
		return
	end

	if not claim or claim.record ~= record or not claim.id or claim.id ~= id then return end
	local root = ClubMap.aliveRoot(player)
	local inputTime = now - math.clamp(player:GetNetworkPing() / 2, 0, GoalRules.PowerLatencyCap)
	if record.phase ~= "ready" or rhythmOwner == record or inputTime > claim.expiresAt
		or not GoalShot.canStart(record, root, now) then
		releaseGoal(claim)
		return
	end
	if inputTime - claim.startsAt < GoalRules.PowerMinTime then
		remote:FireClient(player, "goalReady", id, claim.startsAt, claim.expiresAt)
		return
	end

	local multiplier = GoalRules.powerBand(GoalRules.powerHeight(inputTime - claim.startsAt))
	local shot = GoalShot.apply(record, root, claim.level, multiplier, coinCap, now)
	if not shot then
		releaseGoal(claim)
		return
	end
	local flight = { record = record }
	goalClaim = flight
	ballStations:SetAttribute("GoalPower", shot.multiplier)
	ballStations:SetAttribute("GoalStart", shot.startedAt)
	ballStations:SetAttribute("GoalOwner", player.UserId)
	ballStations:SetAttribute("GoalPreparing", 0)
	alignToBall(root, goalHome)
	task.delay(math.max(0, shot.impactAt - workspace:GetServerTimeNow()), function()
		releaseGoal(flight)
	end)
	shot.id = id
	remote:FireClient(player, "goalHit", shot)
	if shot.remaining == 0 then status(record) end
end

remote.OnServerEvent:Connect(function(player, action, target, expected, ...)
	local record = records[player]
	if not record or record.closing or type(action) ~= "string" then
		return
	end
	if action == "rhythmTap" then
		if record.phase == "ready" then
			rhythmTap(record, target, expected)
		end
		return
	end
	if action == "kick" then
		if record.phase == "ready" and rhythmOwner == record and record.freePractice
			and ClubRules.isNewKick(target, record.lastKickSequence) and canPractice(player) then
			record.lastKickSequence = target
			kick(record)
		end
		return
	end
	if action == "goalPrepare" or action == "goalShoot" or action == "goalCancel" then
		if type(target) == "number" and expected == nil and select("#", ...) == 0 then
			goalCommand(record, action, target)
		end
		return
	end
	local now = os.clock()
	if action == "sync" or action == "retry" then
		if now - record.lastSync < 0.8 then
			return
		end
		record.lastSync = now
		if action == "retry" and record.phase == "failed" then
			task.spawn(load, record)
		else
			status(record)
		end
		return
	end
	if record.phase == "ready" and now - record.lastCommand >= 0.08 then
		record.lastCommand = now
		if type(target) == "number" and (target % 1 ~= 0 or target < 1 or target > Balance.RankMax) then
			return
		end
		if type(target) == "number" or type(target) == "boolean" then
			if action == "trick" or action == "dailyChoose" or action == "dailyClaim" then
				clubCommand(record, action, target, expected)
			else
				command(record, action, target, expected)
			end
		end
	end
end)

Players.PlayerAdded:Connect(join)
Players.PlayerRemoving:Connect(leave)
for _, player in Players:GetPlayers() do
	join(player)
end

task.spawn(function()
	while not shuttingDown do
		task.wait(0.25)
		local now = os.clock()
		for _, record in records do
			if record.phase == "ready" and not record.closing and now >= record.nextPay then
				local seconds = math.floor(now - record.nextPay) + 1
				record.nextPay += seconds
				local data = record.data
				local income = Balance.income(data.active, data.levels[data.active] or 0)
				if income > 0 then
					data.coins = math.min(coinCap, data.coins + income * seconds)
					status(record)
				end
			end
		end
	end
end)

task.spawn(function()
	while not shuttingDown do
		task.wait(0.2)
		local time = workspace:GetServerTimeNow()
		local day = ClubRules.day(os.time())
		local claim = goalClaim
		if claim and claim.id then
			local record = claim.record
			local root = ClubMap.aliveRoot(record.player)
			if record.phase ~= "ready" or not root or not GoalRules.canReachBall(root.Position)
				or time > claim.expiresAt + GoalRules.PowerLatencyCap then
				releaseGoal(claim)
			end
		end
		for _, record in records do
			if record.phase ~= "ready" or record.closing then
				continue
			end
			local root = ClubMap.aliveRoot(record.player)
			if root then
				local district = ClubMap.district(districts, root)
				if record.player:GetAttribute("JuggleDistrict") ~= district then
					record.player:SetAttribute("JuggleDistrict", district)
				end
			end
			if record.slot <= 6 then
				Pitch.updateTrainingRing(record.pad, root, Balance.pitchTier(record.data.owned).tint)
			end
			local changed = ClubRules.roll(record.data.club, day)
			local round = record.rhythm
			if rhythmOwner == record then
				local inside = canPractice(record.player)
				if not inside or (round and time >= round.finish) then
					finishPractice(record, time, not inside)
					continue
				elseif round and ClubRules.expireBeats(round, time) then
					changed = true
				end
			end
			if changed then
				status(record)
			end
		end
	end
end)

task.spawn(function()
	while not shuttingDown do
		task.wait(5)
		for _, record in records do
			if record.phase == "ready" and not record.closing and os.clock() - record.lastSaved >= 45 then
				task.spawn(save, record, false)
			end
		end
	end
end)

game:BindToClose(function()
	shuttingDown = true
	for player in records do
		task.spawn(leave, player)
	end
	local deadline = os.clock() + 27
	while next(records) and os.clock() < deadline do
		task.wait()
	end
end)
