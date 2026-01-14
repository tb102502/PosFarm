--[[
    Area Highlight Grass Blocking System.lua
    Place in: ServerScriptService/Modules/GrassBlockingSystem.lua
    
    FEATURES:
    ✅ Uses existing grass in workspace
    ✅ Creates highlighted rectangular areas that need clearing
    ✅ Tracks grass clearing progress in each area
    ✅ Unlocks areas when all grass is cleared
    ✅ No grass spawning - works with what's already there
]]

local GrassBlockingSystem = {}

-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

-- Load GameConfig for timing


-- System configuration
GrassBlockingSystem.Config = {
	-- Visual settings for area highlights
	highlightColor = Color3.fromRGB(255, 100, 100),        -- Red highlight
	highlightTransparency = 0.7,                           -- Semi-transparent
	borderThickness = 0.5,                                 -- Border thickness
	animateHighlight = true,                               -- Pulse animation

	-- Progress settings
	showProgressBar = true,
	progressColor = Color3.fromRGB(100, 255, 100),

	-- Areas to block (you can customize these coordinates)
	blockedAreas = {
		{
			name = "ShopArea",
			areaType = "ShopTouchPart", 
			center = Vector3.new(-327.288, -3.636, 31.402),      -- Center of the area to clear
			size = Vector3.new(22.8, 1, 12.525),     -- Size of area to clear
			height = 5                          -- Height above ground for highlight
		},
		{
			name = "CowArea", 
			areaType = "CowMilkingChair",
			center = Vector3.new(-258.563, -5.254, 80.28),     -- Adjust coordinates for your map
			size = Vector3.new(18.325, 1.15, 45.45),
			height = 5
		},
		{
			name = "GardenArea",
			areaType = "GardenSpot", 
			center = Vector3.new(-373.103, -4.131, 90.506),    -- Adjust coordinates for your map
			size = Vector3.new(70.862, 0.686, 60.63),
			height = 5
		},
		{
			name = "WheatFieldArea",
			areaType = "WheatField",
			center = Vector3.new(-285.125, -3.904, 178.167),     -- Adjust coordinates for your map  
			size = Vector3.new(51.35, 1, 27.725),
			height = 5
		}
		-- Add more areas as needed
	}
}

-- Tracking data
GrassBlockingSystem.ActiveAreas = {}        -- areaData -> {highlight, grassInArea, clearedGrass, totalGrass}
GrassBlockingSystem.GrassToArea = {}        -- grass -> areaData mapping

-- ========== AREA MANAGEMENT ==========

function GrassBlockingSystem:CreateAreaHighlight(areaData)
	print("🔳 Creating highlight for " .. areaData.name)

	-- Create the main highlight part
	local highlight = Instance.new("Part")
	highlight.Name = "AreaHighlight_" .. areaData.name
	highlight.Size = areaData.size
	highlight.Position = areaData.center + Vector3.new(0, areaData.height, 0)
	highlight.Material = Enum.Material.ForceField
	highlight.Color = self.Config.highlightColor
	highlight.Transparency = self.Config.highlightTransparency
	highlight.Anchored = true
	highlight.CanCollide = false
	highlight.TopSurface = Enum.SurfaceType.Smooth
	highlight.BottomSurface = Enum.SurfaceType.Smooth

	-- Add a selection box for better visibility
	local selectionBox = Instance.new("SelectionBox")
	selectionBox.Adornee = highlight
	selectionBox.Color3 = self.Config.highlightColor
	selectionBox.LineThickness = self.Config.borderThickness
	selectionBox.Transparency = 0.3
	selectionBox.Parent = highlight

	-- Create pulsing animation if enabled
	if self.Config.animateHighlight then
		self:CreatePulseAnimation(highlight)
	end

	-- Create progress indicator
	local billboard = self:CreateProgressIndicator(areaData)
	billboard.Parent = highlight

	highlight.Parent = workspace

	print("✅ Created highlight for " .. areaData.name .. " at " .. tostring(areaData.center))
	return highlight
end

