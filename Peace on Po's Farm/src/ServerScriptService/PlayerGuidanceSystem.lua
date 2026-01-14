--[[
    FIXED PlayerGuidanceSystem.lua
    Place in: ServerScriptService/PlayerGuidanceSystem.lua
    
    FIXES:
    ✅ Fixed remote event creation timing
    ✅ Consistent tutorial completion tracking
    ✅ Simplified debug system
    ✅ Better error handling
    ✅ Automatic waypoint position detection
]]

local PlayerGuidanceSystem = {}

-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

-- Configuration
PlayerGuidanceSystem.Config = {
	-- Appearance settings
	arrowColor = Color3.fromRGB(255, 255, 255),
	arrowHighlightColor = Color3.fromRGB(100, 255, 100),
	arrowHeight = 5,
	arrowWidth = 1.2,
	arrowSegmentLength = 2,
	arrowGap = 0.8,

	-- Animation settings
	pulseSpeed = 1.5,
	pulseIntensity = 0.3,

	-- Distance settings
	maxArrowDistance = 50,
	minArrowDistance = 5,
	playerHeightOffset = 2,

	-- FIXED: Auto-detect waypoint positions
	waypoints = {} -- Will be populated automatically
}

-- State tracking
PlayerGuidanceSystem.ActiveGuidance = {}
PlayerGuidanceSystem.RemoteEvents = {}
PlayerGuidanceSystem.IsInitialized = false
-- ========== FIXED: REMOTE EVENT SETUP ==========

function PlayerGuidanceSystem:SetupRemoteEvents()
	print("📡 Setting up guidance remote events...")

	-- Wait for or create GameRemotes folder
	local remoteFolder = ReplicatedStorage:FindFirstChild("GameRemotes")
	if not remoteFolder then
		remoteFolder = Instance.new("Folder")
		remoteFolder.Name = "GameRemotes"
		remoteFolder.Parent = ReplicatedStorage
		print("Created GameRemotes folder")
	end

	-- Create guidance-specific remote events
	local guidanceEvents = {
		"ShowWaypoint",
		"HideWaypoint",
		"GuidanceDebug"
	}

	for _, eventName in ipairs(guidanceEvents) do
		local event = remoteFolder:FindFirstChild(eventName)
		if not event then
			event = Instance.new("RemoteEvent")
			event.Name = eventName
			event.Parent = remoteFolder
			print("Created RemoteEvent: " .. eventName)
		end
		self.RemoteEvents[eventName] = event
	end

	-- Setup debug remote handler
	if self.RemoteEvents.GuidanceDebug then
		self.RemoteEvents.GuidanceDebug.OnServerEvent:Connect(function(player, command, arg)
			self:HandleDebugCommand(player, command, arg)
		end)
		print("✅ Debug remote handler connected")
	end

	print("✅ Guidance remote events setup complete")
	return true
end

-- ========== FIXED: TUTORIAL COMPLETION TRACKING ==========

function PlayerGuidanceSystem:HasPlayerCompletedTutorial(player)
	-- Check multiple sources for consistency
	local hasCompleted = false

	-- Check GameCore data
	if _G.GameCore and _G.GameCore.GetPlayerData then
		local success, playerData = pcall(function()
			return _G.GameCore:GetPlayerData(player)
		end)

		if success and playerData then
			-- Check both possible field names for compatibility
			hasCompleted = playerData.completedTutorial or playerData.hasSeenInstructions
		end
	end

	-- Check player attributes as fallback
	if not hasCompleted then
		hasCompleted = player:GetAttribute("CompletedTutorial") == true or 
			player:GetAttribute("HasSeenInstructions") == true
	end

	return hasCompleted
end

