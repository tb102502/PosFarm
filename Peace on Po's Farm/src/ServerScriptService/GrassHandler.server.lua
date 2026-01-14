--[[
    INSTANT GrassHandler.server.lua - Grass disappears immediately
    Replace your existing GrassHandler.server.lua with this version
]]

local Replicated = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local TweenService = game:GetService("TweenService")


-- Try to load MowerSystem for regrow time calculations
local MowerSystem = nil
spawn(function()
	local success, result = pcall(function()
		return require(ServerScriptService.Modules:WaitForChild("MowerSystem", 10))
	end)

	if success and result then
		MowerSystem = result
		print("✅ GrassHandler: MowerSystem loaded - extended regrow times enabled")
	else
		warn("⚠️ GrassHandler: MowerSystem not available - using default regrow times")
	end
end)

-- Get remote events
local folder = Replicated:WaitForChild("GameRemotes")
local GrassMowed = folder:WaitForChild("GrassMowed")

-- Sizes for grass states
local MowedSize = Vector3.new(2, 0.4, 2)  -- Grass when mowed (short)
local FullSize = Vector3.new(2, 4, 2)     -- Grass when fully grown (tall)

print("🌱 INSTANT GrassHandler loaded!")
print("   Grass disappears IMMEDIATELY when mowed")


-- Function to handle MeshPart grass mowing INSTANTLY
local function handleMeshGrassMowing(grass)
	-- INSTANT mowing - no animation
	grass.Size = Vector3.new(grass.Size.X, 0.4, grass.Size.Z)
	grass.Transparency = 0.3
	grass.Color = Color3.fromRGB(124, 156, 107) -- Duller green

	-- Stop swaying animation
	local swayScript = grass:FindFirstChild("Script")
	if swayScript then
		swayScript.Disabled = true
	end

	-- Set attributes
	grass:SetAttribute("IsMowed", true)
	grass:SetAttribute("MowedTime", tick())
end

-- Function to handle MeshPart grass regrowth (still animated for nice effect)
local function regrowMeshGrass(grass)
	-- Find the original size if stored
	local originalSize = grass:GetAttribute("OriginalSize")
	if not originalSize then
		originalSize = Vector3.new(2, 4, 2)
		grass:SetAttribute("OriginalSize", originalSize)
	end

	-- INSTANT regrowth (or keep animated if you prefer)
	grass.Size = originalSize
	grass.Transparency = 0
	grass.Color = Color3.fromRGB(34, 139, 34) -- Original green

	-- Re-enable swaying animation
	local swayScript = grass:FindFirstChild("Script")
	if swayScript then
		swayScript.Disabled = false
	end

	-- Clear mowed status
	grass:SetAttribute("IsMowed", false)
	grass:SetAttribute("MowedTime", nil)

	print("🌱 Mesh grass regrown!")
end

-- Function to handle Part grass regrowth
local function regrowPartGrass(grass)
	-- INSTANT regrowth
	grass.Size = FullSize

	-- Clear mowed status
	grass:SetAttribute("IsMowed", false)
	grass:SetAttribute("MowedTime", nil)

	print("🌱 Part grass regrown!")
end



-- Debug function
_G.DebugGrassRegrow = function()
	print("=== INSTANT GRASS REGROW DEBUG ===")
	print("Mode: INSTANT DISAPPEAR")

	if not _G.GrassRegrowData then
		print("No grass regrow data available")
		return
	end

	local currentTime = tick()
	local activeRegrows = 0

	for grass, data in pairs(_G.GrassRegrowData) do
		if grass and grass.Parent then
			activeRegrows = activeRegrows + 1
			local timeLeft = data.expectedRegrowAt - currentTime
			local minutesLeft = timeLeft / 60


			print("   Time until regrowth: " .. string.format("%.1f", minutesLeft) .. " minutes")
		end
	end

	print("Active regrows: " .. activeRegrows)
	print("==========================")
end

print("⚡ INSTANT grass mowing system ready!")
print("🧪 Debug: _G.DebugGrassRegrow()")