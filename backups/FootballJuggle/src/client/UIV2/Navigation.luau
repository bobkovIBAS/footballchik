local GuiService = game:GetService("GuiService")
local UserInputService = game:GetService("UserInputService")

local Components = require(script.Parent.Components)
local Navigation = {}
Navigation.__index = Navigation

local specs = {
	{ "shop", "Бутсы", "Shop", "red" },
	{ "team", "Команда", "Team", "blue" },
	{ "club", "Прогресс", "Progress", "purple" },
	{ "settings", "Настройки", "Settings", "gray" },
}

function Navigation.new(hud, quiet)
	local self = setmetatable({ hud = hud, buttons = {}, menuButtons = {} }, Navigation)
	local root = Components.new("Frame", hud.field, { Name = "Navigation", BackgroundTransparency = 1 })
	self.root = root
	self.modal = Components.Modal(hud.gui, "QuickNavigation", "Клуб", quiet, function() hud:showMenu(false) end)
	for i, spec in specs do
		local function open()
			if spec[1] == "club" and not hud.progressAvailable then
				hud:toast("Прогресс откроется после улучшения бутс, золотого удара или контракта.")
				return
			end
			self.source = i
			hud:open(spec[1])
		end
		self.buttons[i] = Components.IconButton(root, spec[1], spec[2], spec[3], spec[4], quiet, open)
		local item = Components.IconButton(self.modal.face, spec[1], spec[2], spec[3], spec[4], quiet, open)
		item.root.Size = UDim2.fromOffset(96, 70)
		item.root.Position = UDim2.fromOffset(13 + (i - 1) % 2 * 105, 48 + math.floor((i - 1) / 2) * 78)
		self.menuButtons[i] = item
	end
	self.menu = Components.IconButton(root, "OpenNavigation", "Клуб", "Menu", "blue", quiet, function()
		hud:showMenu(true)
	end)
	self.menu.root.Size = UDim2.fromScale(1, 1)
	self.modal.panel.Size = UDim2.fromOffset(226, 212)
	local menu = self.menuButtons
	self.modal.close.NextSelectionDown = menu[2].hit
	for index, item in menu do
		local hit = item.hit
		hit.NextSelectionLeft = index % 2 == 0 and menu[index - 1].hit or hit
		hit.NextSelectionRight = index % 2 == 1 and menu[index + 1].hit or hit
		hit.NextSelectionUp = index > 2 and menu[index - 2].hit or self.modal.close
		hit.NextSelectionDown = index <= 2 and menu[index + 2].hit or hit
	end
	return self
end

function Navigation:layout(compact, side, width, height)
	self.compact = compact
	for index, item in self.buttons do
		item.root.Visible = not compact
		item.root.Position = side and UDim2.fromOffset(0, (index - 1) * (height + 9))
			or UDim2.fromOffset((index - 1) * (width + 7), 0)
		item.root.Size = UDim2.fromOffset(width, height)
		local previous, nextItem = self.buttons[index - 1], self.buttons[index + 1]
		local previousHit, nextHit = previous and previous.hit, nextItem and nextItem.hit
		item.hit.NextSelectionUp = side and previousHit or nil
		item.hit.NextSelectionDown = side and nextHit or nil
		item.hit.NextSelectionLeft = not side and previousHit or nil
		item.hit.NextSelectionRight = not side and nextHit or nil
	end
	self.menu.root.Visible = compact
end

function Navigation:focus()
	if self.hud.page then return end
	if self.hud.menuOpen then
		GuiService.SelectedObject = self.menuButtons[1].hit
	elseif self.hud.phase == "ready" and self.root.Visible then
		GuiService.SelectedObject = self.compact and self.menu.hit or self.buttons[1].hit
	end
end

function Navigation:setOpen(open)
	self.modal.setOpen(open)
	self.hud.field.Visible = not open and self.hud.page == nil
	if UserInputService.PreferredInput == Enum.PreferredInput.Gamepad and self.hud.page == nil then
		if open then
			GuiService.SelectedObject = self.menuButtons[1].hit
		elseif self.root.Visible then
			GuiService.SelectedObject = self.menu.hit
		end
	end
end

function Navigation:restore()
	if self.source and UserInputService.PreferredInput == Enum.PreferredInput.Gamepad and self.root.Visible then
		GuiService.SelectedObject = self.compact and self.menu.hit or self.buttons[self.source].hit
	end
	self.source = nil
end

return Navigation
