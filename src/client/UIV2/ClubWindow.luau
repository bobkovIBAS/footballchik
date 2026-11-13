local GuiService = game:GetService("GuiService")
local UserInputService = game:GetService("UserInputService")
local shared = game:GetService("ReplicatedStorage").Juggle
local Balance = require(shared.Balance)
local Rules = require(shared.ClubRules)
local C = require(script.Parent.Components)
local Art = require(script.Parent.Art)
local amount = require(script.Parent.Parent.UiKit).amount

local Club = {}
Club.__index = Club

local pages = {
	{ "shop", "Бутсы", "Shop", "red" },
	{ "team", "Команда", "Team", "blue" },
	{ "club", "Прогресс", "Progress", "purple" },
	{ "settings", "Настройки", "Settings", "gray" },
}
local upgrades = {
	{ "boots", "Бутсы", "Shop", "red", Balance.BootMax, Balance.bootPrice,
		function(level) return ("+%s монет  •  ×%.2f сила"):format(amount(Balance.kickPower(level)), Balance.bootTrainingPercent(level) / 100) end },
	{ "frequency", "Частота золота", "GoldBall", "gold", Balance.FrequencyMax, Balance.frequencyPrice,
		function(level) return "Каждый " .. Balance.interval(level) .. "-й удар" end },
	{ "multiplier", "Множитель", "Power", "purple", Balance.MultiplierMax, Balance.multiplierPrice,
		function(level) return "×" .. Balance.multiplier(level) .. " монет" end },
}
local center = Enum.TextXAlignment.Center
local soft = Color3.fromRGB(225, 213, 241)

local function line(parent, name, text, size, x, y, cut, height, opt)
	return C.label(parent, name, text, size, UDim2.fromOffset(x, y), UDim2.new(1, -cut, 0, height),
		opt or { stroke = 1.2, min = 10 })
end

local function track(face, y, tone, quiet)
	local root, set = C.ProgressBar(face, "Progress", tone, quiet)
	root.Position, root.Size = UDim2.fromOffset(12, y), UDim2.new(1, -24, 0, 9)
	return set
end

local function card(parent, name, title, subtitle, icon, tone, height)
	local root, face = C.ItemCard(parent, name, title, subtitle, icon, tone)
	root.Size = UDim2.new(1, -9, 0, height)
	return root, face
end

local function action(face, name, quiet, callback)
	local item = C.Action(face, name, "", "green", quiet, callback)
	item.root.AnchorPoint = Vector2.new(0, 1)
	item.root.Position, item.root.Size = UDim2.new(0, 11, 1, -8), UDim2.new(1, -22, 0, 42)
	return item
end

local function scroll(parent, name)
	local root = C.new("ScrollingFrame", parent, { Name = name, BorderSizePixel = 0,
		BackgroundTransparency = 1, ScrollBarThickness = 5, ScrollBarImageColor3 = soft,
		CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollingDirection = Enum.ScrollingDirection.Y, Visible = false })
	C.new("UIPadding", root, { PaddingTop = UDim.new(0, 5), PaddingLeft = UDim.new(0, 4),
		PaddingBottom = UDim.new(0, 8) })
	local layout = C.new("UIListLayout", root, { Padding = UDim.new(0, 11), SortOrder = Enum.SortOrder.LayoutOrder })
	return root, layout
end

function Club:command(key, target, expected, confirmed)
	if self.pending or not self.data then return end
	local request = { key = key, confirmed = confirmed }
	self.pending = request
	self.send(key, target, expected)
	self:render()
	task.delay(2, function()
		if self.pending ~= request then return end
		self.pending = nil
		self:render()
		self.notice("Ответ задерживается. Проверьте результат и повторите.", "red")
	end)
end

function Club:price(item, key, price, verb, cap)
	local waiting = self.pending and self.pending.key == key
	local success = self.lastConfirmed == key
	local shortfall = price and math.max(0, price - self.data.coins)
	item.title.Text = waiting and "ОЖИДАНИЕ…" or success and "✓  ПОДТВЕРЖДЕНО"
		or not price and (cap or "МАКС. УРОВЕНЬ")
		or shortfall > 0 and ("НЕ ХВАТАЕТ " .. amount(shortfall)) or verb
	item:setActive(not self.pending and not success and price ~= nil and shortfall == 0, success and "cyan" or "green", success)
end

