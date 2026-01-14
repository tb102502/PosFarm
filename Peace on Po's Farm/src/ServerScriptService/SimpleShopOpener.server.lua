local SimpleShopOpener = {}
-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
-- Configuration
local SHOP_POSITION = Vector3.new(-327.288, -3.636, 31.402) -- Adjust this to your shop location
local SHOP_RANGE = 15 -- How close players need to be to open shop
local CLOSE_RANGE = 25 -- How far before auto-closing shop
local CHECK_INTERVAL = 1 -- Check every 1 second
-- State tracking
local playersInShop = {}
local shopTouchPart = nil
local remoteEvents = {}
local playersTouchingPart = {}  -- NEW: Track which players are touching the part
-- ========== REMOTE EVENT CONNECTIONS ==========
local function connectToRemoteEvents()
	print("🔗 SimpleShopOpener: Connecting to remote events...")
	-- Wait for GameRemotes folder
	local gameRemotes = ReplicatedStorage:WaitForChild("GameRemotes", 30)
	if not gameRemotes then
		warn("❌ SimpleShopOpener: GameRemotes folder not found!")
		return false
	end

	-- Get required remote events
	local openShopEvent = gameRemotes:WaitForChild("OpenShop", 10)
	local closeShopEvent = gameRemotes:WaitForChild("CloseShop", 10)

	if openShopEvent and closeShopEvent then
		remoteEvents.OpenShop = openShopEvent
		remoteEvents.CloseShop = closeShopEvent
		print("✅ SimpleShopOpener: Connected to shop remote events")
		return true
	else
		warn("❌ SimpleShopOpener: Required remote events not found!")
		return false
	end
end
-- ========== SHOP OPENING/CLOSING FUNCTIONS ==========
local function openShopForPlayer(player)
	if playersInShop[player.UserId] then
		return -- Already in shop
	end
	print("🛒 SimpleShopOpener: Opening shop for " .. player.Name)

	-- Mark player as in shop
	playersInShop[player.UserId] = {
		inShop = true,
		nearShop = true
	}

	-- Fire remote event to open shop on client
	if remoteEvents.OpenShop then
		remoteEvents.OpenShop:FireClient(player)
		print("📡 SimpleShopOpener: Sent OpenShop event to " .. player.Name)
	else
		warn("❌ SimpleShopOpener: OpenShop remote event not available!")
	end
end
local function closeShopForPlayer(player)
	if not playersInShop[player.UserId] then
		return -- Not in shop
	end
	print("🚪 SimpleShopOpener: Closing shop for " .. player.Name)

	-- Remove player from shop
	playersInShop[player.UserId] = nil

	-- Fire remote event to close shop on client
	if remoteEvents.CloseShop then
		remoteEvents.CloseShop:FireClient(player)
		print("📡 SimpleShopOpener: Sent CloseShop event to " .. player.Name)
	else
		warn("❌ SimpleShopOpener: CloseShop remote event not available!")
	end
end
local function CheckGrassBlocking(player, area)
	if _G.GrassBlockingSystem then
		return _G.GrassBlockingSystem:CheckAreaAccess(area, player, "ShopTouchPart")
	end
	return true -- If grass system not available, allow access
end
-- ========== SHOP TOUCH PART CREATION ==========
-- NEW: Run the proximity check on a regular interval

local function CheckPlayerProximity()
	if not shopTouchPart then return end
	for _, player in pairs(Players:GetPlayers()) do
		if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
			local distance = (player.Character.HumanoidRootPart.Position - SHOP_POSITION).Magnitude

			local playerData = playersInShop[player.UserId]
			local wasNearShop = playerData and playerData.nearShop
			local isNearShop = distance <= SHOP_RANGE

			-- If too far away, close shop
			if distance > CLOSE_RANGE and playerData and playerData.inShop then
				closeShopForPlayer(player)
				-- If just entered range and not already in shop
			elseif isNearShop and not wasNearShop then
				-- Check grass blocking before opening shop
				if CheckGrassBlocking(player, shopTouchPart) then
					openShopForPlayer(player)
				else
					-- Shop is blocked by grass, player already notified by GrassBlockingSystem
					playersInShop[player.UserId] = {
						nearShop = true,
						inShop = false
					}
				end
				-- If just left range but was in range before
			elseif not isNearShop and wasNearShop then
				closeShopForPlayer(player)
			end
		end
	end
end

local function startProximityChecking()
	local lastCheck = tick()
	RunService.Heartbeat:Connect(function()
		-- Only check every CHECK_INTERVAL seconds
		if tick() - lastCheck < CHECK_INTERVAL then
			return
		end
		lastCheck = tick()

		CheckPlayerProximity()
	end)

	print("🔄 SimpleShopOpener: Started proximity checking every " .. CHECK_INTERVAL .. " seconds")
