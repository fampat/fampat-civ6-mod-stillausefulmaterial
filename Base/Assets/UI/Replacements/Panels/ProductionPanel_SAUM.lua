-- =============================================================================
-- StillAUsefulMaterial - Extension for ProductionPanel
-- Add event handler for updating the current state
-- after after pressing the boost-button
-- =============================================================================

-- Basegame context
include("ProductionPanel");

-- Add a log event for loading this
print("Loading ProductionPanel_SAUM.lua");

-- Bind original functions
ORIGINAL_Initialize = Initialize;

function Initialize()
	-- Original initializer
	ORIGINAL_Initialize();

  -- Update the ui after production progress has been made
	Events.CityProductionUpdated.Add(Refresh);
	Events.CityProductionCompleted.Add(Refresh);

	-- Log initialization
	print("Initialized");
end

-- Fire!
Initialize();