function Club:buildShop()
	self.shop = {}
	for i, spec in upgrades do
		local key, title, icon, tone = table.unpack(spec)
		local root, face = card(self.frames.shop, key, title, "", icon, tone, 212)
		root.LayoutOrder = i
		local current = line(face, "Current", "", 14, 12, 61, 24, 22)
		local nextValue = line(face, "Next", "", 14, 12, 85, 24, 22)
		local price = line(face, "Price", "", 15, 12, 116, 24, 21)
		local set = track(face, 145, "gold", self.quiet)
		local buy = action(face, "Buy", self.quiet, function()
			local nextLevel = self.data[key] + 1
			self:command(key, nextLevel, nil, function(data) return data[key] >= nextLevel end)
		end)
		self.shop[i] = { root = root, face = face, level = face.Detail, current = current, next = nextValue, price = price, set = set, buy = buy }
	end
end

function Club:buildSettings()
	self.settings = {}
	for i, spec in { { "muted", "Звук", "Удары и игровые эффекты", "Settings", "blue" },
		{ "quiet", "Меньше эффектов", "Сокращает анимации и следы", "Power", "purple" } } do
		local key = spec[1]
		local root, face = card(self.frames.settings, key, spec[2], spec[3], spec[4], spec[5], 104)
		root.LayoutOrder = i
		local toggle, set = C.Toggle(face, "Toggle", self.quiet, function()
			local target = not self.data[key]
			self:command(key, target, nil, function(data) return data[key] == target end)
		end)
		toggle.root.Position, toggle.root.Size = UDim2.new(1, -124, 0, 55), UDim2.fromOffset(111, 42)
		self.settings[i] = { key = key, set = set }
	end
	local root, face = card(self.frames.settings, "Storage", "Сохранение", "", "Progress", "dark", 97)
	root.LayoutOrder = 3
	face.Detail.Visible = false
	self.storage = line(face, "StorageInfo", "", 14, 13, 51, 26, 31, { wrap = true, min = 10, stroke = false })
end

function Club:buildTeam()
	local frame = self.frames.team
	local summary = C.new("Frame", frame, { Name = "TeamSummary", BackgroundTransparency = 1, LayoutOrder = 1 })
	self.teamSummary = summary
	local contract, contractFace = card(summary, "NextContract", "Следующий контракт", "", "Team", "blue", 134)
	contract.LayoutOrder = 1
	self.contractInfo = line(contractFace, "ContractInfo", "", 14, 13, 58, 26, 22)
	self.contractName = contractFace.Detail
	self.sign = action(contractFace, "Sign", self.quiet, function()
		local rank = self.data.owned + 1
		self:command("sign", rank, nil, function(data) return data.owned >= rank end)
	end)
	local active, activeFace = card(summary, "ActivePlayer", "На поле", "", "Ball", "green", 150)
		self.contractCard, self.activeCard = contract, active
	self.activeName = activeFace.Detail
	self.activeInfo = line(activeFace, "ActiveInfo", "", 14, 13, 54, 26, 23)
	self.activeRole = line(activeFace, "RoleHelp", "", 12, 13, 77, 26, 21)
	self.train = action(activeFace, "Train", self.quiet, function()
		local rank = self.data.active
		local target = self.data.levels[rank] + 1
		self:command("train", rank, target, function(data) return (data.levels[rank] or 0) >= target end)
	end)
	local divider, face = C.Panel(frame, "DivisionPicker", "blue", 14)
	divider.LayoutOrder = 3
	divider.Size = UDim2.new(1, -9, 0, 60)
	self.divisionTitle = line(face, "Division", "", 16, 55, 0, 110, 53, { align = center, min = 11 })
	for _, dir in { -1, 1 } do
		local arrow = C.Action(face, dir < 0 and "Previous" or "Next", dir < 0 and "‹" or "›", "purple", self.quiet, function()
			self.division = (self.division - 1 + dir) % #Balance.Tiers + 1
			self:renderTeam()
		end)
		arrow.root.Position = dir < 0 and UDim2.fromOffset(8, 7) or UDim2.new(1, -48, 0, 7)
		arrow.root.Size = UDim2.fromOffset(40, 42)
	end
	local grid = C.new("Frame", frame, { Name = "Roster", BackgroundTransparency = 1, LayoutOrder = 4, Size = UDim2.new(1, -9, 0, 335) })
	self.grid, self.players = grid, {}
	self.gridLayout = C.new("UIGridLayout", grid, { CellPadding = UDim2.fromOffset(10, 10), SortOrder = Enum.SortOrder.LayoutOrder })
	for i = 1, 5 do
		local root, playerFace = card(grid, "Player" .. i, "", "", "Team", "blue", 123)
		root.LayoutOrder = i
		local detail = line(playerFace, "Status", "", 13, 10, 54, 20, 23)
		local selectPlayer = action(playerFace, "Select", self.quiet, function()
			local rank = (self.division - 1) * 5 + i
			self:command("equip", rank, nil, function(data) return data.active == rank end)
		end)
		self.players[i] = { face = playerFace, detail = detail, select = selectPlayer }
	end
