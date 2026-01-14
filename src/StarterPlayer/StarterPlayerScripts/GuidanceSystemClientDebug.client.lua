--[[
    FIXED GuidanceSystemClientDebug.client.lua
    Place in: StarterPlayer/StarterPlayerScripts/GuidanceSystemClientDebug.client.lua
    
    FIXES:
    ✅ Simplified remote connection logic
    ✅ Better error handling
    ✅ Immediate debug interface availability
    ✅ Clearer status messages
    ✅ Fallback functionality
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer

print("🔧 Loading FIXED Guidance System Client Debug...")

-- ========== IMMEDIATE DEBUG INTERFACE ==========
-- Create debug interface immediately to prevent errors

_G.GuidanceDebug = {
	DebugGuidance = function()
		print("🔍 Requesting guidance debug info from server...")
		local success, error = pcall(function()
			local gameRemotes = ReplicatedStorage:WaitForChild("GameRemotes", 5)
			if gameRemotes then
				local debugEvent = gameRemotes:WaitForChild("GuidanceDebug", 3)
				if debugEvent then
					debugEvent:FireServer("DebugGuidance")
					print("✅ Debug request sent successfully")
				else
					print("❌ GuidanceDebug remote not found")
					print("   Server guidance system may not be loaded")
				end
			else
				print("❌ GameRemotes folder not found")
				print("   Server systems may not be initialized")
			end
		end)

		if not success then
			print("❌ Failed to send debug request: " .. tostring(error))
		end
	end,

	ResetTutorial = function(playerName)
		local targetPlayer = playerName or LocalPlayer.Name
		print("🔄 Resetting tutorial for: " .. targetPlayer)

		local success, error = pcall(function()
			local gameRemotes = ReplicatedStorage:WaitForChild("GameRemotes", 5)
			if gameRemotes then
				local debugEvent = gameRemotes:WaitForChild("GuidanceDebug", 3)
				if debugEvent then
					debugEvent:FireServer("ResetPlayerTutorial", targetPlayer)
					print("✅ Reset request sent successfully")
				else
					print("❌ GuidanceDebug remote not found")
				end
			else
				print("❌ GameRemotes folder not found")
			end
		end)

		if not success then
			print("❌ Failed to send reset request: " .. tostring(error))
		end
	end,

	StartGuidance = function(playerName)
		local targetPlayer = playerName or LocalPlayer.Name
		print("🎯 Starting guidance for: " .. targetPlayer)

		local success, error = pcall(function()
			local gameRemotes = ReplicatedStorage:WaitForChild("GameRemotes", 5)
			if gameRemotes then
				local debugEvent = gameRemotes:WaitForChild("GuidanceDebug", 3)
				if debugEvent then
					debugEvent:FireServer("ForceStartGuidance", targetPlayer)
					print("✅ Start guidance request sent successfully")
				else
					print("❌ GuidanceDebug remote not found")
				end
			else
				print("❌ GameRemotes folder not found")
			end
		end)

		if not success then
			print("❌ Failed to send start guidance request: " .. tostring(error))
		end
	end,

	PrintWaypoints = function()
		print("🗺️ Requesting waypoint list from server...")

		local success, error = pcall(function()
			local gameRemotes = ReplicatedStorage:WaitForChild("GameRemotes", 5)
			if gameRemotes then
				local debugEvent = gameRemotes:WaitForChild("GuidanceDebug", 3)
				if debugEvent then
					debugEvent:FireServer("PrintWaypoints")
					print("✅ Waypoint request sent successfully")
				else
					print("❌ GuidanceDebug remote not found")
				end
			else
				print("❌ GameRemotes folder not found")
			end
		end)

		if not success then
			print("❌ Failed to send waypoint request: " .. tostring(error))
		end
	end,

	DetectWaypoints = function()
		print("🔍 Requesting waypoint detection from server...")

		local success, error = pcall(function()
			local gameRemotes = ReplicatedStorage:WaitForChild("GameRemotes", 5)
			if gameRemotes then
				local debugEvent = gameRemotes:WaitForChild("GuidanceDebug", 3)
				if debugEvent then
					debugEvent:FireServer("DetectWaypoints")
					print("✅ Waypoint detection request sent successfully")
				else
					print("❌ GuidanceDebug remote not found")
				end
			else
				print("❌ GameRemotes folder not found")
			end
		end)

		if not success then
			print("❌ Failed to send waypoint detection request: " .. tostring(error))
		end
	end,

	CheckStatus = function()
		print("=== GUIDANCE SYSTEM CLIENT STATUS ===")

		-- Check ReplicatedStorage
		local gameRemotes = ReplicatedStorage:FindFirstChild("GameRemotes")
		print("GameRemotes folder: " .. (gameRemotes and "✅ Found" or "❌ Not Found"))

		if gameRemotes then
			local guidanceEvents = {
				"GuidanceDebug",
				"ShowWaypoint", 
				"HideWaypoint"
			}

			print("Guidance Remote Events:")
			for _, eventName in ipairs(guidanceEvents) do
				local event = gameRemotes:FindFirstChild(eventName)
				print("  " .. eventName .. ": " .. (event and "✅" or "❌"))
			end
		end

		-- Check global references
		print("Global References:")
		print("  _G.PlayerGuidanceSystem: " .. (_G.PlayerGuidanceSystem and "✅" or "❌"))
		print("  _G.GuidanceDebug: " .. (_G.GuidanceDebug and "✅" or "❌"))

		-- Check workspace for guidance markers
		local guidanceMarkers = 0
		for _, obj in pairs(workspace:GetChildren()) do
			if obj.Name:find("GuidanceMarker") then
				guidanceMarkers = guidanceMarkers + 1
			end
		end
		print("Active guidance markers: " .. guidanceMarkers)

		print("=====================================")
	end,

	Help = function()
		print("🎮 GUIDANCE SYSTEM DEBUG COMMANDS:")
		print("  _G.GuidanceDebug.DebugGuidance() - Show server guidance status")
		print("  _G.GuidanceDebug.ResetTutorial() - Reset tutorial for local player")
		print("  _G.GuidanceDebug.ResetTutorial('PlayerName') - Reset for specific player")
		print("  _G.GuidanceDebug.StartGuidance() - Force start guidance for local player")
		print("  _G.GuidanceDebug.StartGuidance('PlayerName') - Force start for specific player")
		print("  _G.GuidanceDebug.PrintWaypoints() - Show configured waypoints")
		print("  _G.GuidanceDebug.DetectWaypoints() - Auto-detect waypoints")
		print("  _G.GuidanceDebug.CheckStatus() - Check client-side status")
		print("  _G.GuidanceDebug.Help() - Show this help")
		print("")
		print("🎯 QUICK COMMANDS:")
		print("  _G.DebugGuidance() - Quick debug")
		print("  _G.ResetTutorial() - Quick reset")
		print("  _G.StartGuidance() - Quick start")
		print("")
		print("💡 TROUBLESHOOTING:")
		print("  1. Use CheckStatus() to verify setup")
		print("  2. If remotes missing, restart server script")
		print("  3. Use DetectWaypoints() if no waypoints found")
		print("  4. Check server console for detailed errors")
	end
}

-- ========== QUICK ACCESS ALIASES ==========

_G.DebugGuidance = _G.GuidanceDebug.DebugGuidance
_G.ResetTutorial = _G.GuidanceDebug.ResetTutorial  
_G.StartGuidance = _G.GuidanceDebug.StartGuidance

-- ========== CONNECTION VERIFICATION ==========

spawn(function()
	wait(3) -- Give server time to initialize

	print("🔌 Verifying guidance system connection...")

	local attempts = 0
	local maxAttempts = 10
	local connected = false

	while attempts < maxAttempts and not connected do
		attempts = attempts + 1

		local gameRemotes = ReplicatedStorage:FindFirstChild("GameRemotes")
		if gameRemotes then
			local debugEvent = gameRemotes:FindFirstChild("GuidanceDebug")
			if debugEvent then
				connected = true
				print("✅ Successfully connected to guidance system!")
				break
			end
		end

		if attempts == 1 then
			print("⏳ Waiting for guidance system to initialize...")
		elseif attempts % 3 == 0 then
			print("⏳ Still waiting... (attempt " .. attempts .. "/" .. maxAttempts .. ")")
		end

		wait(1)
	end

	if not connected then
		print("⚠️ Could not connect to guidance system after " .. maxAttempts .. " attempts")
		print("   This is normal if the guidance system isn't loaded on the server")
		print("   Debug commands will still work once the server system loads")
	end

	-- Always show available commands
	print("")
	print("📋 GUIDANCE DEBUG COMMANDS READY:")
	print("  Type: _G.GuidanceDebug.Help() for full command list")
	print("  Quick: _G.DebugGuidance() | _G.ResetTutorial() | _G.StartGuidance()")
end)

-- ========== CHAT COMMAND INTERFACE ==========

LocalPlayer.Chatted:Connect(function(message)
	local lowerMessage = message:lower()

	if lowerMessage == "/guidancedebug" or lowerMessage == "/gdebug" then
		_G.GuidanceDebug.DebugGuidance()

	elseif lowerMessage == "/guidancehelp" or lowerMessage == "/ghelp" then
		_G.GuidanceDebug.Help()

	elseif lowerMessage == "/resettutorial" then
		_G.GuidanceDebug.ResetTutorial()

	elseif lowerMessage == "/startguidance" then
		_G.GuidanceDebug.StartGuidance()

	elseif lowerMessage == "/guidancestatus" then
		_G.GuidanceDebug.CheckStatus()

	elseif lowerMessage == "/detectwaypoints" then
		_G.GuidanceDebug.DetectWaypoints()
	end
end)

print("✅ FIXED Guidance System Client Debug loaded!")
print("🎮 Quick Commands: /guidancehelp | /gdebug | /resettutorial | /startguidance")
print("📝 Script Commands: _G.GuidanceDebug.Help() for full list")