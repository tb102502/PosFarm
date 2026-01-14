--[[
    DetectorVisualizer.server.lua
    Place in: ServerScriptService/DetectorVisualizer.server.lua
    
    Visualizes and fixes the GrassDetector positioning
]]

local workspace = game:GetService("Workspace")
local Players = game:GetService("Players")

print("👁️ DetectorVisualizer: Starting...")

-- Configuration
local TRACTOR_NAME = "OldWornOutTractor"

-- Function to visualize detector bounds
local function visualizeDetectorBounds(detector, duration)
	duration = duration or 10

	print("🎯 Visualizing detector bounds for " .. duration .. " seconds...")

	local detectorPos = detector.Position
	local detectorSize = detector.Size

	-- Calculate corners of the detection area
	local minBounds = detectorPos - (detectorSize / 2)
	local maxBounds = detectorPos + (detectorSize / 2)

	print("  Detector Position: " .. tostring(detectorPos))
	print("  Detector Size: " .. tostring(detectorSize))
	print("  Min Bounds: " .. tostring(minBounds))
	print("  Max Bounds: " .. tostring(maxBounds))

	-- Create corner markers
	local corners = {
		Vector3.new(minBounds.X, detectorPos.Y, minBounds.Z), -- Front-left
		Vector3.new(maxBounds.X, detectorPos.Y, minBounds.Z), -- Front-right
		Vector3.new(minBounds.X, detectorPos.Y, maxBounds.Z), -- Back-left
		Vector3.new(maxBounds.X, detectorPos.Y, maxBounds.Z), -- Back-right
	}

	local markers = {}

	for i, cornerPos in ipairs(corners) do
		local marker = Instance.new("Part")
		marker.Name = "DetectorCorner" .. i
		marker.Size = Vector3.new(1, 4, 1)
		marker.Material = Enum.Material.Neon
		marker.Color = Color3.fromRGB(255, 0, 255) -- Bright magenta
		marker.Anchored = true
		marker.CanCollide = false
		marker.Position = cornerPos
		marker.Parent = workspace

		table.insert(markers, marker)
		print("  Created corner marker " .. i .. " at " .. tostring(cornerPos))
	end

	-- Create center marker
	local centerMarker = Instance.new("Part")
	centerMarker.Name = "DetectorCenter"
	centerMarker.Size = Vector3.new(0.5, 6, 0.5)
	centerMarker.Material = Enum.Material.Neon
	centerMarker.Color = Color3.fromRGB(0, 255, 255) -- Bright cyan
	centerMarker.Anchored = true
	centerMarker.CanCollide = false
	centerMarker.Position = detectorPos
	centerMarker.Parent = workspace
	table.insert(markers, centerMarker)

	-- Clean up after duration
	spawn(function()
		wait(duration)
		for _, marker in ipairs(markers) do
			if marker.Parent then
				marker:Destroy()
			end
		end
		print("🧹 Cleaned up detector visualization")
	end)

	return markers
end

-- Function to check and fix detector positioning
local function checkDetectorPositioning()
	local tractor = workspace:FindFirstChild(TRACTOR_NAME)
	if not tractor then
		print("❌ No tractor found")
		return false
	end

	local detector = tractor:FindFirstChild("GrassDetector")
	if not detector then
		print("❌ No GrassDetector found in tractor")
		print("💡 Run _G.SimpleTractorEnhance() to create detector")
		return false
	end

	print("=== DETECTOR POSITIONING CHECK ===")
	print("Tractor: " .. tractor.Name)
	print("Detector: " .. detector.Name)
	print("")

	-- Check detector properties
	print("DETECTOR PROPERTIES:")
	print("  Position: " .. tostring(detector.Position))
	print("  Size: " .. tostring(detector.Size))
	print("  Anchored: " .. tostring(detector.Anchored))
	print("  CanCollide: " .. tostring(detector.CanCollide))
	print("  Transparency: " .. detector.Transparency)
	print("  Color: " .. tostring(detector.Color))
	print("")

	-- Check tractor seat for reference
	local seat = tractor:FindFirstChildOfClass("VehicleSeat")
	if seat then
		print("TRACTOR SEAT (for reference):")
		print("  Position: " .. tostring(seat.Position))
		print("  Size: " .. tostring(seat.Size))
		print("")

		-- Calculate where detector should be relative to seat
		local seatPos = seat.Position
		local detectorPos = detector.Position
		local offset = detectorPos - seatPos

		print("POSITIONING ANALYSIS:")
		print("  Detector is " .. tostring(offset) .. " from seat")
		print("  Distance from seat: " .. math.floor((offset).Magnitude * 10) / 10 .. " studs")

		-- Check if detector is roughly under the tractor
		local horizontalDistance = math.sqrt(offset.X^2 + offset.Z^2)
		print("  Horizontal distance: " .. math.floor(horizontalDistance * 10) / 10 .. " studs")
		print("  Vertical offset: " .. math.floor(offset.Y * 10) / 10 .. " studs")

		if horizontalDistance > 10 then
			print("  ⚠️ Detector might be too far from tractor horizontally")
		end

		if offset.Y > 0 then
			print("  ⚠️ Detector is ABOVE seat - should be below")
		elseif offset.Y < -10 then
			print("  ⚠️ Detector might be too far below tractor")
		end
	end

	-- Check for weld constraints
	print("")
	print("WELD CHECK:")
	local hasWeld = false
	for _, child in ipairs(detector:GetChildren()) do
		if child:IsA("WeldConstraint") then
			hasWeld = true
			print("  ✅ Found WeldConstraint: " .. child.Name)
			if child.Part0 then
				print("    Part0: " .. child.Part0.Name)
			end
			if child.Part1 then
				print("    Part1: " .. child.Part1.Name)
			end
		end
	end

	-- Also check chassis for welds to detector
	local chassis = tractor:FindFirstChild("Chassis") or tractor.PrimaryPart
	if chassis then
		for _, child in ipairs(chassis:GetChildren()) do
			if child:IsA("WeldConstraint") and 
				(child.Part0 == detector or child.Part1 == detector) then
				hasWeld = true
				print("  ✅ Found WeldConstraint in chassis: " .. child.Name)
			end
		end
	end

	if not hasWeld then
		print("  ❌ No WeldConstraint found - detector won't move with tractor!")
	end

	print("==================================")

	return true
