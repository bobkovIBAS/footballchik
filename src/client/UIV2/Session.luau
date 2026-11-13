local Session = {}
Session.__index = Session

function Session.new(remote)
	return setmetatable({ remote = remote, sequence = 0 }, Session)
end

function Session:connect(hud, goals, effects)
	local remote = self.remote
	local received = false

	remote.OnClientEvent:Connect(function(kind, phase, data, message, effect, memory, rhythm, freePractice)
		if kind == "goalHit" then
			goals:confirm(phase)
		elseif kind == "goalReady" then
			goals:ready(phase, data, message)
		elseif kind == "goalCancelled" then
			goals:cancelled(phase)
		elseif kind == "clubOpen" then
			if not data or not hud.page then hud:open(phase, data) end
		elseif kind == "state" then
			received = true
			hud:setState(phase, data, memory, rhythm, freePractice)
			if data then effects:settings(data.muted, data.quiet) end
			goals:setProfile(data)
			if effect then
				hud:confirm(effect)
				effects:reward(effect, hud.goalImpact ~= nil)
			end
			if message then hud:toast(message, effect and effect.kind) end
		end
	end)

	task.defer(function()
		repeat
			remote:FireServer("sync")
			task.wait(1)
		until received
	end)
end

function Session:send(action, ...)
	if action == "kick" then
		self.sequence += 1
		self.remote:FireServer(action, self.sequence)
	elseif action == "rhythmTap" then
		self.sequence += 1
		local roundId = ...
		self.remote:FireServer(action, roundId, self.sequence)
	else
		self.remote:FireServer(action, ...)
	end
end

return Session
