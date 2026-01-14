--[[
    SIMPLE WORKING TractorSystem.lua
    Place in: ServerScriptService/Modules/TractorSystem.lua
    
    This is a simplified version that should work without errors
]]

local TractorSystem = {}

-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Config
TractorSystem.Config = {
	maxSpeed = 25,
	turnSpeed = 60,
	interactionDistance = 12,
}

-- Tracking
TractorSystem.Tractors = {}
TractorSystem.PlayerTractors = {}

-- Helper to find largest part
function TractorSystem:FindLargestPart(model)
	local largest, vol = nil, 0
	for _, part in ipairs(model:GetDescendants()) do
		if part:IsA("BasePart") then
			local v = part.Size.X * part.Size.Y * part.Size.Z
			if v > vol then 
				largest, vol = part, v 
			end
		end
	end
	return largest
end

-- Fix movement issues
function TractorSystem:FixMovementIssues(tractor)
	if not tractor then
		warn("❌ No tractor provided")
		return false
	end

	print("🔧 Fixing movement issues for: " .. tractor.Name)

	-- Step 1: Find chassis
	local chassis = tractor.PrimaryPart or self:FindLargestPart(tractor)
	if not chassis then
		warn("❌ No chassis found")
		return false
	end

	chassis.Name = "Chassis"
	tractor.PrimaryPart = chassis
	print("✅ Chassis: " .. chassis.Name)

	-- Step 2: Unanchor everything
	local unanchored = 0
	for _, part in ipairs(tractor:GetDescendants()) do
		if part:IsA("BasePart") and part.Anchored then
			part.Anchored = false
			part.CanCollide = true
			unanchored = unanchored + 1
		end
	end
	print("📍 Unanchored " .. unanchored .. " parts")

	-- Step 3: Fix VehicleSeat
	local seat = tractor:FindFirstChildOfClass("VehicleSeat")
	if not seat then
		warn("❌ No VehicleSeat found")
		return false
	end

	seat.Anchored = false
	seat.CanCollide = true
	seat.Disabled = false
	seat.MaxSpeed = self.Config.maxSpeed
	seat.Torque = 10000
	seat.TurnSpeed = self.Config.turnSpeed

	print("✅ VehicleSeat configured:")
	print("  MaxSpeed: " .. seat.MaxSpeed)
	print("  Torque: " .. seat.Torque)
	print("  Anchored: " .. tostring(seat.Anchored))
	print("  Disabled: " .. tostring(seat.Disabled))

	-- Step 4: Clear velocities
	for _, part in ipairs(tractor:GetDescendants()) do
		if part:IsA("BasePart") then
			if part.AssemblyLinearVelocity then
				part.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
				part.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
			end
		end
	end

	-- Step 5: Weld everything to chassis
	local welded = 0
	for _, part in ipairs(tractor:GetDescendants()) do
		if part:IsA("BasePart") and part ~= chassis then
			-- Remove old welds
			for _, child in ipairs(part:GetChildren()) do
				if child:IsA("WeldConstraint") and child.Name:find("ChassisWeld") then
					child:Destroy()
				end
			end

			-- Create new weld
			local weld = Instance.new("WeldConstraint")
			weld.Name = "ChassisWeld"
			weld.Part0 = chassis
			weld.Part1 = part
			weld.Parent = chassis
			welded = welded + 1
		end
	end
	print("🔗 Welded " .. welded .. " parts to chassis")

	-- Step 6: Ensure proximity prompt exists
	local prompt = tractor:FindFirstChildOfClass("ProximityPrompt", true)
	if not prompt then
		prompt = Instance.new("ProximityPrompt")
		prompt.ActionText = "Drive Tractor"
		prompt.ObjectText = "Old Tractor"
		prompt.HoldDuration = 0
		prompt.MaxActivationDistance = self.Config.interactionDistance
		prompt.Parent = seat
		print("✅ Created ProximityPrompt")
	end

	print("✅ Movement fixes complete!")
	return true
end

-- Force seat a player
function TractorSystem:ForceSeatPlayer(player, tractor)
	if not (player and tractor) then 
		return false 
	end

	local seat = tractor:FindFirstChildOfClass("VehicleSeat")
	if not seat then 
		warn("❌ No VehicleSeat found")
		return false 
	end

	local character = player.Character
	if not character then 
		warn("❌ Player has no character")
		return false 
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then 
		warn("❌ No humanoid found")
		return false 
	end

	print("🚜 Seating " .. player.Name .. " in tractor")

	-- Ensure seat is ready
	seat.Disabled = false
	seat.Anchored = false

	-- Position character above seat
	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
	if humanoidRootPart then
		humanoidRootPart.CFrame = seat.CFrame + Vector3.new(0, 5, 0)
		wait(0.1)
	end

	-- Attempt to sit
	seat:Sit(humanoid)
	wait(0.2)

	-- Check if successful
	if seat.Occupant == humanoid then
		print("✅ Successfully seated " .. player.Name)
		self.PlayerTractors[player] = tractor
		return true
	else
		warn("❌ Failed to seat " .. player.Name)
		return false
	end
