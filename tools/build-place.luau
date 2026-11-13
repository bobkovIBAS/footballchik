local fs = require("@lune/fs")
local roblox = require("@lune/roblox")
local process = require("@lune/process")
local V, CF = roblox.Vector3, roblox.CFrame
local Enum, Instance = roblox.Enum, roblox.Instance

local scenePath, codePath, output = table.unpack(process.args)
assert(scenePath and codePath and output, "Usage: lune run tools/build-place <map.rbxl> <rojo.rbxl> <output.rbxl>")
local map = roblox.deserializePlace(fs.readFile(scenePath))
local code = roblox.deserializePlace(fs.readFile(codePath))
local world = map:GetService("Workspace")
local hub = assert(world:FindFirstChild("HubLayout"))
local academy = assert(world:FindFirstChild("FootballAcademyDesign"))
local replicated = map:GetService("ReplicatedStorage")
local client = map:GetService("StarterPlayer"):FindFirstChild("StarterPlayerScripts")
code:GetService("ReplicatedStorage").Juggle.Parent = replicated
code:GetService("ServerScriptService").JuggleServer.Parent = map:GetService("ServerScriptService")
code:GetService("StarterPlayer").StarterPlayerScripts.JuggleClient.Parent = client
world:SetAttribute("FootballUIVersion", 2)
world.StreamingEnabled = true
map:GetService("StarterGui").ScreenOrientation = Enum.ScreenOrientation.Sensor

local function folder(parent, name, class)
	local object = Instance.new(class or "Folder")
	object.Name, object.Parent = name, parent
	return object
end

local function marker(parent, name, frame, size)
	local object = folder(parent, name, "Part")
	object.Size, object.CFrame = size or V.one * 0.25, frame
	object.Anchored, object.CanCollide, object.CanQuery, object.CanTouch = true, false, false, false
	object.Transparency, object.CastShadow = 1, false
	return object
end

local arrival = hub["04_CollisionAndSpawn"].PreviewSpawn
arrival.Name = "Arrival"
arrival:SetAttribute("HubSpawn", nil)
arrival.Duration = 0
arrival.CFrame = CF.lookAlong(V.new(-9, 0.363, 15.8), V.new(-0.24, 0, -1))
local annotations = hub["05_TemporaryPlanning"]:FindFirstChild("01_BallAndCaptions")
if annotations then annotations:Destroy() end

local stadium = hub["02_MainStadium"]
local east, west = stadium.GoalEast, stadium.GoalWest
east:SetAttribute("Playable", true)
west:SetAttribute("Playable", false)
local template = folder(replicated.Juggle, "StadiumGoalVisual", "Model")
east.Frame.Parent, east.Net.Parent = template, template
-- Keep the stadium model visible in Edit. The server removes these
-- two render groups before clients attach their own copy from ReplicatedStorage.
template.Frame:Clone().Parent = east
template.Net:Clone().Parent = east

local campus = folder(world, "FootballCampus", "Model")
campus:SetAttribute("IntegratedLayout", true)
campus.ModelStreamingMode = Enum.ModelStreamingMode.Persistent
local districts = folder(campus, "ClubDistricts")
local rhythm = folder(districts, "Academy")
local shop = folder(districts, "BootShop")
local team = folder(districts, "TeamCourt")
local tricks = folder(districts, "TrickCourt")
local daily = folder(districts, "ClubAlley")

local function prompt(anchor, position, title, action, key, distance, radius)
	local a = folder(anchor, "Interaction", "Attachment")
	a.Position = anchor.CFrame:PointToObjectSpace(position)
	local p = folder(a, "ProximityPrompt", "ProximityPrompt")
	p.ActionText, p.ObjectText = action, title
	p.KeyboardKeyCode, p.GamepadKeyCode = Enum.KeyCode[key], Enum.KeyCode.ButtonX
	p.MaxActivationDistance, p.RequiresLineOfSight, p.ClickablePrompt = distance, false, true
	p.Exclusivity = Enum.ProximityPromptExclusivity.OnePerButton
	if radius then anchor:SetAttribute("CircleRadius", radius) end
end

local function platform(parent, stage, name, title, action, offset)
	local center, count, deckHeight = V.zero, 0, 0
	for _, part in academy.Collision:GetChildren() do
		if part.Name == stage .. " deck" then
			center += part.CFrame.Position
			count += 1
			deckHeight = part.CFrame.Position.Y + part.Size.Y / 2
		end
	end
	assert(count > 0, stage .. " deck is missing")
	center /= count
	local pos = V.new(center.X, deckHeight + 2.9, center.Z + offset)
	prompt(marker(parent, name, CF.new(pos)), pos, title, action, "E", 3.25, 3.25)
	marker(parent, "Bounds", CF.new(center.X, 5, center.Z), V.new(20, 14, 17))
end

platform(team, "Team", "TeamBench", "КОМАНДА", "Открыть команду", 4.3)
platform(tricks, "Tricks", "TrickBoard", "ФИНТЫ", "Выбрать финт", 4.3)
platform(daily, "Daily", "DailyBoard", "ЗАДАНИЕ ДНЯ", "Открыть задание", 3.8)

local counter = hub["05_BootsShop"].FutureShopInteraction.CounterAnchor
local counterPoint = counter.CFrame:PointToWorldSpace(counter.InteractionAnchor.CFrame.Position)
prompt(marker(shop, "ShopSign", CF.new(counterPoint)), counterPoint, "МАГАЗИН БУТС", "Открыть улучшения", "F", 6)

local parquet = hub["04_FutsalArena"].Collision.Parquet
local practice = parquet.CFrame:PointToWorldSpace(V.new(-11, parquet.Size.Y / 2, 10))
local station = marker(rhythm, "RhythmStation", CF.new(practice))
folder(station, "BallRest", "Attachment")
prompt(station, practice + V.new(0, 0.98, 0), "ТРЕНИРОВОЧНЫЙ МЯЧ", "Начать тренировку", "F", 5.5)
marker(rhythm, "RhythmBounds", CF.new(practice + V.new(0, 4, 0)), V.new(14, 12, 14))

local ring = marker(station, "PracticeMark", CF.new(practice + V.new(0, 0.045, 0))
	* CF.Angles(0, 0, math.pi / 2), V.new(0.04, 4.4, 4.4))
ring.Shape = Enum.PartType.Cylinder
ring.Material = Enum.Material.SmoothPlastic
ring.Color, ring.Transparency = roblox.Color3.fromRGB(96, 181, 230), 0.38

fs.writeFile(output, roblox.serializePlace(map))
