--[[
    FIXED SimpleTractorEnhancer.server.lua
    Place in: ServerScriptService/SimpleTractorEnhancer.server.lua
    
    This is the ONLY grass cutting system you need
]]

local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local workspace = game:GetService("Workspace")

print("🚜 FIXED SimpleTractorEnhancer: Starting...")

-- Configuration
local TRACTOR_NAME = "OldWornOutTractor"
local GRASS_DETECTOR_NAME = "GrassDetector"

-- Global system state
local GrassCuttingSystem = {
	active = false,
	connection = nil,
	tractor = nil,
	grassDetector = nil,
	seat = nil,
	lastCut = 0
}

-- FIXED: More consistent grass detection
local function isGrassMowable(grass)
	-- Must be named "Grass"
	if grass.Name ~= "Grass" then 
		return false 
	end

	-- Must not be already mowed
	if grass:GetAttribute("IsMowed") then 
		return false 
	end

	-- Must be a BasePart
	if not grass:IsA("BasePart") then
		return false
	end

	-- Must be tall enough (works for both MeshPart and Part)
	return grass.Size.Y >= 1.5  -- Lowered threshold to be more permissive
end

-- FIXED: Better grass cutting with instant visual feedback
local function cutGrassInstantly(grass, player, regrowBonus)
	-- Store original size
	if not grass:GetAttribute("OriginalSize") then
		grass:SetAttribute("OriginalSize", grass.Size)
	end

	-- Stop swaying animation if exists
	local swayScript = grass:FindFirstChild("Script")
	if swayScript and swayScript.Enabled then
		swayScript.Enabled = false
	end

	-- Instant visual changes - works for any grass type
	grass.Size = Vector3.new(grass.Size.X, 0.4, grass.Size.Z)
	grass.Transparency = math.min(grass.Transparency + 0.3, 0.8)
	grass.Color = Color3.fromRGB(124, 156, 107) -- Duller green

	-- Mark as mowed
	grass:SetAttribute("IsMowed", true)
	grass:SetAttribute("MowedTime", tick())

	-- Fire grass mowed event
	local gameRemotes = ReplicatedStorage:FindFirstChild("GameRemotes")
	local grassMowed = gameRemotes and gameRemotes:FindFirstChild("GrassMowed")

	if grassMowed then
		pcall(function()
			grassMowed:Fire(player, grass, regrowBonus or 0)
		end)
	end
end

-- FIXED: Improved grass detection area
local function findGrassInArea(detector)
	local found = {}
	local detectorPos = detector.Position
	local detectorSize = detector.Size

	-- Slightly expand detection area for better coverage
	local expansion = 1
	local minBounds = detectorPos - ((detectorSize + Vector3.new(expansion, 0, expansion)) / 2)
	local maxBounds = detectorPos + ((detectorSize + Vector3.new(expansion, 0, expansion)) / 2)

	-- Search for grass in the area
	for _, obj in ipairs(workspace:GetDescendants()) do
		if obj:IsA("BasePart") and obj.Name == "Grass" and isGrassMowable(obj) then
			local pos = obj.Position

			-- Check if grass is within detector bounds (including Y for better detection)
			if pos.X >= minBounds.X and pos.X <= maxBounds.X and
				pos.Y >= minBounds.Y - 5 and pos.Y <= maxBounds.Y + 5 and  -- More lenient Y bounds
				pos.Z >= minBounds.Z and pos.Z <= maxBounds.Z then
				table.insert(found, obj)
			end
		end
	end

	return found
end

