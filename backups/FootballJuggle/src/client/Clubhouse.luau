local GuiService = game:GetService("GuiService")
local UserInputService = game:GetService("UserInputService")
local Balance = require(game:GetService("ReplicatedStorage"):WaitForChild("Juggle"):WaitForChild("Balance"))

local ClubRules = require(game:GetService("ReplicatedStorage").Juggle:WaitForChild("ClubRules"))
local ClubUI = require(script.Parent:WaitForChild("ClubUI"))

local Clubhouse = {}
Clubhouse.__index = Clubhouse

local pages = {
	{ key = "shop", title = "Улучшения", subtitle = "Бутсы и золотой мяч", tint = "lime" },
	{ key = "team", title = "Команда", subtitle = "Контракты, состав и тренировки", tint = "cyan" },
	{ key = "club", title = "Прогресс", subtitle = "Финты, задание дня и Академия", tint = "gold" },
	{ key = "settings", title = "Настройки", subtitle = "Звук и эффекты", tint = "white" },
}

local upgrades = {
	{ key = "boots", name = "Бутсы", mark = "+", tint = "lime", max = Balance.BootMax, price = Balance.bootPrice,
		value = function(n) return ("+%d мон. · ×%.2f"):format(Balance.kickPower(n), Balance.bootTrainingPercent(n) / 100) end },
	{ key = "frequency", name = "Частота золота", mark = "10", tint = "gold", max = Balance.FrequencyMax, price = Balance.frequencyPrice,
		value = function(n) return "Каждый " .. Balance.interval(n) .. "-й" end },
	{ key = "multiplier", name = "Множитель золота", mark = "×", tint = "gold", max = Balance.MultiplierMax, price = Balance.multiplierPrice,
		value = function(n) return "×" .. Balance.multiplier(n) end },
}

local preferences = {
	{ key = "muted", name = "Звук", description = "Удары, награды и подписания", mark = "♫" },
	{ key = "quiet", name = "Меньше эффектов", description = "Короче следы и ниже подброс", mark = "≈" },
}

local function title(ui, parent, text, size, color, x, y, width, height, align)
	local object = ui.label(parent, text, size, color, align)
	object.Position = UDim2.fromOffset(x, y)
	object.Size = UDim2.new(1, width, 0, height)
	return object
end

local function meter(ui, parent, position, size, tint)
	return ui.meter(parent, position, size, tint)
end

local function tile(ui, parent, order, height, tint)
	return ui.card(parent, order, height, tint)
end

local function emblem(ui, parent, mark, tint, width, height, y)
	local plate = ui.create("Frame", parent, {
		Position = UDim2.fromOffset(12, y), Size = UDim2.fromOffset(width, height),
		BackgroundColor3 = tint:Lerp(ui.palette.dark, 0.83), BorderSizePixel = 0,
	})
	ui.rounded(plate, 9)
	ui.outline(plate, tint:Lerp(ui.palette.dark, 0.48))
	local text = title(ui, plate, mark, 16, tint, 2, 0, -4, height, Enum.TextXAlignment.Center)
	return text
end

local function action(ui, parent, position, size)
	local object = ui.button(parent, "", ui.type.body, ui.palette.dark, ui.palette.white)
	object.Position, object.Size = position, size
	ui.fit(object, 10, ui.type.body)
	return object
end

local function paint(ui, button, text, enabled, tint, selected)
	ui.setAction(button, text, enabled, tint, selected)
end

local function price(ui, button, verb, cost, coins, tint)
	local affordable = cost ~= nil and coins >= cost
	local text = cost and (affordable and (verb .. "  ◈ " .. ui.amount(cost))
		or ("◈ " .. ui.amount(cost) .. "  ·  Нужно ещё " .. ui.amount(cost - coins))) or "МАКС. УРОВЕНЬ"
	paint(ui, button, text, affordable, tint, not cost)
end

local function scroller(ui, parent, key)
	local frame = ui.create("ScrollingFrame", parent, {
		Name = key, BackgroundTransparency = 1, BorderSizePixel = 0,
		CanvasSize = UDim2.fromOffset(0, 0), AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollingDirection = Enum.ScrollingDirection.Y, ScrollBarThickness = 4,
		ScrollBarImageColor3 = ui.palette.soft, Visible = false,
	})
	ui.create("UIPadding", frame, { PaddingTop = UDim.new(0, 2), PaddingBottom = UDim.new(0, 5), PaddingLeft = UDim.new(0, 1) })
	local layout = ui.create("UIListLayout", frame, { Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder })
	return frame, layout
end

