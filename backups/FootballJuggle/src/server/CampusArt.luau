local Lighting = game:GetService("Lighting")
local Kit = require(script.Parent:WaitForChild("WorldKit"))
local Pitch = require(script.Parent:WaitForChild("Pitch"))
local ClubMap = require(script.Parent:WaitForChild("ClubMap"))
local GoalCourse = require(script.Parent:WaitForChild("GoalCourse"))
local p = Kit.colors
local v, rgb = Vector3.new, Color3.fromRGB
local CampusArt = {}
local version = 8

local stone, metal = Enum.Material.Limestone, Enum.Material.Metal
local warm, glow, dark = rgb(233, 219, 196), rgb(246, 177, 59), rgb(23, 40, 67)

local function walk(parent, from, to, width)
	local cf = CFrame.lookAt((from + to) / 2, to)
	local length = (to - from).Magnitude
	Kit.part(parent, "PavedWalk", v(width, 0.095, length + 0.28), cf, warm, stone).CastShadow = false
	for _, side in { -1, 1 } do
		Kit.part(parent, "StoneCurb", v(0.30, 0.12, length), cf * CFrame.new(side * width / 2, 0.016, 0),
			rgb(250, 235, 215), stone).CastShadow = false
	end
end

local function bench(parent, x, z, yaw)
	local cf = CFrame.new(x, 0, z) * CFrame.Angles(0, yaw, 0)
	for _, side in { -1, 1 } do
		Kit.part(parent, "BenchLeg", v(0.29, 0.88, 0.67), cf * CFrame.new(side * 1.65, 0.50, 0), p.navy, metal)
		Kit.part(parent, "BenchBackPost", v(0.20, 1.16, 0.16), cf * CFrame.new(side * 1.65, 1.36, -0.30), p.navy, metal)
	end
	for i = -1, 1 do
		Kit.part(parent, "BenchSlat", v(4.17, 0.13, 0.23), cf * CFrame.new(0, 0.96, 0.24 * i),
			rgb(182, 110, 61), Enum.Material.WoodPlanks)
	end
	for i = 0, 1 do
		Kit.part(parent, "BackrestSlat", v(4.17, 0.29, 0.15), cf * CFrame.new(0, 1.35 + 0.31 * i, -0.35),
			rgb(192, 123, 72), Enum.Material.WoodPlanks)
	end
end

local function crown(parent, x, y, z, scale, tint)
	Kit.beam(parent, "TreeTrunk", v(x, y, z), v(x + 0.23 * scale, y + 4.0 * scale, z),
		0.49 * scale, 0.49 * scale, rgb(120, 83, 52), Enum.Material.Wood, true).CastShadow = false
	for _, spec in {
		{ -0.86, 3.95, -0.55, 4.55, 3.74, 4.1, 0.0 },
		{ 0.76, 4.64, 0.21, 4.36, 4.2, 4.37, 0.22 },
		{ -0.25, 5.34, 0.03, 3.92, 3.26, 3.60, 0.13 },
	} do
		local dx, dy, dz, sx, sy, sz, amount = table.unpack(spec)
		local leaves = Kit.ellipsoid(parent, "Canopy", v(sx, sy, sz) * scale, v(x + dx * scale, y + dy * scale, z + dz * scale),
			tint:Lerp(rgb(133, 201, 70), amount), Enum.Material.Grass)
		leaves.CastShadow = amount == 0.22
	end
end

local function garden(parent, x, z, width, depth, h, treeScale)
	Kit.disc(parent, "PlanterWall", x, h / 2, z, width, depth, h, rgb(209, 188, 158), stone)
	Kit.disc(parent, "PlanterCoping", x, h + 0.02, z, width + 0.25, depth + 0.25, 0.16, warm, stone)
	Kit.disc(parent, "PlantedBed", x, h + 0.107, z, width - 0.36, depth - 0.36, 0.035,
		rgb(77, 142, 64), Enum.Material.Grass).CastShadow = false
	for i, offsets in { { -0.28, 0.10 }, { 0.09, -0.25 }, { 0.30, 0.12 } } do
		Kit.shrub(parent, x + offsets[1] * width, h + 0.13, z + offsets[2] * depth, 0.65 + 0.19 * i)
	end
	if treeScale then crown(parent, x - width * 0.09, h + 0.1, z, treeScale, rgb(47, 130, 77)) end
