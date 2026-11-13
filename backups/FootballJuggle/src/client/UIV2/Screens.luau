local UserInputService = game:GetService("UserInputService")
local shared = game:GetService("ReplicatedStorage"):WaitForChild("Juggle")
local Balance = require(shared:WaitForChild("Balance"))
local Rules = require(shared:WaitForChild("ClubRules"))
local parent = script.Parent.Parent
local Clubhouse = require(script.Parent.ClubWindow)
local ClubUI = require(parent.ClubUI)
local Ui = require(parent.UiKit)
local C = require(script.Parent.Components)
local Art = require(script.Parent.Art)
local Navigation = require(script.Parent.Navigation)
local Rhythm = require(script.Parent.Rhythm)
local Goals = require(script.Parent.Goals)
local Prompts = require(script.Parent.Prompts)

local Hud = {}
Hud.__index = Hud

local center = Enum.TextXAlignment.Center
local comboWindow = 1.8

function Hud.new(playerGui, send)
	local self = setmetatable({ send = send, phase = "loading", combo = 0, lastHit = 0 }, Hud)
	local quiet = function() return self.data and self.data.quiet or false end
	self.quiet = quiet
	local gui = C.new("ScreenGui", playerGui, {
		Name = "JuggleUIV2", ResetOnSpawn = false, DisplayOrder = 10, ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets, ClipToDeviceSafeArea = true,
	})
	self.gui = gui
	self.field = C.new("Frame", gui, { Name = "FieldHUD", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1 })
	self.wallet, self.setWallet, self.walletCaption = C.CurrencyCounter(self.field, "Coins", "МОНЕТЫ", "Coins", "gold", quiet, Ui.amount)
	self.power, self.setPower = C.CurrencyCounter(self.field, "TrainingPower", "СИЛА", "Power", "cyan", quiet, Ui.amount)
	self.nav = Navigation.new(self, quiet)
	self.dock = C.new("Frame", self.field, { Name = "ActionDock", BackgroundTransparency = 1 })
	self.kick = C.PrimaryButton(self.dock, "Kick", "ЗАГРУЗКА…", "Ball", quiet, function() self:requestKick() end)
	self.kick.root.Position, self.kick.root.Size = UDim2.new(0, 0, 1, -58), UDim2.new(1, 0, 0, 58)
	self.gold, self.goldFace = C.Panel(self.dock, "GoldProgress", "dark", 12)
	self.gold.Size = UDim2.new(1, 0, 0, 42)
	self.gold.Position = UDim2.new(0, 0, 1, -106)
	Art.icon(self.goldFace, "GoldBall", UDim2.fromOffset(3, 0), UDim2.fromOffset(37, 37), 5)
	self.goldTitle = C.label(self.goldFace, "Caption", "ЗОЛОТОЙ МЯЧ", 12, UDim2.fromOffset(41, 3),
		UDim2.new(1, -99, 0, 16), { min = 9 })
	self.goldValue = C.label(self.goldFace, "Value", "", 13, UDim2.new(1, -63, 0, 3), UDim2.fromOffset(52, 16),
		{ align = Enum.TextXAlignment.Right, min = 9 })
	local rail, setProgress = C.ProgressBar(self.goldFace, "ProgressBar", "gold", quiet)
	rail.Position, rail.Size = UDim2.fromOffset(41, 22), UDim2.new(1, -51, 0, 8)
	self.setProgress = setProgress
	self.comboBadge, self.comboText = C.StatusBadge(self.field, "Combo", "", "purple")
	self.comboBadge.Visible = false
	self.rewardBadge = C.StatusBadge(self.field, "DailyReward", "НАГРАДА ГОТОВА", "purple")
	self.rewardBadge.Visible = false
	self.guide, self.guideFace = C.ItemCard(self.field, "TrainingHint", "Первые шаги", "", "Ball", "dark")
	self.guideText = self.guideFace.Detail
	self.guideButton = C.new("TextButton", self.guide, {
		Name = "Hit", BackgroundTransparency = 1, Text = "", Size = UDim2.fromScale(1, 1), ZIndex = 8,
		AutoButtonColor = false, Selectable = false,
	})
	self.guideButton.Activated:Connect(function()
		if self.step == 2 then self:open("shop") elseif self.step == 3 then self:open("team") end
	end)
	self.notice, self.notify = C.Notification(gui, quiet)
	self.notice.ZIndex = 20
	self.clubhouse = Clubhouse.new(gui, send, function(page, section) self:open(page, section) end, quiet, function(message) self:toast(message, "error") end)
	self.rhythmOverlay = Rhythm.new(self.field, quiet)
	self.rhythmOverlay.root:GetPropertyChangedSignal("Visible"):Connect(function() self:updateDock() end)
	self.field:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() self:layout() end)
	UserInputService:GetPropertyChangedSignal("PreferredInput"):Connect(function() self:layout() end)
	self:layout()
	self:setState("loading", nil, true)
	return self