end

function Club:buildProgress()
	local frame = self.frames.club
	local summary, summaryFace = card(frame, "Division", "Дивизион", "", "Team", "blue", 107)
	summary.LayoutOrder = 3
	self.progressDivision = summary
	self.divisionName = summaryFace.Detail
	self.divisionInfo = line(summaryFace, "Requirement", "", 13, 12, 56, 24, 20)
	self.divisionMeter = track(summaryFace, 82, "cyan", self.quiet)
	local academy, academyFace = card(frame, "Academy", "Школа ритма", "", "Power", "cyan", 62)
	academy.LayoutOrder = 4
	self.progressAcademy = academy
	self.academyResult = academyFace.Detail
	self.taskHeader, self.taskFace = card(frame, "Daily", "Задание дня", "", "Progress", "purple", 70)
	self.taskHeader.LayoutOrder = 1
	self.taskStatus = self.taskFace.Detail
	self.taskMeter = track(self.taskFace, 65, "gold", self.quiet)
	self.claim = action(self.taskFace, "Claim", self.quiet, function()
		local day = self.data.club.daily.day
		self:command("dailyClaim", 1, day, function(data) return data.club.daily.day == day and data.club.daily.claimed end)
	end)
	self.tasks = {}
	for i, task in Rules.Tasks do
		local root, face = card(frame, "Task" .. i, task.name, task.detail, "Progress", "purple", 107)
		local choose = action(face, "Choose", self.quiet, function()
			local day = self.data.club.daily.day
			self:command("dailyChoose", i, day, function(data) return data.club.daily.day == day and data.club.daily.choice == i end)
		end)
		root.LayoutOrder = i + 1
		self.tasks[i] = { root = root, choose = choose }
	end
	self.tricks = {}
	for i, title in Rules.Tricks do
		local root, face = card(frame, "Trick" .. i, title, "", i == 1 and "Ball" or "GoldBall", "gold", 107)
		local choose = action(face, "Choose", self.quiet, function()
			self:command("trick", i, nil, function(data) return data.club.trick == i end)
		end)
		root.LayoutOrder = i
		self.tricks[i] = { root = root, detail = face.Detail, choose = choose }
	end
end

function Club:renderTeam()
	local data = self.data
	local nextRank, rank = data.owned + 1, data.active
	local hasNext = nextRank <= Balance.RankMax
	self.contractName.Text = hasNext and ("№" .. (31 - nextRank) .. "  " .. Balance.playerName(nextRank)) or "Коллекция собрана"
	local cost = hasNext and Balance.contractPrice(nextRank)
	self.contractInfo.Text = hasNext and (Balance.tier(nextRank).name .. "  ·  +" .. amount(Balance.income(nextRank, 1)) .. "/с")
		or "Все футболисты подписаны"
	self:price(self.sign, "sign", cost or nil, cost and "ПОДПИСАТЬ  ·  " .. amount(cost) or "", "СОСТАВ СОБРАН")
	local level, role = data.levels[rank], Rules.role(rank)
	self.activeName.Text = level and ("№" .. (31 - rank) .. "  " .. Balance.playerName(rank)) or "Свободный слот"
	self.activeInfo.Text = level and ("Ур. " .. level .. "  ·  " .. Rules.Roles[role] .. "  ·  +" .. amount(Balance.income(rank, level)) .. "/с") or "Подпиши первого футболиста"
	self.activeRole.Text = level and Rules.RoleHelp[role] or ""
	local train = level and level < Balance.PlayerLevelMax and Balance.playerUpgradePrice(rank, level)
	self:price(self.train, "train", train or nil, train and "ТРЕНИРОВАТЬ  ·  " .. amount(train) or "", level and "МАКС. УРОВЕНЬ" or "НУЖЕН ФУТБОЛИСТ")
	self.divisionTitle.Text = self.division .. " / " .. #Balance.Tiers .. "  ·  " .. Balance.Tiers[self.division].name
	for i, view in self.players do
		local index = (self.division - 1) * 5 + i
		local owned = data.levels[index]
		local selected = index == rank
		if view.face.TeamIcon:IsA("ImageLabel") then
			view.face.TeamIcon.ImageColor3 = C.white:Lerp(Balance.tier(index).tint, .38)
		end
		view.face.Title.Text = "№" .. (31 - index) .. " " .. Balance.playerName(index)
		view.face.Detail.Text = Rules.Roles[Rules.role(index)] .. (owned and ("  ·  Ур. " .. owned) or "")
		view.detail.Text = "+" .. amount(Balance.income(index, owned or 1)) .. "/с"
		view.select.title.Text = selected and "✓  НА ПОЛЕ" or owned and "ВЫСТАВИТЬ" or index == nextRank and "СЛЕДУЮЩИЙ КОНТРАКТ" or "ЗАКРЫТО"
		view.select:setActive(owned ~= nil and not selected and self.pending == nil, "cyan", selected)
	end
