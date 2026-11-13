local Balance = {
	BootMax = 30,
	TrainingPowerMax = 10000000,
	FrequencyMax = 4,
	MultiplierMax = 3,
	RankMax = 30,
	PlayerLevelMax = 3,
	UseStudioDataStore = false,
}

function Balance.bootPrice(level)
	return math.ceil(15 * 1.55 ^ level)
end

function Balance.kickPower(level)
	return math.ceil(1.5 ^ level)
end

function Balance.bootTrainingPercent(level)
	return 100 + level * 5
end

function Balance.goalDamage(boots, trainingPower)
	return Balance.kickPower(boots) + math.floor((trainingPower or 0) * Balance.bootTrainingPercent(boots) / 100)
end

function Balance.frequencyPrice(level)
	return 150 * 4 ^ level
end

function Balance.multiplierPrice(level)
	return 250 * 5 ^ level
end

function Balance.interval(level)
	return 10 - level
end

function Balance.multiplier(level)
	return 2 + level
end

function Balance.contractPrice(rank)
	return math.ceil(80 * 1.55 ^ (rank - 1))
end

function Balance.playerUpgradePrice(rank, level)
	return math.ceil(Balance.contractPrice(rank) * (level == 1 and 35 or 65) / 100)
end

function Balance.income(rank, level)
	if rank == 0 then
		return 0
	end
	local base = math.ceil(5 * 1.5 ^ (rank - 1))
	return base + (level - 1) * math.max(1, math.floor(0.15 * base))
end

Balance.Tiers = {
	{ name = "Дворовая лига", tint = Color3.fromRGB(180, 244, 88) },
	{ name = "Академия", tint = Color3.fromRGB(76, 227, 175) },
	{ name = "Первый дивизион", tint = Color3.fromRGB(85, 218, 255) },
	{ name = "Премьер-лига", tint = Color3.fromRGB(147, 154, 255) },
	{ name = "Мировая лига", tint = Color3.fromRGB(245, 134, 255) },
	{ name = "Легенды", tint = Color3.fromRGB(255, 200, 71) },
}

local roles = {
	"Финтёр", "Вингер", "Плеймейкер", "Капитан", "Бомбардир",
	"Маэстро", "Дриблёр", "Снайпер", "Диспетчер", "Спринтер",
	"Таран", "Лидер", "Страйкер", "Дирижёр", "Артист",
	"Тактик", "Форвард", "Мастер паса", "Либеро", "Виртуоз",
	"Ракета", "Шоумен", "Архитектор", "Волшебник", "Феномен",
	"Уличный король", "Десятка", "Король поля", "Машина голов", "Легенда мяча",
}

function Balance.tier(rank)
	return Balance.Tiers[math.clamp(math.ceil(rank / 5), 1, #Balance.Tiers)]
end

function Balance.pitchTier(owned)
	if owned == Balance.RankMax then
		return { name = "Коллекция собрана", tint = Color3.fromRGB(255, 200, 71) }
	end
	return Balance.Tiers[math.floor(owned / 5) + 1]
end

function Balance.playerName(rank)
	return roles[rank]
end

return Balance
