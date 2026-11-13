local Kit = require(script.Parent:WaitForChild("WorldKit"))

local Plaza = {}
local v, rgb = Vector3.new, Color3.fromRGB
local origin = CFrame.new(-70, 0, -45) * CFrame.Angles(0, math.rad(52), 0)
local navy, blue, cyan = rgb(18, 33, 72), rgb(29, 71, 161), rgb(64, 213, 255)
local purple, amber, gold = rgb(191, 112, 255), rgb(255, 192, 70), rgb(219, 151, 44)
local ivory, paving = rgb(248, 232, 201), rgb(219, 206, 184)
local metal, stone, neon = Enum.Material.Metal, Enum.Material.Limestone, Enum.Material.Neon

local function block(parent, name, size, position, tint, material, rotation)
	local piece = Kit.part(parent, name, size, origin * CFrame.new(position) * (rotation or CFrame.identity), tint, material)
	piece.CastShadow = size.Y > 0.55 and material ~= neon
	return piece
end

local function rounded(parent, name, size, position, tint, material, rotation)
	local piece = Kit.ellipsoid(parent, name, size, origin * CFrame.new(position) * (rotation or CFrame.identity),
		tint, material)
	piece.CastShadow = false
	return piece
end

local function disc(parent, name, x, y, z, diameter, height, tint, material, solid)
	local piece = Kit.part(parent, name, v(height, diameter, diameter),
		origin * CFrame.new(x, y, z) * CFrame.Angles(0, 0, math.pi / 2),
		tint, material, solid, Enum.PartType.Cylinder)
	piece.CastShadow = height > 0.25
	return piece
end

local function beam(parent, name, a, b, width, tint, material)
	local piece = Kit.beam(parent, name, origin * a, origin * b, width, width, tint, material, true)
	piece.CastShadow = false
	return piece
end

local function polyline(parent, name, points, width, tint, material)
	for i = 2, #points do
		beam(parent, name, points[i - 1], points[i], width, tint, material)
	end
end

local function badge(parent, name, x, y, z, diameter, tint)
	block(parent, name .. "Rim", v(0.24, diameter, diameter), v(x, y, z), gold, metal,
		CFrame.Angles(0, math.pi / 2, 0)).Shape = Enum.PartType.Cylinder
	block(parent, name .. "Face", v(0.11, diameter - 0.23, diameter - 0.23), v(x, y, z + 0.13), tint,
		Enum.Material.SmoothPlastic, CFrame.Angles(0, math.pi / 2, 0)).Shape = Enum.PartType.Cylinder
end

local function sign(parent, name, x, y, z, width, height, title, accent)
	block(parent, name .. "Frame", v(width + 0.42, height + 0.4, 0.55), v(x, y, z - 0.06), gold, metal)
	local board = block(parent, name, v(width, height, 0.58), v(x, y, z + 0.08), navy, metal)
	Kit.lettering(board, title, nil, accent)
	board.Lettering.CanvasSize = Vector2.new(math.round(width / height * 90), 90)
	beam(parent, name .. "Light", v(x - width / 2, y - height / 2, z + 0.4),
		v(x + width / 2, y - height / 2, z + 0.4), 0.11, accent, neon)
end

local function planter(parent, x, z, scale)
	disc(parent, "Planter", x, 0.30, z, 3.6 * scale, 0.6, ivory, stone)
	disc(parent, "PlanterBed", x, 0.60, z, 3.3 * scale, 0.13, rgb(79, 131, 46), Enum.Material.Grass)
	local center = origin * v(x, 0.65, z)
	Kit.shrub(parent, center.X, center.Y, center.Z, 1.15 * scale)
end