end

-- Function to fix detector positioning
local function fixDetectorPositioning()
	local tractor = workspace:FindFirstChild(TRACTOR_NAME)
	if not tractor then
		print("❌ No tractor found")
		return false
	end

	local detector = tractor:FindFirstChild("GrassDetector")
	if not detector then
		print("❌ No GrassDetector found")
		return false
	end

	print("🔧 Fixing detector positioning...")

	-- Find reference point (seat or chassis)
	local seat = tractor:FindFirstChildOfClass("VehicleSeat")
	local chassis = tractor:FindFirstChild("Chassis") or tractor.PrimaryPart
	local reference = seat or chassis

	if not reference then
		print("❌ No reference point found (seat or chassis)")
		return false
	end

	print("  Using reference: " .. reference.Name)

	-- Position detector under the reference point
	local refPos = reference.Position
	local newDetectorPos = Vector3.new(refPos.X, refPos.Y - 3, refPos.Z)

	detector.Position = newDetectorPos
	detector.Anchored = false
	detector.CanCollide = false

	-- Make sure it's visible for debugging
	detector.Transparency = 0.5
	detector.Color = Color3.fromRGB(100, 255, 100)
	detector.Material = Enum.Material.ForceField

	print("  Moved detector to: " .. tostring(newDetectorPos))

	-- Re-weld to chassis/reference
	-- Remove old welds first
	for _, child in ipairs(detector:GetChildren()) do
		if child:IsA("WeldConstraint") then
			child:Destroy()
		end
	end

	if chassis then
		for _, child in ipairs(chassis:GetChildren()) do
			if child:IsA("WeldConstraint") and 
				(child.Part0 == detector or child.Part1 == detector) then
				child:Destroy()
			end
		end
	end

	-- Create new weld
	local weld = Instance.new("WeldConstraint")
	weld.Name = "DetectorWeld"
	weld.Part0 = reference
	weld.Part1 = detector
	weld.Parent = reference

	print("  Created new weld between " .. reference.Name .. " and detector")
	print("✅ Detector positioning fixed!")

	return true
end

-- Global functions
_G.CheckDetector = function()
	return checkDetectorPositioning()
end

_G.FixDetector = function()
	return fixDetectorPositioning()
end

_G.VisualizeDetector = function(duration)
	duration = duration or 10
	local tractor = workspace:FindFirstChild(TRACTOR_NAME)
	if not tractor then
		print("❌ No tractor found")
		return
	end

	local detector = tractor:FindFirstChild("GrassDetector")
	if not detector then
		print("❌ No GrassDetector found")
		return
	end

	return visualizeDetectorBounds(detector, duration)
end

_G.DetectorStatus = function()
	local tractor = workspace:FindFirstChild(TRACTOR_NAME)
	if not tractor then
		print("❌ No tractor found")
		return
	end

	local detector = tractor:FindFirstChild("GrassDetector")
	if not detector then
		print("❌ No GrassDetector found")
		print("💡 Run _G.SimpleTractorEnhance() to create detector")
		return
	end

	print("🔍 QUICK DETECTOR STATUS:")
	print("  Exists: ✅")
	print("  Position: " .. tostring(detector.Position))
	print("  Size: " .. tostring(detector.Size))
	print("  Visible: " .. (detector.Transparency < 1 and "✅" or "❌"))
	print("  Anchored: " .. (detector.Anchored and "❌ Problem" or "✅"))

	-- Check if it's moving with tractor
	local seat = tractor:FindFirstChildOfClass("VehicleSeat")
	if seat then
		local distance = (detector.Position - seat.Position).Magnitude
		print("  Distance from seat: " .. math.floor(distance * 10) / 10 .. " studs")
		if distance > 15 then
			print("  ⚠️ Detector seems far from tractor")
		end
	end
end

print("✅ DetectorVisualizer loaded!")
print("🔧 Commands:")
print("  _G.CheckDetector() - Check detector positioning")
print("  _G.FixDetector() - Fix detector positioning")
print("  _G.VisualizeDetector(10) - Show detector bounds for 10 seconds")
print("  _G.DetectorStatus() - Quick detector status")