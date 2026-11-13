local UserInputService = game:GetService("UserInputService")

local Input = {}

function Input.bind(hud, goals)
	local shotHeld = {}
	UserInputService.InputBegan:Connect(function(input, processed)
		local key = input.KeyCode
		if key == Enum.KeyCode.ButtonB and (hud.page or hud.menuOpen) then
			if hud.menuOpen then hud:showMenu(false) else hud:open(nil) end
			return
		end
		if key == Enum.KeyCode.ButtonSelect and hud.focusNavigation then
			hud:focusNavigation()
			return
		end
		if processed then return end
		if key == Enum.KeyCode.E or key == Enum.KeyCode.ButtonR2 then
			hud:requestKick()
		elseif key == Enum.KeyCode.Q or key == Enum.KeyCode.ButtonY then
			if not shotHeld[key] then
				shotHeld[key] = true
				if not hud.menuOpen then goals:requestShot() end
			end
		end
	end)
	UserInputService.InputEnded:Connect(function(input) shotHeld[input.KeyCode] = nil end)
	UserInputService.WindowFocusReleased:Connect(function() table.clear(shotHeld) end)
end

return Input