end

function Hud:layout()
	local size = self.field.AbsoluteSize
	local touch = UserInputService.TouchEnabled
	local portrait = size.Y > size.X
	local narrow = size.X < 430
	local short = size.X > size.Y and size.Y < 400
	local edge = short and 10 or 13
	local counterHeight = short and 46 or 54
	local counterWidth = math.clamp(math.floor((size.X - 2 * edge - 10) / 2), 90, short and 132 or 164)
	self.wallet.Size, self.power.Size = UDim2.fromOffset(counterWidth, counterHeight), UDim2.fromOffset(counterWidth, counterHeight)
	self.wallet.Position, self.power.Position = UDim2.fromOffset(edge, edge), UDim2.fromOffset(edge + counterWidth + 9, edge)

	local side = not portrait
	local compact = short or size.X < 340
	local navWidth = narrow and 72 or 84
	local navHeight = short and 58 or (portrait and 61 or 73)
	local nav = self.nav.root
	nav.AnchorPoint = side and Vector2.new(1, 0) or Vector2.zero
	nav.Position = side and UDim2.new(1, -edge, 0, edge) or UDim2.fromOffset(edge, edge + counterHeight + 12)
	nav.Size = UDim2.fromOffset(compact and 68 or (side and navWidth or 4 * navWidth + 21),
		compact and 55 or (side and 4 * navHeight + 27 or navHeight))
	self.nav:layout(compact, side, navWidth, navHeight)

	local dockWidth = math.max(145, math.min(short and 260 or 330, size.X - 2 * edge - (touch and short and 178 or 0)))
	local bottom = touch and (short and 8 or (portrait and 85 or 59)) or 13
	self.dock.AnchorPoint, self.dock.Position = Vector2.new(.5, 1), UDim2.new(.5, 0, 1, -bottom)
	self.dock.Size = UDim2.fromOffset(dockWidth, 106)
	self.comboBadge.AnchorPoint = Vector2.new(.5, 1)
	self.comboBadge.Position, self.comboBadge.Size = UDim2.new(.5, 0, 1, -bottom - 113), UDim2.fromOffset(117, 27)
	local guideY = edge + counterHeight + (portrait and navHeight + 24 or 12)
	self.guide.Size = UDim2.fromOffset(short and 186 or 218, 59)
	self.shortLayout, self.portraitLayout = short, portrait
	self.dockWidth, self.dockBottom = dockWidth, bottom
	self:updateGuide()
	self.guide.Position = UDim2.fromOffset(edge, guideY)
	self.rewardBadge.Position, self.rewardBadge.Size = UDim2.fromOffset(edge, guideY + 65), UDim2.fromOffset(143, 27)
	self.notice.AnchorPoint = Vector2.new(.5, 0)
	self.notice.Position = UDim2.new(.5, 0, 0, portrait and guideY + 97 or edge + counterHeight + 10)
	self.notice.Size = UDim2.fromOffset(math.max(140, math.min(340, size.X - 2 * edge)), 47)
	if self.prompts then self.prompts:update() end
	local rhythm = self.rhythmOverlay.root
	rhythm.AnchorPoint = short and Vector2.new(1, 0) or Vector2.new(.5, 1)
	rhythm.Position = short and UDim2.new(1, -edge, 0, 70) or UDim2.new(.5, 0, 1, -bottom - 66)
	rhythm.Size = UDim2.fromOffset(short and 222 or dockWidth, rhythm.Size.Y.Offset)
	self.rhythmOverlay:draw()
end

