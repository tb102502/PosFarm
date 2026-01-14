--[[
    GrassCuttingDebugger.server.lua
    Place in: ServerScriptService/GrassCuttingDebugger.server.lua
    
    Real-time debugging for grass cutting system
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local workspace = game:GetService("Workspace")

print("🌿 GrassCuttingDebugger: Starting...")

-- Configuration
local TRACTOR_NAME = "OldWornOutTractor"
local DEBUG_ENABLED = false
local DEBUG_CONNECTION = nil

-- Function to check if grass can be mowed
local function isGrassMowable(grass)
	if grass.Name ~= "Grass" or grass:GetAttribute("IsMowed") then 
		return false 
	end

	if grass:IsA("MeshPart") or grass:IsA("Part") then
		return grass.Size.Y >= 2
	end

	return grass:IsA("BasePart")
end

-- Function to find grass in detector area with debugging
local function findGrassInAreaDebug(detector)
	local found = {}
	local detectorPos = detector.Position
	local detectorSize = detector.Size

	-- Calculate bounding box
	local minBounds = detectorPos - (detectorSize / 2)
	local maxBounds = detectorPos + (detectorSize / 2)

	local totalGrassChecked = 0
	local grassInBounds = 0
	local mowableGrass = 0

	-- Search for grass in the area
	for _, obj in ipairs(workspace:GetDescendants()) do
		if obj:IsA("BasePart") and obj.Name == "Grass" then
			totalGrassChecked = totalGrassChecked + 1
			local pos = obj.Position

			-- Check if grass is within detector bounds
			if pos.X >= minBounds.X and pos.X <= maxBounds.X and
				pos.Y >= minBounds.Y and pos.Y <= maxBounds.Y and
				pos.Z >= minBounds.Z and pos.Z <= maxBounds.Z then

				grassInBounds = grassInBounds + 1

				if isGrassMowable(obj) then
					mowableGrass = mowableGrass + 1
					table.insert(found, obj)
				end
			end
		end
	end

	-- Return both results and debug info
	return found, {
		totalGrassChecked = totalGrassChecked,
		grassInBounds = grassInBounds,
		mowableGrass = mowableGrass,
		detectorPos = detectorPos,
		detectorSize = detectorSize,
		minBounds = minBounds,
		maxBounds = maxBounds
	}
end

-- Real-time debugging function
local function grassCuttingDebugHeartbeat()
	if not DEBUG_ENABLED then return end

	local tractor = workspace:FindFirstChild(TRACTOR_NAME)
	if not tractor then return end

	local seat = tractor:FindFirstChildOfClass("VehicleSeat")
	if not seat then return end

	local grassDetector = tractor:FindFirstChild("GrassDetector")
	if not grassDetector then return end

	-- Check if someone is driving
	if not seat.Occupant then
		return -- Don't spam when no one is driving
	end

	-- Get the driver
	local driver = Players:GetPlayerFromCharacter(seat.Occupant.Parent)
	if not driver then return end

	-- Get velocity
	local velocity = seat.AssemblyLinearVelocity
	local speed = velocity.Magnitude

	-- Find grass with debug info
	local grassList, debugInfo = findGrassInAreaDebug(grassDetector)

	-- Print debug info every 2 seconds
	if not tractor:GetAttribute("LastDebugTime") or 
		(tick() - tractor:GetAttribute("LastDebugTime")) > 2 then

		tractor:SetAttribute("LastDebugTime", tick())

		print("🌿 REAL-TIME GRASS CUTTING DEBUG:")
		print("  Driver: " .. driver.Name)
		print("  Speed: " .. math.floor(speed * 100) / 100 .. " (need >= 2)")
		print("  Speed OK: " .. (speed >= 2 and "✅" or "❌"))
		print("")
		print("  Detector Position: " .. tostring(debugInfo.detectorPos))
		print("  Detector Size: " .. tostring(debugInfo.detectorSize))
		print("")
		print("  Total grass in world: " .. debugInfo.totalGrassChecked)
		print("  Grass in detector bounds: " .. debugInfo.grassInBounds)
		print("  Mowable grass in bounds: " .. debugInfo.mowableGrass)
		print("  Grass that would be cut: " .. #grassList)
		print("")

		if #grassList > 0 then
			print("  🎯 GRASS FOUND! Reasons it might not cut:")
			if speed < 2 then
				print("    ❌ Speed too slow (" .. speed .. " < 2)")
			else
				print("    ✅ Speed is good (" .. speed .. " >= 2)")
			end

			-- Check if SimpleTractorEnhancer is active
			local hasSystem = grassDetector:GetAttribute("GrassCuttingEnabled")
			print("    GrassCuttingEnabled: " .. (hasSystem and "✅" or "❌"))

			if not hasSystem then
				print("    💡 Run _G.SimpleTractorEnhance() to activate cutting")
			end
		else
			print("  📍 NO GRASS FOUND! Possible issues:")
			if debugInfo.totalGrassChecked == 0 then
				print("    ❌ No grass exists in the world")
				print("    💡 Make sure there are parts named 'Grass'")
			elseif debugInfo.grassInBounds == 0 then
				print("    ❌ No grass in detector area")
				print("    💡 Drive to an area with grass")
			elseif debugInfo.mowableGrass == 0 then
				print("    ❌ All grass in area is already cut")
				print("    💡 Wait for grass to regrow or find uncut grass")
			end
		end
		print("  ================================")
	end
end

-- Global functions for manual debugging
_G.EnableGrassDebug = function()
	DEBUG_ENABLED = true

	if DEBUG_CONNECTION then
		DEBUG_CONNECTION:Disconnect()
	end

	DEBUG_CONNECTION = RunService.Heartbeat:Connect(grassCuttingDebugHeartbeat)
	print("✅ Grass cutting debug ENABLED - drive around to see real-time info")
end

_G.DisableGrassDebug = function()
	DEBUG_ENABLED = false

	if DEBUG_CONNECTION then
		DEBUG_CONNECTION:Disconnect()
		DEBUG_CONNECTION = nil
	end

	print("❌ Grass cutting debug DISABLED")
end

_G.GrassDebugSnapshot = function()
	local tractor = workspace:FindFirstChild(TRACTOR_NAME)
	if not tractor then
		print("❌ No tractor found")
		return
	end

	local grassDetector = tractor:FindFirstChild("GrassDetector")
	if not grassDetector then
		print("❌ No GrassDetector found")
		return
	end

	print("📸 GRASS DEBUG SNAPSHOT:")
	local grassList, debugInfo = findGrassInAreaDebug(grassDetector)

	print("  Detector Position: " .. tostring(debugInfo.detectorPos))
	print("  Detector Size: " .. tostring(debugInfo.detectorSize))
	print("  Bounds: " .. tostring(debugInfo.minBounds) .. " to " .. tostring(debugInfo.maxBounds))
	print("")
	print("  Total grass in world: " .. debugInfo.totalGrassChecked)
	print("  Grass in detector bounds: " .. debugInfo.grassInBounds)
	print("  Mowable grass in bounds: " .. debugInfo.mowableGrass)
	print("")

	if #grassList > 0 then
		print("  🌿 MOWABLE GRASS FOUND:")
		for i, grass in ipairs(grassList) do
			if i <= 5 then -- Show first 5
				print("    " .. i .. ". " .. grass.Name .. " at " .. tostring(grass.Position) .. 
					" (Size: " .. tostring(grass.Size) .. ")")
			elseif i == 6 then
				print("    ... and " .. (#grassList - 5) .. " more")
				break
			end
		end
	else
		print("  ❌ NO MOWABLE GRASS FOUND")
	end

	-- Check system status
	local hasSystem = grassDetector:GetAttribute("GrassCuttingEnabled")
	print("")
	print("  System Status:")
	print("    GrassCuttingEnabled: " .. (hasSystem and "✅" or "❌"))

	if not hasSystem then
		print("    💡 Run _G.SimpleTractorEnhance() to enable grass cutting")
	end
end

_G.CheckNearbyGrass = function(radius)
	radius = radius or 20

	local tractor = workspace:FindFirstChild(TRACTOR_NAME)
	if not tractor then
		print("❌ No tractor found")
		return
	end

	local grassDetector = tractor:FindFirstChild("GrassDetector")
	if not grassDetector then
		print("❌ No GrassDetector found")
		return
	end

	local detectorPos = grassDetector.Position
	local nearbyGrass = {}

	for _, obj in ipairs(workspace:GetDescendants()) do
		if obj:IsA("BasePart") and obj.Name == "Grass" then
			local distance = (obj.Position - detectorPos).Magnitude
			if distance <= radius then
				table.insert(nearbyGrass, {
					grass = obj,
					distance = distance,
					mowable = isGrassMowable(obj),
					size = obj.Size,
					position = obj.Position
				})
			end
		end
	end

	-- Sort by distance
	table.sort(nearbyGrass, function(a, b) return a.distance < b.distance end)

	print("🔍 NEARBY GRASS (within " .. radius .. " studs):")
	print("  Total found: " .. #nearbyGrass)

	local mowableCount = 0
	for i, grassInfo in ipairs(nearbyGrass) do
		if grassInfo.mowable then
			mowableCount = mowableCount + 1
		end

		if i <= 10 then -- Show first 10
			local status = grassInfo.mowable and "✅ Mowable" or "❌ Cut/Small"
			print("    " .. i .. ". Distance: " .. math.floor(grassInfo.distance) .. 
				" - Size: " .. tostring(grassInfo.size) .. " - " .. status)
		elseif i == 11 then
			print("    ... and " .. (#nearbyGrass - 10) .. " more")
			break
		end
	end

	print("  Mowable: " .. mowableCount .. "/" .. #nearbyGrass)

	if mowableCount == 0 then
		print("💡 Try driving to an area with taller grass!")
	end
end

print("✅ GrassCuttingDebugger loaded!")
print("🔧 Debug Commands:")
print("  _G.EnableGrassDebug() - Enable real-time debug while driving")
print("  _G.DisableGrassDebug() - Disable real-time debug")
print("  _G.GrassDebugSnapshot() - Take debug snapshot")
print("  _G.CheckNearbyGrass(20) - Check grass within 20 studs")