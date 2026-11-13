local DataStoreService = game:GetService("DataStoreService")
local RunService = game:GetService("RunService")
local shared = game:GetService("ReplicatedStorage"):WaitForChild("Juggle")
local Balance = require(shared:WaitForChild("Balance"))
local ClubRules = require(shared:WaitForChild("ClubRules"))
local GoalRules = require(shared:WaitForChild("GoalRules"))

local Profiles = {}
local studio = RunService:IsStudio()
local persistent = not studio or (Balance.UseStudioDataStore and game.PlaceId ~= 0)
local store
if persistent then
	store = DataStoreService:GetDataStore(studio and "JuggleStudio_v1" or "Juggle_v1")
end

local leaseSeconds = 180
local memory = {}
Profiles.studioMemory = not persistent

local function number(value, cap, minimum)
	if type(value) ~= "number" or value ~= value or math.abs(value) == math.huge then
		return minimum
	end
	return math.clamp(math.floor(value), minimum, cap)
end

local function read(raw)
	local data = type(raw) == "table" and raw or {}
	local owned = number(data.owned, Balance.RankMax, 0)
	local frequency = number(data.frequency, Balance.FrequencyMax, 0)
	local levels = {}
	for rank = 1, owned do
		local stored = type(data.levels) == "table" and data.levels[rank]
		levels[rank] = number(stored, Balance.PlayerLevelMax, 1)
	end
	return {
		coins = number(data.coins, 9e15, 0),
		boots = number(data.boots, Balance.BootMax, 0),
		trainingPower = number(data.trainingPower, Balance.TrainingPowerMax, 0),
		frequency = frequency,
		multiplier = number(data.multiplier, Balance.MultiplierMax, 0),
		progress = number(data.progress, Balance.interval(frequency) - 1, 0),
		owned = owned,
		active = number(data.active, owned, owned == 0 and 0 or 1),
		levels = levels,
		muted = data.muted == true,
		quiet = data.quiet == true,
		club = ClubRules.normalize(data.club),
		goals = GoalRules.normalize(data.goals),
	}
end

local function key(userId)
	return "user_" .. userId
end

function Profiles.load(userId, sessionId)
	if not store then
		return read(memory[userId])
	end

	for attempt = 1, 3 do
		local ok, value = pcall(function()
			return store:UpdateAsync(key(userId), function(old)
				local lock = type(old) == "table" and old.session
				if type(lock) == "table" and type(lock.expires) == "number"
					and lock.expires > os.time() and lock.id ~= sessionId then
					return nil
				end
				local data = read(old)
				data.session = { id = sessionId, expires = os.time() + leaseSeconds }
				return data
			end)
		end)
		if ok and value then
			return read(value)
		end
		if attempt < 3 then
			task.wait(ok and 2 or attempt)
		end
	end
	warn("[Juggle] Could not acquire profile for", userId)
	return nil
end

function Profiles.save(userId, sessionId, data, release)
	local snapshot = read(data)
	if not store then
		memory[userId] = snapshot
		return true
	end

	for attempt = 1, 3 do
		local ok, value = pcall(function()
			return store:UpdateAsync(key(userId), function(old)
				local lock = type(old) == "table" and old.session
				if type(lock) ~= "table" or lock.id ~= sessionId then
					return nil
				end
				local update = table.clone(snapshot)
				if not release then
					update.session = { id = sessionId, expires = os.time() + leaseSeconds }
				end
				return update
			end)
		end)
		if ok then
			return value ~= nil, value == nil
		end
		if attempt < 3 then
			task.wait(attempt)
		end
	end
	warn("[Juggle] Could not save profile for", userId)
	return false, false
end

return Profiles
