local GoalRules = {
	MaxLevel = 10000,
	ShotInterval = 0.62,
	RespawnDelay = 1.25,
	X = 0,
	GroundY = 0.06,
	GoalZ = -75,
	TargetHeight = 3.0,
	ShotNearZ = -61,
	ShotFarZ = -43,
	ShotHalfWidth = 8,
	MaxShotDistance = 34,
	BallZ = -52,
	BallRadius = 0.43,
	BallReach = 4,
	ShotWindup = 0.22,
	FlightDuration = 0.26,
	PowerSweepSeconds = 1.20,
	PowerStartLead = 0.15,
	PowerMinTime = 0.16,
	PowerTimeout = 8,
	PowerLatencyCap = 0.12,
	PowerBands = {
		{ minimum = 0, multiplier = 0.1 },
		{ minimum = 0.25, multiplier = 0.5 },
		{ minimum = 0.50, multiplier = 1 },
		{ minimum = 0.75, multiplier = 1.5 },
		{ minimum = 0.90, multiplier = 2 },
	},
}

-- Calculate in tenths so repeated fractional hits reach zero exactly.
local hpScale = 10

function GoalRules.maxHP(level)
	local steps = level - 1
	return 8 + steps * 4 + math.floor(steps ^ 1.55)
end

function GoalRules.reward(level)
	local steps = level - 1
	return 12 + steps * 2 + math.floor(0.15 * steps ^ 1.25)
end

local function isFinite(value)
	return type(value) == "number" and math.abs(value) < math.huge
end

function GoalRules.normalize(raw)
	raw = type(raw) == "table" and raw or {}
	local level = isFinite(raw.level) and math.clamp(math.floor(raw.level), 1, GoalRules.MaxLevel) or 1
	local maxHP = GoalRules.maxHP(level)
	local hp = maxHP
	if isFinite(raw.hp) then
		local minimum = level == GoalRules.MaxLevel and 0 or 1
		local units = math.floor(math.clamp(raw.hp, 0, maxHP) * hpScale + 0.5)
		hp = math.max(minimum, units) / hpScale
	end
	return { level = level, hp = hp }
end

function GoalRules.canShoot(position)
	local x = position.X - GoalRules.X
	local y = position.Y - GoalRules.GroundY
	local z = position.Z
	local distanceZ = z - GoalRules.GoalZ
	local distanceY = y - GoalRules.TargetHeight
	return math.abs(x) <= GoalRules.ShotHalfWidth and y >= 0 and y <= 7
		and z >= GoalRules.ShotNearZ and z <= GoalRules.ShotFarZ
		and x * x + distanceY * distanceY + distanceZ * distanceZ <= GoalRules.MaxShotDistance ^ 2
end

function GoalRules.canReachBall(position)
	local x, z = position.X - GoalRules.X, position.Z - GoalRules.BallZ
	return GoalRules.canShoot(position) and x * x + z * z <= GoalRules.BallReach ^ 2
end

function GoalRules.powerHeight(elapsed)
	local phase = (math.max(0, elapsed) / GoalRules.PowerSweepSeconds) % 2
	return 1 - math.abs(1 - phase)
end

function GoalRules.powerBand(height)
	for index = #GoalRules.PowerBands, 1, -1 do
		local band = GoalRules.PowerBands[index]
		if height >= band.minimum then return band.multiplier, index end
	end
	return GoalRules.PowerBands[1].multiplier, 1
end

function GoalRules.hit(goals, kickPower, damageMultiplier)
	if goals.hp <= 0 then
		return nil
	end

	local level = goals.level
	local hp = math.floor(goals.hp * hpScale + 0.5)
	local damageInTenths = math.min(hp, math.max(1, math.floor(kickPower * (damageMultiplier or 1) * hpScale + 0.5)))
	local damage = damageInTenths / hpScale
	local remaining = (hp - damageInTenths) / hpScale
	goals.hp = remaining
	local reward = 0
	if remaining == 0 then
		reward = GoalRules.reward(level)
		if level < GoalRules.MaxLevel then
			goals.level = level + 1
			goals.hp = GoalRules.maxHP(goals.level)
		end
	end
	return damage, remaining, reward
end

return GoalRules