function PlayerGuidanceSystem:MarkTutorialComplete(player)
	print("✅ Marking tutorial complete for: " .. player.Name)

	-- Save to GameCore if available
	if _G.GameCore and _G.GameCore.GetPlayerData then
		pcall(function()
			local playerData = _G.GameCore:GetPlayerData(player)
			if playerData then
				playerData.completedTutorial = true
				playerData.hasSeenInstructions = true -- For compatibility
				_G.GameCore:UpdatePlayerData(player, playerData)
			end
		end)
	end

	-- Save to player attributes as backup
	player:SetAttribute("CompletedTutorial", true)
	player:SetAttribute("HasSeenInstructions", true)

	-- Clean up guidance for this player
	self:CleanupPlayerGuidance(player.UserId)

	-- Send completion notification
	if _G.GameCore and _G.GameCore.SendNotification then
		_G.GameCore:SendNotification(player, "✅ Tutorial Complete!", 
			"You've learned the basics! Enjoy the game!", "success")
	end
end

function PlayerGuidanceSystem:DebugWorkspaceObjects()
	print("=== WORKSPACE OBJECT SCAN ===")

	local objectTypes = {}
	local cowObjects = {}
	local shopObjects = {}
	local gardenObjects = {}

	-- Scan all objects in workspace
	for _, obj in pairs(workspace:GetDescendants()) do
		local objType = obj.ClassName
		objectTypes[objType] = (objectTypes[objType] or 0) + 1

		-- Look for cow-related objects
		if obj.Name:lower():find("cow") then
			table.insert(cowObjects, obj.Name .. " (" .. obj.ClassName .. ") at " .. tostring(obj:IsA("BasePart") and obj.Position or "N/A"))
		end

		-- Look for shop-related objects
		if obj.Name:lower():find("shop") or obj.Name:lower():find("store") then
			table.insert(shopObjects, obj.Name .. " (" .. obj.ClassName .. ") at " .. tostring(obj:IsA("BasePart") and obj.Position or "N/A"))
		end

		-- Look for garden-related objects
		if obj.Name:lower():find("garden") or obj.Name:lower():find("soil") or obj.Name:lower():find("farm") then
			table.insert(gardenObjects, obj.Name .. " (" .. obj.ClassName .. ") at " .. tostring(obj:IsA("BasePart") and obj.Position or "N/A"))
		end
	end

	print("Object Types Found:")
	for objType, count in pairs(objectTypes) do
		if count > 0 then
			print("  " .. objType .. ": " .. count)
		end
	end

	print("\nCow Objects:")
	for _, obj in ipairs(cowObjects) do
		print("  " .. obj)
	end

	print("\nShop Objects:")
	for _, obj in ipairs(shopObjects) do
		print("  " .. obj)
	end

	print("\nGarden Objects:")
	for _, obj in ipairs(gardenObjects) do
		print("  " .. obj)
	end

	print("========================")
end