end

local function createShopTouchPart()
	print("🏗️ SimpleShopOpener: Creating shop touch part...")
	-- Remove any existing shop parts
	for _, obj in pairs(workspace:GetChildren()) do
		if obj.Name:find("ShopTouchPart") then
			obj:Destroy()
		end
	end

	-- Create new touch part
	local touchPart = Instance.new("Part")
	touchPart.Name = "SimpleShopTouchPart"
	touchPart.Size = Vector3.new(20, 4, 20) -- Large touch area
	touchPart.Position = SHOP_POSITION
	touchPart.BrickColor = BrickColor.new("Bright green")
	touchPart.Material = Enum.Material.Neon
	touchPart.Anchored = true
	touchPart.CanCollide = false
	touchPart.Transparency = 0.3
	touchPart.Parent = workspace

	-- Add visual effects
	local selectionBox = Instance.new("SelectionBox")
	selectionBox.Adornee = touchPart
	selectionBox.Color3 = Color3.fromRGB(100, 255, 100)
	selectionBox.LineThickness = 0.2
	selectionBox.Transparency = 0.5
	selectionBox.Parent = touchPart

	-- Add floating text
	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.new(8, 0, 2, 0)
	billboard.StudsOffset = Vector3.new(0, 8, 0)
	billboard.Parent = touchPart

	local shopLabel = Instance.new("TextLabel")
	shopLabel.Size = UDim2.new(1, 0, 1, 0)
	shopLabel.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	shopLabel.BackgroundTransparency = 0.3
	shopLabel.Text = "🛒 SHOP\nStep here to browse!"
	shopLabel.TextColor3 = Color3.new(1, 1, 1)
	shopLabel.TextScaled = true
	shopLabel.Font = Enum.Font.GothamBold
	shopLabel.TextStrokeTransparency = 0
	shopLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
	shopLabel.Parent = billboard

	local labelCorner = Instance.new("UICorner")
	labelCorner.CornerRadius = UDim.new(0.2, 0)
	labelCorner.Parent = shopLabel

	-- Pulsing animation
	spawn(function()
		while touchPart and touchPart.Parent do
			local tween = TweenService:Create(touchPart,
				TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
				{Transparency = 0.1}
			)
			tween:Play()
			wait(4)
		end
	end)

	-- FIXED: Touch detection with proper player tracking
	touchPart.Touched:Connect(function(hit)
		local humanoid = hit.Parent:FindFirstChild("Humanoid")
		if humanoid then
			local player = Players:GetPlayerFromCharacter(hit.Parent)
			if player then
				-- Track that this player is touching the part
				playersTouchingPart[player.UserId] = true

				-- Check grass blocking before opening shop
				if CheckGrassBlocking(player, touchPart) then
					openShopForPlayer(player)
				end
			end
		end
	end)

	-- NEW: Add TouchEnded detection to know when players step off the part
	touchPart.TouchEnded:Connect(function(hit)
		local humanoid = hit.Parent:FindFirstChild("Humanoid")
		if humanoid then
			local player = Players:GetPlayerFromCharacter(hit.Parent)
			if player then
				-- Mark that player is no longer touching the part
				playersTouchingPart[player.UserId] = nil

				-- We don't close the shop here - that happens when they get far enough away
				-- This just tracks that they're no longer on the part
			end
		end
	end)

	shopTouchPart = touchPart
	print("✅ SimpleShopOpener: Shop touch part created at " .. tostring(SHOP_POSITION))
	return touchPart
