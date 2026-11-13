local RunService = game:GetService("RunService")
local shared = game:GetService("ReplicatedStorage"):WaitForChild("Juggle")
local Rules = require(shared:WaitForChild("ClubRules"))
local Balance = require(shared:WaitForChild("Balance"))

local ClubUI = {}
local bold = Enum.Font.GothamBold

local function text(ui, parent, value, size, color, x, y, right, height, font)
	return ui.place(parent, value, size, color, UDim2.fromOffset(x, y),
		UDim2.new(1, -right, 0, height or 22), nil, font)
end

local function heading(ui, box, eyebrow, name, tint)
	local p, t = ui.palette, ui.type
	text(ui, box, eyebrow, t.micro, tint, 12, 8, 24, 15, bold)
	text(ui, box, name, t.section, p.white, 12, 25, 24, 22, bold)
end

local function row(ui, box, y, name, height)
	local item = ui.button(box, "", ui.type.button, ui.palette.dark, ui.palette.white)
	item.Name = name
	item.Position = UDim2.fromOffset(12, y)
	item.Size = UDim2.new(1, -24, 0, height or 44)
	return item
end

function ClubUI.visible(data)
	return data ~= nil and (data.club.gold > 0 or data.boots > 0 or data.owned > 0)
end

function ClubUI.dailyTarget(choice)
	return Rules.Tasks[choice].target
end

function ClubUI.page(parent, send, ui)
	local p, t = ui.palette, ui.type
	local tricks = ui.card(parent, 1, 184, p.gold)
	tricks.Name = "TricksCard"
	heading(ui, tricks, "ЗОЛОТОЙ УДАР", "Фирменные финты", p.gold)
	local trickRows = {}
	local data
	for id, name in Rules.Tricks do
		local item = row(ui, tricks, 55 + (id - 1) * 61, "Trick" .. id, 54)
		local title = text(ui, item, name, t.button, p.white, 11, 6, 22, 18, bold)
		local state = text(ui, item, "", t.micro, p.soft, 11, 26, 22, 20)
		ui.fit(state, 10, t.micro)
		local border = ui.outline(item)
		item.Activated:Connect(function()
			if item.Active then send("trick", id) end
		end)
		trickRows[id] = { item = item, title = title, state = state, border = border }
	end

	local daily = ui.card(parent, 2, 249, p.cyan)
	daily.Name = "DailyCard"
	heading(ui, daily, "КЛУБНЫЕ ОТМЕТКИ", "Задание дня", p.cyan)
	local detail = text(ui, daily, "", t.body, p.soft, 12, 51, 24, 20)
	ui.fit(detail, 10, t.body)
	local choices = {}
	for id, task in Rules.Tasks do
		local item = row(ui, daily, 78 + (id - 1) * 55, "DailyChoice" .. id, 48)
		text(ui, item, task.name, t.body, p.white, 11, 5, 22, 18, bold)
		text(ui, item, task.detail, t.micro, p.cyan, 11, 23, 22, 18)
		ui.outline(item, p.cyan:Lerp(p.line, 0.55))
		item.Activated:Connect(function()
			if item.Active and data then send("dailyChoose", id, data.club.daily.day) end
		end)
		choices[id] = item
	end
	local fill = ui.meter(daily, UDim2.fromOffset(12, 77), UDim2.new(1, -24, 0, 6), p.cyan)
	local reward = row(ui, daily, 94, "ClaimDaily")
	reward.Activated:Connect(function()
		if reward.Active and data then send("dailyClaim", 1, data.club.daily.day) end
	end)

	local academy = ui.card(parent, 3, 112)
	academy.Name = "AcademyCard"
	heading(ui, academy, "ТРЕНИРОВКА РИТМА", "Академия", p.cyan)
	local licence = text(ui, academy, "", t.body, p.white, 12, 52, 24, 20, bold)
	local medal = text(ui, academy, "", t.micro, p.soft, 12, 77, 24, 20)
	ui.fit(licence, 10, t.body)
	ui.fit(medal, 10, t.micro)

	return function(snapshot)
		data = snapshot
		if not data then return end
		local club = data.club
		for id, view in trickRows do
			local chosen = club.trick == id
			local unlocked = id == 1 or club.gold >= Rules.GoldForHeel
			ui.setAction(view.item, "", unlocked and not chosen, p.gold, chosen)
			view.item.BackgroundColor3 = (chosen and p.gold:Lerp(p.dark, 0.87)) or (unlocked and p.panel or p.dark)
			view.border.Color = chosen and p.gold or p.line
			view.title.TextColor3 = unlocked and p.white or p.soft
			view.state.TextColor3 = chosen and p.gold or p.soft
			view.state.Text = chosen and "Выбран · для золотого удара"
				or (unlocked and "Выбрать для золотого удара" or ("Закрыт · золотые удары " .. club.gold .. "/" .. Rules.GoldForHeel))
		end

		licence.Text = "Школа ритма на футзальной арене"
		local best = club.rhythmBest
		local award = best >= 8 and "Золото" or (best >= 6 and "Серебро" or (best >= 4 and "Бронза" or "Без медали"))
		medal.Text = "Ритм " .. best .. "/" .. Rules.BeatCount .. " · " .. award .. " · Отметки " .. club.marks
		daily.Visible = data.owned > 0
		if not daily.Visible then return end
		local progress = club.daily
		local task = Rules.Tasks[progress.choice]
		for _, item in choices do item.Visible = task == nil end
		fill.Parent.Visible = task ~= nil
		reward.Visible = task ~= nil
		daily.Size = UDim2.new(1, -6, 0, task and 150 or 249)
		if task then
			detail.Text = task.name .. "   ·   " .. progress.count .. " / " .. task.target
			fill.Size = UDim2.fromScale(progress.count / task.target, 1)
			local ready = progress.count >= task.target and not progress.claimed
			ui.setAction(reward, progress.claimed and "ОТМЕТКА ПОЛУЧЕНА" or (ready and "ЗАБРАТЬ ОТМЕТКУ" or "ЗАДАНИЕ В ПРОЦЕССЕ"),
				ready, p.cyan, progress.claimed)
		else
			detail.Text = "Выбери одно · Отметки " .. club.marks
		end

	end