function GrassBlockingSystem:CreatePulseAnimation(highlight)
	spawn(function()
		local originalTransparency = highlight.Transparency

		while highlight.Parent do
			-- Pulse brighter
			local brightTween = TweenService:Create(highlight, 
				TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
				{Transparency = originalTransparency - 0.2}
			)
			brightTween:Play()
			brightTween.Completed:Wait()

			-- Pulse dimmer
			local dimTween = TweenService:Create(highlight, 
				TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
				{Transparency = originalTransparency + 0.1}
			)
			dimTween:Play()
			dimTween.Completed:Wait()
		end
	end)
end

function GrassBlockingSystem:CreateProgressIndicator(areaData)
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "ProgressIndicator"
	billboard.Size = UDim2.new(0, 200, 0, 80)
	billboard.StudsOffset = Vector3.new(0, areaData.size.Y/2 + 2, 0)
	billboard.AlwaysOnTop = true

	-- Main frame
	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(1, 0, 1, 0)
	frame.BackgroundColor3 = Color3.new(0, 0, 0)
	frame.BackgroundTransparency = 0.3
	frame.BorderSizePixel = 0
	frame.Parent = billboard

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.1, 0)
	corner.Parent = frame

	-- Title
	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(1, 0, 0.4, 0)
	title.Position = UDim2.new(0, 0, 0, 0)
	title.BackgroundTransparency = 1
	title.Text = "🚫 " .. areaData.name:gsub("Area", "") .. " BLOCKED"
	title.TextColor3 = self.Config.highlightColor
	title.TextScaled = true
	title.Font = Enum.Font.GothamBold
	title.Parent = frame

	-- Status
	local status = Instance.new("TextLabel")
	status.Name = "Status"
	status.Size = UDim2.new(1, 0, 0.3, 0)
	status.Position = UDim2.new(0, 0, 0.4, 0)
	status.BackgroundTransparency = 1
	status.Text = "Clear all grass in this area"
	status.TextColor3 = Color3.new(1, 1, 1)
	status.TextScaled = true
	status.Font = Enum.Font.Gotham
	status.Parent = frame

	-- Progress bar
	if self.Config.showProgressBar then
		local progressBg = Instance.new("Frame")
		progressBg.Name = "ProgressBg"
		progressBg.Size = UDim2.new(0.9, 0, 0.2, 0)
		progressBg.Position = UDim2.new(0.05, 0, 0.75, 0)
		progressBg.BackgroundColor3 = Color3.new(0.2, 0.2, 0.2)
		progressBg.BorderSizePixel = 0
		progressBg.Parent = frame

		local progressCorner = Instance.new("UICorner")
		progressCorner.CornerRadius = UDim.new(0.5, 0)
		progressCorner.Parent = progressBg

		local progressFill = Instance.new("Frame")
		progressFill.Name = "ProgressFill"
		progressFill.Size = UDim2.new(0, 0, 1, 0)
		progressFill.Position = UDim2.new(0, 0, 0, 0)
		progressFill.BackgroundColor3 = self.Config.progressColor
		progressFill.BorderSizePixel = 0
		progressFill.Parent = progressBg

		local fillCorner = Instance.new("UICorner")
		fillCorner.CornerRadius = UDim.new(0.5, 0)
		fillCorner.Parent = progressFill
	end

	return billboard
end

-- ========== GRASS DETECTION ==========