local function bench(parent, x, z, tint)
	for _, side in {-1, 1} do
		block(parent, "BenchFoot", v(0.22, 0.62, 1.15), v(x + side * 1.42, 0.51, z), navy, metal)
	end
	block(parent, "BenchSeat", v(3.55, 0.16, 1.16), v(x, 0.86, z), tint, Enum.Material.SmoothPlastic)
	block(parent, "BenchBack", v(3.55, 0.72, 0.16), v(x, 1.19, z - 0.52), tint, Enum.Material.SmoothPlastic)
end

local function banner(parent, x, z, height)
	beam(parent, "BannerMast", v(x - 1.2, 0.18, z), v(x - 1.2, height, z), 0.20, navy, metal)
	beam(parent, "BannerRod", v(x - 1.4, height, z), v(x + 1.4, height, z), 0.16, gold, metal)
	local cloth = block(parent, "BluePennant", v(2.15, 3.15, 0.10), v(x, height - 1.65, z), blue, Enum.Material.Fabric)
	cloth.CastShadow = false
	Kit.lettering(cloth, "⚽", nil, ivory)
	cloth.Lettering.CanvasSize = Vector2.new(74, 108)
	beam(parent, "BannerHem", v(x - 1.07, height - 3.19, z + 0.07),
		v(x + 1.07, height - 3.19, z + 0.07), 0.095, gold, metal)
end

local function cup(parent, x, y, z, scale)
	local trophy = Kit.model(parent, "GoldCup")
	local function layer(name, lift, width, thickness, tint)
		disc(trophy, name, x, y + lift * scale, z, width * scale, thickness * scale, tint, metal)
	end
	layer("Foot", 0.20, 2.1, 0.4, gold)
	layer("BaseTrim", 0.42, 1.85, 0.12, amber)
	layer("Stem", 0.83, 0.78, 0.78, gold)
	layer("StemCollar", 1.24, 1.22, 0.20, amber)
	for i = 0, 14 do
		local progress = i / 14
		layer("Bowl", 1.36 + i * 0.156, 1.05 + math.sin(progress * math.pi / 2) * 2.53, 0.168,
			gold:Lerp(amber, 0.18 + progress * 0.26))
	end
	layer("RolledRim", 3.61, 3.78, 0.17, amber)
	layer("CupInterior", 3.70, 3.45, 0.015, rgb(136, 83, 25))
	for _, side in {-1, 1} do
		local points = {}
		for i = 0, 10 do
			local phase = i / 10
			local reach = 1.67 - phase * 0.45 + 0.90 * math.sin(phase * math.pi)
			table.insert(points, v(x + reach * scale * side, y + (3.42 - 1.62 * phase) * scale, z))
		end
		polyline(trophy, "Handle", points, 0.24 * scale, amber, metal)
	end
end

