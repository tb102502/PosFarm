--[[
    FIXED GameInstructions.client.lua
    Place in: StarterPlayer/StarterPlayerScripts/GameInstructions.client.lua
    
    FIXES:
    ✅ Consistent tutorial completion tracking with guidance system
    ✅ Better integration with player data systems
    ✅ Simplified responsive design (more reliable)
    ✅ Clearer separation from guidance system
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

print("=== FIXED GAME INSTRUCTIONS SYSTEM LOADING ===")

-- ========== FIXED: CONSISTENT TUTORIAL TRACKING ==========

local hasSeenInstructions = false

-- Function to check if player has seen instructions (consistent with guidance system)
local function checkInstructionStatus()
	-- Check GameCore data first (consistent with guidance system)
	if _G.GameClient and _G.GameClient.GetPlayerData then
		local success, playerData = pcall(function()
			return _G.GameClient:GetPlayerData()
		end)

		if success and playerData then
			-- Check both field names for compatibility
			hasSeenInstructions = playerData.hasSeenInstructions or playerData.completedTutorial
			return hasSeenInstructions
		end
	end

	-- Fallback to player attributes
	hasSeenInstructions = player:GetAttribute("HasSeenInstructions") == true or 
		player:GetAttribute("CompletedTutorial") == true

	return hasSeenInstructions
end

-- Function to mark instructions as read (consistent with guidance system)
local function markInstructionsAsRead()
	print("📚 Marking instructions as read...")

	hasSeenInstructions = true

	-- Save to GameCore if available (consistent with guidance system)
	if _G.GameClient and _G.GameClient.GetPlayerData then
		pcall(function()
			local playerData = _G.GameClient:GetPlayerData() or {}
			playerData.hasSeenInstructions = true
			playerData.completedTutorial = true -- For consistency with guidance system

			-- Update player data
			if _G.GameCore and _G.GameCore.UpdatePlayerData then
				_G.GameCore:UpdatePlayerData(player, playerData)
			end
		end)
	end

	-- Save to player attributes as backup
	player:SetAttribute("HasSeenInstructions", true)
	player:SetAttribute("CompletedTutorial", true)

	print("✅ Instructions marked as read (compatible with guidance system)")
end

-- ========== SIMPLIFIED RESPONSIVE DESIGN ==========

local function getDeviceInfo()
	local camera = workspace.CurrentCamera
	local viewportSize = camera.ViewportSize
	local isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

	return {
		isMobile = isMobile,
		viewportSize = viewportSize,
		scaleFactor = isMobile and 1.1 or 1.0
	}
end

-- ========== INSTRUCTION CONTENT ==========

local INSTRUCTION_PAGES = {
	{
		title = "🌾 Welcome to Protect Po's Place!",
		icon = "🎮",
		content = {
			"Welcome to a nice calm farming simulator... Until the gnomes attack!",
			"",
			"🎯 YOUR GOAL:",
			"• Restore Po's Farm by milking cows, mowing grass, and planting crops",
			"• When night falls, gnomes try to destroy your progress",
			"• Prepare defenses and grow your farm during the day",
			"",
			"🚀 GETTING STARTED:",
			"• First, mow the overgrown grass around the farm",
			"• Milk the cow to earn your first coins", 
			"• Buy seeds from the shop and plant them in your garden",
			"• Harvest crops to earn more money",
			"",
			"🎮 CONTROLS:",
			"• Press F to open Farm menu",
			"• Press H to harvest all crops",
			"• Click on highlighted areas to interact",
			"• Follow any guidance arrows that appear",
			"",
			"Ready to become a farming legend? Let's make those pesky gnomes sorry they ever invaded!"
		}
	}
}

-- ========== SIMPLIFIED GUI CREATION ==========

local function createInstructionGUI()
	-- Remove existing GUI
	local existingGUI = playerGui:FindFirstChild("InstructionGUI")
	if existingGUI then
		existingGUI:Destroy()
	end

	local deviceInfo = getDeviceInfo()
	print("Creating instructions for device: " .. (deviceInfo.isMobile and "Mobile" or "Desktop"))

	-- Main ScreenGui
	local instructionGUI = Instance.new("ScreenGui")
	instructionGUI.Name = "InstructionGUI"
	instructionGUI.ResetOnSpawn = false
	instructionGUI.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	instructionGUI.IgnoreGuiInset = deviceInfo.isMobile
	instructionGUI.Parent = playerGui

	-- Background overlay
	local overlay = Instance.new("Frame")
	overlay.Name = "Overlay"
	overlay.Size = UDim2.new(1, 0, 1, 0)
	overlay.Position = UDim2.new(0, 0, 0, 0)
	overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	overlay.BackgroundTransparency = 0.3
	overlay.BorderSizePixel = 0
	overlay.Parent = instructionGUI

	-- Main frame - simplified sizing
	local mainFrame = Instance.new("Frame")
	mainFrame.Name = "MainFrame"
	mainFrame.Size = deviceInfo.isMobile and UDim2.new(0.95, 0, 0.9, 0) or UDim2.new(0.8, 0, 0.85, 0)
	mainFrame.Position = deviceInfo.isMobile and UDim2.new(0.025, 0, 0.05, 0) or UDim2.new(0.1, 0, 0.075, 0)
	mainFrame.BackgroundColor3 = Color3.fromRGB(20, 25, 30)
	mainFrame.BorderSizePixel = 0
	mainFrame.Parent = overlay

	-- Corner radius
	local mainCorner = Instance.new("UICorner")
	mainCorner.CornerRadius = UDim.new(0.02, 0)
	mainCorner.Parent = mainFrame

	-- Header frame
	local headerFrame = Instance.new("Frame")
	headerFrame.Name = "Header"
	headerFrame.Size = UDim2.new(1, 0, 0.12, 0)
	headerFrame.Position = UDim2.new(0, 0, 0, 0)
	headerFrame.BackgroundColor3 = Color3.fromRGB(40, 50, 60)
	headerFrame.BorderSizePixel = 0
	headerFrame.Parent = mainFrame

	local headerCorner = Instance.new("UICorner")
	headerCorner.CornerRadius = UDim.new(0.02, 0)
	headerCorner.Parent = headerFrame

	-- Title
	local titleLabel = Instance.new("TextLabel")
	titleLabel.Name = "Title"
	titleLabel.Size = UDim2.new(0.8, 0, 1, 0)
	titleLabel.Position = UDim2.new(0.05, 0, 0, 0)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Text = "📖 Farm Defense - Player Guide"
	titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	titleLabel.TextScaled = true
	titleLabel.Font = Enum.Font.GothamBold
	titleLabel.Parent = headerFrame

	-- Close button
	local closeButton = Instance.new("TextButton")
	closeButton.Name = "CloseButton"
	closeButton.Size = UDim2.new(0.12, 0, 0.7, 0)
	closeButton.Position = UDim2.new(0.86, 0, 0.15, 0)
	closeButton.BackgroundColor3 = Color3.fromRGB(220, 50, 50)
	closeButton.Text = "✕"
	closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	closeButton.TextScaled = true
	closeButton.Font = Enum.Font.GothamBold
	closeButton.BorderSizePixel = 0
	closeButton.Parent = headerFrame

	local closeCorner = Instance.new("UICorner")
	closeCorner.CornerRadius = UDim.new(0.2, 0)
	closeCorner.Parent = closeButton

	-- Content area
	local contentFrame = Instance.new("Frame")
	contentFrame.Name = "Content"
	contentFrame.Size = UDim2.new(1, 0, 0.76, 0)
	contentFrame.Position = UDim2.new(0, 0, 0.12, 0)
	contentFrame.BackgroundTransparency = 1
	contentFrame.Parent = mainFrame

	-- Scrolling content
	local scrollFrame = Instance.new("ScrollingFrame")
	scrollFrame.Name = "ContentScroll"
	scrollFrame.Size = UDim2.new(0.95, 0, 0.95, 0)
	scrollFrame.Position = UDim2.new(0.025, 0, 0.025, 0)
	scrollFrame.BackgroundColor3 = Color3.fromRGB(35, 40, 45)
	scrollFrame.BorderSizePixel = 0
	scrollFrame.ScrollBarThickness = deviceInfo.isMobile and 12 or 8
	scrollFrame.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 100)
	scrollFrame.Parent = contentFrame

	local scrollCorner = Instance.new("UICorner")
	scrollCorner.CornerRadius = UDim.new(0.03, 0)
	scrollCorner.Parent = scrollFrame

	-- Content text
	local contentLabel = Instance.new("TextLabel")
	contentLabel.Name = "ContentText"
	contentLabel.Size = UDim2.new(1, -20, 1, 0)
	contentLabel.Position = UDim2.new(0, 10, 0, 0)
	contentLabel.BackgroundTransparency = 1
	contentLabel.Text = ""
	contentLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
	contentLabel.TextScaled = true
	contentLabel.Font = Enum.Font.Gotham
	contentLabel.TextXAlignment = Enum.TextXAlignment.Left
	contentLabel.TextYAlignment = Enum.TextYAlignment.Top
	contentLabel.TextWrapped = true
	contentLabel.Parent = scrollFrame

	-- Bottom navigation
	local bottomFrame = Instance.new("Frame")
	bottomFrame.Name = "BottomNav"
	bottomFrame.Size = UDim2.new(1, 0, 0.12, 0)
	bottomFrame.Position = UDim2.new(0, 0, 0.88, 0)
	bottomFrame.BackgroundTransparency = 1
	bottomFrame.Parent = mainFrame

	-- Finish button
	local finishButton = Instance.new("TextButton")
	finishButton.Name = "FinishButton"
	finishButton.Size = UDim2.new(0.3, 0, 0.8, 0)
	finishButton.Position = UDim2.new(0.35, 0, 0.1, 0)
	finishButton.BackgroundColor3 = Color3.fromRGB(0, 180, 0)
	finishButton.Text = "Start Playing! ✓"
	finishButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	finishButton.TextScaled = true
	finishButton.Font = Enum.Font.GothamBold
	finishButton.BorderSizePixel = 0
	finishButton.Parent = bottomFrame

	local finishCorner = Instance.new("UICorner")
	finishCorner.CornerRadius = UDim.new(0.1, 0)
	finishCorner.Parent = finishButton

	-- ========== FUNCTIONALITY ==========

	-- Close function
	local function closeInstructions()
		markInstructionsAsRead()

		TweenService:Create(mainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
			Size = UDim2.new(0, 0, 0, 0),
			Position = UDim2.new(0.5, 0, 0.5, 0)
		}):Play()

		TweenService:Create(overlay, TweenInfo.new(0.3), {
			BackgroundTransparency = 1
		}):Play()

		wait(0.3)
		instructionGUI:Destroy()
	end

	-- Button connections
	closeButton.MouseButton1Click:Connect(closeInstructions)
	finishButton.MouseButton1Click:Connect(closeInstructions)

	-- ESC key support (desktop only)
	if not deviceInfo.isMobile then
		local escConnection
		escConnection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
			if gameProcessed then return end
			if input.KeyCode == Enum.KeyCode.Escape and instructionGUI.Parent then
				escConnection:Disconnect()
				closeInstructions()
			end
		end)
	end

	-- Load content
	local page = INSTRUCTION_PAGES[1]
	titleLabel.Text = page.title
	contentLabel.Text = table.concat(page.content, "\n")
	scrollFrame.CanvasSize = UDim2.new(0, 0, 2, 0)

	-- Animate entrance
	mainFrame.Size = UDim2.new(0, 0, 0, 0)
	mainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
	overlay.BackgroundTransparency = 1

	TweenService:Create(overlay, TweenInfo.new(0.3), {
		BackgroundTransparency = 0.3
	}):Play()

	TweenService:Create(mainFrame, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Size = deviceInfo.isMobile and UDim2.new(0.95, 0, 0.9, 0) or UDim2.new(0.8, 0, 0.85, 0),
		Position = deviceInfo.isMobile and UDim2.new(0.025, 0, 0.05, 0) or UDim2.new(0.1, 0, 0.075, 0)
	}):Play()

	return instructionGUI
