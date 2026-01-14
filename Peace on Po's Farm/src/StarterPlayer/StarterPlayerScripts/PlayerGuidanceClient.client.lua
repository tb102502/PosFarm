local PlayerGuidanceClient = {}
-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
-- Local player
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
-- State tracking
PlayerGuidanceClient.State = {
	currentWaypoint = nil,
	waypointMarker = nil,
	waypointGui = nil,
	isVisible = false
}
-- Configuration
PlayerGuidanceClient.Config = {
	waypointMarkerSize = 4,           -- Size of 3D waypoint marker
	waypointMarkerColor = Color3.fromRGB(100, 255, 100),
	waypointPulseSpeed = 1,           -- Speed of pulse animation
	waypointPulseIntensity = 0.3,     -- Intensity of pulse effect
	waypointHeight = 5,               -- Height above ground
	waypointDistanceThreshold = 150,  -- Maximum distance to show waypoint
	waypointCheckInterval = 0.5       -- How often to check visibility
}
-- ========== INITIALIZATION ==========
function PlayerGuidanceClient:Initialize()
	print("PlayerGuidanceClient: Initializing...")
	-- Setup remote connections
	self:SetupRemoteConnections()

	-- Start visibility checking
	self:StartVisibilityChecking()

	print("PlayerGuidanceClient: Initialized!")
end
function PlayerGuidanceClient:SetupRemoteConnections()
	local remoteFolder = ReplicatedStorage:WaitForChild("GameRemotes", 10)
	if not remoteFolder then
		warn("PlayerGuidanceClient: GameRemotes folder not found!")
		return
	end
	-- Show waypoint marker
	local showWaypoint = remoteFolder:WaitForChild("ShowWaypoint", 5)
	if showWaypoint then
		showWaypoint.OnClientEvent:Connect(function(waypointData)
			self:ShowWaypoint(waypointData)
		end)
	end

	-- Hide waypoint marker
	local hideWaypoint = remoteFolder:WaitForChild("HideWaypoint", 5)
	if hideWaypoint then
		hideWaypoint.OnClientEvent:Connect(function()
			self:HideWaypoint()
		end)
	end

	print("PlayerGuidanceClient: Remote connections established")
end
-- ========== WAYPOINT FUNCTIONS ==========
function PlayerGuidanceClient:ShowWaypoint(waypointData)
	-- Clean up existing waypoint
	self:HideWaypoint()
	-- Store waypoint data
	self.State.currentWaypoint = waypointData

	-- Create 3D marker
	self:CreateWaypointMarker(waypointData)

	-- Create screen GUI indicator
	self:CreateWaypointGui(waypointData)

	self.State.isVisible = true
	print("PlayerGuidanceClient: Showing waypoint - " .. waypointData.name)
end
function PlayerGuidanceClient:HideWaypoint()
	-- Clean up 3D marker
	if self.State.waypointMarker then
		self.State.waypointMarker:Destroy()
		self.State.waypointMarker = nil
	end
	-- Clean up GUI
	if self.State.waypointGui then
		self.State.waypointGui:Destroy()
		self.State.waypointGui = nil
	end

	self.State.currentWaypoint = nil
	self.State.isVisible = false
	print("PlayerGuidanceClient: Waypoint hidden")
