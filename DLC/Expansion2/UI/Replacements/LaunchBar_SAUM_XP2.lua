-- =============================================================================
-- StillAUsefulMaterial - Extension for LaunchBar
-- Add event handler for updating the current state
-- after adding the boost-button
-- =============================================================================

-- Basegame context
include("LaunchBar_Expansion2.lua");

-- Add a log event for loading this
print("Loading LaunchBar_SAUM.lua");

-- Bind original functions
ORIGINAL_Initialize = Initialize;

function Initialize()
	-- Original initializer
	ORIGINAL_Initialize();

  -- Update the ui of the top-bar
	LuaEvents.RefreshLaunchBar.Add(RealizeBacking);

	-- Log initialization
	print("Initialized");
end

-- Fire!
Initialize();
