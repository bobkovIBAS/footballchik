local shared = game:GetService("ReplicatedStorage"):WaitForChild("Juggle")
local Rules = require(shared:WaitForChild("GoalRules"))

local Motion = { ShotDuration = 0.59, TrainingContact = 0.31 }

-- Phase, hip, knee, ankle, torso pitch, twist, balance arm, support bend.
local juggle = {
	{ 0.00,  0,   0,   0,  0,   0,  0, 0 },
	{ 0.12,  9, -29,  -5,  3,  -3, 11, 5 },
	{ 0.22, 31, -49,   7,  4,  -5, 17, 7 },
	{ 0.31, 42, -32, -13,  0,   2, 21, 8 },
	{ 0.43, 50, -24, -12, -4,   5, 23, 8 },
	{ 0.68, 24, -32,   4,  1,   3, 13, 4 },
	{ 1.00,  0,   0,   0,  0,   0,  0, 0 },
}
local heel = {
	{ 0.00,  0,   0,   0,  0,   0,  0, 0 },
	{ 0.18, -8, -22,  10,  5,   5, 12, 5 },
	{ 0.35,-16, -55,   2,  8,   9, 21, 8 },
	{ 0.48,-21, -65, -10,  8,   6, 22, 7 },
	{ 0.74, -7, -31,   4,  4,   1, 12, 4 },
	{ 1.00,  0,   0,   0,  0,   0,  0, 0 },
}
local shotContact = Rules.ShotWindup / Motion.ShotDuration
local shot = {
	{ 0.00,   0,   0,   0,  0,   0,  0, 0 },
	{ 0.19, -24, -44,  10,  7,  16, 23, 9 },
	{ shotContact, 15, -23, -8,  7, -9, 29, 8 },
	{ 0.54,  58, -20, -11,  4, -20, 33, 6 },
	{ 0.73,  35, -37,   5,  3, -10, 19, 5 },
	{ 1.00,   0,   0,   0,  0,   0,  0, 0 },
}

local slots = {
	RightUpperLeg = "RightHip", RightLowerLeg = "RightKnee", RightFoot = "RightAnkle",
	LeftUpperLeg = "LeftHip", LeftLowerLeg = "LeftKnee", LeftFoot = "LeftAnkle",
	UpperTorso = "Torso", Torso = "Torso",
	RightUpperArm = "RightArm", LeftUpperArm = "LeftArm",
	RightLowerArm = "RightElbow", LeftLowerArm = "LeftElbow",
	["Right Leg"] = "RightHip", ["Left Leg"] = "LeftHip",
	["Right Arm"] = "RightArm", ["Left Arm"] = "LeftArm",
}

function Motion.smooth(t)
	t = math.clamp(t, 0, 1)
	return t * t * (3 - 2 * t)
end

function Motion.duration(trick)
	return trick == 2 and 0.68 or (trick == 1 and 0.64 or 0.55)
end

function Motion.contact(trick)
	return trick == 2 and 0.35 or Motion.TrainingContact
end

local function sample(frames, phase)
	for index = 2, #frames do
		local b = frames[index]
		if phase <= b[1] then
			local a = frames[index - 1]
			local t = Motion.smooth((phase - a[1]) / (b[1] - a[1]))
			local function radians(column)
				return math.rad(a[column] + (b[column] - a[column]) * t)
			end
			return radians(2), radians(3), radians(4), radians(5), radians(6), radians(7), radians(8)
		end
	end
	return 0, 0, 0, 0, 0, 0, 0
end

function Motion.bind(character)
	local rig = { joints = {}, applied = {}, links = {}, feet = {} }
	for _, side in { "Right", "Left" } do
		rig.feet[side] = character:FindFirstChild(side .. "Foot") or character:FindFirstChild(side .. " Leg")
	end
	for _, motor in character:GetDescendants() do
		local parent, child, c0, c1
		if motor:IsA("Motor6D") then
			parent, child, c0, c1 = motor.Part0, motor.Part1, motor.C0, motor.C1
		elseif motor:IsA("AnimationConstraint") and motor.Attachment0 and motor.Attachment1 then
			parent, child = motor.Attachment0.Parent, motor.Attachment1.Parent
			c0, c1 = motor.Attachment0.CFrame, motor.Attachment1.CFrame
		end
		if parent and child and parent:IsA("BasePart") and child:IsA("BasePart") then
			local joint = { motor = motor, parent = parent, c0 = c0, c1 = c1 }
			rig.links[child] = joint
			local slot = slots[child.Name]
			if slot then rig.joints[slot] = joint end
		end
	end
	return rig
