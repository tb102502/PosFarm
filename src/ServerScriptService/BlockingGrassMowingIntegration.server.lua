
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

print("🌿 BlockingGrassMowingIntegration: Setting up mowing tool integration...")

-- Connect to the GrassMowed event to ensure blocking grass is processed
local function SetupGrassMowedIntegration()
	local success, error = pcall(function()
		local remotes = ReplicatedStorage:WaitForChild("GameRemotes")
		local grassMowed = remotes:WaitForChild("GrassMowed")
		
		-- Enhanced GrassMowed event handler
		grassMowed.Event:Connect(function(player, grassPart, regrowBonus)
			-- Check if this is blocking grass
			if grassPart:GetAttribute("IsBlockingGrass") then
				print("🌿 Blocking grass mowed by " .. player.Name)
				
				-- Let GrassBlockingSystem handle the area unblocking
				if _G.GrassBlockingSystem then
					_G.GrassBlockingSystem:OnGrassMowed(player, grassPart)
				end
				
				-- Show notification
				if _G.GameCore and _G.GameCore.SendNotification then
					_G.GameCore:SendNotification(player, "🌿 Area Unblocked!", 
						"You cleared blocking grass" .. ("success"))
				end
			end
		end)
		
		print("✅ GrassMowed event integration setup complete")
	end)
	
	if not success then
		warn("❌ Failed to setup GrassMowed integration: " .. tostring(error))
	end
end

-- Setup integration after a delay
spawn(function()
	wait(3) -- Wait for other systems to load
	SetupGrassMowedIntegration()
end)
