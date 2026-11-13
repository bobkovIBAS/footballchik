local UserInputService = game:GetService("UserInputService")
local Balance = require(game:GetService("ReplicatedStorage"):WaitForChild("Juggle"):WaitForChild("Balance"))

local ClubRules = require(game:GetService("ReplicatedStorage").Juggle:WaitForChild("ClubRules"))
local Ui = require(script.Parent:WaitForChild("UiKit"))
local Clubhouse = require(script.Parent:WaitForChild("Clubhouse"))
local ClubUI = require(script.Parent:WaitForChild("ClubUI"))

local Hud = {}
Hud.__index = Hud

local p, space, typeSize = Ui.palette, Ui.space, Ui.type
local center, right = Enum.TextXAlignment.Center, Enum.TextXAlignment.Right
local bold, heavy = Enum.Font.GothamBold, Enum.Font.GothamBlack
local white = Color3.new(1, 1, 1)
local comboWindow = 1.8

local function makeWallet(self)
	local wallet = Ui.panel(self.field, "Score", p.panel, 15)
	Ui.gradient(wallet, white, Color3.fromRGB(182, 211, 216), 90)
	self.walletMarker = Ui.create("Frame", wallet, { Size = UDim2.fromOffset(4, 29), Position = UDim2.fromOffset(0, 13),
		BackgroundColor3 = p.lime, BorderSizePixel = 0 })
	Ui.rounded(self.walletMarker, 3)
	self.walletTitle = Ui.place(wallet, "НАБИВАЙ!  /  МОНЕТЫ", typeSize.micro, p.soft,
		UDim2.fromOffset(12, 5), UDim2.new(1, -22, 0, 16), nil, bold)
	self.coins = Ui.place(wallet, "0", typeSize.title, p.white, UDim2.fromOffset(12, 19), UDim2.new(1, -24, 0, 27), nil, heavy)
	self.income = Ui.place(wallet, "+0 / сек", typeSize.micro, p.cyan, UDim2.fromOffset(12, 47), UDim2.new(1, -24, 0, 14), nil, bold)
	self.walletScale = Ui.create("UIScale", wallet, { Scale = 1 })
	return wallet
end

local function makeMenu(self)
	local menu = Ui.button(self.field, "", typeSize.button, p.panel, p.white)
	menu.Name = "OpenClub"
	menu.AnchorPoint = Vector2.new(1, 0)
	Ui.outline(menu)
	for index = 1, 3 do
		local line = Ui.create("Frame", menu, {
			Position = UDim2.fromOffset(12, 15 + (index - 1) * 5), Size = UDim2.fromOffset(index == 2 and 14 or 11, 2),
			BackgroundColor3 = p.lime, BorderSizePixel = 0,
		})
		Ui.rounded(line, 2)
	end
	Ui.place(menu, "Клуб", typeSize.button, p.white, UDim2.fromOffset(34, 0), UDim2.new(1, -42, 1, 0), nil, bold)
	self.menuDot = Ui.create("Frame", menu, {
		AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -7, 0, 7), Size = UDim2.fromOffset(6, 6),
		BackgroundColor3 = p.gold, BorderSizePixel = 0, Visible = false,
	})
	Ui.rounded(self.menuDot, 6)
	menu.Activated:Connect(function()
		if self.phase == "ready" then
			self:open(self.lastPage or "shop")
		end
	end)
	return menu
end

local function makeDock(self)
	local dock = Ui.panel(self.field, "KickDock", p.panel, 16)
	Ui.gradient(dock, white, Color3.fromRGB(183, 206, 211), 90)
	self.goldLabel = Ui.place(dock, "ЗОЛОТОЙ МЯЧ", typeSize.micro, p.gold, UDim2.fromOffset(10, 6), UDim2.new(1, -72, 0, 14), nil, bold)
	self.goldCount = Ui.place(dock, "0 / 10", typeSize.micro, p.white, UDim2.new(1, -72, 0, 6), UDim2.fromOffset(62, 14), right, bold)
	local rail = Ui.create("Frame", dock, { Position = UDim2.fromOffset(10, 24), Size = UDim2.new(1, -20, 0, 5), BackgroundTransparency = 1 })
	self.segments = {}
	for index = 1, 10 do
		local segment = Ui.create("Frame", rail, { BorderSizePixel = 0, BackgroundColor3 = p.line })
		Ui.rounded(segment, 3)
		self.segments[index] = segment
	end
	local kick = Ui.button(dock, "НАБИВАТЬ", 19, p.lime, p.dark)
	kick.Name = "Kick"
	kick.Font = heavy
	kick.Position = UDim2.fromOffset(8, 36)
	kick.Size = UDim2.new(1, -16, 1, -44)
	Ui.gradient(kick, white, Color3.fromRGB(216, 231, 184), 90)
	self.kick = kick
	Ui.fit(kick, 11, 19)
	self.kickScale = Ui.create("UIScale", kick, { Scale = 1 })
	kick.Activated:Connect(function() self:requestKick() end)
	return dock