end

function Motion.restore(rig)
	for motor, original in rig.applied do
		if motor.Parent then motor.Transform = original end
	end
	table.clear(rig.applied)
end

local function rotate(rig, key, pitch, yaw, roll)
	local joint = rig.joints[key]
	if joint and joint.motor.Parent then
		local motor, basis = joint.motor, joint.c0.Rotation
		local original = motor.Transform
		rig.applied[motor] = original
		motor.Transform = basis:Inverse() * CFrame.Angles(pitch, yaw, roll) * basis * original
	end
end

local function jointFrame(parentFrame, joint)
	return parentFrame * joint.c0 * joint.motor.Transform
end

local function partFrame(rig, part)
	local joint = rig.links[part]
	if joint and joint.motor.Parent then
		return jointFrame(partFrame(rig, joint.parent), joint) * joint.c1:Inverse()
	end
	return part.CFrame
end

local function alignJoint(joint, parentFrame, rotation, blend)
	local base = parentFrame * joint.c0
	local current = joint.motor.Transform
	local desired = CFrame.new(current.Position) * base.Rotation:ToObjectSpace(rotation)
	joint.motor.Transform = current:Lerp(desired, blend)
end

-- Fit the plant-and-strike key to the actual avatar dimensions and stationary ball.
local function fitShotFoot(rig, root, ball, blend)
	local hip, knee, ankle = rig.joints.RightHip, rig.joints.RightKnee, rig.joints.RightAnkle
	local foot = rig.feet.Right
	if not hip or not foot or not foot.Parent then return end
	local hipParent = partFrame(rig, hip.parent)
	local hipFrame = jointFrame(hipParent, hip)
	local facing = CFrame.lookAlong(Vector3.zero, Vector3.new(root.LookVector.X, 0, root.LookVector.Z))
	local contact = ball - facing.LookVector * Rules.BallRadius
	if not knee or not ankle then
		local toe = partFrame(rig, foot):PointToWorldSpace(Vector3.new(0, -foot.Size.Y * 0.43, -foot.Size.Z * 0.44))
		local turn = CFrame.fromRotationBetweenVectors(toe - hipFrame.Position, contact - hipFrame.Position)
		alignJoint(hip, hipParent, turn * hipFrame.Rotation, blend)
		return
	end
	local kneeFrame = jointFrame(hipFrame * hip.c1:Inverse(), knee)
	local ankleFrame = jointFrame(kneeFrame * knee.c1:Inverse(), ankle)
	local toe = Vector3.new(0, 0, -foot.Size.Z * 0.49)
	local footAtBall = CFrame.new(contact - facing:VectorToWorldSpace(toe)) * facing
	local ankleTarget = (footAtBall * ankle.c1).Position
	local upper = kneeFrame.Position - hipFrame.Position
	local lower = ankleFrame.Position - kneeFrame.Position
	local a, b = upper.Magnitude, lower.Magnitude
	if a < 0.05 or b < 0.05 then return end
	local delta = ankleTarget - hipFrame.Position
	if delta.Magnitude < 0.02 then return end
	local axis = delta.Unit
	local distance = math.clamp(delta.Magnitude, math.abs(a - b) + 0.01, a + b - 0.01)
	local bend = facing.LookVector - axis * facing.LookVector:Dot(axis)
	if bend.Magnitude < 0.01 then return end
	local along = (a * a - b * b + distance * distance) / (2 * distance)
	local desiredUpper = axis * along + bend.Unit * math.sqrt(math.max(0, a * a - along * along))
	local desiredLower = axis * distance - desiredUpper
	local hipRotation = CFrame.fromRotationBetweenVectors(upper, desiredUpper) * hipFrame.Rotation
	local kneeRotation = CFrame.fromRotationBetweenVectors(lower, desiredLower) * kneeFrame.Rotation
	alignJoint(hip, hipParent, hipRotation, blend)
	local kneeParent = jointFrame(hipParent, hip) * hip.c1:Inverse()
	alignJoint(knee, kneeParent, kneeRotation, blend)
	local ankleParent = jointFrame(kneeParent, knee) * knee.c1:Inverse()
	alignJoint(ankle, ankleParent, (facing * ankle.c1).Rotation, blend)
