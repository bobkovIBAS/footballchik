local Kit = require(script.Parent:WaitForChild("WorldKit"))
local p = Kit.colors
local v = Vector3.new
local ClubMap = {}

local function bounds(parent, name, x, z, width, depth)
	local part = Kit.part(parent, name, v(width, 14, depth), v(x, 5, z), p.ink)
	part.Transparency = 1
	part.CastShadow = false
	return part
end

local function prompt(board, at, action, heading, reach)
	local attachment = Instance.new("Attachment")
	attachment.Name = "Interaction"
	attachment.Position = board.CFrame:PointToObjectSpace(at)
	attachment.Parent = board
	local value = Instance.new("ProximityPrompt")
	value.ActionText, value.ObjectText = action, heading
	value.KeyboardKeyCode, value.GamepadKeyCode = Enum.KeyCode.F, Enum.KeyCode.ButtonX
	value.MaxActivationDistance = reach or 8
	value.RequiresLineOfSight = reach == nil
	value.Parent = attachment
end

local c = Color3.fromRGB
local blue, gold = c(41, 218, 247), c(255, 186, 59)
local navy, cream, brass = c(22, 39, 68), c(248, 233, 206), c(198, 151, 76)
local stone, metal = Enum.Material.Limestone, Enum.Material.Metal
local up = Vector3.yAxis

local function facePlaza(x, z, yaw)
	return CFrame.new(x, 0, z) * CFrame.Angles(0, math.rad(yaw), 0)
end

local function facade(parent, origin)
	return function(name, size, offset, tint, material, solid, angle)
		return Kit.part(parent, name, size, origin * CFrame.new(offset) * (angle or CFrame.identity), tint, material, solid)
	end
end

local function academy(parent)
	local zone = Kit.model(parent, "Academy")
	local stationX, stationZ = -45, 32
	Kit.disc(zone, "StationBase", stationX, 0.14, stationZ, 2.4, 2.4, 0.24, navy, metal)
	Kit.beam(zone, "StationColumn", v(stationX, 0.25, stationZ), v(stationX, 1.68, stationZ),
		0.37, 0.37, navy, metal, true)
	local station = Kit.sign(zone, "RhythmStation", facePlaza(stationX, stationZ, 19) * CFrame.new(0, 1.78, 0),
		3.18, 1.0, "СТАРТ", nil, blue)
	Kit.lettering(station, "СТАРТ", nil, blue, Enum.NormalId.Front)
	prompt(station, v(stationX, 2.65, stationZ), "Начать тренировку", "ШКОЛА РИТМА", 22)
	bounds(zone, "RhythmBounds", -42, 35, 58, 34)
	require(script.Parent.TrainingArena).install(zone)
end

local function boot(parent, frame, scale, accent)
	local shoe = Kit.model(parent, "DisplayBoot")
	local rubber, leather = c(27, 39, 54), accent:Lerp(c(22, 43, 69), 0.18)
	local function piece(name, size, x, y, z, tint, material, tilt)
		local transform = frame * CFrame.new(v(x, y, z) * scale) * (tilt or CFrame.identity)
		local part = Kit.ellipsoid(shoe, name, size * scale, transform, tint, material)
		part.CastShadow = false
	end
	piece("Outsole", v(6.15, 0.36, 2.28), 0, 0.42, 0, rubber, Enum.Material.Rubber)
	piece("EdgeOfSole", v(6.04, 0.28, 2.23), 0.02, 0.58, 0, cream, Enum.Material.SmoothPlastic)
	piece("Toe", v(4.1, 0.97, 2.17), 0.93, 0.97, 0, leather, Enum.Material.SmoothPlastic,
		CFrame.Angles(0, 0, -0.13))
	piece("Instep", v(3.35, 1.34, 2.09), -0.37, 1.15, 0, leather, Enum.Material.SmoothPlastic,
		CFrame.Angles(0, 0, -0.24))
	piece("Heel", v(2.37, 1.58, 1.95), -1.74, 1.25, 0, leather, Enum.Material.SmoothPlastic)
	piece("HeelGuard", v(0.73, 1.12, 1.43), -2.57, 1.13, 0, rubber, Enum.Material.Rubber)
	piece("Collar", v(1.80, 0.35, 1.64), -1.76, 1.94, 0, rubber, Enum.Material.Fabric,
		CFrame.Angles(0, 0, 0.07))
	piece("CollarOpening", v(1.36, 0.09, 1.20), -1.8, 2.09, 0, c(13, 21, 36), nil)
	piece("Tongue", v(2.06, 0.26, 1.1), -0.65, 1.73, 0, rubber, Enum.Material.Fabric,
		CFrame.Angles(0, 0, -0.23))
	for i = 0, 4 do
		piece("Lace", v(0.12, 0.125, 0.97 - i * 0.045), -1.1 + i * 0.33, 1.98 - i * 0.101, 0, cream,
			Enum.Material.Fabric, CFrame.Angles(0, (i % 2 == 0 and 1 or -1) * 0.27, -0.18))
	end
	for _, side in { -1, 1 } do
		piece("SideFlash", v(1.66, 0.22, 0.22), -0.58, 1.15, side * 1.00, cream, nil,
			CFrame.Angles(0, side * 0.14, 0.31))
		for _, x in { -1.91, -1.02, 0.93, 1.89 } do
			piece("Stud", v(0.30, 0.36, 0.32), x, 0.31, side * 0.63, rubber, Enum.Material.Rubber)
		end
	end