local function arch(parent)
	local z = -9.4
	for _, side in {-1, 1} do
		local x = side * 10.0
		block(parent, "ArchPlinth", v(2.72, 0.55, 2.55), v(x, 0.33, z), paving, stone)
		block(parent, "ArchColumn", v(1.33, 9.45, 1.36), v(x, 5.10, z), ivory, stone)
		block(parent, "ColumnInlay", v(0.16, 7.7, 0.10), v(x - side * 0.42, 5.1, z + 0.73), cyan, neon)
		block(parent, "ArchCapital", v(2.27, 0.52, 2.12), v(x, 9.87, z), gold, metal)
		beam(parent, "ArchShoulder", v(x, 10.08, z), v(side * 2.3, 12.35, z), 0.96, blue, metal)
		beam(parent, "ArchGoldEdge", v(x, 10.61, z + 0.39), v(side * 2.4, 12.80, z + 0.39), 0.19, amber, metal)
		beam(parent, "ArchCyanEdge", v(x - side * 0.27, 10.39, z + 0.49), v(side * 2.4, 12.55, z + 0.49), 0.14, cyan, neon)
		banner(parent, side * 13.1, z + 0.15, 7.7)
		planter(parent, side * 11.7, z + 1.73, 0.93)
		for tier = 1, 2 do
			local seatZ = z + 3.6 - tier * 1.35
			block(parent, "Terrace", v(4.9, 0.5 * tier, 1.32), v(side * 15.8, 0.25 * tier, seatZ), ivory, stone)
			for index = -1, 1 do
				local seatX = side * 15.8 + index * 1.48
				block(parent, "Seat", v(1.35, 0.16, 0.97), v(seatX, 0.5 * tier + 0.10, seatZ), blue)
				block(parent, "SeatBack", v(1.35, 0.61, 0.16), v(seatX, 0.5 * tier + 0.36, seatZ - 0.39), blue)
			end
		end
	end
	sign(parent, "AcademySign", 0, 10.72, z + 0.46, 18.45, 2.88, "АКАДЕМИЯ", cyan)
	badge(parent, "AcademyCrest", 0, 13.08, z + 0.40, 4.55, blue)
	Kit.football(parent, origin * v(0, 13.08, z + 0.89), 1.65, false)
	for _, side in {-1, 1} do
		for i = 0, 6 do
			local angle = math.rad(8 + i * 11)
			local x, y = side * (2.4 + math.sin(angle) * 0.64), 11.6 + i * 0.39
			rounded(parent, "LaurelLeaf", v(0.39, 0.84, 0.12), v(x, y, z + 0.63),
				i % 2 == 0 and amber or gold, metal, CFrame.Angles(0, side * 0.21, -side * (0.92 - i * 0.10)))
		end
	end
end

local function emblem(parent, kind, x, y, z)
	if kind == "team" then
		for _, side in {-1, 0, 1} do
			local lift = side == 0 and 0.12 or -0.11
			rounded(parent, "TeamHead", v(0.43, 0.43, 0.12), v(x + side * 0.52, y + 0.31 + lift, z), ivory)
			rounded(parent, "TeamTorso", v(0.59, 0.60, 0.10), v(x + side * 0.52, y - 0.22 + lift, z), ivory)
		end
	elseif kind == "tricks" then
		rounded(parent, "RunnerHead", v(0.43, 0.43, 0.15), v(x + 0.30, y + 0.63, z), ivory)
		polyline(parent, "Runner", {v(x - 0.68, y - 0.61, z), v(x - 0.10, y - 0.12, z),
			v(x + 0.22, y + 0.38, z), v(x + 0.65, y + 0.17, z)}, 0.17, ivory)
		polyline(parent, "Runner", {v(x + 0.51, y - 0.70, z), v(x + 0.37, y - 0.34, z),
			v(x - 0.10, y - 0.12, z)}, 0.17, ivory)
		beam(parent, "RunnerArm", v(x + 0.22, y + 0.38, z), v(x - 0.49, y + 0.20, z), 0.15, ivory)
	else
		block(parent, "Calendar", v(1.50, 1.42, 0.09), v(x, y, z), amber, metal)
		block(parent, "CalendarFace", v(1.23, 1.08, 0.10), v(x, y - 0.09, z + 0.065), navy)
		for _, side in {-1, 1} do
			block(parent, "CalendarBinding", v(0.12, 0.40, 0.12), v(x + side * 0.42, y + 0.65, z + 0.09), ivory)
		end
		polyline(parent, "Checkmark", {v(x - 0.41, y - 0.03, z + 0.13), v(x - 0.14, y - 0.30, z + 0.13),
			v(x + 0.43, y + 0.22, z + 0.13)}, 0.12, amber)
	end
end