end
-- ========== CHAT COMMANDS ==========
local function setupChatCommands()
	Players.PlayerAdded:Connect(function(player)
		player.Chatted:Connect(function(message)
			local command = message:lower()
			if command == "/shop" or command == "/store" then
				print("🛒 SimpleShopOpener: Manual shop open command from " .. player.Name)
				openShopForPlayer(player)

			elseif command == "/closeshop" then
				print("🚪 SimpleShopOpener: Manual shop close command from " .. player.Name)
				closeShopForPlayer(player)

			elseif command == "/shopinfo" then
				print("=== SHOP INFO FOR " .. player.Name .. " ===")
				print("Shop position: " .. tostring(SHOP_POSITION))
				print("Shop range: " .. SHOP_RANGE .. " studs")
				print("Close range: " .. CLOSE_RANGE .. " studs")
				print("Player in shop: " .. tostring(playersInShop[player.UserId] ~= nil))

				if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
					local distance = (player.Character.HumanoidRootPart.Position - SHOP_POSITION).Magnitude
					print("Distance to shop: " .. math.floor(distance) .. " studs")
				end

				print("Touch part exists: " .. tostring(shopTouchPart ~= nil))
				print("Remote events connected: " .. tostring(remoteEvents.OpenShop ~= nil))
				print("===============================")

			elseif command == "/testshopremote" then
				print("🧪 SimpleShopOpener: Testing shop remote for " .. player.Name)
				if remoteEvents.OpenShop then
					remoteEvents.OpenShop:FireClient(player)
					print("📡 Test OpenShop event sent")
				else
					print("❌ OpenShop remote not available")
				end
			end
		end)
	end)

	-- Connect for existing players
	for _, player in pairs(Players:GetPlayers()) do
		player.Chatted:Connect(function(message)
			local command = message:lower()

			if command == "/shop" or command == "/store" then
				openShopForPlayer(player)
			elseif command == "/closeshop" then
				closeShopForPlayer(player)
			elseif command == "/shopinfo" then
				print("=== SHOP INFO FOR " .. player.Name .. " ===")
				print("Shop position: " .. tostring(SHOP_POSITION))
				print("Shop range: " .. SHOP_RANGE .. " studs")
				print("Player in shop: " .. tostring(playersInShop[player.UserId] ~= nil))
				if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
					local distance = (player.Character.HumanoidRootPart.Position - SHOP_POSITION).Magnitude
					print("Distance to shop: " .. math.floor(distance) .. " studs")
				end
				print("Touch part exists: " .. tostring(shopTouchPart ~= nil))
				print("Remote events connected: " .. tostring(remoteEvents.OpenShop ~= nil))
				print("===============================")
			elseif command == "/testshopremote" then
				if remoteEvents.OpenShop then
					remoteEvents.OpenShop:FireClient(player)
					print("📡 Test OpenShop event sent to " .. player.Name)
				else
					print("❌ OpenShop remote not available")
				end
			end
		end)
	end
end
-- ========== PLAYER CLEANUP ==========
local function setupPlayerCleanup()
	Players.PlayerRemoving:Connect(function(player)
		playersInShop[player.UserId] = nil
		playersTouchingPart[player.UserId] = nil
		print("🧹 SimpleShopOpener: Cleaned up shop state for " .. player.Name)
	end)
end
-- ========== INITIALIZATION ==========
local function initialize()
	print("🚀 SimpleShopOpener: Starting FIXED initialization...")
	-- Wait a bit for the game to load
	wait(3) -- Increased wait time for GameCore to setup remotes

	-- Step 1: Connect to remote events first
	local remoteSuccess = connectToRemoteEvents()
	if not remoteSuccess then
		warn("❌ SimpleShopOpener: Failed to connect to remote events - retrying in 5 seconds...")
		wait(5)
		remoteSuccess = connectToRemoteEvents()
		if not remoteSuccess then
			error("❌ SimpleShopOpener: Cannot function without remote events!")
		end
	end

	-- Step 2: Setup other systems
	setupChatCommands()
	setupPlayerCleanup()
	createShopTouchPart()

	-- NEW: Start proximity checking as a continuous process
	startProximityChecking()

	-- Global reference
	_G.SimpleShopOpener = SimpleShopOpener

	print("✅ SimpleShopOpener: FIXED initialization complete!")
	print("🛒 Shop available at position: " .. tostring(SHOP_POSITION))
	print("📱 Chat commands: /shop, /closeshop, /shopinfo, /testshopremote")
	print("🎯 Walk to the green glowing area to open shop automatically!")
end
-- ========== DEBUG FUNCTIONS ==========
function SimpleShopOpener:DebugStatus()
	print("=== SIMPLE SHOP OPENER DEBUG ===")
	print("Remote events connected: " .. tostring(remoteEvents.OpenShop ~= nil))
	print("Touch part exists: " .. tostring(shopTouchPart ~= nil))
	print("Players in shop: " .. (function()
		local count = 0
		for _ in pairs(playersInShop) do count = count + 1 end
		return count
	end)())
	print("Players touching part: " .. (function()
		local count = 0
		for _ in pairs(playersTouchingPart) do count = count + 1 end
		return count
	end)())
	print("Shop position: " .. tostring(SHOP_POSITION))
	print("Shop range: " .. SHOP_RANGE .. " studs")
	print("Close range: " .. CLOSE_RANGE .. " studs")
	print("================================")
end
-- Global debug access
_G.DebugShopOpener = function()
	if _G.SimpleShopOpener then
		_G.SimpleShopOpener:DebugStatus()
	end
end
-- Start the system
initialize()
return SimpleShopOpener