local function buildShop(self)
	local ui, p = self.ui, self.ui.palette
	for index, upgrade in upgrades do
		local tint = p[upgrade.tint]
		local box = tile(ui, self.frames.shop, index, 165, tint)
		box.Name = upgrade.key
		emblem(ui, box, upgrade.mark, tint, 40, 39, 12)
		local heading = title(ui, box, upgrade.name, 17, p.white, 62, 11, -73, 22)
		heading.Font = Enum.Font.GothamBold
		ui.fit(heading, 12, 17)
		local level = title(ui, box, "", 11, tint, 62, 35, -74, 15)
		level.Font = Enum.Font.GothamBold
		local detail = title(ui, box, "", 14, p.white, 12, 65, -24, 26)
		detail.TextScaled = true
		ui.create("UITextSizeConstraint", detail, { MinTextSize = 10, MaxTextSize = 14 })
		local fill = meter(ui, box, UDim2.fromOffset(12, 97), UDim2.new(1, -24, 0, 6), tint)
		local buy = action(ui, box, UDim2.new(0, 12, 1, -53), UDim2.new(1, -24, 0, 43))
		buy.Name = "Buy"
		buy.Activated:Connect(function()
			if buy.Active and self.data then
				self.send(upgrade.key, self.data[upgrade.key] + 1)
			end
		end)
		self.shop[index] = { box = box, level = level, detail = detail, fill = fill, buy = buy, heading = heading }
	end
end

local function buildTeam(self)
	local ui, p = self.ui, self.ui.palette
	local page = self.frames.team
	local featured = tile(ui, page, 1, 151, p.cyan)
	featured.Name = "NextContract"
	emblem(ui, featured, "№", p.cyan, 44, 43, 12)
	self.featureLabel = title(ui, featured, "СЛЕДУЮЩИЙ КОНТРАКТ", 11, p.cyan, 66, 10, -80, 17)
	self.featureName = title(ui, featured, "", 20, p.white, 66, 28, -80, 27)
	self.featureName.Font = Enum.Font.GothamBold
	ui.fit(self.featureName, 13, 20)
	self.featureDetail = title(ui, featured, "", 13, p.soft, 12, 60, -24, 20)
	self.featureProgress = meter(ui, featured, UDim2.fromOffset(12, 83), UDim2.new(1, -24, 0, 4), p.cyan)
	self.featureBuy = action(ui, featured, UDim2.new(0, 12, 1, -51), UDim2.new(1, -24, 0, 42))
	self.featureBuy.Name = "SignContract"
	self.featureBuy.Activated:Connect(function()
		if self.featureBuy.Active and self.data then
			self.send("sign", self.data.owned + 1)
		end
	end)

	local active = tile(ui, page, 2, 136)
	active.Name = "ActivePartner"
	emblem(ui, active, "XI", p.cyan, 42, 38, 12)
	self.activeName = title(ui, active, "", 16, p.white, 65, 10, -77, 24)
	self.activeDetail = title(ui, active, "", 12, p.soft, 65, 32, -77, 21)
	self.activeRole = title(ui, active, "", 12, p.cyan, 12, 53, -24, 20)
	ui.fit(self.activeRole, 10, 12)
	self.train = action(ui, active, UDim2.new(0, 12, 1, -51), UDim2.new(1, -24, 0, 42))
	self.train.Name = "TrainPartner"
	self.train.Activated:Connect(function()
		if self.train.Active and self.data then
			local rank = self.data.active
			self.send("train", rank, self.data.levels[rank] + 1)
		end
	end)

	for tierIndex, tier in Balance.Tiers do
		local order = tierIndex * 10
		local division = title(ui, page, string.format("%02d  /  %s", tierIndex, tier.name), 13, tier.tint, 0, 0, -6, 22)
		division.LayoutOrder = order
		for slot = 1, 5 do
			local rank = (tierIndex - 1) * 5 + slot
			local box, stroke = tile(ui, page, order + slot, 62)
			emblem(ui, box, tostring(31 - rank), tier.tint, 35, 34, 14)
			local name = title(ui, box, Balance.playerName(rank), 14, p.white, 57, 9, -164, 21)
			local detail = title(ui, box, "", 11, p.soft, 57, 32, -164, 18)
			local equip = action(ui, box, UDim2.new(1, -102, 0, 10), UDim2.fromOffset(92, 42))
			equip.Activated:Connect(function()
				if equip.Active then
					self.send("equip", rank)
				end
			end)
			self.roster[rank] = { name = name, detail = detail, equip = equip, stroke = stroke, tint = tier.tint }
		end
	end
