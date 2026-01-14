--[[
    ENHANCED TractorSystemInitializer.server.lua with Better Seating
    Place in: ServerScriptService/TractorSystemInitializer.server.lua
    
    Fixed seating issues with detailed debugging
]]

local ServerScriptService = game:GetService("ServerScriptService")
local Players = game:GetService("Players")

print("🚜 Enhanced TractorSystemInitializer: Starting...")

-- Configuration
local TRACTOR_NAME = "OldWornOutTractor"

-- Global reference
local TractorSystem = nil

-- Enhanced seating function with detailed debugging
local function EnhancedForceSeatPlayer(player, tractor)
	if not player then
		print("❌ No player provided")
		return false
	end

	if not tractor then
		tractor = workspace:FindFirstChild(TRACTOR_NAME)
	end

	if not tractor then
		print("❌ No tractor found")
		return false
	end

	print("🚜 Attempting to seat " .. player.Name .. " in " .. tractor.Name)

	-- Check character
	local character = player.Character
	if not character then
		print("❌ Player has no character")
		return false
	end
	print("✅ Character found: " .. character.Name)

	-- Check humanoid
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		print("❌ No humanoid found in character")
		return false
	end
	print("✅ Humanoid found: " .. humanoid.Name)

	-- Check HumanoidRootPart
	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
	if not humanoidRootPart then
		print("❌ No HumanoidRootPart found")
		return false
	end
	print("✅ HumanoidRootPart found")

	-- Find VehicleSeat
	local seat = tractor:FindFirstChildOfClass("VehicleSeat")
	if not seat then
		print("❌ No VehicleSeat found in tractor")
		return false
	end
	print("✅ VehicleSeat found: " .. seat.Name)

	-- Check if seat is already occupied
	if seat.Occupant then
		local currentOccupant = seat.Occupant.Parent
		print("⚠️ Seat already occupied by: " .. currentOccupant.Name)

		-- Unseat current occupant if it's a different player
		if currentOccupant ~= character then
			print("🔄 Unseating current occupant...")
			seat:Sit(nil)
			wait(0.2)
		else
			print("✅ Player is already seated")
			return true
		end
	end

	-- Check seat properties and fix them
	print("🔧 Checking seat properties...")
	print("  Anchored: " .. tostring(seat.Anchored))
	print("  Disabled: " .. tostring(seat.Disabled))
	print("  CanCollide: " .. tostring(seat.CanCollide))

	-- Fix seat properties
	if seat.Anchored then
		seat.Anchored = false
		print("  Fixed: Unanchored seat")
	end

	if seat.Disabled then
		seat.Disabled = false
		print("  Fixed: Enabled seat")
	end

	seat.CanCollide = true

	-- Ensure good driving parameters
	if seat.MaxSpeed < 20 then
		seat.MaxSpeed = 25
		print("  Fixed: Set MaxSpeed to " .. seat.MaxSpeed)
	end

	if seat.Torque < 5000 then
		seat.Torque = 10000
		print("  Fixed: Set Torque to " .. seat.Torque)
	end

	if seat.TurnSpeed < 40 then
		seat.TurnSpeed = 60
		print("  Fixed: Set TurnSpeed to " .. seat.TurnSpeed)
	end

	-- Position character above seat (higher up for safety)
	print("📍 Positioning character above seat...")
	local seatPosition = seat.Position
	local abovePosition = Vector3.new(seatPosition.X, seatPosition.Y + 10, seatPosition.Z)

	humanoidRootPart.CFrame = CFrame.new(abovePosition)
	print("  Moved character to: " .. tostring(abovePosition))

	-- Wait for position to update
	wait(0.3)

	-- Clear any existing velocities
	if humanoidRootPart.AssemblyLinearVelocity then
		humanoidRootPart.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
		humanoidRootPart.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
	end

	-- Attempt to sit (multiple attempts)
	print("🪑 Attempting to sit...")
	local seatAttempts = 0
	local maxAttempts = 5

	while seatAttempts < maxAttempts do
		seatAttempts = seatAttempts + 1
		print("  Attempt " .. seatAttempts .. "/" .. maxAttempts)

		-- Try to sit
		seat:Sit(humanoid)

		-- Wait and check
		wait(0.4)

		if seat.Occupant == humanoid then
			print("✅ Successfully seated " .. player.Name .. " on attempt " .. seatAttempts)

			-- Give final status
			print("🎮 Seating complete:")
			print("  Driver: " .. player.Name)
			print("  Seat: " .. seat.Name)
			print("  MaxSpeed: " .. seat.MaxSpeed)
			print("  Use WASD to drive!")

			return true
		else
			print("❌ Attempt " .. seatAttempts .. " failed, occupant: " .. tostring(seat.Occupant))

			-- Try moving closer to seat for next attempt
			if seatAttempts < maxAttempts then
				local newPosition = Vector3.new(seatPosition.X, seatPosition.Y + (6 - seatAttempts), seatPosition.Z)
				humanoidRootPart.CFrame = CFrame.new(newPosition)
				wait(0.2)
			end
		end
	end

	print("❌ Failed to seat " .. player.Name .. " after " .. maxAttempts .. " attempts")
	print("🔧 Troubleshooting info:")
	print("  Seat anchored: " .. tostring(seat.Anchored))
	print("  Seat disabled: " .. tostring(seat.Disabled))
	print("  Seat occupant: " .. tostring(seat.Occupant))
	print("  Character in workspace: " .. tostring(character.Parent == workspace))
	print("  Humanoid state: " .. tostring(humanoid:GetState()))

	return false