end
function PlayerGuidanceClient:CreateWaypointMarker(waypointData)
	-- Create marker container
	local marker = Instance.new("Part")
	marker.Name = "WaypointMarker_" .. waypointData.name
	marker.Size = Vector3.new(
		self.Config.waypointMarkerSize,
		self.Config.waypointMarkerSize,
		self.Config.waypointMarkerSize
	)
	marker.Position = waypointData.position + Vector3.new(0, self.Config.waypointHeight, 0)
	marker.Anchored = true
	marker.CanCollide = false
	marker.CastShadow = false
	marker.Material = Enum.Material.Neon
	marker.Color = self.Config.waypointMarkerColor
	marker.Transparency = 0.3
	marker.Shape = Enum.PartType.Ball
	-- Create billboard for icon
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "WaypointIcon"
	billboard.Size = UDim2.new(0, 50, 0, 50)
	billboard.StudsOffset = Vector3.new(0, 2, 0)
	billboard.AlwaysOnTop = true
	billboard.Parent = marker

	-- Create icon
	local icon = Instance.new("TextLabel")
	icon.Name = "Icon"
	icon.Size = UDim2.new(1, 0, 1, 0)
	icon.BackgroundTransparency = 1
	icon.Text = waypointData.icon or "🎯"
	icon.TextScaled = true
	icon.Font = Enum.Font.GothamBold
	icon.TextColor3 = Color3.new(1, 1, 1)
	icon.TextStrokeTransparency = 0
	icon.TextStrokeColor3 = Color3.new(0, 0, 0)
	icon.Parent = billboard

	-- Create name label
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "Name"
	nameLabel.Size = UDim2.new(0, 150, 0, 25)
	nameLabel.Position = UDim2.new(0.5, -75, 1, 5)
	nameLabel.BackgroundTransparency = 0.5
	nameLabel.BackgroundColor3 = Color3.new(0, 0, 0)
	nameLabel.Text = waypointData.name
	nameLabel.TextScaled = true
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextColor3 = Color3.new(1, 1, 1)
	nameLabel.Parent = billboard

	local nameCorner = Instance.new("UICorner")
	nameCorner.CornerRadius = UDim.new(0.3, 0)
	nameCorner.Parent = nameLabel

	-- Start pulse animation
	self:AnimateWaypointMarker(marker)

	marker.Parent = workspace
	self.State.waypointMarker = marker
end
function PlayerGuidanceClient:AnimateWaypointMarker(marker)
	-- Pulse size animation
	spawn(function()
		local initialSize = marker.Size
		while marker and marker.Parent do
			local pulseTween = TweenService:Create(marker,
				TweenInfo.new(
					self.Config.waypointPulseSpeed,
					Enum.EasingStyle.Sine,
					Enum.EasingDirection.InOut
				),
				{
					Size = initialSize * (1 + self.Config.waypointPulseIntensity),
					Transparency = 0.5
				}
			)
			pulseTween:Play()
			pulseTween.Completed:Wait()

			if not marker or not marker.Parent then break end

			local pulseTweenBack = TweenService:Create(marker,
				TweenInfo.new(
					self.Config.waypointPulseSpeed,
					Enum.EasingStyle.Sine,
					Enum.EasingDirection.InOut
				),
				{
					Size = initialSize,
					Transparency = 0.3
				}
			)
			pulseTweenBack:Play()
			pulseTweenBack.Completed:Wait()
		end
	end)

	-- Slow rotation animation
	spawn(function()
		local rotationOffset = 0

		while marker and marker.Parent do
			rotationOffset = rotationOffset + 0.01

			marker.CFrame = CFrame.new(marker.Position) * 
				CFrame.fromEulerAnglesXYZ(0, rotationOffset, 0)

			RunService.Heartbeat:Wait()
		end
	end)
end
function PlayerGuidanceClient:CreateWaypointGui(waypointData)
	-- Create screen GUI for offscreen indicator
	local gui = Instance.new("ScreenGui")
	gui.Name = "WaypointIndicator"
	gui.ResetOnSpawn = false
	gui.Parent = PlayerGui
	-- Create container
	local container = Instance.new("Frame")
	container.Name = "Container"
	container.Size = UDim2.new(0, 100, 0, 100)
	container.Position = UDim2.new(0.5, -50, 0.5, -50)
	container.BackgroundTransparency = 1
	container.Parent = gui

	-- Create arrow indicator
	local arrow = Instance.new("ImageLabel")
	arrow.Name = "DirectionArrow"
	arrow.Size = UDim2.new(0, 50, 0, 50)
	arrow.Position = UDim2.new(0.5, -25, 0.5, -25)
	arrow.BackgroundTransparency = 1
	arrow.Image = "rbxassetid://6034328955" -- Arrow image
	arrow.ImageColor3 = self.Config.waypointMarkerColor
	arrow.Parent = container

	-- Create distance label
	local distanceLabel = Instance.new("TextLabel")
	distanceLabel.Name = "Distance"
	distanceLabel.Size = UDim2.new(0, 100, 0, 20)
	distanceLabel.Position = UDim2.new(0.5, -50, 1, 0)
	distanceLabel.BackgroundTransparency = 0.5
	distanceLabel.BackgroundColor3 = Color3.new(0, 0, 0)
	distanceLabel.Text = "? m"
	distanceLabel.TextScaled = true
	distanceLabel.Font = Enum.Font.GothamBold
	distanceLabel.TextColor3 = Color3.new(1, 1, 1)
	distanceLabel.Visible = false
	distanceLabel.Parent = container

	local distanceCorner = Instance.new("UICorner")
	distanceCorner.CornerRadius = UDim.new(0.3, 0)
	distanceCorner.Parent = distanceLabel

	self.State.waypointGui = gui

	-- Start updating GUI position
	self:StartGuiPositionUpdates()