end

-- ========== CHAT COMMANDS ==========

local function setupChatCommands()
	player.Chatted:Connect(function(message)
		local lowerMessage = message:lower()
		if lowerMessage == "/help" or lowerMessage == "/instructions" or lowerMessage == "/guide" then
			createInstructionGUI()
		elseif lowerMessage == "/resetinstructions" then
			-- Admin command to reset instructions
			player:SetAttribute("HasSeenInstructions", false)
			player:SetAttribute("CompletedTutorial", false)
			hasSeenInstructions = false
			print("🔄 Instructions reset - will show on next join")
		end
	end)
end

-- ========== AUTO-SHOW LOGIC ==========

local function autoShowInstructions()
	wait(3) -- Wait for game to load

	local shouldShow = not checkInstructionStatus()

	if shouldShow then
		print("📚 Showing instructions for new player")
		createInstructionGUI()
	else
		print("✅ Player has seen instructions before")

		-- Show reminder notification
		pcall(function()
			game.StarterGui:SetCore("SendNotification", {
				Title = "📖 Welcome Back!",
				Text = "Type /help for instructions",
				Duration = 5
			})
		end)
	end
end

-- ========== INTEGRATION WITH GUIDANCE SYSTEM ==========

-- Listen for remote events that might indicate instruction completion
spawn(function()
	wait(5) -- Give time for systems to load

	-- Check if guidance system is available
	if _G.PlayerGuidanceSystem then
		print("🔗 Instructions system detected guidance system")

		-- If guidance system marks tutorial complete, mark instructions as read too
		local checkTimer = 0
		spawn(function()
			while wait(5) do
				checkTimer = checkTimer + 5

				-- Check if guidance system marked tutorial complete
				if _G.PlayerGuidanceSystem and player:GetAttribute("CompletedTutorial") == true then
					if not hasSeenInstructions then
						print("🔗 Guidance system completed tutorial, marking instructions as read")
						markInstructionsAsRead()
					end
				end

				-- Stop checking after 5 minutes
				if checkTimer >= 300 then
					break
				end
			end
		end)
	end
end)

-- ========== INITIALIZE SYSTEM ==========

local function initializeInstructions()
	print("🚀 Initializing FIXED Game Instructions...")

	-- Setup chat commands
	setupChatCommands()

	-- Auto-show for new players
	autoShowInstructions()

	print("✅ FIXED Game Instructions ready!")
	print("📱 Features:")
	print("  ✅ Consistent tutorial tracking with guidance system")
	print("  ✅ Simplified responsive design")
	print("  ✅ Better integration with player data")
	print("  ✅ Cross-system compatibility")
	print("")
	print("💬 Commands:")
	print("  /help - Show instructions")
	print("  /instructions - Alternative command")
	print("  /guide - Another alternative")
	print("  /resetinstructions - Reset instruction status")
end

-- Start initialization
initializeInstructions()

print("=== FIXED GAME INSTRUCTIONS SYSTEM READY ===")