end

local function buildSettings(self)
	local ui, p = self.ui, self.ui.palette
	local page = self.frames.settings
	for index, preference in preferences do
		local box = tile(ui, page, index, 80)
		emblem(ui, box, preference.mark, p.cyan, 37, 37, 20)
		title(ui, box, preference.name, 15, p.white, 59, 15, -137, 23)
		local description = title(ui, box, preference.description, 11, p.soft, 59, 39, -137, 29)
		description.TextWrapped = true
		local toggle = action(ui, box, UDim2.new(1, -74, 0, 18), UDim2.fromOffset(62, 44))
		toggle.Name = index == 1 and "SoundToggle" or "MotionToggle"
		toggle.Activated:Connect(function()
			if self.data then
				self.send(preference.key, not self.data[preference.key])
			end
		end)
		self.toggles[index] = toggle
	end
	local storage = tile(ui, page, 3, 80)
	title(ui, storage, "Прогресс", 15, p.white, 12, 10, -24, 22)
	self.storage = title(ui, storage, "", 13, p.soft, 12, 34, -24, 35)
	self.storage.TextWrapped = true
end

function Clubhouse.new(gui, send, onPage, ui)
	local p, t, spacing = ui.palette, ui.type, ui.space
	local self = setmetatable({ ui = ui, send = send, frames = {}, tabs = {}, shop = {}, roster = {}, toggles = {}, transition = 0 }, Clubhouse)
	local layer = ui.create("Frame", gui, {
		Name = "Clubhouse", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Visible = false, ZIndex = 3,
	})
	self.layer = layer
	local shade = ui.create("TextButton", layer, {
		Name = "Scrim", Size = UDim2.fromScale(1, 1), BackgroundColor3 = p.dark, BackgroundTransparency = 0.3,
		Text = "", AutoButtonColor = false, BorderSizePixel = 0, Selectable = false,
	})
	self.shade = shade
	shade.Activated:Connect(function() onPage(nil) end)

	local window = ui.panel(layer, "Window", p.panel, 22)
	window.AnchorPoint, window.Position = Vector2.new(0.5, 0.5), UDim2.fromScale(0.5, 0.485)
	window.Active, window.ZIndex = true, 2
	self.window = window
	self.scale = ui.create("UIScale", window, { Scale = 1 })

	self.ribbon = ui.create("Frame", window, {
		Position = UDim2.fromOffset(17, 11), Size = UDim2.fromOffset(35, 3), BorderSizePixel = 0, BackgroundColor3 = p.lime,
	})
	ui.rounded(self.ribbon, 4)
	self.eyebrow = title(ui, window, "НАБИВАЙ!  /  КЛУБ", t.micro, p.soft, 17, 18, -168, 15)
	self.eyebrow.Font = Enum.Font.GothamBold
	self.title = title(ui, window, "", 27, p.white, 17, 34, -164, 31)
	self.title.Font = Enum.Font.GothamBlack
	ui.fit(self.title, 15, 27)
	self.subtitle = title(ui, window, "", t.body, p.soft, 17, 66, -34, 19)

	local wallet = ui.panel(window, "MenuWallet", p.dark, 11)
	wallet.Position = UDim2.new(1, -159, 0, 24)
	wallet.Size = UDim2.fromOffset(97, 40)
	local walletText = ui.place(wallet, "", t.body, p.gold, UDim2.fromOffset(6, 0), UDim2.new(1, -12, 1, 0),
		Enum.TextXAlignment.Center, Enum.Font.GothamBold)
	ui.fit(walletText, 10, t.body)
	self.wallet = walletText
	local close = ui.button(window, "×", 23, p.tile, p.white)
	close.Name = "CloseClub"
	self.close = close
	close.Position = UDim2.new(1, -55, 0, 22)
	close.Size = UDim2.fromOffset(43, 44)
	ui.outline(close)
	close.Activated:Connect(function() onPage(nil) end)

	local nav = ui.create("Frame", window, { Name = "Sections", BackgroundTransparency = 1 })
	local navLayout = ui.create("UIListLayout", nav, { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder })
	for index, spec in pages do
		local tab = ui.button(nav, spec.title, t.body, p.tile, p.soft)
		tab.Name = "Tab_" .. spec.key
		tab.LayoutOrder = index
		ui.fit(tab, 10, t.body)
		ui.outline(tab)
		tab.Activated:Connect(function() onPage(spec.key) end)
		self.tabs[index] = tab
		local frame, layout = scroller(ui, window, spec.key)
		self.frames[spec.key] = frame
		if spec.key == "shop" then self.shopLayout = layout end
	end

	buildShop(self)
	buildTeam(self)
	buildSettings(self)
	self.renderClub = ClubUI.page(self.frames.club, send, ui)

	function self:layout()
		local viewport = layer.AbsoluteSize
		local wide = viewport.X >= 765 and viewport.Y >= 440
		local short = viewport.Y < 410
		local desired = (self.page == "shop" and (wide and 386 or 659))
			or (self.page == "settings" and 425) or 653
		local width = math.max(240, math.min(viewport.X - (wide and 42 or 22), wide and 913 or 560))
		local height = math.max(190, math.min(viewport.Y - (short and 12 or 26), desired))
		window.Size = UDim2.fromOffset(width, height)
		self.subtitle.Visible = not short
		local startY = short and 71 or 93
		local bodyX, bodyY = wide and 177 or spacing.pad, wide and startY or startY + 50
		nav.Position = UDim2.fromOffset(spacing.pad, startY)
		nav.Size = wide and UDim2.new(0, 151, 1, -startY - spacing.pad) or UDim2.new(1, -2 * spacing.pad, 0, 43)
		navLayout.FillDirection = wide and Enum.FillDirection.Vertical or Enum.FillDirection.Horizontal
		local count = ClubUI.visible(self.data) and 4 or 3
		for index, spec in pages do
			local tab = self.tabs[index]
			tab.Visible = spec.key ~= "club" or count == 4
			tab.Size = wide and UDim2.new(1, 0, 0, 45) or UDim2.new(1 / count, -5, 1, 0)
			tab.Text = wide and (string.format("%02d", index) .. "   " .. spec.title) or spec.title
		end
		for _, frame in self.frames do
			frame.Position = UDim2.fromOffset(bodyX, bodyY)
			frame.Size = UDim2.new(1, -bodyX - spacing.pad, 1, -bodyY - spacing.pad)
		end
		local grid = wide and width - bodyX >= 650
		self.shopLayout.FillDirection = grid and Enum.FillDirection.Horizontal or Enum.FillDirection.Vertical
		for _, item in self.shop do
			item.box.Size = grid and UDim2.new(1 / 3, -8, 0, 177) or UDim2.new(1, -6, 0, 166)
		end
	end
	layer:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() self:layout() end)
	self:layout()
	return self