function Hud:isTraining()
	return self.rhythm ~= nil and self.rhythm.start ~= nil
end

function Hud:showMenu(open)
	if open and (self.page or self:isTraining() or self.phase ~= "ready") then return end
	if self.menuOpen == open then return end
	self.menuOpen = open
	self.nav:setOpen(open)
	if self.prompts then self.prompts:update() end
end

function Hud:focusNavigation()
	self.nav:focus()
end

function Hud:open(page, section)
	if page and self:isTraining() then return end
	local wasOpen = self.page ~= nil
	self.page = page
	if self.menuOpen then self:showMenu(false) end
	self.field.Visible = page == nil
	self.clubhouse:open(page, section)
	self.rhythmOverlay:update(self.rhythm, page)
	self:updateDock()
	if not page and wasOpen then self.nav:restore() end
end

function Hud:requestKick()
	if self.page or self.menuOpen then return end
	if self.phase == "failed" then
		self.send("retry")
	elseif self.phase == "ready" then
		if self:isTraining() then
			local round = self.rhythm
			local index = Rules.beatIndex(round, workspace:GetServerTimeNow())
			if index < round.nextBeat or index > Rules.BeatCount or self.lastRhythmTap == index then return end
			self.lastRhythmTap = index
			self.send("rhythmTap", round.id)
		elseif self.freePractice then
			self.send("kick")
		end
	end
end

function Hud:confirm(effect)
	if effect.kind ~= "kick" then return end
	local text = "+" .. Ui.amount(effect.coins) .. " МОНЕТ"
	if effect.gold then text = "ЗОЛОТОЙ УДАР  ·  " .. text .. "  ×" .. effect.multiplier end
	self.notify(text, effect.gold and "gold" or "green", effect.gold and "GoldBall" or "Coins", effect.gold)
	local now = os.clock()
	self.combo = now - (self.lastKickAt or 0) <= comboWindow and effect.hit == self.lastHit + 1 and self.combo + 1 or 1
	self.lastKickAt, self.lastHit = now, effect.hit
	self.comboText.Text = "КОМБО ×" .. Ui.amount(self.combo)
	self.comboBadge.Visible = self.combo > 1 and not self.goalVisible and not self:isTraining()
	if self.comboTimer then task.cancel(self.comboTimer) end
	self.comboTimer = task.delay(comboWindow, function()
		self.comboTimer, self.combo = nil, 0
		self.comboBadge.Visible = false
	end)
end

function Hud:toast(value, kind)
	self.clubhouse:reject(value)
	local tone, icon = "blue", "Progress"
	if kind == "sign" then tone, icon = "purple", "Team"
	elseif kind == "upgrade" then tone, icon = "gold", "Shop"
	elseif value == "Получена клубная отметка" then tone, icon = "gold", "Progress"
	elseif kind == "error" or self.phase == "failed" or self.phase == "locked" or value == "Пока не хватает монет" then
		tone, icon = "red", "Settings"
	end
	if self.page then self.clubhouse.notify(value, tone, icon, true)
	else self.notify(value, tone, icon, true) end
end

function Hud:updateGuide()
	local first = self.shortLayout and "Набивай у мяча" or "Начни набивание у мяча"
	self.guideText.Text = ({ first, "Улучши бутсы", "Подпиши футболиста" })[self.step] or ""
end

function Hud:updateDock()
	local active = self:isTraining() or self.freePractice or self.phase ~= "ready"
	self.kick.root.Visible = not self.goalVisible and (active or not self.worldPromptActive)
	self.nav.root.Visible = self.phase == "ready" and not self:isTraining() and not self.goalVisible
	if self.prompts then self.prompts:update() end
	self.gold.Visible = not self.goalVisible and self.phase == "ready" and not self.rhythmOverlay.root.Visible and (self.freePractice or not self.worldPromptActive)
	self.comboBadge.Visible = self.combo > 1 and not self.goalVisible and not self:isTraining() and (self.freePractice or not self.worldPromptActive)
	self.guide.Visible = self.step ~= nil and self.step <= 3 and not self.goalVisible and not self.rhythmOverlay.root.Visible
end

function Hud:setGoalVisible(visible)
	if visible == self.goalVisible then return end
	self.goalVisible = visible
	self.rhythmOverlay:setSuppressed(visible)
	self:updateDock()
