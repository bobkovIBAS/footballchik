local shared = game:GetService("ReplicatedStorage"):WaitForChild("Juggle")
local Kit = require(script.Parent:WaitForChild("WorldKit"))
local p = Kit.colors
local v, c = Vector3.new, Color3.fromRGB
local stone, metal = Enum.Material.Concrete, Enum.Material.Metal
local blue, amber, red = c(46, 113, 239), c(255, 201, 89), c(237, 63, 91)
local GoalCourse = {}

local function arc(parent, name, x, z, radius, start, finish, count, tint)
	local last
	for i = 0, count do
		local a = math.rad(start + (finish - start) * i / count)
		local point = v(x + radius * math.cos(a), 0.135, z + radius * math.sin(a))
		if last then
			Kit.beam(parent, name, last, point, 0.18, 0.02, tint).CastShadow = false
		end
		last = point
	end
end

local function pennant(parent, x, y, z, tint)
	Kit.beam(parent, "PennantPole", v(x, y, z), v(x, y + 3.4, z), 0.12, 0.12, p.navy, metal, true)
	Kit.disc(parent, "Finial", x, y + 3.45, z, 0.30, 0.30, 0.21, amber, metal)
	Kit.part(parent, "ClubFlag", v(2.5, 1.48, 0.09), v(x + 1.25, y + 2.50, z), tint, Enum.Material.Fabric)
	Kit.part(parent, "ClubFlagStripe", v(0.23, 1.48, 0.12), v(x + 0.24, y + 2.50, z), p.white, Enum.Material.Fabric)
end

local function floodlight(parent, x, z)
	for _, side in { -1, 1 } do
		local foot, top = v(x + side * 0.92, 0, z), v(x + side * 0.65, 20.65, z)
		Kit.beam(parent, "FloodlightLeg", foot, top, 0.31, 0.31, p.navy, metal)
		Kit.disc(parent, "FloodlightFoot", foot.X, 0.28, z, 0.9, 0.9, 0.56, p.stone, stone)
		for row = 0, 5 do
			Kit.beam(parent, "TowerBrace", v(x + side * 0.83, 1.0 + row * 3.27, z + 0.09),
				v(x - side * 0.83, 4.27 + row * 3.27, z + 0.09), 0.12, 0.13, p.navy, metal)
		end
	end
	local cf = CFrame.new(x, 21.0, z + 0.15) * CFrame.Angles(0.19, 0, 0)
	Kit.part(parent, "FloodlightBank", v(6.42, 3.78, 0.42), cf, p.navy, metal)
	for i = -2, 2 do
		for j = -1, 1 do
			local head = Kit.part(parent, "FloodlightLens", v(0.88, 0.75, 0.27), cf * CFrame.new(i * 1.13, j * 1.04, 0.41),
				p.white, Enum.Material.Neon, false, Enum.PartType.Block)
			head.CastShadow = false
		end
	end
end

local function grandstand(parent, x, goal)
	local stand = Kit.model(parent, "Grandstand")
	local z = goal - 14
	Kit.part(stand, "Concourse", v(53.6, 3.2, 8.3), v(x, 1.60, z + 0.4), c(78, 108, 159), stone, true)
	for i = -3, 3 do
		local px = x + i * 7.4
		Kit.part(stand, "ConcoursePanel", v(6.65, 2.75, 0.17), v(px, 1.62, z + 4.61), c(32, 54, 103), metal)
		Kit.part(stand, "ConcretePier", v(0.60, 4.16, 0.53), v(px + 3.52, 2.13, z + 4.6), c(141, 169, 201), stone)
	end
	for row = 0, 4 do
		local height = 3.6 + row * 1.13
		local pz = z + 3.0 - row * 1.62
		Kit.part(stand, "ConcreteTier", v(53.3, 0.69, 1.70), v(x, height - 0.25, pz), c(178, 202, 225), stone)
		for section = -4, 4 do
			local px = x + section * 5.8
			local tint = (row + section) % 4 == 0 and c(110, 176, 255) or blue
			Kit.part(stand, "SeatBank", v(5.33, 0.19, 0.74), v(px, height + 0.20, pz), tint)
			Kit.part(stand, "SeatBacks", v(5.33, 0.49, 0.21), v(px, height + 0.38, pz - 0.31), tint)
		end
	end
	Kit.part(stand, "BalconyFascia", v(53.9, 0.71, 0.48), v(x, 3.26, z + 4.68), c(196, 214, 233), metal)
	for i = -4, 4 do
		local px, height = x + i * 5.95, 14.1 - math.abs(i) ^ 1.63 * 0.47
		local tilt = math.rad(i * -6)
		local cf = CFrame.new(px, height, z - 1.3) * CFrame.Angles(-0.14, 0, tilt)
		Kit.part(stand, "CanopyShell", v(6.15, 0.54, 8.2), cf, c(193, 222, 247), metal)
		Kit.part(stand, "CanopyFascia", v(6.15, 0.23, 0.25), cf * CFrame.new(0, -0.1, 4.18), blue, metal)
		Kit.beam(stand, "CanopyColumn", v(px, 5.8, z - 4.4), v(px, height - 0.27, z - 4.4), 0.25, 0.25, p.navy, metal)
		if i % 2 == 0 then pennant(stand, px, height + 0.26, z - 0.74, i % 4 == 0 and red or blue) end
	end
	local bx, by, bz = x, 16.55, goal - 11.30
	local border = CFrame.new(bx, by, bz)
	Kit.part(stand, "BadgeBorder", v(5.2, 4.7, 0.54), border, amber, metal)
	Kit.part(stand, "BadgeEnamel", v(4.63, 4.1, 0.42), border * CFrame.new(0, 0, 0.36), p.ink, metal)
	Kit.football(stand, v(bx, by + 0.05, bz + 1.06), 1.57)
	for i = -1, 1 do
		Kit.part(stand, "CrestCrown", v(0.57, 0.85 - math.abs(i) * 0.20, 0.40),
			border * CFrame.new(i * 0.70, 2.54, 0.22) * CFrame.Angles(0, 0, -i * 0.30), amber, metal)
	end
