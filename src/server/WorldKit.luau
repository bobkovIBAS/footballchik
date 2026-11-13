local Kit = {}
local color = Color3.fromRGB
Kit.colors = {
	ink = color(24, 43, 70), navy = color(32, 65, 105), white = color(253, 249, 228),
	stone = color(225, 218, 199), sand = color(235, 206, 161), grass = color(102, 181, 101),
	mint = color(84, 234, 190), teal = color(35, 149, 144), blue = color(68, 133, 230),
	gold = color(255, 198, 87), violet = color(125, 107, 231), coral = color(243, 128, 104),
}
local palette = Kit.colors

function Kit.model(parent, name)
	local model = Instance.new("Model")
	model.Name = name
	model.Parent = parent
	return model
end

function Kit.part(parent, name, size, at, tint, material, solid, shape)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.CFrame = typeof(at) == "CFrame" and at or CFrame.new(at)
	part.Color = tint
	part.Material = material or Enum.Material.SmoothPlastic
	part.Shape = shape or Enum.PartType.Block
	part.Anchored = true
	part.CanCollide = solid == true
	part.CanTouch = false
	part.CanQuery = solid == true
	part.CastShadow = true
	part.Parent = parent
	return part
end

function Kit.ellipsoid(parent, name, size, at, tint, material)
	local part = Kit.part(parent, name, size, at, tint, material)
	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType = Enum.MeshType.Sphere
	mesh.Parent = part
	return part
end

function Kit.disc(parent, name, x, y, z, width, depth, height, tint, material)
	return Kit.part(parent, name, Vector3.new(height, width, depth),
		CFrame.new(x, y, z) * CFrame.Angles(0, 0, math.pi / 2), tint, material, false, Enum.PartType.Cylinder)
end

function Kit.beam(parent, name, from, to, width, depth, tint, material, round)
	local direction = to - from
	local cf = CFrame.lookAt((from + to) / 2, to, math.abs(direction.Unit.Y) > 0.99 and Vector3.zAxis or Vector3.yAxis)
	if round then
		return Kit.part(parent, name, Vector3.new(direction.Magnitude, width, width),
			cf * CFrame.Angles(0, math.pi / 2, 0), tint, material, false, Enum.PartType.Cylinder)
	end
	return Kit.part(parent, name, Vector3.new(width, depth, direction.Magnitude), cf, tint, material)
end

function Kit.lettering(board, heading, caption, accent, face)
	local gui = Instance.new("SurfaceGui")
	gui.Name = "Lettering"
	gui.Face = face or Enum.NormalId.Back
	gui.CanvasSize = Vector2.new(math.round(board.Size.X / board.Size.Y * 240), 240)
	gui.LightInfluence = 0.05
	gui.MaxDistance = 135
	gui.Parent = board
	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.BackgroundTransparency = 1
	title.Position = UDim2.fromScale(0.035, caption and 0.10 or 0.05)
	title.Size = UDim2.fromScale(0.93, caption and 0.49 or 0.9)
	title.Text = heading
	title.TextScaled = true
	title.TextColor3 = palette.white
	title.Font = Enum.Font.GothamBlack
	title.Parent = gui
	if caption then
		local detail = title:Clone()
		detail.Name = "Caption"
		detail.Position = UDim2.fromScale(0.04, 0.60)
		detail.Size = UDim2.fromScale(0.92, 0.28)
		detail.Text = caption
		detail.TextColor3 = accent
		detail.Font = Enum.Font.GothamBold
		detail.Parent = gui
	end
end

function Kit.sign(parent, name, cf, width, height, heading, caption, accent)
	local board = Kit.part(parent, name, Vector3.new(width, height, 0.48), cf, palette.ink)
	Kit.part(parent, name .. "Cap", Vector3.new(width + 0.20, 0.15, 0.56),
		cf * CFrame.new(0, height / 2 + 0.04, 0), accent)
	Kit.lettering(board, heading, caption, accent)
	return board
end

function Kit.arch(parent, name, x, z, radius, spring, tint, edge)
	for _, side in { -1, 1 } do
		Kit.beam(parent, name .. "Column", Vector3.new(x + side * (radius + 0.65), 0.1, z),
			Vector3.new(x + side * radius, spring, z), 1.12, 1.38, tint, Enum.Material.Metal)
	end
	local last
	for step = 0, 10 do
		local angle = step * math.pi / 10
		local point = Vector3.new(x + math.cos(angle) * radius, spring + math.sin(angle) * radius * 0.55, z)
		if last then
			Kit.beam(parent, name .. "Rib", last, point, 0.92, 1.1, tint, Enum.Material.Metal, true)
			Kit.beam(parent, name .. "Trim", last + Vector3.new(0, 0.1, 0.45), point + Vector3.new(0, 0.1, 0.45),
				0.20, 0.20, edge, nil, true)
		end
		last = point
	end
end