local function platform(parent, name, anchorName, kind, title, action, x, z, accent, tint)
	local model = Kit.model(parent, name)
	disc(model, "StonePlinth", x, 0.095, z, 14.8, 0.19, ivory, stone, true)
	disc(model, "PlatformRim", x, 0.175, z, 14.42, 0.075, accent, neon)
	disc(model, "PlatformDeck", x, 0.205, z, 14.11, 0.10, tint, Enum.Material.SmoothPlastic)
	local circleZ = z + 1.8
	local radius = 3.25
	local glow = disc(model, "InteractionGlow", x, 0.273, circleZ, radius * 2, 0.035, accent, neon)
	glow.Transparency = 0.35
	disc(model, "CircleCenter", x, 0.294, circleZ, 5.94, 0.020, tint:Lerp(navy, 0.22), Enum.Material.SmoothPlastic)
	local anchor = block(model, anchorName, v(0.2, 0.2, 0.2), v(x, 3.18, circleZ), ivory)
	anchor.Transparency = 1
	anchor:SetAttribute("CircleRadius", radius)
	local interaction = Instance.new("Attachment")
	interaction.Name = "Interaction"
	interaction.Parent = anchor
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText, prompt.ObjectText = action, title
	prompt.KeyboardKeyCode, prompt.GamepadKeyCode = Enum.KeyCode.E, Enum.KeyCode.ButtonX
	prompt.RequiresLineOfSight, prompt.ClickablePrompt = false, true
	prompt.MaxActivationDistance = radius
	prompt.HoldDuration = 0
	prompt.Style = Enum.ProximityPromptStyle.Custom
	prompt.Parent = interaction
	local bounds = block(model, "Bounds", v(14.4, 14, 14.4), v(x, 5, z), navy)
	bounds.Transparency, bounds.CastShadow = 1, false
	local back = z - 4.6
	local signHeight = kind == "daily" and 3.47 or 4.9
	for _, side in {-1, 1} do
		local postX = x + side * 5.1
		block(model, "SignFoot", v(0.98, 0.35, 0.94), v(postX, 0.41, back), ivory, stone)
		block(model, "SignPillar", v(0.61, signHeight, 0.61), v(postX, signHeight / 2 + 0.35, back), navy, metal)
		block(model, "PillarLight", v(0.11, signHeight - 0.67, 0.10), v(postX, signHeight / 2 + 0.34, back + 0.35), accent, neon)
		block(model, "SignCap", v(0.98, 0.27, 0.96), v(postX, signHeight + 0.33, back), amber, metal)
	end
	sign(model, "PlatformSign", x, signHeight, back + 0.16, 10.7, 1.70, title, accent)
	badge(model, "PlatformCrest", x, signHeight + 1.83, back + 0.19, 2.68, tint)
	emblem(model, kind, x, signHeight + 1.83, back + 0.42)
	return model
end

local function teamDetails(parent, x, z)
	local panelZ = z - 3.51
	block(parent, "TacticsFrame", v(5.15, 2.55, 0.26), v(x - 1.21, 2.10, panelZ), gold, metal)
	block(parent, "TacticsBoard", v(4.87, 2.28, 0.11), v(x - 1.21, 2.10, panelZ + 0.17), rgb(30, 88, 120))
	local left, right, front = x - 3.29, x + 0.87, panelZ + 0.24
	polyline(parent, "TacticsPitch", {v(left, 1.34, front), v(left, 2.86, front), v(right, 2.86, front),
		v(right, 1.34, front), v(left, 1.34, front)}, 0.045, ivory)
	beam(parent, "TacticsHalfway", v(x - 1.21, 1.34, front), v(x - 1.21, 2.86, front), 0.05, ivory)
	for _, spec in {{-2.70, 2.47}, {-2.10, 1.70}, {-1.52, 2.36}, {-0.42, 1.88}, {0.21, 2.48}} do
		rounded(parent, "TacticsMagnet", v(0.18, 0.18, 0.07), v(x + spec[1], spec[2], front + 0.02), cyan)
	end
	for i = 0, 1 do
		local shirtX = x + 2.10 + i * 1.30
		block(parent, "KitTorso", v(0.84, 1.11, 0.19), v(shirtX, 1.35, z - 2.6), blue, Enum.Material.Fabric)
		for _, side in {-1, 1} do
			block(parent, "KitSleeve", v(0.31, 0.43, 0.21), v(shirtX + side * 0.45, 1.64, z - 2.6), blue,
				Enum.Material.Fabric, CFrame.Angles(0, 0, side * 0.41))
		end
		local number = block(parent, "KitNumber", v(0.59, 0.62, 0.025), v(shirtX, 1.37, z - 2.49), blue, Enum.Material.Fabric)
		Kit.lettering(number, i == 0 and "10" or "7", nil, ivory)
		number.Lettering.CanvasSize = Vector2.new(55, 60)
	end
	cup(parent, x + 4.15, 0.38, z - 0.95, 0.32)
	bench(parent, x - 3.08, z + 0.21, blue)
