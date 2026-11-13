local Rules = require("../src/shared/GoalRules")

local first = Rules.normalize(nil)
local second = Rules.normalize(nil)
assert(first.level == 1 and first.hp == 8)
assert(Rules.normalize({ level = 2, hp = 5 }).hp == 5)
assert(Rules.normalize({ level = 0 / 0, hp = math.huge }).hp == 8)

local damage, remaining, reward = Rules.hit(first, 1)
assert(damage == 1 and remaining == 7 and reward == 0)
assert(second.level == 1 and second.hp == 8)
damage, remaining, reward = Rules.hit(first, 2, 5)
assert(damage == 7 and remaining == 0 and reward == 12)
assert(first.level == 2 and first.hp == 13)
assert(second.level == 1 and second.hp == 8)

local previous = 0
for level = 1, Rules.MaxLevel do
	local hp = Rules.maxHP(level)
	assert(hp > previous)
	previous = hp
end
local final = Rules.normalize({ level = Rules.MaxLevel, hp = 1 })
damage, remaining, reward = Rules.hit(final, 5)
assert(damage == 1 and remaining == 0 and reward == Rules.reward(Rules.MaxLevel))
assert(final.level == Rules.MaxLevel and final.hp == 0)
assert(Rules.normalize(final).hp == 0 and Rules.hit(final, 100) == nil)

assert(Rules.canShoot({ X = Rules.X, Y = 3, Z = Rules.BallZ - 1 }))
assert(not Rules.canShoot({ X = Rules.X + 9, Y = 3, Z = Rules.BallZ - 1 }))
assert(not Rules.canShoot({ X = Rules.X, Y = 3, Z = Rules.GoalZ }))
assert(not Rules.canShoot({ X = Rules.X, Y = 8, Z = Rules.BallZ - 1 }))
assert(Rules.canReachBall({ X = Rules.X, Y = 3, Z = Rules.BallZ }))
assert(Rules.canReachBall({ X = Rules.X + Rules.BallReach, Y = 3, Z = Rules.BallZ }))
assert(not Rules.canReachBall({ X = Rules.X + Rules.BallReach + 0.01, Y = 3, Z = Rules.BallZ }))
assert(not Rules.canReachBall({ X = Rules.X, Y = 8, Z = Rules.BallZ }))
assert(Rules.canShoot({ X = Rules.X, Y = 3, Z = Rules.ShotFarZ - 1 }))
assert(not Rules.canReachBall({ X = Rules.X, Y = 3, Z = Rules.ShotFarZ - 1 }))
assert(not Rules.canShoot({ X = Rules.X, Y = 3, Z = -26 }), "previous ball position must be outside the new strike area")

for _, sample in {
	{ 0, 0.1 }, { 0.2499, 0.1 }, { 0.25, 0.5 }, { 0.4999, 0.5 }, { 0.50, 1 },
	{ 0.7499, 1 }, { 0.75, 1.5 }, { 0.8999, 1.5 }, { 0.90, 2 }, { 1, 2 },
} do
	assert(Rules.powerBand(sample[1]) == sample[2], "incorrect power band at " .. sample[1])
end
for _, sample in { { -1, 0 }, { 0, 0 }, { 0.5, 0.5 }, { 1, 1 }, { 1.5, 0.5 }, { 2, 0 }, { 2.5, 0.5 } } do
	assert(math.abs(Rules.powerHeight(sample[1] * Rules.PowerSweepSeconds) - sample[2]) < 1e-8)
end
local fractional = Rules.normalize(nil)
damage, remaining = Rules.hit(fractional, 1, 0.1)
assert(damage == 0.1 and remaining == 7.9)
damage, remaining = Rules.hit(fractional, 1, 0.5)
assert(damage == 0.5 and remaining == 7.4)
assert(Rules.normalize(fractional).hp == 7.4)
local lastTenth = Rules.normalize({ level = 1, hp = 0.1 })
damage, remaining, reward = Rules.hit(lastTenth, 1, 0.1)
assert(damage == 0.1 and remaining == 0 and reward == Rules.reward(1))
local highLevel = Rules.normalize({ level = Rules.MaxLevel })
local highHP = highLevel.hp
damage, remaining = Rules.hit(highLevel, 100000, 1.5)
assert(damage == 150000 and remaining == highHP - 150000)

print("Goal rules: shot boundaries, sweep, fractional damage and HP progression passed")