end

local function welcome(parent)
	local square = Kit.model(parent, "BallPlaza")
	local z = 9.7
	for _, spec in {
		{ 30.8, 27.8, 0.111, 0.055, rgb(199, 178, 148), stone },
		{ 30.3, 27.3, 0.139, 0.030, rgb(246, 231, 207), stone },
		{ 24.6, 22.2, 0.157, 0.019, rgb(220, 201, 174), stone },
		{ 23.9, 21.5, 0.169, 0.019, warm, stone },
		{ 13.8, 13.8, 0.185, 0.045, rgb(190, 168, 137), stone },
		{ 12.9, 12.9, 0.215, 0.035, rgb(80, 143, 60), Enum.Material.Grass },
		{ 9.6, 9.6, 0.44, 0.43, rgb(124, 89, 57), stone },
		{ 9.66, 9.66, 0.66, 0.095, glow, Enum.Material.SmoothPlastic },
		{ 9.22, 9.22, 0.76, 0.16, rgb(238, 206, 153), stone },
		{ 7.58, 7.58, 0.85, 0.10, rgb(250, 224, 174), metal },
	} do
		local plate = Kit.disc(square, "PlazaRing", 0, spec[3], z, spec[1], spec[2], spec[4], spec[5], spec[6])
		plate.CastShadow = spec[3] >= 0.44
	end
	Kit.football(square, v(0, 3.93, z), 3.23, true)
	for _, angle in { 50, 82, 113, 230, 262, 293 } do
		local a = math.rad(angle)
		Kit.shrub(square, math.sin(a) * 5.65, 0.24, z + math.cos(a) * 5.65, 0.69)
	end
	for _, side in { -1, 1 } do
		Kit.lantern(square, side * 12.8, 22.4, 3.45, false)
		Kit.lantern(square, side * 10.9, -3.8, 3.65, false)
		bench(square, side * 12.8, 30.0, -side * 0.33)
	end
	for _, zz in { 36.0, 25.8, -4.2, -6.4 } do
		for _, side in { -1, 1 } do
			local from, to = v(0, 0.135, zz - 0.59), v(side * 0.9, 0.135, zz + 0.21)
			Kit.beam(square, "GoalRouteInlay", from, to, 0.28, 0.021, rgb(189, 127, 50), metal).CastShadow = false
		end
	end
end

local function portals(parent)
	local gallery = Kit.model(parent, "StadiumGallery")
	local x, z, lift = 40.5, -30.4, 3.6
	Kit.part(gallery, "RockTerraceBase", v(33.7, lift, 12.9), v(x, lift / 2, z - 0.25), rgb(92, 99, 148),
		Enum.Material.Slate, true)
	for step = 1, 8 do
		local h = lift * step / 8
		Kit.part(gallery, "GalleryStep", v(14.5, h, 0.91), v(x - 2, h / 2, z + 13.20 - step * 0.87),
			rgb(127, 120, 171), stone, true)
	end
	local deck = Kit.model(gallery, "LockedPortals")
	Kit.part(deck, "GalleryTerrace", v(35, 0.095, 14.2), v(x, 0.059, z + 1), rgb(104, 101, 157), stone)
	Kit.part(deck, "RockRetainingWall", v(34.4, 4.9, 2.4), v(x, 2.25, z - 6.6), rgb(102, 111, 166), Enum.Material.Slate)
	for i = 0, 2 do
		local px = x + (i - 1) * 10.25
		local tint = ({ rgb(80, 184, 223), rgb(151, 116, 225), rgb(212, 111, 194) })[i + 1]
		Kit.disc(deck, "PortalFoot", px, 0.20, z, 8.15, 5.15, 0.35, p.ink, stone)
		Kit.disc(deck, "PortalFootTrim", px, 0.39, z, 7.7, 4.85, 0.07, tint, Enum.Material.Neon)
		Kit.arch(deck, "InactiveGate", px, z, 3.35, 5.53, rgb(65, 64, 138), tint)
		for _, side in { -1, 1 } do
			Kit.neon(deck, "PortalColumnLight", v(0.22, 5.02, 0.20), v(px + side * 3.38, 2.86, z + 0.64), tint)
		end
		local screen = Kit.part(deck, "InactiveVeil", v(6.2, 5.15, 0.14), v(px, 3.05, z + 0.13),
			tint, Enum.Material.Glass)
		screen.Transparency, screen.CastShadow = 0.32, false
		local last
		for j = 0, 6 do
			local a = j * math.pi / 6
			local point = v(px + math.cos(a) * 0.57, 3.92 + math.sin(a) * 0.65, z + 0.43)
			if last then
				Kit.beam(deck, "LockShackle", last, point, 0.21, 0.21, p.white,
					Enum.Material.SmoothPlastic, true).CastShadow = false
			end
			last = point
		end
		Kit.part(deck, "LockBody", v(1.68, 1.09, 0.24), v(px, 3.44, z + 0.43),
			p.white, Enum.Material.SmoothPlastic).CastShadow = false
		Kit.part(deck, "Keyway", v(0.25, 0.40, 0.12), v(px, 3.44, z + 0.59), dark, metal).CastShadow = false
	end
	Kit.part(deck, "GallerySignMast", v(0.42, 8.46, 0.42), v(x, 4.31, z - 0.38), p.ink, metal).CastShadow = false
	Kit.part(deck, "GallerySignBracket", v(0.33, 0.36, 1.66), v(x, 8.46, z + 0.39), p.ink, metal).CastShadow = false
	Kit.sign(deck, "ComingSoon", CFrame.new(x, 8.81, z + 1.16),
		12.7, 2.64, "АРЕНЫ", "СКОРО", rgb(193, 146, 242))
	deck:PivotTo(deck:GetPivot() + v(0, lift, 0))
	local placement = CFrame.new(69, 0, -49) * CFrame.Angles(0, math.rad(-50), 0)
	gallery:PivotTo(placement * CFrame.new(-x, 0, -z) * gallery:GetPivot())