end

-- Create enhanced system for existing tractor
local function CreateEnhancedSystem()
	print("🔄 Creating enhanced tractor system for existing tractor...")

	TractorSystem = {
		-- Get the existing tractor
		GetTractor = function(self)
			return workspace:FindFirstChild(TRACTOR_NAME)
		end,

		FixMovementIssues = function(self, tractor)
			if not tractor then 
				tractor = self:GetTractor()
			end

			if not tractor then
				warn("❌ No tractor found")
				return false
			end

			print("🔧 Fixing movement issues for existing tractor...")

			-- Ensure all parts are unanchored
			local fixedParts = 0
			for _, part in ipairs(tractor:GetDescendants()) do
				if part:IsA("BasePart") and part.Anchored then
					part.Anchored = false
					part.CanCollide = true
					fixedParts = fixedParts + 1
				end
			end

			if fixedParts > 0 then
				print("📍 Unanchored " .. fixedParts .. " parts")
			end

			-- Find and fix VehicleSeat
			local seat = tractor:FindFirstChildOfClass("VehicleSeat")
			if not seat then
				warn("❌ No VehicleSeat found in tractor")
				return false
			end

			-- Fix seat properties
			seat.Anchored = false
			seat.CanCollide = true
			seat.Disabled = false

			-- Ensure good driving parameters
			seat.MaxSpeed = math.max(seat.MaxSpeed, 25)
			seat.Torque = math.max(seat.Torque, 10000)
			seat.TurnSpeed = math.max(seat.TurnSpeed, 60)

			print("🪑 VehicleSeat configured:")
			print("  MaxSpeed: " .. seat.MaxSpeed)
			print("  Torque: " .. seat.Torque)
			print("  TurnSpeed: " .. seat.TurnSpeed)
			print("  Anchored: " .. tostring(seat.Anchored))
			print("  Disabled: " .. tostring(seat.Disabled))

			return true
		end,

		DebugTractor = function(self, tractor)
			if not tractor then 
				tractor = self:GetTractor()
			end

			if not tractor then 
				print("❌ No tractor found")
				return 
			end

			print("=== ENHANCED TRACTOR DEBUG ===")
			print("Tractor: " .. tractor.Name .. " ✅")

			local seat = tractor:FindFirstChildOfClass("VehicleSeat")
			print("VehicleSeat: " .. (seat and "✅" or "❌"))

			if seat then
				print("  Name: " .. seat.Name)
				print("  Anchored: " .. (seat.Anchored and "❌ PROBLEM" or "✅"))
				print("  Disabled: " .. (seat.Disabled and "❌ PROBLEM" or "✅"))
				print("  CanCollide: " .. tostring(seat.CanCollide))
				print("  MaxSpeed: " .. seat.MaxSpeed)
				print("  Torque: " .. seat.Torque)
				print("  TurnSpeed: " .. seat.TurnSpeed)
				print("  Position: " .. tostring(seat.Position))
				print("  Size: " .. tostring(seat.Size))

				if seat.Occupant then
					local occupantChar = seat.Occupant.Parent
					print("  Occupant: " .. occupantChar.Name)
				else
					print("  Occupant: None")
				end
			end

			-- Check grass detector and cutting system
			local grassDetector = tractor:FindFirstChild("GrassDetector")
			print("GrassDetector: " .. (grassDetector and "✅" or "❌"))

			if grassDetector then
				print("  Size: " .. tostring(grassDetector.Size))
				print("  Position: " .. tostring(grassDetector.Position))
				print("  CanCollide: " .. tostring(grassDetector.CanCollide))
				print("  Transparency: " .. grassDetector.Transparency)

				-- Check for grass cutting system
				local hasRunServiceSystem = grassDetector:GetAttribute("GrassCuttingEnabled")
				print("  GrassCuttingEnabled: " .. (hasRunServiceSystem and "✅" or "❌"))
			end

			-- Check for anchored parts
			local anchoredParts = 0
			local totalParts = 0
			for _, part in ipairs(tractor:GetDescendants()) do
				if part:IsA("BasePart") then
					totalParts = totalParts + 1
					if part.Anchored then
						anchoredParts = anchoredParts + 1
					end
				end
			end

			print("Parts: " .. totalParts .. " total, " .. anchoredParts .. " anchored")
			if anchoredParts > 0 then
				print("  ⚠️ Anchored parts may prevent movement!")
			end

			-- Check PrimaryPart
			print("PrimaryPart: " .. (tractor.PrimaryPart and tractor.PrimaryPart.Name or "❌ Not set"))

			print("===============================")
		end,

		-- Enhanced force seat player function
		ForceSeatPlayer = function(self, player, tractor)
			return EnhancedForceSeatPlayer(player, tractor)
		end,

		-- Check grass cutting system
		CheckGrassCutting = function(self, tractor)
			if not tractor then
				tractor = self:GetTractor()
			end

			if not tractor then
				print("❌ No tractor found")
				return false
			end

			print("🌿 GRASS CUTTING SYSTEM CHECK:")

			local grassDetector = tractor:FindFirstChild("GrassDetector")
			if not grassDetector then
				print("❌ No GrassDetector found")
				print("💡 Use SimpleTractorEnhancer to add grass cutting")
				return false
			end

			local hasRunServiceSystem = grassDetector:GetAttribute("GrassCuttingEnabled")
			if not hasRunServiceSystem then
				print("❌ No grass cutting system active")
				print("💡 Use SimpleTractorEnhancer to add grass cutting")
				return false
			end

			-- Check for remote events
			local replicatedStorage = game:GetService("ReplicatedStorage")
			local gameRemotes = replicatedStorage:FindFirstChild("GameRemotes")
			if not gameRemotes then
				print("❌ GameRemotes folder not found")
				return false
			end

			local grassMowed = gameRemotes:FindFirstChild("GrassMowed")
			if not grassMowed then
				print("❌ GrassMowed remote event not found")
				return false
			end

			print("✅ Grass cutting system properly configured")
			return true
		end,

		-- Test function to verify everything works
		TestTractorFull = function(self, player)
			print("🧪 FULL TRACTOR TEST SEQUENCE")
			print("==============================")

			local tractor = self:GetTractor()
			if not tractor then
				print("❌ No tractor found")
				return false
			end

			-- Step 1: Debug current state
			print("Step 1: Debugging current state...")
			self:DebugTractor(tractor)

			-- Step 2: Fix movement issues
			print("\nStep 2: Fixing movement issues...")
			local fixSuccess = self:FixMovementIssues(tractor)
			print("Movement fixes: " .. (fixSuccess and "✅" or "❌"))

			-- Step 3: Check grass cutting
			print("\nStep 3: Checking grass cutting...")
			local grassSuccess = self:CheckGrassCutting(tractor)
			print("Grass cutting: " .. (grassSuccess and "✅" or "❌"))

			-- Step 4: Test seating
			print("\nStep 4: Testing seating...")
			local seatSuccess = self:ForceSeatPlayer(player, tractor)
			print("Seating: " .. (seatSuccess and "✅" or "❌"))

			print("\n==============================")
			print("FULL TEST RESULTS:")
			print("  Movement: " .. (fixSuccess and "✅" or "❌"))
			print("  Grass Cutting: " .. (grassSuccess and "✅" or "❌"))
			print("  Seating: " .. (seatSuccess and "✅" or "❌"))
			print("  Overall: " .. (fixSuccess and grassSuccess and seatSuccess and "✅ SUCCESS" or "❌ ISSUES FOUND"))

			if seatSuccess then
				print("\n🎮 You are now seated in the tractor!")
				print("Use WASD to drive and test grass cutting")
			end

			return fixSuccess and grassSuccess and seatSuccess
		end
	}

	print("✅ Enhanced system created for existing tractor")