end

local function trickDetails(parent, x, z)
	for _, offset in {-2.9, -0.8} do
		local dx, dz = x + offset, z - 2.5
		disc(parent, "DummyFoot", dx, 0.38, dz, 1.21, 0.15, gold, metal)
		rounded(parent, "DummyHead", v(0.61, 0.66, 0.43), v(dx, 2.82, dz), amber, metal)
		polyline(parent, "DummyOutline", {v(dx - 0.36, 0.50, dz), v(dx - 0.36, 1.14, dz), v(dx - 0.62, 1.40, dz),
			v(dx - 0.62, 2.23, dz), v(dx + 0.62, 2.23, dz), v(dx + 0.62, 1.40, dz),
			v(dx + 0.36, 1.14, dz), v(dx + 0.36, 0.50, dz)}, 0.14, amber, metal)
	end
	for i = 0, 3 do
		local lineZ = z - 1.7 + i * 0.61
		beam(parent, "AgilityRung", v(x + 1.24, 0.274, lineZ), v(x + 2.71, 0.274, lineZ), 0.052, amber)
	end
	for _, edge in {1.24, 2.71} do
		beam(parent, "AgilityRail", v(x + edge, 0.274, z - 1.7), v(x + edge, 0.274, z + 0.13), 0.052, amber)
	end
	for _, offset in {-4.4, 4.1} do
		local dx = x + offset
		block(parent, "ConeFoot", v(0.74, 0.09, 0.74), v(dx, 0.31, z + 1.0), rgb(245, 111, 35))
		for i = 0, 3 do
			local width = 0.59 - i * 0.12
			disc(parent, "ConeTier", dx, 0.48 + i * 0.22, z + 1.0, width, 0.22,
				i == 2 and ivory or rgb(245, 111, 35), Enum.Material.SmoothPlastic)
		end
	end
	Kit.football(parent, origin * v(x + 3.4, 0.76, z - 2.4), 0.52, false)
	Kit.football(parent, origin * v(x + 4.5, 0.73, z - 2.7), 0.48, false)
end

local function dailyDetails(parent, x, z)
	local tx, tz = x - 2.4, z - 2.7
	block(parent, "TaskFrame", v(3.5, 2.10, 0.23), v(tx, 1.57, tz), gold, metal)
	block(parent, "TaskBoard", v(3.29, 1.88, 0.09), v(tx, 1.57, tz + 0.16), blue)
	for i = 0, 2 do
		local y = 2.15 - i * 0.55
		block(parent, "TaskBox", v(0.34, 0.34, 0.045), v(tx - 1.25, y, tz + 0.23), ivory)
		block(parent, "TaskBoxInset", v(0.23, 0.23, 0.045), v(tx - 1.25, y, tz + 0.255), blue)
		beam(parent, "TaskLine", v(tx - 0.91, y, tz + 0.23), v(tx + 1.18 - i * 0.23, y, tz + 0.23), 0.065, ivory)
	end
	local chestX, chestZ = x + 2.25, z - 2.6
	block(parent, "RewardChest", v(2.65, 1.30, 1.56), v(chestX, 0.92, chestZ), blue, metal)
	local lid = block(parent, "BarrelLid", v(2.68, 1.50, 1.50), v(chestX, 1.52, chestZ), blue, metal)
	lid.Shape = Enum.PartType.Cylinder
	for _, side in {-1, 1} do
		block(parent, "ChestBand", v(0.20, 1.43, 1.63), v(chestX + side * 1.02, 0.95, chestZ), amber, metal)
		block(parent, "ChestLidBand", v(0.21, 1.55, 1.55), v(chestX + side * 1.02, 1.52, chestZ), amber, metal).Shape = Enum.PartType.Cylinder
	end
	block(parent, "ChestLatch", v(0.47, 0.53, 0.18), v(chestX, 1.36, chestZ + 0.82), amber, metal)
	block(parent, "ChestKeyhole", v(0.11, 0.22, 0.025), v(chestX, 1.36, chestZ + 0.93), navy)