function Kit.flag(parent, x, z, height, tint)
	Kit.beam(parent, "Flagpole", Vector3.new(x, 0, z), Vector3.new(x, height, z), 0.20, 0.20, palette.navy,
		Enum.Material.Metal, true)
	local cloth = Kit.part(parent, "Pennant", Vector3.new(1.55, 2.85, 0.11), Vector3.new(x + 0.88, height - 1.64, z),
		tint, Enum.Material.Fabric)
	cloth.CastShadow = false
	Kit.part(parent, "PennantStripe", Vector3.new(1.56, 0.20, 0.14), cloth.CFrame * CFrame.new(0, -0.8, 0), palette.white)
end

function Kit.planter(parent, x, z, size, accent, tree)
	Kit.disc(parent, "Planter", x, 0.23, z, size, size, 0.46, palette.stone, Enum.Material.Limestone)
	Kit.disc(parent, "PlanterRim", x, 0.49, z, size + 0.08, size + 0.08, 0.15, accent)
	Kit.disc(parent, "PlantBed", x, 0.58, z, size - 0.4, size - 0.4, 0.14, palette.teal, Enum.Material.Grass)
	if tree then
		Kit.beam(parent, "Trunk", Vector3.new(x, 0.5, z), Vector3.new(x + 0.25, 4.8, z), 0.64, 0.64,
			color(143, 97, 63), Enum.Material.Wood, true)
		Kit.part(parent, "Canopy", Vector3.new(5.6, 5.3, 4.9), Vector3.new(x, 5.5, z), color(62, 159, 94),
			nil, false, Enum.PartType.Ball)
		Kit.part(parent, "Canopy", Vector3.new(4.2, 4.0, 4.1), Vector3.new(x + 1.18, 6.4, z - 0.6), color(125, 199, 99),
			nil, false, Enum.PartType.Ball)
	else
		Kit.part(parent, "Shrub", Vector3.new(size * 0.74, size * 0.45, size * 0.68),
			Vector3.new(x, 0.8, z), color(87, 191, 112), nil, false, Enum.PartType.Ball)
	end
end

local function triangle(parent, a, b, c, tint)
	local ab, ac, bc = b - a, c - a, c - b
	if ab.Magnitude > ac.Magnitude and ab.Magnitude > bc.Magnitude then
		a, c = c, a
	elseif ac.Magnitude > bc.Magnitude then
		a, b = b, a
	end
	ab, ac, bc = b - a, c - a, c - b
	local right = ac:Cross(ab).Unit
	local back = bc.Unit
	local up = back:Cross(right).Unit
	local height = math.abs(ab:Dot(up))
	Kit.part(parent, "PanelFacet", Vector3.new(0.075, height, math.abs(ab:Dot(back))),
		CFrame.fromMatrix((a + b) / 2, right, up, back), tint, Enum.Material.SmoothPlastic, false, Enum.PartType.Wedge)
	Kit.part(parent, "PanelFacet", Vector3.new(0.075, height, math.abs(ac:Dot(back))),
		CFrame.fromMatrix((a + c) / 2, -right, up, -back), tint, Enum.Material.SmoothPlastic, false, Enum.PartType.Wedge)
end

local pentagon

local function panelTemplate()
	if pentagon then return pentagon end
	local model = Instance.new("Model")
	model.Name = "Pentagon"
	local dark = color(23, 25, 34)
	local points = {}
	-- The pentagons of a truncated icosahedron subtend this radius on the sphere.
	for i = 0, 4 do
		local a = math.pi * 2 * i / 5
		points[i + 1] = Vector3.new(math.cos(a) * 1.13, math.sin(a) * 1.13, 3.00)
	end
	for i = 1, 5 do
		triangle(model, Vector3.new(0, 0, 3.23), points[i], points[i % 5 + 1], dark)
	end
	local pieces = model:GetChildren()
	local main = table.remove(pieces, 1)
	local ok, results = pcall(function()
		return game:GetService("GeometryService"):UnionAsync(main, pieces, {
			SplitApart = false, CollisionFidelity = Enum.CollisionFidelity.Box,
		})
	end)
	if ok and #results > 0 then
		for _, piece in model:GetChildren() do piece:Destroy() end
		for _, union in results do
			union.Name = "PanelShell"
			union.Color, union.Material, union.UsePartColor = dark, Enum.Material.SmoothPlastic, true
			union.Anchored, union.CanCollide, union.CanTouch, union.CanQuery, union.CastShadow = true, false, false, false, false
			union.Parent = model
		end
	end
	model.WorldPivot = CFrame.identity
	pentagon = model
	return model
end