end

function Club:renderProgress()
	local data, d = self.data, self.data.club.daily
	local selected = Rules.Tasks[d.choice]
	local daily, tricks = self.section == "daily", self.section == "tricks"
	self.taskHeader.Visible = daily
	self.progressDivision.Visible, self.progressAcademy.Visible = not daily and not tricks, not daily and not tricks
	for key, tab in self.progressTabs do tab:setActive(true, "purple", key == self.section) end
	self.taskHeader.Size = UDim2.new(1, -9, 0, selected and 132 or 64)
	self.taskFace.Progress.Visible = selected ~= nil
	self.claim.root.Visible = selected ~= nil
	self.taskStatus.Text = selected and (selected.name .. "  ·  " .. d.count .. "/" .. selected.target)
		or ("Отметки: " .. data.club.marks .. (data.owned > 0 and "  ·  Выбери одно задание" or "  ·  Нужен первый контракт"))
	if selected then self.taskMeter(d.count / selected.target) end
	local ready = selected and d.count >= selected.target and not d.claimed
	self.claim.title.Text = d.claimed and "✓  ОТМЕТКА ПОЛУЧЕНА" or self.pending and self.pending.key == "dailyClaim" and "ОЖИДАНИЕ…"
		or ready and "ЗАБРАТЬ ОТМЕТКУ" or "В ПРОЦЕССЕ"
	self.claim:setActive(ready == true and self.pending == nil, "gold", d.claimed)
	for _, view in self.tasks do
		view.root.Visible = daily and data.owned > 0 and selected == nil
		view.choose.title.Text = self.pending and self.pending.key == "dailyChoose" and "ОЖИДАНИЕ…" or "ВЫБРАТЬ"
		view.choose:setActive(self.pending == nil, "purple")
	end
	for i, view in self.tricks do
		view.root.Visible = tricks
		local unlocked = i == 1 or data.club.gold >= Rules.GoldForHeel
		local chosen = data.club.trick == i
		view.detail.Text = unlocked and "Для золотого удара" or ("Золотые удары: " .. data.club.gold .. " / " .. Rules.GoldForHeel)
		view.choose.title.Text = chosen and "✓  ВЫБРАН" or unlocked and "ВЫБРАТЬ ФИНТ" or "ЗАКРЫТО"
		view.choose:setActive(unlocked and not chosen and self.pending == nil, "gold", chosen)
	end
	local tier = Balance.pitchTier(data.owned)
	self.divisionName.Text = tier.name
	local nextCount = math.min((math.floor(data.owned / 5) + 1) * 5, Balance.RankMax)
	self.divisionInfo.Text = data.owned == Balance.RankMax and "Все дивизионы пройдены"
		or ("До следующего этапа: " .. data.owned .. " / " .. nextCount .. " контрактов")
	self.divisionMeter(data.owned == Balance.RankMax and 1 or data.owned % 5 / 5)
	local best = data.club.rhythmBest
	local medal = best >= 8 and "Золото" or best >= 6 and "Серебро" or best >= 4 and "Бронза" or "Без медали"
	self.academyResult.Text = ("%d / %d  ·  %s"):format(best, Rules.BeatCount, medal)
end