end

local lessons = {
	{ "Начни набивание у мяча" },
	{ "Улучши бутсы", "shop" },
	{ "Подпиши футболиста", "team" },
}

function ClubUI.overlay(field, dock, ui, open)
	local p, t = ui.palette, ui.type
	local guide = ui.button(field, "", t.body, p.panel, p.white)
	guide.Name = "TrainingHint"
	guide.Visible = false
	ui.outline(guide)
	local stepText = text(ui, guide, "", t.micro, p.lime, 10, 5, 20, 14, bold)
	local goal = text(ui, guide, "", t.body, p.white, 10, 20, 20, 21, bold)
	ui.fit(goal, 10, t.body)
	local rhythmPanel = ui.panel(dock, "ClubGuide", p.panel, 13)
	rhythmPanel.AnchorPoint = Vector2.new(0.5, 1)
	rhythmPanel.Position = UDim2.new(0.5, 0, 0, -7)
	rhythmPanel.Size = UDim2.new(1, 0, 0, 94)
	rhythmPanel.Visible = false
	local outline = rhythmPanel:FindFirstChildOfClass("UIStroke")
	local scale = ui.create("UIScale", rhythmPanel, { Scale = 1 })
	local left, right = Enum.TextXAlignment.Left, Enum.TextXAlignment.Right
	local function readout(name, y, width, align, tint, size)
		local x = align == left and 10 or -10
		local label = ui.place(rhythmPanel, "", size, tint, UDim2.new(align == left and 0 or 1, x, 0, y),
			UDim2.new(width, -10, 0, 18), align, bold)
		label.Name = name
		label.AnchorPoint = Vector2.new(align == left and 0 or 1, 0)
		ui.fit(label, 9, size)
		return label
	end
	local beatText = readout("Beat", 7, 0.5, left, p.soft, t.micro)
	local power = readout("KickPower", 7, 0.5, right, p.cyan, t.body)
	local feedback = readout("Judgement", 49, 0.66, left, p.white, t.button)
	local combo = readout("Combo", 49, 0.34, right, p.soft, t.micro)
	local earned = readout("TrainingGain", 69, 1, left, p.lime, t.micro)
	local rail = ui.panel(rhythmPanel, "RhythmRail", p.dark, 6)
	rail.Position, rail.Size = UDim2.fromOffset(10, 28), UDim2.new(1, -20, 0, 15)
	local function zone(name, window, color)
		local frame = ui.create("Frame", rail, {
			Name = name, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromScale(2 * window / Rules.BeatInterval, 1), BackgroundColor3 = color, BorderSizePixel = 0,
		})
		ui.rounded(frame, 5)
		return frame
	end
	local good = zone("GoodWindow", 0.19, p.cyan:Lerp(p.panel, 0.58))
	local perfect = zone("PerfectWindow", Rules.PerfectWindow, p.gold)
	local cursor = ui.create("Frame", rail, {
		Name = "Cursor", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0, 0.5),
		Size = UDim2.fromOffset(4, 21), BackgroundColor3 = p.white, BorderSizePixel = 0,
	})
	ui.rounded(cursor, 2)
	ui.outline(cursor, p.dark)

	local tints = { Perfect = p.gold, Good = p.cyan, Miss = p.warn }
	local data, rhythm, page, lastEnd, lastResult, pulse
	local guideEnabled = true
	local resultUntil, feedbackUntil = 0, 0
	guide.Activated:Connect(function()
		local lesson = data and lessons[Rules.training(data)]
		if lesson and lesson[2] then open(lesson[2]) end
	end)
	local function draw()
		local show = data ~= nil and page == nil
		local now = show and rhythm and workspace:GetServerTimeNow() or 0
		local active = show and rhythm and rhythm.start ~= nil
		local result = show and rhythm and rhythm.ended ~= nil and now < resultUntil
		rhythmPanel.Visible = active == true or result == true
		if active or result then
			power.Text = "СИЛА " .. ui.amount(Balance.goalDamage(data.boots, data.trainingPower))
			earned.Text = "+" .. ui.amount(rhythm.gained) .. " К ТРЕНИРОВОЧНОЙ СИЛЕ"
			rail.Visible = active
		end
		if active then
			local raw = Rules.beatIndex(rhythm, now)
			local index = math.clamp(raw, 1, Rules.BeatCount)
			local center = rhythm.start + (index - 1) * Rules.BeatInterval
			local offset = now - center
			beatText.Text = "ТАКТ " .. index .. "/" .. Rules.BeatCount
			good.Size = UDim2.fromScale(2 * rhythm.window / Rules.BeatInterval, 1)
			cursor.Position = UDim2.fromScale(math.clamp(0.5 + offset / Rules.BeatInterval, 0, 1), 0.5)
			local onPerfect = index >= rhythm.nextBeat and math.abs(offset) <= Rules.PerfectWindow
			perfect.BackgroundColor3 = onPerfect and p.gold:Lerp(p.white, 0.35) or p.gold
			cursor.BackgroundColor3 = onPerfect and p.dark or p.white
			combo.Text = "КОМБО ×" .. rhythm.combo
			local last = rhythm.last
			if last and now < feedbackUntil then
				feedback.Text = last.grade:upper() .. "  +" .. last.gain
				feedback.TextColor3 = tints[last.grade]
			else
				feedback.Text = raw < 1 and "Приготовься" or (raw > Rules.BeatCount and "Подводим итог"
					or (index >= rhythm.nextBeat and math.abs(offset) <= rhythm.window and "БЕЙ!" or "Держи ритм"))
				feedback.TextColor3 = p.white
			end
			outline.Color = feedback.TextColor3 == p.white and p.line or feedback.TextColor3
		elseif result then
			beatText.Text = "РЕЗУЛЬТАТ"
			feedback.Text = rhythm.cancelled and "Раунд прерван" or ("ОЧКИ " .. rhythm.score .. "/" .. Rules.BeatCount)
			feedback.TextColor3 = rhythm.cancelled and p.warn or p.gold
			combo.Text = "МАКС. ×" .. rhythm.bestCombo
			outline.Color = feedback.TextColor3
		end
		local step = show and Rules.training(data) or 4
		local lesson = lessons[step]
		guide.Visible = guideEnabled and lesson ~= nil and not rhythmPanel.Visible
		if lesson then
			stepText.Text = ("ПЕРВЫЕ ШАГИ  /  0%d"):format(step)
			goal.Text = lesson[1] .. (lesson[2] and "  ›" or "")
			guide.Active, guide.Selectable, guide.AutoButtonColor = lesson[2] ~= nil, lesson[2] ~= nil, lesson[2] ~= nil
		end
	end

	RunService.RenderStepped:Connect(function()
		if rhythmPanel.Visible then draw() end
	end)
	return {
		setGuideEnabled = function(enabled) guideEnabled = enabled end,
		layout = function(edge, width, shortTouch)
			guide.AnchorPoint = Vector2.new(0, shortTouch and 1 or 0)
			guide.Position = shortTouch and UDim2.new(0, edge, 1, -118) or UDim2.fromOffset(edge, edge + 74)
			guide.Size = UDim2.fromOffset(width, shortTouch and 44 or 47)
			stepText.Visible = not shortTouch
			goal.Position = UDim2.fromOffset(10, shortTouch and 0 or 20)
			goal.Size = shortTouch and UDim2.new(1, -20, 1, 0) or UDim2.new(1, -20, 0, 21)
		end,
		update = function(snapshot, round, currentPage)
			local previousId = rhythm and rhythm.id
			data, rhythm, page = snapshot, round, currentPage
			local last = round and round.last
			if last and (round.id ~= previousId or last.index ~= lastResult) then
				lastResult = last.index
				feedbackUntil = workspace:GetServerTimeNow() + 0.54
				if snapshot and not snapshot.quiet then
					if pulse then pulse:Cancel() end
					scale.Scale = 1.035
					pulse = ui.tween(scale, 0.18, { Scale = 1 })
				end
			end
			if round and round.ended and round.ended ~= lastEnd then
				lastEnd = round.ended
				resultUntil = workspace:GetServerTimeNow() + 3
			end
			draw()
		end,
	}
end

return ClubUI