-- FIXED: Create or fix GrassDetector
local function ensureGrassDetector(tractor)
	-- First, remove any existing Mower tool from GrassDetector (this was the problem!)
	local grassDetector = tractor:FindFirstChild(GRASS_DETECTOR_NAME)
	if grassDetector then
		local mowerTool = grassDetector:FindFirstChild("Mower")
		if mowerTool then
			print("🗑️ Removing problematic Mower tool from GrassDetector...")
			mowerTool:Destroy()
		end

		-- Remove any scripts inside the detector
		for _, child in pairs(grassDetector:GetChildren()) do
			if child:IsA("Script") or child:IsA("LocalScript") then
				print("🗑️ Removing script from GrassDetector: " .. child.Name)
				child:Destroy()
			end
		end

		print("✅ Cleaned existing GrassDetector")
		return grassDetector
	end

	print("📦 Creating new GrassDetector...")

	-- Create clean grass detector part
	grassDetector = Instance.new("Part")
	grassDetector.Name = GRASS_DETECTOR_NAME
	grassDetector.Size = Vector3.new(6, 1, 6)  -- Larger detection area
	grassDetector.Material = Enum.Material.ForceField
	grassDetector.Color = Color3.fromRGB(100, 255, 100)
	grassDetector.Transparency = 0.8
	grassDetector.CanCollide = false
	grassDetector.Anchored = false

	-- Position under tractor
	local chassis = tractor.PrimaryPart or tractor:FindFirstChild("Chassis") or tractor:FindFirstChildOfClass("VehicleSeat")
	if chassis then
		grassDetector.CFrame = chassis.CFrame * CFrame.new(0, -chassis.Size.Y/2 - 1, 1)  -- Slightly forward
	else
		local centerCF = tractor:GetBoundingBox()
		grassDetector.CFrame = centerCF * CFrame.new(0, -3, 1)
	end

	grassDetector.Parent = tractor

	-- Weld to tractor
	if chassis then
		local weld = Instance.new("WeldConstraint")
		weld.Part0 = chassis
		weld.Part1 = grassDetector
		weld.Parent = chassis
		print("🔗 Welded GrassDetector to " .. chassis.Name)
	end

	print("✅ Created clean GrassDetector")
	return grassDetector
end