end

function GoalCourse.build(parent, rules)
	local Rules = rules or require(shared:WaitForChild("GoalRules"))
	local course = Kit.model(parent, "GoalCourse")
	local x, goal, near, far = Rules.X, Rules.GoalZ, Rules.ShotNearZ, Rules.ShotFarZ
	for stripe = 0, 7 do
		local tint = stripe % 2 == 0 and c(75, 179, 64) or c(88, 192, 67)
		Kit.part(course, "PitchStripe", v(55.3, 0.085, 5.9), v(x, 0.052, goal - 7.65 + (stripe + 0.5) * 5.9), tint, Enum.Material.Grass)
	end
	for _, side in { -1, 1 } do
		Kit.part(course, "Touchline", v(0.23, 0.025, 44.2), v(x + side * 26.1, 0.116, goal + 15.8), p.white)
		Kit.part(course, "EndLine", v(52.45, 0.025, 0.23), v(x, 0.116, goal + 15.8 + side * 22.1), p.white)
		Kit.part(course, "PenaltyBoxSide", v(0.19, 0.025, 16), v(x + side * 14.0, 0.118, goal + 1.7), p.white)
		Kit.part(course, "GoalBoxSide", v(0.19, 0.025, 10), v(x + side * 10.2, 0.118, goal - 1.3), p.white)
		Kit.disc(course, "PostSocket", x + side * 8.15, 0.113, goal, 1.56, 1.56, 0.055, p.navy, Enum.Material.Rubber)
		Kit.flag(course, x + side * 26.25, goal - 4.8, 9.0, red)
		Kit.flag(course, x + side * 26.25, goal + 36.2, 5.5, side == -1 and red or blue)
		floodlight(course, x + side * 24.4, goal - 9.2)
	end
	Kit.part(course, "PenaltyBoxEdge", v(28.2, 0.025, 0.19), v(x, 0.118, goal + 9.7), p.white)
	Kit.part(course, "GoalBoxEdge", v(20.6, 0.025, 0.19), v(x, 0.118, goal + 3.7), p.white)
	Kit.part(course, "Midfield", v(52.3, 0.025, 0.19), v(x, 0.121, goal + 24.8), p.white)
	Kit.disc(course, "CenterSpot", x, 0.127, goal + 24.8, 0.52, 0.52, 0.025, p.white)
	arc(course, "CenterCircle", x, goal + 24.8, 8.0, 0, 360, 30, p.white)
	arc(course, "PenaltyArc", x, goal + 6.6, 6.9, 27, 153, 12, p.white)
	for _, zz in { near, far } do
		for _, side in { -1, 1 } do
			Kit.part(course, "StrikeAreaCorner", v(1.30, 0.025, 0.13), v(x + side * 7.35, 0.135, zz), p.mint)
			Kit.part(course, "StrikeAreaCorner", v(0.13, 0.025, 1.4), v(x + side * 8, 0.135, zz + (zz == near and 0.7 or -0.7)), p.mint)
		end
	end
	grandstand(course, x, goal)
	return course
end

return GoalCourse