end

local function grounds(parent)
	local base = Kit.model(parent, "Grounds")
	local width, depth = 240, 214
	local centerX, centerZ = -4, -12
	Kit.part(base, "Foundation", v(width, 3, depth), v(centerX, -1.5, centerZ),
		rgb(87, 159, 65), Enum.Material.Grass, true)
	walk(base, v(0, 0.047, 50), v(0, 0.047, 9.7), 13.7)
	walk(base, v(0, 0.047, 9.7), v(0, 0.047, -35.31), 9)
	for z = 25, 49, 3 do
		Kit.part(base, "PavingJoint", v(13.3, 0.014, 0.048), v(0, 0.102, z), rgb(214, 199, 174), stone).CastShadow = false
		Kit.part(base, "PavingJoint", v(0.052, 0.014, 2.94), v(z % 2 == 0 and -2.22 or 2.22, 0.102, z - 1.5),
			rgb(214, 199, 174), stone).CastShadow = false
	end
	local routes = {
		{ 9, v(-9.2, 0.047, 14.13), v(-34, 0.047, 30), v(-40, 0.047, 30) },
		{ 8.5, v(9.2, 0.047, 14.25), v(31, 0.047, 27.5), v(39, 0.047, 31.7) },
		{ 8.5, v(-10, 0.047, 1), v(-32, 0.047, -13), v(-46, 0.047, -26), v(-57.94, 0.047, -35.58) },
		{ 8.5, v(11, 0.047, 2.5), v(36, 0.047, -16), v(56, 0.047, -40.5), v(58.27, 0.047, -42.61) },
	}
	for _, route in routes do
		for i = 2, #route - 1 do
			walk(base, route[i], route[i + 1], route[1])
		end
	end
	for _, spec in {
		{ v(-11.5, 0.15, 15.6), v(-18.0, 0.15, 19.8), rgb(34, 172, 195) },
		{ v(11.5, 0.15, 15.7), v(18.2, 0.15, 19.7), glow },
		{ v(-10.7, 0.15, 0.6), v(-17.0, 0.15, -3.45), rgb(53, 91, 168) },
		{ v(11.6, 0.15, 2.0), v(18.9, 0.15, -3.35), rgb(134, 110, 195) },
	} do
		Kit.beam(base, "RouteInlay", spec[1], spec[2], 0.29, 0.026, spec[3], metal).CastShadow = false
	end
	for _, bed in {
		{ -21, 42, 12.2, 8.3, 0.90, 1.12 }, { 21, 42, 14.5, 8.2, 1.05, 1.21 },
		{ -33, 53, 10.6, 7.4, 0.78, 0.97 }, { 42, 46, 11.9, 7.2, 0.67 },
		{ -17, -18, 5.1, 3.7, 0.40 }, { 45, -7, 7.4, 4.65, 0.54 },
		{ -65, -6, 12.7, 7.1, 1.10, 1.20 }, { 56, 7, 15.0, 8.8, 1.26, 1.38 },
		{ -88, 48, 17.0, 11.5, 1.45, 1.44 }, { 72, 18, 17.3, 10.5, 1.45, 1.5 },
		{ -86, -52, 12.4, 6.8, 0.88 }, { 77, -20, 12.4, 8.4, 1.05, 1.29 },
	} do
		garden(base, table.unpack(bed))
	end
	for _, spec in { { -31, -5.5 }, { 36, -8 }, { -10.9, 42 }, { 10.9, 42 } } do
		Kit.lantern(base, spec[1], spec[2], 3.46, false)
	end
	for _, side in { -1, 1 } do
		local edgeX = centerX + side * (width / 2 - 1)
		local edgeZ = centerZ + side * (depth / 2 - 1)
		Kit.part(base, "RetainingWall", v(1.25, 2.9, depth), v(edgeX, 1.45, centerZ),
			p.navy, Enum.Material.Concrete, true)
		Kit.part(base, "RetainingWall", v(width - 1, 2.9, 1.25), v(centerX, 1.45, edgeZ),
			p.navy, Enum.Material.Concrete, true)
		Kit.part(base, "WallCoping", v(1.52, 0.25, depth), v(edgeX, 2.99, centerZ), warm, stone)
		Kit.part(base, "WallCoping", v(width - 0.5, 0.25, 1.52), v(centerX, 2.99, edgeZ), warm, stone)
		for _, barrier in {
			Kit.part(base, "EdgeGuard", v(0.5, 18, depth), v(centerX + side * width / 2, 8.98, centerZ), dark, nil, true),
			Kit.part(base, "EdgeGuard", v(width, 18, 0.5), v(centerX, 8.98, centerZ + side * depth / 2), dark, nil, true),
		} do
			barrier.Transparency, barrier.CastShadow = 1, false
		end
	end
