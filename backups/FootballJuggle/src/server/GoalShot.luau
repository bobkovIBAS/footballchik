local shared = game:GetService("ReplicatedStorage"):WaitForChild("Juggle")
local Balance = require(shared:WaitForChild("Balance"))
local Rules = require(shared:WaitForChild("GoalRules"))

local GoalShot = {}

function GoalShot.canStart(record, root, now)
	return root and record.data.goals.hp > 0 and now >= record.nextGoalShot and now >= record.goalRespawnAt
		and Rules.canReachBall(root.Position)
end

function GoalShot.apply(record, root, level, multiplier, coinCap, now)
	local goals = record.data.goals
	if level ~= goals.level or not GoalShot.canStart(record, root, now) then
		return nil
	end

	local kickPower = Balance.goalDamage(record.data.boots, record.data.trainingPower)
	local damage, remaining, reward = Rules.hit(goals, kickPower, multiplier)
	record.nextGoalShot = now + Rules.ShotInterval
	local broken = remaining == 0
	if broken then
		record.goalRespawnAt = now + Rules.RespawnDelay
		local previousCoins = record.data.coins
		record.data.coins = math.min(coinCap, previousCoins + reward)
		reward = record.data.coins - previousCoins
	end

	return {
		level = level,
		damage = damage,
		multiplier = multiplier,
		remaining = remaining,
		reward = reward,
		startedAt = now,
		impactAt = now + Rules.ShotWindup + Rules.FlightDuration,
		nextLevel = goals.level,
		nextHP = goals.hp,
		respawnAt = record.goalRespawnAt,
	}
end

return GoalShot