end

function Plaza.build(parent)
	local court = Kit.model(parent, "AcademyHall")
	court:SetAttribute("OpenPlaza", true)
	disc(court, "PavedCourt", 0, 0.071, 0, 28.4, 0.14, paving, stone, true)
	disc(court, "CourtBorder", 0, 0.151, 0, 18.5, 0.024, blue, metal)
	disc(court, "GoldInlay", 0, 0.163, 0, 17.73, 0.025, amber, neon)
	disc(court, "CenterStone", 0, 0.178, 0, 17.45, 0.024, ivory, stone)
	for _, side in {-1, 1} do
		block(court, "PavedLink", v(4.2, 0.105, 12.4), v(side * 8.2, 0.052, 12.05), paving, stone,
			CFrame.Angles(0, math.rad(-side * 44), 0))
	end
	disc(court, "TrophyFoot", 0, 0.33, 0, 7.25, 0.38, blue, metal, true)
	disc(court, "TrophyHalo", 0, 0.53, 0, 7.05, 0.115, cyan, neon)
	disc(court, "TrophyPedestal", 0, 1.40, 0, 5.65, 1.80, navy, metal, true)
	disc(court, "PedestalCrown", 0, 2.35, 0, 6.09, 0.19, gold, metal)
	cup(court, 0, 2.45, 0, 1.50)
	badge(court, "TrophyBadge", 0, 1.40, 2.86, 1.64, blue)
	Kit.football(court, origin * v(0, 1.41, 3.14), 0.61, false)
	for _, side in {-1, 1} do
		for i = 0, 6 do
			local x = side * (1.90 + 0.29 * i)
			local y = 4.08 + 0.25 * i + 0.028 * i * i
			rounded(court, "CupLaurel", v(0.33, 0.74, 0.14), v(x, y, 0.62), amber, metal,
				CFrame.Angles(0, 0, -side * (1.16 - i * 0.13)))
		end
	end
	arch(court)
	for _, side in {-1, 1} do
		planter(court, side * 5.1, 2.6, 0.81)
		bench(court, side * 7.3, -5.0, blue)
		local world = origin * v(side * 10.4, 0, 10.3)
		Kit.lantern(court, world.X, world.Z, 2.62, false)
	end

	local team = platform(parent, "TeamCourt", "TeamBench", "team", "КОМАНДА", "Открыть команду", -16.3, 4.2, cyan, blue)
	teamDetails(team, -16.3, 4.2)
	local tricks = platform(parent, "TrickCourt", "TrickBoard", "tricks", "ФИНТЫ", "Открыть финты", 16.3, 4.2, purple, rgb(101, 62, 170))
	trickDetails(tricks, 16.3, 4.2)
	local daily = platform(parent, "ClubAlley", "DailyBoard", "daily", "ЗАДАНИЕ ДНЯ", "Открыть задание", 0, 18.0, amber, rgb(70, 88, 142))
	dailyDetails(daily, 0, 18.0)
	for _, side in {-1, 1} do
		banner(daily, side * 7.0, 16.9, 4.95)
		planter(daily, side * 7.0, 18.7, 0.83)
	end
	return court
end

return Plaza
