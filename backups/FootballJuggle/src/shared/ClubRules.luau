local Rules = {
	GoldForHeel = 3,
	BeatCount = 8,
	BeatInterval = 0.72,
	PerfectWindow = 0.09,
	MaxRhythmCompensation = 0.12,
	RhythmTapInterval = 0.14,
	RhythmPower = { Perfect = 5, Good = 2, Miss = 0 },
	Tricks = { "Вокруг света", "Подброс пяткой" },
	Roles = { "Технарь", "Капитан", "Снайпер" },
	RoleHelp = { "Больше времени на удар в Академии", "Двойной зачёт в разминке с напарником", "Двойной зачёт золотых ударов в задании" },
	Tasks = {
		{ name = "Разминка", detail = "40 принятых ударов", target = 40 },
		{ name = "Золотая серия", detail = "4 золотых удара", target = 4 },
		{ name = "Командная тренировка", detail = "20 ударов с напарником", target = 20 },
	},
}

local function integer(value, max)
	if type(value) ~= "number" or value ~= value or math.abs(value) == math.huge then
		return 0
	end
	return math.clamp(math.floor(value), 0, max)
end

function Rules.day(timestamp)
	return math.floor(timestamp / 86400)
end

function Rules.normalize(raw)
	raw = type(raw) == "table" and raw or {}
	local gold = integer(raw.gold, Rules.GoldForHeel)
	local old = type(raw.daily) == "table" and raw.daily or {}
	local choice = integer(old.choice, #Rules.Tasks)
	local task = Rules.Tasks[choice]
	local count = task and integer(old.count, task.target) or 0
	return {
		gold = gold,
		trick = raw.trick == 2 and gold >= Rules.GoldForHeel and 2 or 1,
		marks = integer(raw.marks, 1e6),
		rhythmBest = integer(raw.rhythmBest, Rules.BeatCount),
		daily = {
			day = integer(old.day, 1e7), choice = choice, count = count,
			claimed = task ~= nil and count == task.target and old.claimed == true,
		},
	}
end

function Rules.roll(club, day)
	if club.daily.day < day then
		club.daily = { day = day, choice = 0, count = 0, claimed = false }
		return true
	end
	return false
end

function Rules.choose(club, day, choice)
	local daily = club.daily
	if day ~= daily.day or daily.choice ~= 0 or not Rules.Tasks[choice] then
		return false
	end
	daily.choice = choice
	return true
end

function Rules.claim(club, day)
	local daily = club.daily
	local task = Rules.Tasks[daily.choice]
	if day ~= daily.day or daily.claimed or not task or daily.count < task.target then
		return false
	end
	daily.claimed = true
	club.marks = math.min(club.marks + 1, 1e6)
	return true
end

function Rules.role(rank)
	if rank > 0 then
		return (rank - 1) % #Rules.Roles + 1
	end
	return 0
end

function Rules.isNewKick(sequence, lastSequence)
	return type(sequence) == "number" and sequence % 1 == 0
		and sequence > lastSequence and sequence <= 2147483647
end

function Rules.onKick(club, gold, active)
	if gold then
		club.gold = math.min(club.gold + 1, Rules.GoldForHeel)
	end
	local daily = club.daily
	local task = Rules.Tasks[daily.choice]
	if daily.claimed or not task then
		return
	end
	local role = Rules.role(active)
	local added = 0
	if daily.choice == 1 then
		added = 1
	elseif daily.choice == 2 and gold then
		added = role == 3 and 2 or 1
	elseif daily.choice == 3 and active > 0 then
		added = role == 2 and 2 or 1
	end
	daily.count = math.min(task.target, daily.count + added)
end

function Rules.training(data)
	if data.owned > 0 then
		return 4
	elseif data.club.gold == 0 and data.boots == 0 then
		return 1
	elseif data.boots == 0 then
		return 2
	end
	return 3
end

function Rules.newRhythm(now, rank, id)
	local window = Rules.role(rank) == 1 and 0.235 or 0.19
	local start = now + 2.5
	return {
		id = id, start = start, window = window,
		finish = start + (Rules.BeatCount - 0.5) * Rules.BeatInterval + Rules.MaxRhythmCompensation,
		hits = 0, faults = 0, nextBeat = 1, combo = 0, bestCombo = 0, gained = 0,
		lastSequence = 0, nextTap = now,
	}
end

function Rules.beatIndex(round, time)
	return math.floor((time - round.start) / Rules.BeatInterval + 0.5) + 1
end

local function finishBeat(round, grade, attempted)
	local index = round.nextBeat
	round.nextBeat += 1
	if grade == "Miss" then
		round.combo = 0
		if attempted then round.faults += 1 end
	else
		round.hits += 1
		round.combo += 1
		round.bestCombo = math.max(round.bestCombo, round.combo)
	end
	local result = { index = index, grade = grade, gain = 0 }
	round.last = result
	return result
end

function Rules.expireBeats(round, now)
	local nextBeat = round.nextBeat
	while round.nextBeat <= Rules.BeatCount do
		local close = round.start + (round.nextBeat - 0.5) * Rules.BeatInterval + Rules.MaxRhythmCompensation
		if now < close then break end
		finishBeat(round, "Miss", false)
	end
	return nextBeat ~= round.nextBeat
end

function Rules.beat(round, now, oneWayLatency)
	if now >= round.finish then return end
	local adjusted = now - math.clamp(oneWayLatency, 0, Rules.MaxRhythmCompensation)
	local index = Rules.beatIndex(round, adjusted)
	if index < round.nextBeat or index > Rules.BeatCount then return end
	while round.nextBeat < index do
		finishBeat(round, "Miss", false)
	end
	local center = round.start + (index - 1) * Rules.BeatInterval
	local error = math.abs(adjusted - center)
	local grade = error <= Rules.PerfectWindow and "Perfect" or (error <= round.window and "Good" or "Miss")
	return finishBeat(round, grade, true)
end

function Rules.score(round)
	return math.max(0, round.hits - round.faults)
end

return Rules