function Club:render()
	if not self.page or not self.data then return end
	local data = self.data
	self.wallet.Text = amount(data.coins)
	self.tabs.club:setActive(data.club.gold > 0 or data.boots > 0 or data.owned > 0, "purple", self.page == "club")
	if self.page == "shop" then
		for i, spec in upgrades do
			local key, _, _, _, max, cost, value = table.unpack(spec)
			local current, view = data[key], self.shop[i]
			local price = current < max and cost(current) or nil
			view.level.Text = ("Ур. %d / %d"):format(current, max)
			view.current.Text = "Сейчас  ·  " .. value(current)
			view.next.Text = price and "Дальше  ·  " .. value(current + 1) or "Достигнут максимум"
			view.price.Text = price and "Цена  ·  " .. amount(price) .. " монет" or ""
			view.set(current / max)
			self:price(view.buy, key, price, "КУПИТЬ")
		end
	elseif self.page == "team" then
		self:renderTeam()
	elseif self.page == "club" then
		self:renderProgress()
	elseif self.page == "settings" then
		for _, setting in self.settings do
			local enabled = data[setting.key]
			if setting.key == "muted" then enabled = not enabled end
			setting.set(enabled, self.pending ~= nil, self.pending and self.pending.key == setting.key)
		end
		self.storage.Text = self.memory and "В Studio прогресс хранится до завершения теста." or "Прогресс сохраняется автоматически."
	end
end

function Club:setState(data, memory)
	self.data, self.memory = data, memory
	local request = self.pending
	if request and data and request.confirmed(data) then
		self.pending, self.lastConfirmed = nil, request.key
		task.delay(.9, function()
			if self.lastConfirmed == request.key then
				self.lastConfirmed = nil
				self:render()
			end
		end)
	elseif not data then
		self.pending, self.lastConfirmed = nil, nil
	end
	self:render()
end

function Club:reject(message)
	if message == "Пока не хватает монет" and self.pending then
		self.pending = nil
		self:render()
	end
end

function Club:layout()
	local size = self.modal.layer.AbsoluteSize
	local wide = size.X >= 760
	local short = size.Y < 410
	local width = math.clamp(size.X - (wide and 78 or 20), 252, 900)
	local maximum = (self.page == "shop" and width >= 650 and 362) or (self.page == "settings" and 456) or 635
	local height = math.clamp(size.Y - (short and 24 or 55), 165, maximum)
	self.modal.panel.Size = UDim2.fromOffset(width, height)
	self.modal.heading.Size = UDim2.new(1, -166, 0, 35)
	self.walletFrame.Size = UDim2.fromOffset(78, 35)
	self.walletFrame.Position = UDim2.new(1, -131, 0, 7)
	local tabHeight = short and 36 or 42
	self.nav.Position, self.nav.Size = UDim2.fromOffset(12, 48), UDim2.new(1, -24, 0, tabHeight)
	local bodyY = 55 + tabHeight
	for _, frame in self.frames do
		frame.Position, frame.Size = UDim2.fromOffset(10, bodyY), UDim2.new(1, -18, 1, -bodyY - 9)
	end
	self.progressNav.Position, self.progressNav.Size = UDim2.fromOffset(13, bodyY), UDim2.new(1, -26, 0, 36)
	local clubBody = bodyY + 43
	self.frames.club.Position, self.frames.club.Size = UDim2.fromOffset(10, clubBody), UDim2.new(1, -18, 1, -clubBody - 9)
	local split = width >= 570
	self.teamSummary.Size = UDim2.new(1, -9, 0, split and (short and 129 or 150) or 295)
	self.contractCard.Size = UDim2.new(split and .5 or 1, split and -5 or 0, 0, split and (short and 129 or 150) or 134)
	self.activeCard.Size = UDim2.new(split and .5 or 1, split and -5 or 0, 0, short and split and 129 or 150)
	self.activeCard.Position = split and UDim2.new(.5, 5, 0, 0) or UDim2.fromOffset(0, 145)
	self.activeRole.Visible = not (short and split)
	local shopGrid = width >= 650
	self.shopLayout.FillDirection = shopGrid and Enum.FillDirection.Horizontal or Enum.FillDirection.Vertical
	for _, entry in self.shop do
		local compact = short and not shopGrid
		entry.root.Size = shopGrid and UDim2.new(1/3, -11, 0, 212) or UDim2.new(1, -9, 0, compact and 174 or 212)
		entry.current.Position = UDim2.fromOffset(12, compact and 52 or 61)
		entry.next.Position = UDim2.fromOffset(12, compact and 71 or 85)
		entry.price.Position = UDim2.fromOffset(12, compact and 91 or 116)
		entry.face.Progress.Position = UDim2.fromOffset(12, compact and 113 or 145)
		entry.buy.root.Size = UDim2.new(1, -22, 0, compact and 40 or 42)
	end
	local columns = width >= 680 and 3 or width >= 430 and 2 or 1
	self.gridLayout.FillDirectionMaxCells = columns
	self.gridLayout.CellSize = UDim2.new(1 / columns, -10, 0, 126)
	self.grid.Size = UDim2.new(1, -9, 0, math.ceil(5 / columns) * 136)