end

local function skyline(parent)
	local sky = Kit.model(parent, "CliffBackdrop")
	local slate, moss = rgb(112, 137, 158), rgb(101, 156, 88)
	local function outsideCampus(x, z)
		local offsetX = if x < -70 then -52 elseif x > 70 then 49 else 0
		local offsetZ = if z < -70 then -49 elseif z > 65 then 40 else 0
		return x + offsetX, z + offsetZ
	end
	local function mass(name, x, y, z, sx, sy, sz, tint, mat, shape, yaw)
		local frame = CFrame.new(x, y, z) * CFrame.Angles(0, yaw or 0, 0)
		local part
		if shape == Enum.PartType.Wedge then
			part = Kit.part(sky, name, v(sx, sy, sz), frame, tint, mat, false, shape)
		else
			part = Kit.ellipsoid(sky, name, v(sx, sy, sz), frame, tint, mat)
		end
		part.CastShadow = false
	end
	mass("ValleyFloor", 0, -14, -33, 399, 13.5, 326, rgb(98, 154, 88), Enum.Material.Grass)
	for _, ridge in {
		{ -122, -126, 109, 49, 76, rgb(103, 155, 144) }, { -66, -165, 102, 46, 80, rgb(113, 155, 158) },
		{ -21, -185, 96, 37, 87, rgb(128, 162, 163) }, { 44, -178, 103, 57, 80, rgb(110, 153, 158) },
		{ 105, -154, 108, 68, 87, rgb(107, 151, 147) }, { 150, -101, 91, 54, 97, rgb(100, 152, 135) },
		{ -123, -54, 77, 32, 94, rgb(98, 152, 107) }, { 132, -28, 85, 37, 92, rgb(101, 155, 104) },
	} do
		local x, z, sx, sy, sz, tint = table.unpack(ridge)
		x, z = outsideCampus(x, z)
		mass("DistantRidge", x, -8, z, sx, sy, sz, tint, Enum.Material.Grass)
	end
	for _, rock in {
		{ -99, -63, 45, 27, 34, 0.27 }, { -81, -89, 42, 31, 31, 0.42 },
		{ -57, -103, 38, 22, 28, -0.32 }, { -37, -118, 38, 16, 29, -0.19 },
		{ 42, -116, 36, 21, 29, -0.28 }, { 64, -101, 35, 35, 29, 0.20 },
		{ 85, -80, 39, 29, 35, 0.43 }, { 104, -56, 39, 23, 32, 0.34 },
	} do
		local x, z, width, h, depth, yaw = table.unpack(rock)
		x, z = outsideCampus(x, z)
		local axis = CFrame.new(x, -6, z) * CFrame.Angles(0, yaw, 0)
		mass("RockShoulder", x + 1.1, h * 0.34 - 6, z - 1.65, width * 0.98, h * 0.98, depth,
			slate, Enum.Material.Slate, nil, yaw)
		for i = -1, 1 do
			local offset = axis * v(i * width * 0.23, h * (0.30 + 0.07 * i), -2.1 + i * 1.4)
			mass("CliffFace", offset.X, offset.Y, offset.Z, width * 0.41, h * (0.70 + 0.06 * i), depth * 0.87,
				slate:Lerp(rgb(148, 168, 179), (i + 1) * 0.19), Enum.Material.Slate, Enum.PartType.Wedge, yaw + 0.57 * i)
		end
		mass("UpperMeadow", x - 1.6, h * 0.66 - 6, z - 4.0, width * 0.84, h * 0.35, depth * 0.88,
			moss, Enum.Material.Grass, nil, yaw)
	end
	for _, slope in {
		{ -83, -25, 31, 17, 47 }, { -84, 10, 24, 13, 48 }, { -82, 43, 26, 13, 36 },
		{ 85, 33, 24, 15, 42 }, { 87, -3, 29, 17, 43 }, { 90, -39, 32, 18, 46 },
		{ -49, 72, 44, 15, 24 }, { 48, 72, 46, 17, 24 },
	} do
		local x, z, width, h, depth = table.unpack(slope)
		x, z = outsideCampus(x, z)
		mass("OuterSlope", x, -4.1, z, width, h, depth, rgb(77, 146, 71), Enum.Material.Grass)
	end
	for _, tree in {
		{ -84, 3, -25, 1.18 }, { -80, 2, -17, 1.00 }, { -85, 2, 15, 0.97 }, { -84, 1, 42, 1.10 },
		{ -95, 17, -67, 1.26 }, { -76, 18, -90, 1.09 }, { -62, 12, -103, 0.88 },
		{ 83, 2, 33, 1.05 }, { 86, 3.8, -2, 1.30 }, { 83, 3.5, -11, 0.88 }, { 89, 4, -38, 1.08 },
		{ 67, 22, -104, 1.24 }, { 83, 18, -82, 1.14 }, { 103, 12, -59, 0.95 },
	} do
		local x, z = outsideCampus(tree[1], tree[3])
		crown(sky, x, tree[2] - 1.3, z, tree[4], rgb(66, 140, 91))
	end
	for _, tree in {
		{ -83, 2, -33, 1.04 }, { -85, 1.3, -28, 0.72 },
		{ 87, 2.3, 1, 1.00 }, { 91, 2, -39, 1.24 },
		{ 65, 19.3, -108, 1.04 },
	} do
		local x, y, z, scale = table.unpack(tree)
		x, z = outsideCampus(x, z)
		local pine = Kit.model(sky, "RidgePine")
		Kit.pine(pine, x, y, z, scale)
		for _, part in pine:GetChildren() do part.CastShadow = false end
	end
	local fall = Kit.model(sky, "Waterfall")
	for i = -1, 1 do
		local stream = Kit.part(fall, "WaterRibbon", v(1.22, 16.1 + i * 0.60, 0.32),
			CFrame.new(63 + i * 1.14, 5.9, -88.2 + i * 0.10) * CFrame.Angles(math.rad(6), 0, math.rad(-3)),
			rgb(134 + i * 14, 221 + i * 8, 241), Enum.Material.SmoothPlastic)
		stream.Transparency, stream.CastShadow = 0.12 + math.abs(i) * 0.26, false
	end
	Kit.disc(fall, "WaterBasin", 62.7, -1.9, -85.5, 13.7, 9.9, 0.19,
		rgb(93, 185, 199), Enum.Material.SmoothPlastic).CastShadow = false
	local sprayOrigin = Kit.part(fall, "MistOrigin", v(3.6, 0.18, 1.7), v(62.7, -1.65, -86.6), moss)
	sprayOrigin.Transparency, sprayOrigin.CastShadow = 1, false
	local mist = Instance.new("ParticleEmitter")
	mist.Name = "WaterfallMist"
	mist.Texture = "rbxasset://textures/particles/smoke_main.dds"
	mist.Color = ColorSequence.new(rgb(212, 239, 245))
	mist.Lifetime, mist.Speed = NumberRange.new(0.9, 1.5), NumberRange.new(0.8, 1.7)
	mist.Rate, mist.SpreadAngle = 5, Vector2.new(55, 40)
	mist.Size = NumberSequence.new(0.65, 2.6)
	mist.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.83),
		NumberSequenceKeypoint.new(0.28, 0.64),
		NumberSequenceKeypoint.new(1, 1),
	})
	mist.Parent = sprayOrigin
	fall:PivotTo(fall:GetPivot() - v(0, 0, 49))