function Kit.football(parent, center, radius, seams)
	local model = Kit.model(parent, "ClassicFootball")
	Kit.part(model, "IvoryShell", Vector3.one * radius * 1.939, center, color(252, 248, 239),
		Enum.Material.SmoothPlastic, false, Enum.PartType.Ball)
	local phi = (1 + math.sqrt(5)) / 2
	local yaw = CFrame.Angles(0.16, 0.26, 0.24)
	local vertices = {}
	for _, x in { -1, 1 } do
		for _, y in { -1, 1 } do
			table.insert(vertices, Vector3.new(0, x, y * phi).Unit)
			table.insert(vertices, Vector3.new(x, y * phi, 0).Unit)
			table.insert(vertices, Vector3.new(y * phi, 0, x).Unit)
		end
	end
	local template = panelTemplate()
	for _, vertex in vertices do
		local normal = yaw:VectorToWorldSpace(vertex)
		local neighbor
		for _, candidate in vertices do
			if math.abs(vertex:Dot(candidate) - 1 / math.sqrt(5)) < 0.001 then
				neighbor = candidate
				break
			end
		end
		local right = yaw:VectorToWorldSpace((neighbor - vertex * vertex:Dot(neighbor)).Unit)
		local clone = template:Clone()
		clone:ScaleTo(radius / 3.2)
		clone:PivotTo(CFrame.fromMatrix(center, right, normal:Cross(right), normal))
		clone.Parent = model
	end
	if seams then
		local edgeTint = color(174, 168, 158)
		local r = radius * 0.972
		for i, a in vertices do
			for j = i + 1, #vertices do
				local b = vertices[j]
				if math.abs(a:Dot(b) - 1 / math.sqrt(5)) < 0.001 then
					local start = yaw:VectorToWorldSpace((2 * a + b).Unit)
					local finish = yaw:VectorToWorldSpace((a + 2 * b).Unit)
					local last = center + start * r
					for step = 1, 3 do
						local point = center + start:Lerp(finish, step / 3).Unit * r
						Kit.beam(model, "PanelSeam", last, point, 0.034, 0.034, edgeTint, nil, true).CastShadow = false
						last = point
					end
				end
			end
		end
	end
	return model
end

function Kit.lantern(parent, x, z, height, glowing)
	local at = Vector3.new(x, height, z)
	Kit.disc(parent, "LampFoot", x, 0.17, z, 0.84, 0.84, 0.34, palette.ink, Enum.Material.Metal)
	Kit.beam(parent, "LampPost", Vector3.new(x, 0.22, z), at, 0.16, 0.16, palette.navy, Enum.Material.Metal, true)
	Kit.part(parent, "LampBase", Vector3.new(0.64, 0.16, 0.64), at, palette.ink, Enum.Material.Metal)
	local lamp = Kit.part(parent, "LampGlass", Vector3.new(0.57, 0.79, 0.57),
		at + Vector3.new(0, 0.46, 0), color(255, 220, 146), Enum.Material.Neon)
	lamp.CastShadow = false
	Kit.part(parent, "LampCap", Vector3.new(0.72, 0.18, 0.72), at + Vector3.new(0, 0.91, 0), palette.ink, Enum.Material.Metal)
	if glowing then
		local light = Instance.new("PointLight")
		light.Color, light.Range, light.Brightness = color(255, 182, 87), 8, 0.62
		light.Parent = lamp
	end
end

function Kit.pine(parent, x, y, z, scale)
	Kit.beam(parent, "PineTrunk", Vector3.new(x, y, z), Vector3.new(x, y + 3 * scale, z),
		0.40 * scale, 0.4 * scale, color(131, 78, 42), Enum.Material.Wood, true)
	for tier = 0, 2 do
		local width = (3.75 - 0.86 * tier) * scale
		local height = (2.9 - tier * 0.27) * scale
		for side = 0, 3 do
			local cf = CFrame.new(x, y + (2.05 + 1.43 * tier) * scale, z)
				* CFrame.Angles(0, side * math.pi / 2, 0) * CFrame.new(0, 0, -width * 0.25)
			Kit.part(parent, "PineCrown", Vector3.new(width, height, width * 0.5), cf,
				color(46 + tier * 17, 119 + tier * 13 + side * 4, 47 + tier * 5), nil, false, Enum.PartType.Wedge)
		end
	end
end

function Kit.shrub(parent, x, y, z, scale)
	local shades = { color(77, 167, 44), color(111, 188, 51), color(60, 144, 47) }
	for index = 1, 3 do
		local offset = (index - 2) * 0.53 * scale
		Kit.part(parent, "Leaves", Vector3.new(1.24, 1.15, 1.25) * scale,
			Vector3.new(x + offset, y + (index == 2 and 0.60 or 0.42) * scale, z + (index % 2) * 0.35 * scale),
			shades[index], Enum.Material.Grass, false, Enum.PartType.Ball)
	end
end

function Kit.neon(parent, name, size, at, tint)
	local part = Kit.part(parent, name, size, at, tint, Enum.Material.Neon)
	part.CastShadow = false
	return part
end

function Kit.marquee(parent, name, cf, width, height, heading, caption, accent)
	local surround = Kit.part(parent, name .. "Frame", Vector3.new(width + 0.44, height + 0.39, 0.37),
		cf * CFrame.new(0, 0, -0.29), accent, Enum.Material.Metal)
	surround.CastShadow = false
	local board = Kit.sign(parent, name, cf, width, height, heading, caption, accent)
	Kit.neon(parent, name .. "Underlight", Vector3.new(width * 0.95, 0.12, 0.19),
		cf * CFrame.new(0, -height / 2 - 0.14, 0.25), accent)
	return board
end

return Kit