-- FIXED: Main grass cutting with proper cooldown and better detection
local function grassCuttingHeartbeat()
	if not GrassCuttingSystem.active then return end

	local seat = GrassCuttingSystem.seat
	local detector = GrassCuttingSystem.grassDetector

	if not seat or not detector or not seat.Parent or not detector.Parent then 
		return 
	end

	-- Check if someone is driving
	if not seat.Occupant then
		return
	end

	-- Get the driver
	local driver = Players:GetPlayerFromCharacter(seat.Occupant.Parent)
	if not driver then
		return
	end

	-- Check if tractor is moving fast enough
	local velocity = seat.AssemblyLinearVelocity or seat.Velocity
	if velocity.Magnitude < 1.5 then  -- Lowered speed requirement
		return
	end

	-- Apply cooldown
	local currentTime = tick()
	if currentTime - GrassCuttingSystem.lastCut < 0.15 then  -- Faster cutting
		return
	end

	-- Find grass to cut
	local grassList = findGrassInArea(detector)
	if #grassList > 0 then
		-- Cut up to 8 grass pieces per frame
		local maxCuts = math.min(8, #grassList)
		local grassCut = 0

		for i = 1, maxCuts do
			local grass = grassList[i]
			if grass and grass.Parent then
				cutGrassInstantly(grass, driver, 0)
				grassCut = grassCut + 1
			end
		end

		if grassCut > 0 then
			GrassCuttingSystem.lastCut = currentTime
			print("🚜 " .. driver.Name .. " cut " .. grassCut .. " grass with tractor")
		end
	end
end

-- FIXED: Start grass cutting system
local function startGrassCuttingSystem(tractor)
	print("🌿 Starting FIXED grass cutting system...")

	-- Stop any existing system
	if GrassCuttingSystem.connection then
		GrassCuttingSystem.connection:Disconnect()
		GrassCuttingSystem.connection = nil
	end

	-- Verify tractor components
	local seat = tractor:FindFirstChildOfClass("VehicleSeat")
	if not seat then
		warn("❌ No VehicleSeat found in tractor")
		return false
	end

	-- Create/fix GrassDetector (removes problematic Mower tool)
	local grassDetector = ensureGrassDetector(tractor)
	if not grassDetector then
		warn("❌ Failed to create/fix GrassDetector")
		return false
	end

	-- Check for remote events
	local gameRemotes = ReplicatedStorage:FindFirstChild("GameRemotes")
	local grassMowed = gameRemotes and gameRemotes:FindFirstChild("GrassMowed")
	if not grassMowed then
		warn("❌ GrassMowed remote event not found")
		return false
	end

	-- Set up system state
	GrassCuttingSystem.tractor = tractor
	GrassCuttingSystem.grassDetector = grassDetector
	GrassCuttingSystem.seat = seat
	GrassCuttingSystem.active = true
	GrassCuttingSystem.lastCut = 0

	-- Connect to RunService
	GrassCuttingSystem.connection = RunService.Heartbeat:Connect(grassCuttingHeartbeat)

	-- Mark as enhanced
	grassDetector:SetAttribute("GrassCuttingEnabled", true)

	print("✅ FIXED grass cutting system started successfully")
	return true
end

-- Main execution
spawn(function()
	wait(3) -- Give workspace time to load

	print("🚜 Starting FIXED tractor enhancement...")

	local tractor = workspace:FindFirstChild(TRACTOR_NAME)
	if not tractor then
		warn("❌ " .. TRACTOR_NAME .. " not found in workspace")
		return
	end

	local success = startGrassCuttingSystem(tractor)

	if success then
		print("🎉 FIXED tractor enhancement complete!")
		print("🔧 Key fixes applied:")
		print("  ✅ Removed problematic Mower tool from GrassDetector")
		print("  ✅ Cleaned up conflicting scripts")
		print("  ✅ Improved grass detection logic")
		print("  ✅ Better positioning and welding")
		print("  ✅ Faster cutting with lower speed requirement")
		print("")
		print("🎮 How to use:")
		print("  1. Get in the tractor")
		print("  2. Drive over grass at 1.5+ speed")
		print("  3. Watch grass get cut automatically!")
	else
		warn("❌ FIXED tractor enhancement failed")
	end
end)

-- Global functions for debugging
_G.FixedTractorStatus = function()
	print("=== FIXED TRACTOR STATUS ===")
	print("System active: " .. tostring(GrassCuttingSystem.active))
	print("Tractor: " .. (GrassCuttingSystem.tractor and GrassCuttingSystem.tractor.Name or "None"))
	print("GrassDetector: " .. (GrassCuttingSystem.grassDetector and "✅" or "❌"))
	print("VehicleSeat: " .. (GrassCuttingSystem.seat and "✅" or "❌"))
	print("Connection: " .. (GrassCuttingSystem.connection and "✅" or "❌"))

	if GrassCuttingSystem.grassDetector then
		local detector = GrassCuttingSystem.grassDetector
		print("Detector size: " .. tostring(detector.Size))
		print("Detector position: " .. tostring(detector.Position))

		-- Check for problematic children
		local hasProblems = false
		for _, child in pairs(detector:GetChildren()) do
			if child:IsA("Tool") or child:IsA("Script") or child:IsA("LocalScript") then
				print("⚠️ Problem found in detector: " .. child.Name .. " (" .. child.ClassName .. ")")
				hasProblems = true
			end
		end

		if not hasProblems then
			print("✅ GrassDetector is clean")
		end
	end

	if GrassCuttingSystem.seat and GrassCuttingSystem.seat.Occupant then
		local driver = Players:GetPlayerFromCharacter(GrassCuttingSystem.seat.Occupant.Parent)
		print("Current driver: " .. (driver and driver.Name or "Unknown"))

		local velocity = GrassCuttingSystem.seat.AssemblyLinearVelocity or GrassCuttingSystem.seat.Velocity
		print("Current speed: " .. math.floor(velocity.Magnitude * 10) / 10)
	else
		print("Current driver: None")
	end

	print("===========================")
end

_G.CountNearbyGrass = function()
	if not GrassCuttingSystem.grassDetector then
		print("❌ No grass detector available")
		return 0
	end

	local grassList = findGrassInArea(GrassCuttingSystem.grassDetector)
	print("🌿 Found " .. #grassList .. " mowable grass in cutting area")

	-- Show some examples
	for i = 1, math.min(3, #grassList) do
		local grass = grassList[i]
		print("  " .. i .. ". " .. grass.Name .. " at " .. tostring(grass.Position) .. " (Size: " .. tostring(grass.Size) .. ")")
	end

	return #grassList
end

print("✅ FIXED SimpleTractorEnhancer loaded!")
print("🔧 Commands:")
print("  _G.FixedTractorStatus() - Check system status")
print("  _G.CountNearbyGrass() - Count grass in area")