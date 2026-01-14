print("Server script loaded successfully")

local car = script.Parent
print("Car found:", car.Name)

-- Wait for required parts
local stats = car:WaitForChild("Configurations")
local driveSeat = car:WaitForChild("DriveSeat")

print("All parts loaded, setting up car...")

-- Handle player entering/leaving seat
driveSeat.Changed:Connect(function(property)
	if property == "Occupant" then
		if driveSeat.Occupant then
			print("Player entered vehicle")

			-- Get player from the character that's now in the seat
			local player = game.Players:GetPlayerFromCharacter(driveSeat.Occupant.Parent)
			if player then
				print("Player identified:", player.Name)

				-- Try to set network ownership
				local success, error = pcall(function()
					driveSeat:SetNetworkOwner(player)
				end)
				if not success then
					warn("Could not set network owner:", error)
				end

				-- Clone LocalScript to player
				local localScript = script:FindFirstChild("LocalCarScript")
				if localScript then
					local cloned = localScript:Clone()
					cloned.Parent = player.PlayerGui
					cloned.Car.Value = car
					cloned.Disabled = false
					print("LocalScript given to player")
				else
					warn("LocalCarScript not found!")
				end
			end
		else
			print("Player left vehicle")
		end
	end
end)

print("Car setup complete!")