end

function Clubhouse:open(page, section)
	local ui, p = self.ui, self.ui.palette
	local wasOpen = self.layer.Visible
	self.transition += 1
	local id = self.transition
	if self.animation then self.animation:Cancel() end
	if self.shadeTween then self.shadeTween:Cancel() end
	local animate = self.data and not self.data.quiet
	self.page = page
	if not page then
		local selected = GuiService.SelectedObject
		if selected and selected:IsDescendantOf(self.window) then
			local previous = self.previousSelection
			GuiService.SelectedObject = previous and previous.Parent and previous or nil
		end
		self.previousSelection = nil
		if animate and wasOpen then
			self.animation = ui.tween(self.scale, 0.13, { Scale = 0.985 })
			self.shadeTween = ui.tween(self.shade, 0.13, { BackgroundTransparency = 1 })
			self.animation.Completed:Once(function()
				if self.transition == id then self.layer.Visible = false end
			end)
		else
			self.layer.Visible = false
		end
		return
	end

	self.layer.Visible = true
	if UserInputService.PreferredInput == Enum.PreferredInput.Gamepad and not wasOpen then
		self.previousSelection = GuiService.SelectedObject
		GuiService.SelectedObject = self.close
	end
	if page == "club" then
		local frame = self.frames.club
		frame.DailyCard.LayoutOrder = section == "daily" and 0 or 2
		frame.CanvasPosition = Vector2.zero
	end
	self.scale.Scale = animate and (wasOpen and 0.991 or 0.965) or 1
	self.shade.BackgroundTransparency = animate and not wasOpen and 1 or 0.3
	for index, spec in pages do
		local active, tab = spec.key == page, self.tabs[index]
		local tint = p[spec.tint]
		self.frames[spec.key].Visible = active
		tab.BackgroundColor3 = active and tint:Lerp(p.dark, 0.84) or p.tile
		tab.TextColor3 = active and tint or p.soft
		tab:FindFirstChildOfClass("UIStroke").Color = active and tint:Lerp(p.line, 0.43) or p.line
		if active then
			self.title.Text = spec.title
			self.subtitle.Text = spec.subtitle
			self.ribbon.BackgroundColor3 = tint
		end
	end
	self:layout()
	if animate then
		self.animation = ui.tween(self.scale, 0.17, { Scale = 1 })
		self.shadeTween = ui.tween(self.shade, 0.16, { BackgroundTransparency = 0.3 })
	end
	self:render()