end

function Hud.new(playerGui, send)
	local self = setmetatable({ send = send, lastToast = 0, combo = 0, lastHit = 0 }, Hud)
	local gui = Ui.create("ScreenGui", playerGui, {
		Name = "JuggleHUD", ResetOnSpawn = false, DisplayOrder = 10, ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets, ClipToDeviceSafeArea = true,
	})
	local field = Ui.create("Frame", gui, { Name = "FieldHUD", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1 })
	self.field = field
	self.wallet = makeWallet(self)
	self.menu = makeMenu(self)
	self.dock = makeDock(self)

	self.comboBadge = Ui.panel(field, "Combo", p.dark, 12)
	self.comboBadge.Visible = false
	self.comboText = Ui.place(self.comboBadge, "", typeSize.micro, p.cyan, UDim2.fromOffset(5, 0), UDim2.new(1, -10, 1, 0), center, bold)

	self.toastFrame = Ui.panel(gui, "Feedback", p.panel, 14)
	self.toastFrame.Visible = false
	self.toastFrame.ZIndex = 5
	self.toastScale = Ui.create("UIScale", self.toastFrame, { Scale = 1 })
	self.toastBadge = Ui.place(self.toastFrame, "", typeSize.micro, p.lime, UDim2.fromOffset(12, 5), UDim2.new(1, -24, 0, 15), nil, bold)
	self.toastText = Ui.place(self.toastFrame, "", typeSize.body, p.white, UDim2.fromOffset(12, 20), UDim2.new(1, -24, 0, 24), nil, bold)
	Ui.fit(self.toastText, 10, typeSize.body)

	self.clubGuide = ClubUI.overlay(field, self.dock, Ui, function(page) self:open(page) end)
	self.clubhouse = Clubhouse.new(gui, send, function(page) self:open(page) end, Ui)
	field:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() self:layout() end)
	self:layout()
	self:setState("loading", nil, true)
	return self
end

function Hud:layout()
	local size = self.field.AbsoluteSize
	local narrow = size.X < 590
	local short = size.Y < 400 and size.X > size.Y
	local touch = UserInputService.TouchEnabled
	local shortTouch = touch and short
	local edge = narrow and space.pad or space.outer
	local walletWidth = shortTouch and 124 or (narrow and 155 or 181)
	self.wallet.Position = UDim2.fromOffset(edge, edge)
	self.wallet.Size = UDim2.fromOffset(walletWidth, shortTouch and 52 or 66)
	self.walletMarker.Position = UDim2.fromOffset(0, shortTouch and 10 or 13)
	self.walletMarker.Size = UDim2.fromOffset(4, shortTouch and 24 or 29)
	self.walletTitle.Text = shortTouch and "МОНЕТЫ" or "НАБИВАЙ!  /  МОНЕТЫ"
	self.walletTitle.Position = UDim2.fromOffset(12, shortTouch and 1 or 5)
	self.coins.Position = UDim2.fromOffset(12, shortTouch and 12 or 19)
	self.coins.TextSize = shortTouch and typeSize.section or typeSize.title
	self.income.Position = UDim2.fromOffset(12, shortTouch and 34 or 47)
	self.menu.Position = UDim2.new(1, -edge, 0, edge)
	self.menu.Size = UDim2.fromOffset(narrow and 90 or 103, 44)

	local portrait = touch and narrow and size.Y > size.X
	local dockWidth = narrow and math.clamp(math.floor(size.X * (portrait and 0.58 or 0.63)), 177, 275) or 326
	local dockHeight = (short or (portrait and size.Y < 620)) and 83 or 93
	local dockAnchor = short and 1 or 0.5
	local dockX = short and -(touch and 91 or edge) or 0
	local bottom = portrait and math.clamp(math.floor(size.Y * 0.11), 66, 83) or (short and 10 or 13)
	local dockY = -bottom
	self.dock.AnchorPoint = Vector2.new(dockAnchor, 1)
	self.dock.Position = UDim2.new(dockAnchor, dockX, 1, dockY)
	self.dock.Size = UDim2.fromOffset(dockWidth, dockHeight)
	if portrait then
		self.comboBadge.AnchorPoint = Vector2.new(1, 0)
		self.comboBadge.Position = UDim2.new(1, -edge, 0, edge + 52)
	else
		self.comboBadge.AnchorPoint = Vector2.new(dockAnchor, 1)
		self.comboBadge.Position = UDim2.new(dockAnchor, dockX, 1, dockY - dockHeight - 6)
	end
	self.comboBadge.Size = UDim2.fromOffset(128, 24)
	self.clubGuide.layout(edge, math.min(shortTouch and 174 or (narrow and 204 or 232),
		math.max(148, size.X - edge * 2)), shortTouch)
	self:positionToast()
