local Kit = require(script.Parent:WaitForChild("WorldKit"))
local p = Kit.colors
local Pitch = {}
local columns = { 0, 3.4, -3.4, 6.8, -6.8, 10.2 }
local rows = { 31, 27.5, 34.5, 24, 38 }

function Pitch.build(parent, arrival)
	local pads = Kit.model(parent, "TrainingPads")
	for index = 1, 30 do
		local x = columns[(index - 1) % #columns + 1]
		local z = rows[math.floor((index - 1) / #columns) + 1]
		local pad = Kit.model(pads, "Pad" .. index)
		local marker = Kit.part(pad, "Marker", Vector3.one * 0.2, Vector3.new(x, 3.35, z), p.white)
		if arrival then
			local column = (index - 1) % #columns
			local row = math.floor((index - 1) / #columns)
			local offset = Vector3.new((column - 2.5) * 2.6, 3, (row - 1.5) * 2.6)
			marker.CFrame = arrival.CFrame.Rotation + arrival.Position + offset
		end
		marker.Transparency = 1
		marker.CastShadow = false
		if not arrival and index <= #columns then
			local ring = Kit.disc(pad, "TrainingRing", x, 0.145, z, 2.65, 2.65, 0.025, p.mint)
			ring.Transparency = 1
			ring.CastShadow = false
		end
	end
	if arrival then return pads end
	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "Arrival"
	spawn.Position = Vector3.new(0, 0.12, 31)
	spawn.Size = Vector3.new(5, 0.2, 5)
	spawn.Anchored, spawn.Neutral, spawn.Duration = true, true, 0
	spawn.Transparency, spawn.CanCollide, spawn.CanTouch, spawn.CanQuery = 1, false, false, false
	spawn.Parent = parent
	return pads
end

function Pitch.pad(pads, index)
	return pads["Pad" .. index]
end

function Pitch.updateTrainingRing(pad, root, tint)
	local ring = pad:FindFirstChild("TrainingRing")
	if not ring then return end
	local near = root and (root.Position - pad.Marker.Position).Magnitude <= 3
	ring.Transparency = near and 0.64 or 1
	if near then ring.Color = tint end
end

return Pitch