end

local function effect(parent, class)
	local item = parent:FindFirstChildOfClass(class)
	if item then return item end
	item = Instance.new(class)
	item.Parent = parent
	return item
end

function CampusArt.light()
	Lighting.ClockTime = 14.45
	Lighting.GeographicLatitude = 31
	Lighting.Brightness = 2.40
	Lighting.GlobalShadows = true
	Lighting.ShadowSoftness = 0.35
	Lighting.Ambient = rgb(122, 132, 150)
	Lighting.OutdoorAmbient = rgb(153, 164, 181)
	Lighting.ExposureCompensation = 0.02
	Lighting.EnvironmentDiffuseScale = 0.51
	Lighting.EnvironmentSpecularScale = 0.32
	Lighting.ColorShift_Top = rgb(17, 10, 4)
	local atmosphere = effect(Lighting, "Atmosphere")
	atmosphere.Density, atmosphere.Offset, atmosphere.Haze = 0.265, 0.04, 1.29
	atmosphere.Color, atmosphere.Decay = rgb(223, 239, 255), rgb(126, 165, 192)
	atmosphere.Glare = 0
	local correction = effect(Lighting, "ColorCorrectionEffect")
	correction.TintColor, correction.Brightness, correction.Contrast, correction.Saturation = rgb(255, 251, 242), 0.008, 0.055, 0.11
	correction.Enabled = true
	local bloom = effect(Lighting, "BloomEffect")
	bloom.Enabled, bloom.Intensity, bloom.Size, bloom.Threshold = true, 0.15, 18, 1.22
	local sky = effect(Lighting, "Sky")
	sky.StarCount, sky.SunAngularSize = 0, 7
	local clouds = effect(workspace.Terrain, "Clouds")
	clouds.Cover, clouds.Density, clouds.Color = 0.38, 0.46, rgb(246, 250, 255)