end

function Motion.apply(rig, phase, trick, side, weight, root, shotBall)
	local frames = shotBall and shot or (trick == 2 and heel or juggle)
	local hip, knee, ankle, torso, twist, arms, load = sample(frames, phase)
	local direction = side == "Right" and 1 or -1
	local support = side == "Right" and "Left" or "Right"
	local wrap = 0
	if trick == 1 then
		local turn = math.clamp((phase - Motion.TrainingContact) / 0.52, 0, 1)
		wrap = math.sin(turn * 2 * math.pi)
		hip += math.sin(turn * math.pi) * 0.21
	end
	rotate(rig, side .. "Hip", hip * weight, direction * wrap * 0.24 * weight, direction * wrap * 0.38 * weight)
	rotate(rig, side .. "Knee", knee * weight, 0, direction * wrap * 0.11 * weight)
	rotate(rig, side .. "Ankle", ankle * weight, -direction * wrap * 0.15 * weight, 0)
	rotate(rig, support .. "Hip", load * 0.46 * weight, 0, direction * load * 0.34 * weight)
	rotate(rig, support .. "Knee", -load * weight, 0, 0)
	rotate(rig, support .. "Ankle", load * 0.54 * weight, 0, 0)
	rotate(rig, "Torso", torso * weight, twist * direction * weight, -load * direction * 0.8 * weight)
	rotate(rig, side .. "Arm", -arms * weight, 0, arms * direction * 0.42 * weight)
	rotate(rig, support .. "Arm", arms * 0.78 * weight, 0, -arms * direction * 0.57 * weight)
	rotate(rig, side .. "Elbow", -arms * 0.34 * weight, 0, 0)
	rotate(rig, support .. "Elbow", -arms * 0.55 * weight, 0, 0)
	if shotBall and phase > 0.22 and phase < 0.59 then
		local approach = Motion.smooth((phase - 0.22) / (shotContact - 0.22))
		local follow = 1 - Motion.smooth((phase - shotContact) / (0.59 - shotContact))
		fitShotFoot(rig, root, shotBall, approach * follow)
	end
end

function Motion.trainingContact(rig, side, frame, trick)
	local foot = rig.feet[side]
	if not foot or not foot.Parent then
		return frame:PointToWorldSpace(Vector3.new(side == "Right" and 0.55 or -0.55, 0.75, trick == 2 and 0.5 or -0.82))
	end
	local heel = trick == 2
	local r6 = foot.Name == side .. " Leg"
	local y = r6 and -foot.Size.Y * 0.43 or foot.Size.Y * 0.44
	local z = foot.Size.Z * (heel and 0.41 or -0.30)
	local boot = foot.CFrame:PointToWorldSpace(Vector3.new(0, y, z))
	return boot + Vector3.yAxis * Rules.BallRadius
end

function Motion.ball(phase, home, contact, lift, trick, side, facing)
	local contactPhase = Motion.contact(trick)
	if phase < contactPhase then
		local t = Motion.smooth(phase / contactPhase)
		return home:Lerp(contact, t), t * 0.42
	end
	local t = math.clamp((phase - contactPhase) / (1 - contactPhase), 0, 1)
	local arc = 4 * t * (1 - t)
	local drift = facing:VectorToWorldSpace(Vector3.new(
		(trick == 1 and 0.27 or 0.10) * (side == "Right" and 1 or -1), 0, trick == 2 and 0.24 or -0.19))
	local spin = 0.42 * (1 - t) + (trick == 2 and -1 or 1) * t * math.pi * 2
	return contact:Lerp(home, t) + (Vector3.yAxis * lift + drift) * arc, spin
end

return Motion