end

function Hud:positionToast()
	local width = math.min(323, math.max(170, self.field.AbsoluteSize.X - 24))
	self.toastFrame.Size = UDim2.fromOffset(width, 51)
	if self.page then
		self.toastFrame.AnchorPoint = Vector2.new(0.5, 1)
		self.toastFrame.Position = UDim2.new(0.5, 0, 1, -9)
	else
		self.toastFrame.AnchorPoint = Vector2.new(1, 0)
		self.toastFrame.Position = UDim2.new(1, -12, 0, 64)
	end
end

function Hud:open(page, section)
	if page and self:isTraining() then return end
	self.page = page
	if page then
		self.lastPage = page
	end
	self.field.Visible = page == nil
	self.clubhouse:open(page, section)
	self.clubGuide.update(self.data, self.rhythm, page)
	self:positionToast()
end

function Hud:isTraining()
	return self.rhythm ~= nil and self.rhythm.start ~= nil
end

function Hud:requestKick()
	if self.page then
		return
	end
	if self.phase == "failed" then
		self.send("retry")
	elseif self.phase == "ready" then
		if self:isTraining() then
			local round = self.rhythm
			local index = ClubRules.beatIndex(round, workspace:GetServerTimeNow())
			if index < round.nextBeat or index > ClubRules.BeatCount or self.lastRhythmTap == index then
				return
			end
			self.lastRhythmTap = index
			self.send("rhythmTap", round.id)
		elseif self.freePractice then
			self.send("kick")
		else
			return
		end
		if not self.data.quiet then
			if self.kickTween then self.kickTween:Cancel() end
			self.kickScale.Scale = 0.976
			self.kickTween = Ui.tween(self.kickScale, 0.12, { Scale = 1 })
		end
	end
end

function Hud:confirm(effect)
	if effect.kind ~= "kick" then
		return
	end
	local now = os.clock()
	self.combo = now - (self.lastKickAt or 0) <= comboWindow and effect.hit == self.lastHit + 1 and self.combo + 1 or 1
	self.lastKickAt, self.lastHit = now, effect.hit
	self.comboText.Text = "КОМБО  /  " .. Ui.amount(self.combo)
	self.comboBadge.Visible = self.combo > 1 and not (self.rhythm and self.rhythm.start)
	if not self.expiringCombo then
		self.expiringCombo = true
		local function expire()
			local remaining = comboWindow - (os.clock() - self.lastKickAt)
			if remaining > 0 then
				task.delay(remaining, expire)
				return
			end
			self.expiringCombo = false
			self.combo = 0
			self.comboBadge.Visible = false
		end
		task.delay(comboWindow, expire)
	end
	if effect.gold and self.data and not self.data.quiet then
		if self.walletTween then self.walletTween:Cancel() end
		self.walletScale.Scale = 1.045
		self.walletTween = Ui.tween(self.walletScale, 0.20, { Scale = 1 })
	end