end

-- Initialize
local function Initialize()
	CreateEnhancedSystem()

	-- Check if tractor exists
	local tractor = workspace:FindFirstChild(TRACTOR_NAME)
	if not tractor then
		warn("❌ " .. TRACTOR_NAME .. " not found in workspace")
		warn("   Make sure your tractor model exists and is named '" .. TRACTOR_NAME .. "'")
		return false
	end

	print("✅ Found existing tractor: " .. tractor.Name)

	-- Make globally available
	_G.TractorSystem = TractorSystem

	print("🎉 Enhanced tractor system ready!")
	return true
end

-- Start initialization
spawn(function()
	wait(3) -- Wait for workspace to load
	Initialize()
end)

-- Admin commands
local ADMIN_USERNAME = "TommySalami311" -- CHANGE THIS TO YOUR USERNAME

Players.PlayerAdded:Connect(function(player)
	player.Chatted:Connect(function(message)
		if player.Name ~= ADMIN_USERNAME then return end

		local cmd = message:lower()

		if cmd == "/tractorhelp" then
			print("🚜 ENHANCED TRACTOR COMMANDS:")
			print("  === Basic Commands ===")
			print("  /checkstatus      - Check system status")
			print("  /debugtractor     - Debug existing tractor")
			print("  /fixmovement      - Fix movement issues")
			print("  === Seating Commands ===")
			print("  /seatme           - Enhanced seat function")
			print("  /gototractor      - Teleport to tractor")
			print("  === Testing Commands ===")
			print("  /testfull         - Complete system test")
			print("  /checkgrass       - Check grass cutting")
			print("  === Grass Debug Commands ===")
			print("  /debuggrass       - Snapshot of grass detection")
			print("  /enablegrassdebug - Real-time grass debug while driving")
			print("  /disablegrassdebug- Disable real-time debug")
			print("  /nearbygrass      - Check grass within 20 studs")
			print("  === Detector Commands ===")
			print("  /checkdetector    - Check detector positioning")
			print("  /fixdetector      - Fix detector positioning")
			print("  /showdetector     - Visualize detector bounds")
			print("  /detectorstatus   - Quick detector status")

		elseif cmd == "/checkstatus" then
			print("🔍 ENHANCED SYSTEM STATUS:")
			print("TractorSystem loaded: " .. (TractorSystem and "✅" or "❌"))
			print("Global reference: " .. (_G.TractorSystem and "✅" or "❌"))

			local tractor = workspace:FindFirstChild(TRACTOR_NAME)
			print("Existing tractor: " .. (tractor and "✅ " .. tractor.Name or "❌ Not found"))

		elseif cmd == "/debugtractor" then
			if TractorSystem and TractorSystem.DebugTractor then
				TractorSystem:DebugTractor()
			else
				print("❌ DebugTractor not available")
			end

		elseif cmd == "/fixmovement" then
			if TractorSystem and TractorSystem.FixMovementIssues then
				local success = TractorSystem:FixMovementIssues()
				print(success and "✅ Movement fixes applied" or "❌ Fixes failed")
			else
				print("❌ FixMovementIssues not available")
			end

		elseif cmd == "/seatme" then
			if TractorSystem and TractorSystem.ForceSeatPlayer then
				print("🪑 Using enhanced seating function...")
				local success = TractorSystem:ForceSeatPlayer(player)
				-- Success/failure is already printed by the enhanced function
			else
				print("❌ ForceSeatPlayer not available")
			end

		elseif cmd == "/gototractor" then
			local tractor = workspace:FindFirstChild(TRACTOR_NAME)
			if tractor and player.Character and player.Character.PrimaryPart then
				local cf = tractor.PrimaryPart and tractor.PrimaryPart.CFrame or tractor:GetBoundingBox()
				player.Character:SetPrimaryPartCFrame(cf + Vector3.new(8, 0, 0))
				print("✅ Teleported to existing tractor")
			else
				print("❌ Cannot teleport - tractor or character issue")
			end

		elseif cmd == "/testfull" then
			if TractorSystem and TractorSystem.TestTractorFull then
				TractorSystem:TestTractorFull(player)
			else
				print("❌ TestTractorFull not available")
			end

		elseif cmd == "/checkgrass" then
			if TractorSystem and TractorSystem.CheckGrassCutting then
				TractorSystem:CheckGrassCutting()
			else
				print("❌ CheckGrassCutting not available")
			end
		end
	end)
end)

print("🚜 Enhanced TractorSystemInitializer ready with improved seating")