function GrassBlockingSystem:FindGrassInArea(areaData)
	print("🔍 Finding grass in " .. areaData.name)

	local grassInArea = {}
	local areaMin = areaData.center - (areaData.size / 2)
	local areaMax = areaData.center + (areaData.size / 2)

	-- Search all grass in workspace
	for _, obj in pairs(workspace:GetDescendants()) do
		if obj.Name == "Grass" and obj:IsA("BasePart") then
			local pos = obj.Position

			-- Check if grass is within the area bounds
			if pos.X >= areaMin.X and pos.X <= areaMax.X and
				pos.Z >= areaMin.Z and pos.Z <= areaMax.Z then

				-- Check if grass is tall (not already cut)
				if not obj:GetAttribute("IsMowed") and obj.Size.Y >= 2 then
					table.insert(grassInArea, obj)

					-- Track which area this grass belongs to
					self.GrassToArea[obj] = areaData

					print("  Found grass at " .. tostring(pos))
				end
			end
		end
	end

	print("📊 Found " .. #grassInArea .. " grass in " .. areaData.name)
	return grassInArea
end

function GrassBlockingSystem:ActivateArea(areaData)
	print("🚫 Activating blocked area: " .. areaData.name)

	-- Find all grass in this area
	local grassInArea = self:FindGrassInArea(areaData)

	if #grassInArea == 0 then
		print("⚠️ No grass found in " .. areaData.name .. " - area won't be blocked")
		return false
	end

	-- Create highlight
	local highlight = self:CreateAreaHighlight(areaData)

	-- Store area data
	self.ActiveAreas[areaData] = {
		highlight = highlight,
		grassInArea = grassInArea,
		totalGrass = #grassInArea,
		clearedGrass = 0,
		areaData = areaData
	}

	-- Update progress display
	self:UpdateAreaProgress(areaData)

	print("✅ Area " .. areaData.name .. " activated with " .. #grassInArea .. " grass")
	return true
end

-- ========== PROGRESS TRACKING ==========

function GrassBlockingSystem:UpdateAreaProgress(areaData)
	local areaInfo = self.ActiveAreas[areaData]
	if not areaInfo then return end

	local progress = areaInfo.clearedGrass / areaInfo.totalGrass
	local remaining = areaInfo.totalGrass - areaInfo.clearedGrass

	-- Update billboard
	local billboard = areaInfo.highlight:FindFirstChild("ProgressIndicator")
	if billboard then
		local status = billboard:FindFirstChild("Status", true)
		if status then
			status.Text = "Clear grass: " .. areaInfo.clearedGrass .. "/" .. areaInfo.totalGrass .. " (" .. remaining .. " left)"

			-- Change color based on progress
			if progress >= 0.75 then
				status.TextColor3 = Color3.fromRGB(100, 255, 100)
			elseif progress >= 0.5 then
				status.TextColor3 = Color3.fromRGB(255, 255, 100)
			end
		end

		-- Update progress bar
		local progressFill = billboard:FindFirstChild("ProgressFill", true)
		if progressFill then
			local tween = TweenService:Create(progressFill,
				TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{Size = UDim2.new(progress, 0, 1, 0)}
			)
			tween:Play()
		end
	end

	--print("📊 " .. areaData.name .. " progress: " .. areaInfo.clearedGrass .. "/" .. areaInfo.totalGrass .. " (" .. math.floor(progress * 100) .. "%)")
end

function GrassBlockingSystem:OnGrassMowed(player, grassPart)
	-- Check if this grass is in a blocked area
	local areaData = self.GrassToArea[grassPart]
	if not areaData then return end

	local areaInfo = self.ActiveAreas[areaData]
	if not areaInfo then return end

	-- Mark this grass as cleared
	areaInfo.clearedGrass = areaInfo.clearedGrass + 1

	-- Remove from tracking
	self.GrassToArea[grassPart] = nil

	-- Remove from grass list
	for i, grass in ipairs(areaInfo.grassInArea) do
		if grass == grassPart then
			table.remove(areaInfo.grassInArea, i)
			break
		end
	end

	print("🌿 " .. player.Name .. " cleared grass in " .. areaData.name .. " (" .. areaInfo.clearedGrass .. "/" .. areaInfo.totalGrass .. ")")

	-- Update progress
	self:UpdateAreaProgress(areaData)

	-- Check if area is fully cleared
	if areaInfo.clearedGrass >= areaInfo.totalGrass then
		self:UnlockArea(areaData, player)
	else
		-- Notify progress
		
		
	end
end

function GrassBlockingSystem:UnlockArea(areaData, player)
	print("🎉 " .. player.Name .. " unlocked " .. areaData.name .. "!")

	local areaInfo = self.ActiveAreas[areaData]
	if not areaInfo then return end

	-- Success animation on highlight
	local highlight = areaInfo.highlight
	if highlight then
		-- Change to success color
		highlight.Color = self.Config.progressColor

		-- Update billboard
		local billboard = highlight:FindFirstChild("ProgressIndicator")
		if billboard then
			local title = billboard:FindFirstChild("Title", true)
			if title then
				title.Text = "✅ " .. areaData.name:gsub("Area", "") .. " UNLOCKED!"
				title.TextColor3 = self.Config.progressColor
			end

			local status = billboard:FindFirstChild("Status", true)
			if status then
				status.Text = "Access granted!"
			end
		end

		-- Remove highlight after animation
		spawn(function()
			wait(3)
			if highlight.Parent then
				local fadeTween = TweenService:Create(highlight,
					TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
					{Transparency = 1}
				)
				fadeTween:Play()
				fadeTween.Completed:Wait()
				highlight:Destroy()
			end
		end)
	end

	-- Remove from active areas
	self.ActiveAreas[areaData] = nil

	-- Notify all players
	self:NotifyAreaUnlocked(areaData, player)

	-- Create success effect
	self:CreateUnlockEffect(areaData.center)
end

function GrassBlockingSystem:CreateUnlockEffect(position)
	-- Create sparkle effect
	local effect = Instance.new("Part")
	effect.Name = "UnlockEffect"
	effect.Size = Vector3.new(1, 1, 1)
	effect.Position = position + Vector3.new(0, 5, 0)
	effect.Material = Enum.Material.Neon
	effect.Color = self.Config.progressColor
	effect.Anchored = true
	effect.CanCollide = false
	effect.Shape = Enum.PartType.Ball
	effect.Parent = workspace

	-- Expand and fade effect
	local expandTween = TweenService:Create(effect,
		TweenInfo.new(2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{
			Size = Vector3.new(10, 10, 10),
			Transparency = 1
		}
	)
	expandTween:Play()

	-- Clean up
	expandTween.Completed:Connect(function()
		effect:Destroy()
	end)
end

-- ========== ACCESS CHECKING ==========

function GrassBlockingSystem:IsAreaBlocked(areaType)
	-- Check if any area of this type is still active
	for areaData, areaInfo in pairs(self.ActiveAreas) do
		if areaData.areaType == areaType then
			return true
		end
	end
	return false
end

function GrassBlockingSystem:CheckAreaAccess(area, player, areaType)
	if self:IsAreaBlocked(areaType) then
		local message = "🚫 Clear the highlighted grass areas to unlock " .. areaType .. "!"


		return false
	end

	return true
end

-- ========== INITIALIZATION ==========

function GrassBlockingSystem:Initialize()
	print("🔳 Area Highlight Grass Blocking System: Initializing...")

	-- Connect to grass mowing events
	self:ConnectToGrassEvents()

	-- Activate initial blocked areas
	spawn(function()
		wait(3) -- Wait for workspace to load
		self:ActivateInitialAreas()
	end)

	print("🔳 Area Highlight Grass Blocking System: ✅ Ready!")
	print("  Features:")
	print("  ✅ Uses existing workspace grass")
	print("  ✅ Highlighted rectangular areas")
	print("  ✅ Progress tracking")
	print("  ✅ Area unlocking when cleared")

	return true
end

function GrassBlockingSystem:ConnectToGrassEvents()
	local remotes = ReplicatedStorage:WaitForChild("GameRemotes")
	local grassMowed = remotes:WaitForChild("GrassMowed")

	grassMowed.Event:Connect(function(player, grassPart)
		-- Handle any grass mowing (both regular and area grass)
		self:OnGrassMowed(player, grassPart)
	end)

	print("🔗 Connected to grass mowing events")
end

function GrassBlockingSystem:ActivateInitialAreas()
	print("🚫 Activating initial blocked areas...")

	local activatedCount = 0

	for _, areaData in ipairs(self.Config.blockedAreas) do
		local success = self:ActivateArea(areaData)
		if success then
			activatedCount = activatedCount + 1
		end
	end

	print("🚫 Activated " .. activatedCount .. "/" .. #self.Config.blockedAreas .. " areas")

	-- Notify players
	if activatedCount > 0 then
		spawn(function()
			wait(5)
			for _, player in ipairs(Players:GetPlayers()) do
				if _G.GameCore and _G.GameCore.SendNotification then
					_G.GameCore:SendNotification(player, "🚫 Areas Blocked", 
						activatedCount .. " areas need grass clearing! Look for red highlighted zones.", "warning")
				end
			end
		end)
	end
end

-- ========== CONFIGURATION HELPERS ==========

function GrassBlockingSystem:SetAreaCoordinates(areaName, center, size)
	for _, areaData in ipairs(self.Config.blockedAreas) do
		if areaData.name == areaName then
			areaData.center = center
			areaData.size = size
			print("📍 Updated " .. areaName .. " coordinates")
			return true
		end
	end
	print("❌ Area " .. areaName .. " not found")
	return false
end

function GrassBlockingSystem:AddCustomArea(name, areaType, center, size, height)
	local newArea = {
		name = name,
		areaType = areaType,
		center = center,
		size = size,
		height = height or 5
	}

	table.insert(self.Config.blockedAreas, newArea)
	print("➕ Added custom area: " .. name)
	return newArea
end

-- ========== NOTIFICATIONS ==========

function GrassBlockingSystem:NotifyAreaUnlocked(areaData, clearedByPlayer)
	local areaName = areaData.name:gsub("Area", "")

	for _, player in ipairs(Players:GetPlayers()) do
		if _G.GameCore and _G.GameCore.SendNotification then
			if player == clearedByPlayer then
				_G.GameCore:SendNotification(player, "✅ Area Unlocked!", 
					"You cleared the " .. areaName .. "! It's now accessible.", "success")
			else
				_G.GameCore:SendNotification(player, "🌿 Area Available", 
					clearedByPlayer.Name .. " cleared the " .. areaName .. "!", "info")
			end
		end
	end
end

-- ========== DEBUG FUNCTIONS ==========

function GrassBlockingSystem:DebugActiveAreas()
	print("=== AREA HIGHLIGHT GRASS BLOCKING DEBUG ===")
	print("Active areas: " .. self:CountTable(self.ActiveAreas))

	for areaData, areaInfo in pairs(self.ActiveAreas) do
		print("🔳 " .. areaData.name .. ":")
		print("  Progress: " .. areaInfo.clearedGrass .. "/" .. areaInfo.totalGrass)
		print("  Remaining: " .. (areaInfo.totalGrass - areaInfo.clearedGrass))
		print("  Center: " .. tostring(areaData.center))
		print("  Size: " .. tostring(areaData.size))
	end

	print("Grass tracked: " .. self:CountTable(self.GrassToArea))
	print("==========================================")
end

function GrassBlockingSystem:CountTable(t)
	local count = 0
	for _ in pairs(t) do count = count + 1 end
	return count
end

function GrassBlockingSystem:TestAreaSetup()
	print("🧪 Testing area setup...")

	for i, areaData in ipairs(self.Config.blockedAreas) do
		print("Area " .. i .. ": " .. areaData.name)
		print("  Center: " .. tostring(areaData.center))
		print("  Size: " .. tostring(areaData.size))

		local grassFound = #self:FindGrassInArea(areaData)
		print("  Grass found: " .. grassFound)
		print("  Status: " .. (grassFound > 0 and "✅ Ready" or "❌ No grass"))
	end
end

-- ========== GLOBAL ACCESS ==========

_G.GrassBlockingSystem = GrassBlockingSystem

-- Global helper functions
_G.SetAreaCoords = function(areaName, x, y, z, sizeX, sizeY, sizeZ)
	local center = Vector3.new(x, y, z)
	local size = Vector3.new(sizeX, sizeY, sizeZ)
	GrassBlockingSystem:SetAreaCoordinates(areaName, center, size)
end

_G.TestGrassAreas = function() 
	GrassBlockingSystem:TestAreaSetup() 
end

_G.DebugGrassAreas = function() 
	GrassBlockingSystem:DebugActiveAreas() 
end

_G.AddGrassArea = function(name, areaType, x, y, z, sizeX, sizeY, sizeZ)
	local center = Vector3.new(x, y, z)
	local size = Vector3.new(sizeX, sizeY, sizeZ)
	return GrassBlockingSystem:AddCustomArea(name, areaType, center, size)
end

print("✅ Area Highlight Grass Blocking System loaded!")
print("🎯 Key features:")
print("  ✅ Works with existing workspace grass")
print("  ✅ Rectangular area highlights")
print("  ✅ Real-time progress tracking")
print("  ✅ Unlocks when areas are cleared")
print("")
print("🔧 Setup Commands:")
print("  _G.TestGrassAreas() - Test area setup")
print("  _G.SetAreaCoords('ShopArea', x, y, z, sizeX, sizeY, sizeZ) - Set coordinates")
print("  _G.AddGrassArea('NewArea', 'ShopTouchPart', x, y, z, sizeX, sizeY, sizeZ) - Add area")
print("  _G.DebugGrassAreas() - Show debug info")

return GrassBlockingSystem