-- =============================================================================
-- StillAUsefulMaterial - Extension for ProductionManager
-- Add event handler for updating the current state
-- after after pressing the boost-button
-- =============================================================================

-- Basegame context
include("ProductionManager");

-- Add a log event for loading this
print("Loading ProductionManager_SUM.lua");

-- Bind original functions
ORIGINAL_Initialize = Initialize;

function Initialize()
	-- Original initializer
	ORIGINAL_Initialize();

  -- Update the ui after production progress has been made
	Events.CityProductionUpdated.Add(OnCityProductionQueueChanged);
	Events.CityProductionCompleted.Add(OnCityProductionQueueChanged);

	-- Log initialization
	print("Initialized");
end

-- Fire!
Initialize();