end
-- ========== VISIBILITY CHECKING ==========
function PlayerGuidanceClient:StartVisibilityChecking()
	spawn(function()
		while wait(self.Config.waypointCheckInterval) do
			if self.State.isVisible and self.State.currentWaypoint then
				self:UpdateWaypointVisibility()
			end
		end
	end)
	print("PlayerGuidanceClient: Visibility checking started")
end
function PlayerGuidanceClient:UpdateWaypointVisibility()
	-- Only check if we have both character and waypoint
	if not LocalPlayer.Character or not self.State.currentWaypoint then
		return
	end
	local rootPart = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
	if not rootPart then return end

	local waypoint = self.State.currentWaypoint
	local distance = (rootPart.Position - waypoint.position).Magnitude

	-- Update marker visibility based on distance
	local marker = self.State.waypointMarker
	if marker then
		marker.Parent = distance <= self.Config.waypointDistanceThreshold and workspace or nil
	end

	-- Update distance text if available
	if self.State.waypointGui then
		local distanceLabel = self.State.waypointGui:FindFirstChild("Container", true) and
			self.State.waypointGui.Container:FindFirstChild("Distance", true)

		if distanceLabel then
			distanceLabel.Text = math.floor(distance) .. " m"
		end
	end
end
function PlayerGuidanceClient:StartGuiPositionUpdates()
	-- Update GUI indicator to point toward waypoint when offscreen
	spawn(function()
		local camera = workspace.CurrentCamera
		while self.State.waypointGui and self.State.waypointGui.Parent do
			RunService.RenderStepped:Wait()

			if not self.State.currentWaypoint then break end

			local waypointPos = self.State.currentWaypoint.position
			local viewportSize = camera.ViewportSize
			local container = self.State.waypointGui:FindFirstChild("Container")
			local arrow = container and container:FindFirstChild("DirectionArrow")
			local distanceLabel = container and container:FindFirstChild("Distance")

			if container and arrow then
				-- Convert 3D position to 2D screen position
				local screenPos, isOnScreen = camera:WorldToScreenPoint(waypointPos)

				if isOnScreen and screenPos.Z > 0 then
					-- Waypoint is visible on screen - center arrow at waypoint position
					container.Position = UDim2.new(0, screenPos.X - container.AbsoluteSize.X/2, 
						0, screenPos.Y - container.AbsoluteSize.Y/2)

					-- Make arrow transparent when on screen
					arrow.ImageTransparency = 0.7
					if distanceLabel then
						distanceLabel.Visible = false
					end
				else
					-- Waypoint is off screen - position arrow at edge of screen pointing toward waypoint
					local center = Vector2.new(viewportSize.X/2, viewportSize.Y/2)
					local angle = math.atan2(screenPos.Y - center.Y, screenPos.X - center.X)

					-- Calculate position on the edge of the screen
					local edgeX = center.X + math.cos(angle) * (viewportSize.X/2 - 50)
					local edgeY = center.Y + math.sin(angle) * (viewportSize.Y/2 - 50)

					-- Clamp to screen bounds
					edgeX = math.max(50, math.min(viewportSize.X - 50, edgeX))
					edgeY = math.max(50, math.min(viewportSize.Y - 50, edgeY))

					-- Position and rotate arrow
					container.Position = UDim2.new(0, edgeX - container.AbsoluteSize.X/2, 
						0, edgeY - container.AbsoluteSize.Y/2)

					-- Rotate arrow to point toward waypoint
					arrow.Rotation = math.deg(angle) + 90

					-- Make arrow fully visible when off screen
					arrow.ImageTransparency = 0
					if distanceLabel then
						distanceLabel.Visible = true

						-- Calculate distance
						if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
							local rootPart = LocalPlayer.Character.HumanoidRootPart
							local distance = (rootPart.Position - waypointPos).Magnitude
							distanceLabel.Text = math.floor(distance) .. " m"
						end
					end
				end
			end
		end
	end)
end

-- Initialize the client system
PlayerGuidanceClient:Initialize()
-- Make global for debugging
_G.PlayerGuidanceClient = PlayerGuidanceClient
return PlayerGuidanceClient
