local AssetService = game:GetService("AssetService")
local EncodingService = game:GetService("EncodingService")
local RunService = game:GetService("RunService")

local Config = require(script.Parent.Config)

local Art = {}
local tile = 112
local index = { Coins = 0, Power = 1, Shop = 2, Team = 3, Progress = 4, Settings = 5, Ball = 6, GoldBall = 7, Menu = 8 }
local fallback = { Coins = "◈", Power = "ϟ", Shop = "＋", Team = "XI", Progress = "★",
	Settings = "⚙", Ball = "⚽", GoldBall = "★", Menu = "☰" }
local image, attempted

local function localAtlas()
	if not attempted then
		attempted = true
		local ok, result = pcall(function()
			local data = require(script.Parent.AtlasData)
			local size = Vector2.one * (tile * 3)
			local editable = assert(AssetService:CreateEditableImage({ Size = size }), "Atlas image allocation failed")
			local encoded = EncodingService:Base64Decode(buffer.fromstring(data))
			local pixels = EncodingService:DecompressBuffer(encoded, Enum.CompressionAlgorithm.Zstd)
			assert(buffer.len(pixels) == size.X * size.Y * 4, "Unexpected HUD atlas size")
			editable:WritePixelsBuffer(Vector2.zero, size, pixels)
			return editable
		end)
		if ok then image = result else warn("[UIV2] Local icon atlas:", result) end
	end
	return image
end

function Art.icon(parent, name, position, size, z)
	local atlas = Config.AtlasImage == "" and RunService:IsStudio() and localAtlas()
	local object
	if atlas or Config.AtlasImage ~= "" then
		object = Instance.new("ImageLabel")
		if atlas then object.ImageContent = Content.fromObject(atlas) else object.Image = Config.AtlasImage end
		local cell = assert(index[name], name)
		object.ImageRectOffset = Vector2.new(cell % 3, math.floor(cell / 3)) * tile
		object.ImageRectSize = Vector2.one * tile
		object.ScaleType = Enum.ScaleType.Fit
	else
		object = Instance.new("TextLabel")
		object.Text = fallback[name] or "?"
		object.Font = Enum.Font.GothamBlack
		object.TextScaled = true
		object.TextColor3 = Color3.new(1, 1, 1)
		object.TextStrokeTransparency = 0.3
	end
	object.Name = name .. "Icon"
	object.BackgroundTransparency = 1
	object.Position, object.Size, object.ZIndex = position, size, z or 1
	object.Parent = parent
	return object
end

return Art
