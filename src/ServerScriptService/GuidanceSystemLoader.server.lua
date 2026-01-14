--[[
    FIXED GuidanceSystemLoader.server.lua
    Place in: ServerScriptService/GuidanceSystemLoader.server.lua
    
    PURPOSE: Load and initialize the PlayerGuidanceSystem
]]

print("🧭 GuidanceSystemLoader: Starting...")

local ServerScriptService = game:GetService("ServerScriptService")

-- Wait for other core systems to load first
spawn(function()
	wait(5) -- Give other systems time to initialize

	print("🧭 Loading PlayerGuidanceSystem...")

	-- Load PlayerGuidanceSystem
	local guidanceSystemModule = ServerScriptService:FindFirstChild("PlayerGuidanceSystem")

	if not guidanceSystemModule then
		warn("❌ PlayerGuidanceSystem module not found in ServerScriptService!")
		warn("   Make sure PlayerGuidanceSystem.lua is in ServerScriptService")
		return
	end

	local success, PlayerGuidanceSystem = pcall(function()
		return require(guidanceSystemModule)
	end)

	if not success then
		warn("❌ Failed to load PlayerGuidanceSystem: " .. tostring(PlayerGuidanceSystem))
		return
	end

	print("✅ PlayerGuidanceSystem loaded successfully")

	-- Initialize the guidance system
	local initSuccess, initError = pcall(function()
		return PlayerGuidanceSystem:Initialize()
	end)

	if initSuccess then
		print("✅ PlayerGuidanceSystem initialized successfully!")
		print("🎯 Guidance system is now active for new players")

		-- Set global reference
		_G.PlayerGuidanceSystem = PlayerGuidanceSystem
	else
		warn("❌ PlayerGuidanceSystem initialization failed: " .. tostring(initError))
	end
end)

print("🧭 GuidanceSystemLoader: Setup complete")