end

local function store(parent)
	local zone = Kit.model(parent, "BootShop")
	local frame = facePlaza(47, 28, -98)
	local part = facade(zone, frame)
	local dark, panel, amber = c(23, 41, 59), c(46, 75, 89), c(255, 211, 118)
	local lime = c(185, 244, 66)

	part("ShowroomBase", v(17.3, 0.25, 10.3), v(0, 0.16, 0), dark, stone)
	part("Approach", v(15.8, 0.09, 5.5), v(0, 0.073, 7.12), c(229, 198, 149), stone).CastShadow = false
	part("BackWall", v(16.7, 6.65, 0.65), v(0, 3.46, -4.7), panel, metal, true)
	part("SideWall", v(0.64, 6.5, 9.65), v(-8.2, 3.46, 0), dark, metal, true)
	part("Lightbox", v(10.8, 4.9, 0.26), v(-2.3, 2.94, -3.8), c(147, 186, 190), Enum.Material.SmoothPlastic)
	part("DisplayBackdrop", v(5.8, 4.9, 0.12), v(-2.4, 2.94, -3.61), c(202, 221, 208), Enum.Material.SmoothPlastic)
	for _, dx in { -7.75, 2.75 } do
		part("DisplayFin", v(0.32, 4.95, 0.46), v(dx, 2.94, -3.55), amber, metal)
	end
	part("DisplayDeck", v(11.95, 0.22, 6.85), v(-2.2, 0.4, 0), panel, metal)
	part("WindowSill", v(11.8, 0.48, 0.45), v(-2.05, 0.67, 3.95), dark, metal, true)
	local glass = part("DisplayGlass", v(11.35, 4.7, 0.10), v(-2.05, 3.22, 3.95), c(196, 234, 240),
		Enum.Material.Glass, true)
	glass.Transparency, glass.CastShadow = 0.91, false
	for _, dx in { -7.91, 3.80 } do
		part("WindowFrame", v(0.19, 4.8, 0.29), v(dx, 3.23, 3.99), dark, metal)
	end
	part("ReturnWall", v(0.56, 6.35, 6.1), v(8.18, 3.37, -1.65), panel, metal, true)
	part("CornerPier", v(0.65, 6.37, 0.65), v(7.05, 3.41, 3.87), dark, metal, true)
	part("EntryBack", v(3.85, 4.86, 0.34), v(5.75, 2.74, 1.92), dark, metal, true)
	part("EntryLintel", v(3.6, 0.38, 2.13), v(5.49, 5.12, 3.12), dark, metal)
	part("EntryLight", v(3.05, 0.065, 0.23), v(5.45, 4.91, 4.0), amber, Enum.Material.Neon).CastShadow = false
	part("Threshold", v(3.5, 0.095, 2.35), v(5.45, 0.092, 4.83), gold, Enum.Material.SmoothPlastic).CastShadow = false
	local entry = part("EntryLabel", v(3.55, 0.77, 0.18), v(5.44, 5.04, 4.36), panel)
	Kit.lettering(entry, "УЛУЧШЕНИЯ", nil, gold)
	for _, dx in { 3.74, 7.17 } do
		part("EntryJamb", v(0.17, 3.84, 0.15), v(dx, 2.70, 4.17), amber, metal).CastShadow = false
	end
	local corner = CFrame.new(7.65, 3.54, 2.82) * CFrame.Angles(0, math.rad(52), 0)
	local cornerWindow = Kit.part(zone, "CornerGlass", v(2.3, 4.5, 0.12), frame * corner, c(204, 232, 236), Enum.Material.Glass, true)
	cornerWindow.Transparency, cornerWindow.CastShadow = 0.89, false

	for _, display in {
		{ -5.8, 1.02, 0.48, c(48, 168, 244), -0.24 },
		{ -2.18, 1.48, 0.87, lime, 0.31 },
		{ 1.86, 0.91, 0.46, c(246, 107, 73), 0.54 },
	} do
		local dx, top, scale, tint, yaw = table.unpack(display)
		part("BootPedestal", v(scale * 5.8 + 0.6, top - 0.46, scale * 3.35 + 0.6), v(dx, (top + 0.46) / 2, 0.46), dark, metal)
		part("PedestalCap", v(scale * 5.8 + 0.64, 0.10, scale * 3.35 + 0.64), v(dx, top, 0.46), cream, stone)
		boot(zone, frame * CFrame.new(dx, top, 0.46) * CFrame.Angles(0, yaw, 0), scale, tint)
	end
	local lightStrip = part("ShowroomLight", v(10.8, 0.08, 0.28), v(-2.12, 5.9, 2.48),
		c(255, 236, 188), Enum.Material.Neon)
	lightStrip.CastShadow = false
	local light = Instance.new("SurfaceLight")
	light.Face, light.Angle, light.Range, light.Brightness = Enum.NormalId.Bottom, 105, 9, 0.9
	light.Color, light.Parent = c(255, 235, 206), lightStrip

	part("Canopy", v(17.8, 0.47, 10.65), v(0, 6.42, 0.01), dark, metal)
	part("FrontFascia", v(17.8, 1.95, 0.55), v(0, 6.45, 5.17), panel, metal)
	part("FasciaEdge", v(17.8, 0.16, 0.38), v(0, 7.45, 5.17), gold, metal)
	part("CanopyLight", v(16.5, 0.065, 0.16), v(0, 5.44, 5.34), amber, Enum.Material.Neon).CastShadow = false
	local sign = part("ShopSign", v(11.6, 1.87, 0.18), v(-2.11, 6.45, 5.53), panel, metal)
	Kit.lettering(sign, "БУТСЫ", nil, gold)
	for i = 0, 2 do
		part("FasciaStripe", v(0.30, 1.16, 0.08), v(4.35 + i * 0.52, 6.47, 5.50),
			i == 0 and gold or amber, metal, false, CFrame.Angles(0, 0, -0.43)).CastShadow = false
	end
	part("EmblemPlinth", v(3.25, 0.18, 1.64), v(6.03, 7.55, 4.47), panel, metal)
	boot(zone, frame * CFrame.new(6.03, 7.53, 4.47) * CFrame.Angles(0, -0.17, 0), 0.49, gold)

	-- Preserve the interaction point in world space as the facade changes.
	prompt(sign, v(40.452797, 2.65, 31.658434), "Открыть улучшения", "МАГАЗИН БУТС", 10)
end

function ClubMap.build(parent)
	local districts = Kit.model(parent, "ClubDistricts")
	academy(districts)
	store(districts)
	require(script.Parent:WaitForChild("AcademyPlaza")).build(districts)
	return districts
end

function ClubMap.aliveRoot(player)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	return humanoid and humanoid.Health > 0 and character:FindFirstChild("HumanoidRootPart") or nil
end

local function contains(area, root)
	local p0, size = area.CFrame:PointToObjectSpace(root.Position), area.Size * 0.5
	return math.abs(p0.X) <= size.X and math.abs(p0.Y) <= size.Y and math.abs(p0.Z) <= size.Z
end

function ClubMap.inAcademy(districts, player)
	local root = ClubMap.aliveRoot(player)
	return root ~= nil and contains(districts.Academy.RhythmBounds, root)
end

function ClubMap.district(districts, root)
	if contains(districts.Academy.RhythmBounds, root) then return "academy" end
	if contains(districts.TeamCourt.Bounds, root) then return "team" end
	if contains(districts.TrickCourt.Bounds, root) then return "tricks" end
	if contains(districts.ClubAlley.Bounds, root) then return "club" end
	return "field"
end

return ClubMap