function PlayerGuidanceSystem:CreateManualWaypoints()
	print("🗺️ Creating manual waypoints as fallback...")

	self.Config.waypoints = {
		{
			name = "Starting Area",
			position = Vector3.new(0, 10, 0),
			message = "Welcome to the game! This is your starting area.",
			icon = "🎯"
		},
		{
			name = "Exploration Point",
			position = Vector3.new(50, 10, 50),
			message = "Explore this area to find game features!",
			icon = "🔍"
		},
		{
			name = "Activity Center",
			position = Vector3.new(-50, 10, -50),
			message = "Check this area for activities!",
			icon = "⭐"
		}
	}

	print("✅ Created " .. #self.Config.waypoints .. " manual waypoints")
	return self.Config.waypoints
end

function PlayerGuidanceSystem:ForceDetectWaypointsManually()
	print("🔍 Manually detecting waypoints with enhanced search...")

	local waypoints = {}

	-- Enhanced search patterns
	local searchPatterns = {
		cow = {"cow", "cattle", "milk", "dairy"},
		shop = {"shop", "store", "market", "vendor", "buy", "sell"},
		garden = {"garden", "soil", "farm", "plot", "plant", "grow"},
		spawn = {"spawn", "start", "beginning", "entry"}
	}

	for category, patterns in pairs(searchPatterns) do
		print("Searching for " .. category .. " objects...")

		for _, obj in pairs(workspace:GetDescendants()) do
			if obj:IsA("BasePart") then
				local objName = obj.Name:lower()

				for _, pattern in ipairs(patterns) do
					if objName:find(pattern) then
						table.insert(waypoints, {
							name = category:gsub("^%l", string.upper) .. " Area",
							position = obj.Position + Vector3.new(0, 10, 0),
							message = "Visit the " .. category .. " area to continue!",
							icon = category == "cow" and "🐄" or 
								category == "shop" and "🛒" or
								category == "garden" and "🌱" or "🎯"
						})
						print("✅ Found " .. category .. " at: " .. obj.Name .. " (" .. tostring(obj.Position) .. ")")
						break
					end
				end
			end
		end
	end

	-- Remove duplicates and limit to 3 waypoints
	local uniqueWaypoints = {}
	local seenCategories = {}

	for _, waypoint in ipairs(waypoints) do
		local category = waypoint.name:match("(%w+) Area")
		if not seenCategories[category] and #uniqueWaypoints < 3 then
			table.insert(uniqueWaypoints, waypoint)
			seenCategories[category] = true
		end
	end

	if #uniqueWaypoints > 0 then
		self.Config.waypoints = uniqueWaypoints
		print("🎯 Detected " .. #uniqueWaypoints .. " unique waypoints")
	else
		print("⚠️ No waypoints detected, using manual fallback")
		self:CreateManualWaypoints()
	end

	return self.Config.waypoints
end

-- Update the original DetectWaypoints method:
function PlayerGuidanceSystem:DetectWaypoints()
	print("🔍 Auto-detecting waypoint positions...")

	-- First try the original detection
	local waypoints = {}

	-- Try to find cow milking area
	local cowFound = false
	for _, obj in pairs(workspace:GetDescendants()) do
		if obj.Name:lower():find("cow") and obj:IsA("BasePart") then
			table.insert(waypoints, {
				name = "CowMilkingArea",
				position = obj.Position + Vector3.new(0, 5, 0),
				message = "Go to the cow milking area to start earning coins!",
				icon = "🐄"
			})
			print("✅ Found cow at: " .. tostring(obj.Position))
			cowFound = true
			break
		end
	end

	-- Try to find shop area
	local shopFound = false
	for _, obj in pairs(workspace:GetDescendants()) do
		if (obj.Name:lower():find("shop") or obj.Name:lower():find("store")) and obj:IsA("BasePart") then
			table.insert(waypoints, {
				name = "Shop",
				position = obj.Position + Vector3.new(0, 5, 0),
				message = "Go to the shop to buy seeds and sell items!",
				icon = "🛒"
			})
			print("✅ Found shop at: " .. tostring(obj.Position))
			shopFound = true
			break
		end
	end

	-- Try to find garden area
	local garden = workspace:FindFirstChild("Garden")
	if garden and garden:FindFirstChild("Soil") then
		table.insert(waypoints, {
			name = "Garden",
			position = garden.Soil.Position + Vector3.new(0, 5, 0),
			message = "Visit your garden to plant seeds and grow crops!",
			icon = "🌱"
		})
		print("✅ Found garden at: " .. tostring(garden.Soil.Position))
	end

	-- If original detection failed, try enhanced detection
	if #waypoints == 0 then
		print("⚠️ Basic detection failed, trying enhanced detection...")
		waypoints = self:ForceDetectWaypointsManually()
	end

	self.Config.waypoints = waypoints
	print("📍 Total waypoints configured: " .. #waypoints)
	return waypoints
end

-- Add global debug functions
_G.DebugGuidanceWorkspace = function()
	if _G.PlayerGuidanceSystem then
		_G.PlayerGuidanceSystem:DebugWorkspaceObjects()
	else
		print("❌ PlayerGuidanceSystem not available")
	end
end

_G.ForceDetectWaypoints = function()
	if _G.PlayerGuidanceSystem then
		_G.PlayerGuidanceSystem:ForceDetectWaypointsManually()
		_G.PlayerGuidanceSystem:PrintWaypoints()
	else
		print("❌ PlayerGuidanceSystem not available")
	end
end
-- ========== SIMPLIFIED DEBUG SYSTEM ==========

function PlayerGuidanceSystem:HandleDebugCommand(player, command, arg)
	print("📡 Debug command from " .. player.Name .. ": " .. command)

	if command == "DebugGuidance" then
		self:DebugActiveGuidance()

	elseif command == "ResetPlayerTutorial" then
		local targetPlayer = arg and Players:FindFirstChild(arg) or player
		if targetPlayer then
			self:ResetPlayerTutorial(targetPlayer)
		end

	elseif command == "ForceStartGuidance" then
		local targetPlayer = arg and Players:FindFirstChild(arg) or player
		if targetPlayer then
			self:ForceStartGuidance(targetPlayer)
		end

	elseif command == "PrintWaypoints" then
		self:PrintWaypoints()

	elseif command == "DetectWaypoints" then
		self:DetectWaypoints()

	else
		print("❌ Unknown debug command: " .. command)
	end
end

function PlayerGuidanceSystem:ResetPlayerTutorial(player)
	print("🔄 Resetting tutorial for: " .. player.Name)

	-- Clear completion flags
	if _G.GameCore and _G.GameCore.GetPlayerData then
		pcall(function()
			local playerData = _G.GameCore:GetPlayerData(player)
			if playerData then
				playerData.completedTutorial = false
				playerData.hasSeenInstructions = false
				_G.GameCore:UpdatePlayerData(player, playerData)
			end
		end)
	end

	player:SetAttribute("CompletedTutorial", false)
	player:SetAttribute("HasSeenInstructions", false)

	-- Start guidance if waypoints exist
	if #self.Config.waypoints > 0 then
		self:StartGuidanceForPlayer(player)
	end
end

function PlayerGuidanceSystem:ForceStartGuidance(player)
	print("🎯 Force starting guidance for: " .. player.Name)

	if #self.Config.waypoints == 0 then
		self:DetectWaypoints()
	end

	if #self.Config.waypoints > 0 then
		self:StartGuidanceForPlayer(player)
	else
		print("❌ No waypoints available for guidance")
	end
end

function PlayerGuidanceSystem:PrintWaypoints()
	print("=== GUIDANCE WAYPOINTS ===")
	for i, waypoint in ipairs(self.Config.waypoints) do
		print(i .. ". " .. waypoint.name .. " (" .. waypoint.icon .. ")")
		print("   Position: " .. tostring(waypoint.position))
		print("   Message: " .. waypoint.message)
	end
	print("==========================")
end

function PlayerGuidanceSystem:DebugActiveGuidance()
	print("=== GUIDANCE DEBUG STATUS ===")
	print("System initialized: " .. tostring(self.IsInitialized))
	print("Active guidance sessions: " .. self:CountTable(self.ActiveGuidance))
	print("Available waypoints: " .. #self.Config.waypoints)

	for userId, guidance in pairs(self.ActiveGuidance) do
		local player = guidance.player
		if player and player.Parent then
			print("Player: " .. player.Name)
			print("  Current waypoint: " .. guidance.waypoint.name)
			print("  Arrow segments: " .. #guidance.segments)
		end
	end
	print("=============================")
end

-- ========== GUIDANCE CORE FUNCTIONS ==========

function PlayerGuidanceSystem:StartGuidanceForPlayer(player)
	if #self.Config.waypoints == 0 then
		print("⚠️ No waypoints configured for guidance")
		return false
	end

	print("🎯 Starting guidance for: " .. player.Name)

	-- Clean up any existing guidance
	self:CleanupPlayerGuidance(player.UserId)

	-- Start with first waypoint
	self:CreatePlayerGuidanceArrow(player, self.Config.waypoints[1])
	return true
end

function PlayerGuidanceSystem:CreatePlayerGuidanceArrow(player, waypoint)
	if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then
		print("⚠️ Player character not ready for guidance: " .. player.Name)
		return
	end

	local userId = player.UserId
	local playerPos = player.Character.HumanoidRootPart.Position
	local waypointPos = waypoint.position

	-- Create simple guidance marker instead of complex arrows
	local marker = Instance.new("Part")
	marker.Name = "GuidanceMarker_" .. userId
	marker.Size = Vector3.new(4, 8, 4)
	marker.Position = waypointPos
	marker.Anchored = true
	marker.CanCollide = false
	marker.Material = Enum.Material.Neon
	marker.Color = self.Config.arrowHighlightColor
	marker.Shape = Enum.PartType.Cylinder
	marker:SetAttribute("PlayerGuidanceId", userId)

	-- Add billboard GUI
	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.new(0, 100, 0, 50)
	billboard.StudsOffset = Vector3.new(0, 5, 0)
	billboard.Parent = marker

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.Text = waypoint.icon .. " " .. waypoint.name
	label.TextScaled = true
	label.Font = Enum.Font.GothamBold
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextStrokeTransparency = 0
	label.Parent = billboard

	marker.Parent = workspace

	-- Store guidance data
	self.ActiveGuidance[userId] = {
		player = player,
		waypoint = waypoint,
		marker = marker,
		startTime = tick()
	}

	-- Show waypoint notification
	self:ShowWaypointNotification(player, waypoint)

	print("✅ Created guidance marker for " .. player.Name .. " -> " .. waypoint.name)
end

function PlayerGuidanceSystem:ShowWaypointNotification(player, waypoint)
	if _G.GameCore and _G.GameCore.SendNotification then
		_G.GameCore:SendNotification(player, waypoint.icon .. " " .. waypoint.name,
			waypoint.message, "info")
	end

	-- Fire client event
	if self.RemoteEvents.ShowWaypoint then
		self.RemoteEvents.ShowWaypoint:FireClient(player, {
			position = waypoint.position,
			name = waypoint.name,
			icon = waypoint.icon
		})
	end
end

function PlayerGuidanceSystem:CleanupPlayerGuidance(userId)
	-- Remove any existing markers
	for _, obj in pairs(workspace:GetChildren()) do
		if obj:GetAttribute("PlayerGuidanceId") == userId then
			obj:Destroy()
		end
	end

	-- Clear from active tracking
	self.ActiveGuidance[userId] = nil
end

-- ========== PROXIMITY CHECKING ==========

function PlayerGuidanceSystem:StartProximityChecking()
	spawn(function()
		while self.IsInitialized do
			wait(1)

			for userId, guidance in pairs(self.ActiveGuidance) do
				pcall(function()
					self:CheckPlayerProximity(guidance.player)
				end)
			end
		end
	end)
	print("✅ Proximity checking started")
end

function PlayerGuidanceSystem:CheckPlayerProximity(player)
	local userId = player.UserId
	local guidance = self.ActiveGuidance[userId]
	if not guidance then return end

	if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then
		return
	end

	local playerPos = player.Character.HumanoidRootPart.Position
	local waypointPos = guidance.waypoint.position
	local distance = (playerPos - waypointPos).Magnitude

	-- Check if player reached waypoint
	if distance <= self.Config.minArrowDistance then
		print("🎯 Player " .. player.Name .. " reached waypoint: " .. guidance.waypoint.name)

		-- Find current waypoint index
		local currentIndex = 1
		for i, wp in ipairs(self.Config.waypoints) do
			if wp.name == guidance.waypoint.name then
				currentIndex = i
				break
			end
		end

		-- Check if there's a next waypoint
		if currentIndex < #self.Config.waypoints then
			local nextWaypoint = self.Config.waypoints[currentIndex + 1]
			self:CreatePlayerGuidanceArrow(player, nextWaypoint)
		else
			-- Tutorial complete
			self:MarkTutorialComplete(player)
		end
	end
end

-- ========== PLAYER MANAGEMENT ==========

function PlayerGuidanceSystem:HandlePlayerJoin(player)
	print("👋 Player joined guidance system: " .. player.Name)

	player.CharacterAdded:Connect(function(character)
		wait(3) -- Give character time to load

		local hasCompleted = self:HasPlayerCompletedTutorial(player)

		if not hasCompleted then
			print("🆕 Starting guidance for new player: " .. player.Name)
			self:StartGuidanceForPlayer(player)
		else
			print("🔄 Returning player, skipping guidance: " .. player.Name)
		end
	end)
end

function PlayerGuidanceSystem:SetupPlayerHandlers()
	-- Handle existing players
	for _, player in ipairs(Players:GetPlayers()) do
		self:HandlePlayerJoin(player)
	end

	-- Handle new players
	Players.PlayerAdded:Connect(function(player)
		self:HandlePlayerJoin(player)
	end)

	-- Handle players leaving
	Players.PlayerRemoving:Connect(function(player)
		self:CleanupPlayerGuidance(player.UserId)
	end)

	print("✅ Player handlers setup complete")
end

-- ========== UTILITY FUNCTIONS ==========

function PlayerGuidanceSystem:CountTable(t)
	local count = 0
	for _ in pairs(t) do count = count + 1 end
	return count
end

-- ========== INITIALIZATION ==========

function PlayerGuidanceSystem:Initialize()
	print("🧭 Initializing FIXED Player Guidance System...")

	-- Setup remote events first
	local remoteSuccess = self:SetupRemoteEvents()
	if not remoteSuccess then
		warn("❌ Failed to setup remote events")
		return false
	end

	-- Auto-detect waypoints
	self:DetectWaypoints()

	-- Setup player handlers
	self:SetupPlayerHandlers()

	-- Start proximity checking
	self:StartProximityChecking()

	-- Mark as initialized
	self.IsInitialized = true

	-- Register globally
	_G.PlayerGuidanceSystem = self

	print("✅ FIXED Player Guidance System initialized!")
	print("📍 Waypoints: " .. #self.Config.waypoints)
	print("🔧 Debug Commands Available:")
	print("  _G.DebugGuidance() - Show guidance status")
	print("  _G.ResetTutorial('PlayerName') - Reset tutorial")
	print("  _G.StartGuidance('PlayerName') - Force start guidance")

	return true
end

-- ========== GLOBAL DEBUG FUNCTIONS ==========

_G.DebugGuidance = function()
	if _G.PlayerGuidanceSystem then
		_G.PlayerGuidanceSystem:DebugActiveGuidance()
	else
		print("❌ PlayerGuidanceSystem not available")
	end
end

_G.ResetTutorial = function(playerName)
	if not playerName then
		print("Usage: _G.ResetTutorial('PlayerName')")
		return
	end

	if _G.PlayerGuidanceSystem then
		local player = Players:FindFirstChild(playerName)
		if player then
			_G.PlayerGuidanceSystem:ResetPlayerTutorial(player)
		else
			print("Player not found: " .. playerName)
		end
	else
		print("❌ PlayerGuidanceSystem not available")
	end
end

_G.StartGuidance = function(playerName)
	if not playerName then
		print("Usage: _G.StartGuidance('PlayerName')")
		return
	end

	if _G.PlayerGuidanceSystem then
		local player = Players:FindFirstChild(playerName)
		if player then
			_G.PlayerGuidanceSystem:ForceStartGuidance(player)
		else
			print("Player not found: " .. playerName)
		end
	else
		print("❌ PlayerGuidanceSystem not available")
	end
end

return PlayerGuidanceSystem