end

-- Debug tractor
function TractorSystem:DebugTractor(tractor)
	if not tractor then 
		tractor = workspace:FindFirstChild("OldWornOutTractor") 
	end

	if not tractor then 
		print("❌ No tractor found")
		return 
	end

	print("=== TRACTOR DEBUG: " .. tractor.Name .. " ===")

	-- Check chassis
	local chassis = tractor.PrimaryPart
	print("🏗️ Chassis: " .. (chassis and chassis.Name or "❌ Missing"))
	if chassis then
		print("  Anchored: " .. tostring(chassis.Anchored))
		print("  CanCollide: " .. tostring(chassis.CanCollide))
	end

	-- Check VehicleSeat
	local seat = tractor:FindFirstChildOfClass("VehicleSeat")
	print("🪑 VehicleSeat: " .. (seat and "✅" or "❌"))
	if seat then
		print("  Anchored: " .. tostring(seat.Anchored))
		print("  Disabled: " .. tostring(seat.Disabled))
		print("  MaxSpeed: " .. seat.MaxSpeed)
		print("  Torque: " .. seat.Torque)
		print("  TurnSpeed: " .. seat.TurnSpeed)
		print("  Occupant: " .. (seat.Occupant and seat.Occupant.Parent.Name or "None"))
	end

	-- Check for anchored parts
	local anchoredCount = 0
	local totalParts = 0
	for _, part in ipairs(tractor:GetDescendants()) do
		if part:IsA("BasePart") then
			totalParts = totalParts + 1
			if part.Anchored then
				anchoredCount = anchoredCount + 1
			end
		end
	end

	print("📦 Parts: " .. totalParts .. " total, " .. anchoredCount .. " anchored")
	if anchoredCount > 0 then
		print("  ⚠️ Anchored parts will prevent movement!")
	end

	-- Check ProximityPrompt
	local prompt = tractor:FindFirstChildOfClass("ProximityPrompt", true)
	print("🔔 ProximityPrompt: " .. (prompt and "✅" or "❌"))

	-- Movement diagnosis
	print("🚗 Movement Status:")
	if anchoredCount > 0 then
		print("  ❌ CANNOT MOVE: Anchored parts detected")
	elseif not seat then
		print("  ❌ CANNOT MOVE: No VehicleSeat")
	elseif seat.Disabled then
		print("  ❌ CANNOT MOVE: VehicleSeat disabled")
	elseif seat.Anchored then
		print("  ❌ CANNOT MOVE: VehicleSeat anchored")
	else
		print("  ✅ SHOULD BE ABLE TO MOVE")
	end

	print("======================================")
end

-- Movement-specific debug
function TractorSystem:DebugMovement(tractor)
	print("🔍 MOVEMENT DIAGNOSTIC:")
	self:DebugTractor(tractor)
end

-- Initialize the system
function TractorSystem:Initialize()
	print("🚜 Simple TractorSystem: Initializing...")

	-- Wait for tractor to exist
	local tractor = nil
	local attempts = 0

	while attempts < 10 do
		tractor = workspace:FindFirstChild("OldWornOutTractor")
		if tractor then break end
		attempts = attempts + 1
		print("⏳ Waiting for tractor... (" .. attempts .. "/10)")
		wait(1)
	end

	if not tractor then
		warn("❌ OldWornOutTractor not found after 10 attempts")
		return false
	end

	print("✅ Found tractor: " .. tractor.Name)

	-- Apply initial fixes
	local success = self:FixMovementIssues(tractor)
	if not success then
		warn("❌ Initial fixes failed")
		return false
	end

	-- Setup prompt handling
	local prompt = tractor:FindFirstChildOfClass("ProximityPrompt", true)
	if prompt then
		prompt.Triggered:Connect(function(player)
			print("🚜 " .. player.Name .. " triggered tractor prompt")
			self:ForceSeatPlayer(player, tractor)
		end)
		print("✅ ProximityPrompt connected")
	end

	-- Track the tractor
	self.Tractors[tractor] = {
		chassis = tractor.PrimaryPart,
		seat = tractor:FindFirstChildOfClass("VehicleSeat"),
		driver = nil
	}

	-- Setup exit handling
	local seat = tractor:FindFirstChildOfClass("VehicleSeat")
	if seat then
		seat:GetPropertyChangedSignal("Occupant"):Connect(function()
			if not seat.Occupant then
				-- Player exited
				for player, playerTractor in pairs(self.PlayerTractors) do
					if playerTractor == tractor then
						print("🚜 " .. player.Name .. " exited tractor")
						self.PlayerTractors[player] = nil
						break
					end
				end
			end
		end)
	end

	print("✅ Simple TractorSystem initialized successfully")
	return true
end

-- Make globally available
_G.TractorSystem = TractorSystem

return TractorSystem