end

function CampusArt.create(goalRules)
	local campus = Instance.new("Model")
	campus.Name = "FootballCampus"
	campus:SetAttribute("LayoutVersion", version)
	grounds(campus)
	welcome(campus)
	Pitch.build(campus)
	ClubMap.build(campus)
	GoalCourse.build(campus, goalRules)
	portals(campus)
	skyline(campus)
	return campus
end

function CampusArt.build(rebuild, goalRules)
	CampusArt.light()
	local existing = workspace:FindFirstChild("FootballCampus")
	if not rebuild and existing and existing:GetAttribute("LayoutVersion") == version
		and existing:FindFirstChild("GoalCourse") and existing:FindFirstChild("ClubDistricts")
		and existing:FindFirstChild("TrainingPads") then
		return existing
	end
	local campus = CampusArt.create(goalRules)
	campus.Parent = workspace
	if existing then existing:Destroy() end
	for _, spec in { { "JuggleArena", "TrainingPads" }, { "ClubDistricts", "Academy" },
		{ "CampusScenery", "CampusGrounds" }, { "GoalCourse", "ShotSign" } } do
		local old = workspace:FindFirstChild(spec[1])
		if old and old:FindFirstChild(spec[2]) then old:Destroy() end
	end
	return campus
end

return CampusArt