end

function Hud:makeShotGauge()
	return Goals.gauge(self.field, self.quiet)
end

function Hud:styleNameplate(gui, text)
	gui.Size = UDim2.fromOffset(131, 26)
	local badge = C.StatusBadge(gui, "Partner", text, "blue")
	badge.Size = UDim2.fromScale(1, 1)
end

function Hud:makeGoalHealth(gui, level, finished)
	return Goals.health(gui, level, finished, self.quiet)
end

function Hud:goalImpact(shot, damage)
	Goals.impact(self.notify, shot, damage)
end

function Hud:makeGoalButton(request)
	local button = C.PrimaryButton(self.dock, "ShootGoal", "", "Ball", self.quiet, request)
	button.root.Position, button.root.Size = UDim2.new(0, 0, 1, -58), UDim2.new(1, 0, 0, 58)
	button.root.Visible = false
	button.title.Position, button.title.Size = UDim2.fromOffset(57, 4), UDim2.new(1, -64, 0, 26)
	local sub = C.label(button.face, "Power", "", 12, UDim2.fromOffset(56, 29),
		UDim2.new(1, -62, 0, 17), { align = center, min = 10 })
	return function(visible, active, title, power)
		button.root.Visible = visible
		self:setGoalVisible(visible)
		if visible then
			button.title.Text, sub.Text = title, power
			button:setActive(active, "cyan")
		end
	end
end

function Hud:bindWorldPrompts()
	self.prompts = Prompts.bind(self)
	self:updateDock()
end

function Hud:setState(phase, data, memory, rhythm, freePractice)
	if not self.rhythm or not rhythm or self.rhythm.id ~= rhythm.id then self.lastRhythmTap = nil end
	self.phase, self.data, self.rhythm, self.freePractice = phase, data, rhythm, freePractice == true
	local training = self:isTraining()
	self.clubhouse:setState(data, memory)
	self.rhythmOverlay:update(rhythm, self.page)
	if training or phase ~= "ready" then
		if self.menuOpen then self:showMenu(false) end
	end
	if not data or phase ~= "ready" then
		self:open(nil)
		self.setWallet(nil)
		self.walletCaption.Text = "МОНЕТЫ"
		self.setPower(nil)
		self.step = nil
		self.rewardBadge.Visible = false
		self.kick.title.Text = phase == "failed" and "ПОВТОРИТЬ" or (phase == "locked" and "ПЕРЕЗАЙДИТЕ" or "ЗАГРУЗКА…")
		self.kick:setActive(phase == "failed", "green")
		self:updateDock()
		return
	end
	self.progressAvailable = ClubUI.visible(data)
	self.setWallet(data.coins)
	local income = Balance.income(data.active, data.levels[data.active] or 0)
	self.walletCaption.Text = income > 0 and ("МОНЕТЫ · +" .. Ui.amount(income) .. "/с") or "МОНЕТЫ"
	self.setPower(data.trainingPower)
	local interval, multiplier = Balance.interval(data.frequency), Balance.multiplier(data.multiplier)
	local golden = data.progress == interval - 1
	self.goldTitle.Text = golden and "ЗОЛОТО ГОТОВО" or "ЗОЛОТОЙ МЯЧ"
	self.goldValue.Text = golden and "×" .. multiplier or string.format("%d / %d", data.progress, interval)
	self.setProgress(golden and 1 or data.progress / interval)
	self.kick.title.Text = training and "ПОЙМАТЬ ТАКТ" or (self.freePractice and (golden and "ЗОЛОТОЙ УДАР" or "НАБИВАТЬ!") or "К МЯЧУ ДЛЯ ТРЕНИРОВКИ")
	self.kick:setActive(training or self.freePractice, training and "cyan" or (golden and "gold" or "green"))
	self.step = Rules.training(data)
	self:updateGuide()
	self.guideButton.Active, self.guideButton.Selectable = self.step == 2 or self.step == 3, self.step == 2 or self.step == 3
	local daily = data.club.daily
	self.rewardBadge.Visible = data.owned > 0 and not daily.claimed and daily.choice > 0
		and daily.count >= ClubUI.dailyTarget(daily.choice)
	self:updateDock()
end

return Hud
