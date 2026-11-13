local Pitch = require(script.Parent.Pitch)

local IntegratedMap = {}

function IntegratedMap.build()
	local campus = workspace:FindFirstChild("FootballCampus")
	if not campus or not campus:GetAttribute("IntegratedLayout") then return nil end
	local hub = workspace.HubLayout
	local arrival = hub["04_CollisionAndSpawn"].Arrival
	local goal = hub["02_MainStadium"].GoalEast
	local origin = CFrame.lookAlong(goal.GoalOrigin.Position, -goal:GetAttribute("InwardDirection"))
	goal.Frame:Destroy()
	goal.Net:Destroy()
	Pitch.build(campus, arrival)
	return campus, origin, goal.GoalOrigin.GoalCenter.WorldPosition
end

return IntegratedMap