end

function Club:open(page, section)
	local previous = self.page
	self.page = page
	if not page then
		if previous then self.modal.setOpen(false) end
		return
	end
	if page == "team" and previous ~= "team" then
		self.division = math.clamp(math.floor((self.data and self.data.owned or 0) / 5) + 1, 1, #Balance.Tiers)
	end
	if page == "club" then
		self.section = section or (previous == "club" and self.section) or "daily"
		self.frames.club.CanvasPosition = Vector2.zero
	end
	self.progressNav.Visible = page == "club"
	for _, spec in pages do
		local key = spec[1]
		self.frames[key].Visible = key == page
		self.tabs[key]:setActive(true, spec[4], key == page)
		if key == page then self.modal.heading.Text = key == "shop" and "Улучшения" or spec[2] end
	end
	if section == "contracts" then self.frames.team.CanvasPosition = Vector2.zero end
	if not previous then
		self.modal.setOpen(true)
		if UserInputService.PreferredInput == Enum.PreferredInput.Gamepad then
			GuiService.SelectedObject = self.tabs[page].hit
		end
	end
	self:layout()
	self:render()
end

function Club.new(gui, send, open, quiet, notice)
	local self = setmetatable({ send = send, quiet = quiet, notice = notice, frames = {}, tabs = {}, division = 1 }, Club)
	self.modal = C.Modal(gui, "Clubhouse", "", quiet, function() open(nil) end)
	local face = self.modal.face
	local purse, purseFace = C.Panel(face, "Wallet", "dark", 10)
	self.walletFrame = purse
	Art.icon(purseFace, "Coins", UDim2.fromOffset(3, 3), UDim2.fromOffset(24, 24), 6)
	self.wallet = line(purseFace, "Amount", "", 14, 26, 1, 30, 28, { color = Color3.fromRGB(255, 218, 96), align = center })
	self.nav = C.new("Frame", face, { Name = "Tabs", BackgroundTransparency = 1 })
	self.progressNav = C.new("Frame", face, { Name = "ProgressTabs", BackgroundTransparency = 1, Visible = false })
	self.progressTabs = {}
	for i, spec in { { "daily", "Задание дня" }, { "tricks", "Финты" }, { "division", "Дивизионы" } } do
		local tab = C.Action(self.progressNav, spec[1], spec[2], "purple", quiet, function() open("club", spec[1]) end)
		tab.root.Position, tab.root.Size = UDim2.new((i - 1) / 3, 0, 0, 0), UDim2.new(1 / 3, -6, 1, 0)
		self.progressTabs[spec[1]] = tab
	end
	local noticeFrame, notify = C.Notification(face, quiet)
	noticeFrame.Position, noticeFrame.Size, noticeFrame.ZIndex = UDim2.fromOffset(7, 4), UDim2.new(1, -145, 0, 41), 9
	self.notify = notify
	for i, spec in pages do
		local key, title, _, tone = table.unpack(spec)
		local tab = C.Action(self.nav, "Tab_" .. key, title, tone, quiet, function() open(key) end)
		tab.root.Position, tab.root.Size = UDim2.new((i - 1) / #pages, 0, 0, 0), UDim2.new(1 / #pages, -6, 1, 0)
		self.tabs[key] = tab
		local frame, layout = scroll(face, key)
		self.frames[key] = frame
		if key == "shop" then self.shopLayout = layout end
	end
	for i, spec in pages do
		local hit = self.tabs[spec[1]].hit
		hit.NextSelectionLeft = i > 1 and self.tabs[pages[i-1][1]].hit or hit
		hit.NextSelectionRight = i < #pages and self.tabs[pages[i+1][1]].hit or self.modal.close
		hit.NextSelectionUp = self.modal.close
	end
	self.modal.close.NextSelectionDown = self.tabs.shop.hit
	self:buildShop()
	self:buildSettings()
	self:buildTeam()
	self:buildProgress()
	self.modal.layer:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() self:layout() end)
	self:layout()
	return self
end

return Club
