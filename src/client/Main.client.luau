local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local shared = ReplicatedStorage:WaitForChild("Juggle")
local remote = shared:WaitForChild("Action")
local Effects = require(script.Parent:WaitForChild("Effects"))
local GoalView = require(script.Parent:WaitForChild("GoalView"))
local Ui = require(script.Parent:WaitForChild("UiKit"))
local uiV2 = script.Parent:WaitForChild("UIV2")
local Config = require(uiV2.Config)
local Session = require(uiV2.Session)
local Input = require(uiV2.Input)
local WorldUI = require(uiV2.WorldUI)

local version = Config.Version
if RunService:IsStudio() then
	version = workspace:GetAttribute("FootballUIVersion") or version
end
local hudModule = version == 2 and uiV2.Screens or script.Parent:WaitForChild("Hud")
local Hud = require(hudModule)
local playerGui = player:WaitForChild("PlayerGui")
local effects = Effects.new(player)
local session = Session.new(remote)
local send = function(action, ...) session:send(action, ...) end
local hud = Hud.new(playerGui, send)
if hud.styleNameplate then
	effects.styleNameplate = function(gui, text) hud:styleNameplate(gui, text) end
end
local goals = GoalView.new(hud, effects, send)

session:connect(hud, goals, effects)
WorldUI.bind(hud, Ui)
Input.bind(hud, goals)

player.CameraMinZoomDistance = 7
player.CameraMaxZoomDistance = 26