end

function Clubhouse:setState(data, studioMemory)
	local changed = ClubUI.visible(data) ~= ClubUI.visible(self.data)
	self.data, self.studioMemory = data, studioMemory
	if changed then self:layout() end
	self:render()
end

function Clubhouse:render()
	local data = self.data
	if not self.page or not data then
		return
	end
	local ui, p = self.ui, self.ui.palette
	self.wallet.Text = "◈ " .. ui.amount(data.coins)
	self.eyebrow.Text = "КЛУБ  /  " .. Balance.pitchTier(data.owned).name
	if self.page == "shop" then
		for index, upgrade in upgrades do
			local item = self.shop[index]
			local current = data[upgrade.key]
			item.level.Text = "УРОВЕНЬ " .. current .. " / " .. upgrade.max
			item.detail.Text = upgrade.value(current) .. (current < upgrade.max and ("  →  " .. upgrade.value(current + 1)) or "")
			item.fill.Size = UDim2.fromScale(current / upgrade.max, 1)
			price(ui, item.buy, "КУПИТЬ", current < upgrade.max and upgrade.price(current) or nil, data.coins, p[upgrade.tint])
		end
	elseif self.page == "team" then
		local nextRank, active = data.owned + 1, data.active
		local hasNext = nextRank <= Balance.RankMax
		self.featureLabel.Text = "СЛЕДУЮЩИЙ КОНТРАКТ  /  " .. data.owned .. " ИЗ " .. Balance.RankMax
		self.featureName.Text = hasNext and ("№" .. (31 - nextRank) .. "  " .. Balance.playerName(nextRank)) or "Коллекция собрана"
		self.featureDetail.Text = hasNext and (Balance.tier(nextRank).name .. "  ·  +" .. ui.amount(Balance.income(nextRank, 1)) .. "/сек") or "Все футболисты в клубе"
		self.featureProgress.Size = UDim2.fromScale(data.owned / Balance.RankMax, 1)
		if hasNext then
			price(ui, self.featureBuy, "ПОДПИСАТЬ", Balance.contractPrice(nextRank), data.coins, p.cyan)
		else
			paint(ui, self.featureBuy, "ВСЕ КОНТРАКТЫ ПОДПИСАНЫ", false, p.cyan, true)
		end
		local level = data.levels[active]
		local role = ClubRules.role(active)
		self.activeRole.Text = role > 0 and (ClubRules.Roles[role] .. " · " .. ClubRules.RoleHelp[role]) or ""
		self.activeName.Text = level and ("На поле · " .. Balance.playerName(active)) or "Свободный слот"
		self.activeDetail.Text = level and ("Ур. " .. level .. "  ·  +" .. ui.amount(Balance.income(active, level)) .. "/сек") or "Футболист выйдет на поле после подписания"
		if level then
			price(ui, self.train, "ТРЕНИРОВАТЬ", level < Balance.PlayerLevelMax and Balance.playerUpgradePrice(active, level) or nil, data.coins, p.cyan)
		else
			paint(ui, self.train, "ОЖИДАЕТ ИГРОКА", false, p.cyan)
		end
		for rank, item in self.roster do
			local owned = data.levels[rank]
			local selected = rank == active
			item.name.TextColor3 = owned and p.white or p.soft
			item.stroke.Color = selected and p.cyan or p.line
			item.detail.Text = "+" .. ui.amount(Balance.income(rank, owned or 1)) .. "/сек · " .. ClubRules.Roles[ClubRules.role(rank)]
			local state = selected and "НА ПОЛЕ" or (owned and "ВЫСТАВИТЬ" or (rank == nextRank and "В ВИТРИНЕ" or ("ПОСЛЕ №" .. (32 - rank))))
			paint(ui, item.equip, state, owned ~= nil and not selected, item.tint, selected or rank == nextRank)
		end
	elseif self.page == "club" then
		self.renderClub(data)
	elseif self.page == "settings" then
		local enabled = { not data.muted, data.quiet }
		for index, toggle in self.toggles do
			paint(ui, toggle, enabled[index] and "ВКЛ." or "ВЫКЛ.", true, enabled[index] and p.cyan or p.tile)
			if not enabled[index] then
				toggle.TextColor3 = p.soft
			end
		end
		self.storage.Text = self.studioMemory and "В Studio прогресс хранится до остановки сервера." or "Прогресс сохраняется автоматически."
	end
end

return Clubhouse