end

function Hud:toast(value, kind)
	self.lastToast += 1
	local id = self.lastToast
	local reward = value == "Получена клубная отметка"
	local badge = reward and "НАГРАДА ПОЛУЧЕНА" or (kind == "sign" and "НОВЫЙ КОНТРАКТ"
		or (kind == "upgrade" and "УЛУЧШЕНИЕ" or (self.phase == "failed" and "ПРОГРЕСС" or "КЛУБ")))
	self.toastBadge.Text = badge
	self.toastBadge.TextColor3 = reward and p.gold or (kind == "sign" and p.cyan or (self.phase == "failed" and p.warn or p.lime))
	self.toastText.Text = value
	self.toastFrame.Visible = true
	if self.toastTween then self.toastTween:Cancel() end
	self.toastScale.Scale = 1
	if self.data and not self.data.quiet then
		self.toastScale.Scale = 0.96
		self.toastTween = Ui.tween(self.toastScale, 0.16, { Scale = 1 })
	end
	task.delay(2.7, function()
		if self.lastToast == id then
			self.toastFrame.Visible = false
		end
	end)
end

function Hud:setState(phase, data, memory, rhythm, freePractice)
	if not self.rhythm or not rhythm or self.rhythm.id ~= rhythm.id then
		self.lastRhythmTap = nil
	end
	self.phase, self.data, self.rhythm = phase, data, rhythm
	self.freePractice = freePractice == true
	local training = self:isTraining()
	self.clubGuide.update(data, rhythm, self.page)
	self.clubhouse:setState(data, memory)
	self.menu.Visible = phase == "ready" and not training
	if phase ~= "ready" or not data then
		self:open(nil)
		self.kick.Text = phase == "failed" and "ПОВТОРИТЬ" or (phase == "locked" and "ПЕРЕЗАЙДИТЕ" or "ЗАГРУЗКА…")
		self.kick.Active = phase == "failed"
		self.kick.Selectable = self.kick.Active
		self.kick.BackgroundColor3 = p.tile
		self.kick.TextColor3 = p.soft
		self.comboBadge.Visible = false
		return
	end
	self.coins.Text = Ui.amount(data.coins)
	self.income.Text = "+" .. Ui.amount(Balance.income(data.active, data.levels[data.active] or 0)) .. " / сек"
	local interval, multiplier = Balance.interval(data.frequency), Balance.multiplier(data.multiplier)
	local nextGold = data.progress == interval - 1
	self.goldLabel.Text = training and "РИТМ-ТРЕНИРОВКА" or (nextGold and "ЗОЛОТО ГОТОВО" or "ЗОЛОТОЙ МЯЧ")
	self.goldLabel.TextColor3 = training and p.cyan or p.gold
	self.goldCount.Text = training and "" or (nextGold and ("×" .. multiplier) or (data.progress .. " / " .. interval))
	local filled = nextGold and interval or data.progress
	for index, segment in self.segments do
		segment.Visible = not training and index <= interval
		segment.Position = UDim2.fromScale((index - 1) / interval, 0)
		segment.Size = UDim2.new(1 / interval, -3, 1, 0)
		segment.BackgroundColor3 = index <= filled and p.gold or p.line
	end
	local canKick = training or self.freePractice
	self.kick.Active, self.kick.Selectable, self.kick.AutoButtonColor = canKick, canKick, canKick
	self.kick.Text = training and "ПОЙМАТЬ ТАКТ" or (self.freePractice
		and (nextGold and ("ЗОЛОТОЙ УДАР  ×" .. multiplier) or "НАБИВАТЬ") or "ТРЕНИРОВКА У МЯЧА")
	self.kick.BackgroundColor3 = canKick and (training and p.cyan or (nextGold and p.gold or p.lime)) or p.tile
	self.kick.TextColor3 = canKick and p.dark or p.soft
	local daily = data.club.daily
	self.menuDot.Visible = data.owned > 0 and not daily.claimed and daily.choice > 0
		and daily.count >= ClubUI.dailyTarget(daily.choice)
	if rhythm and rhythm.start then
		self.comboBadge.Visible = false
	end
end

return Hud
