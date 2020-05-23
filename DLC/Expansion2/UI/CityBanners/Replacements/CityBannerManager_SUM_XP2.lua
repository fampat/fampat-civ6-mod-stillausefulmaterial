-- =============================================================================
-- StillAUsefulMaterial - Extension for CityBannerManager
-- =============================================================================

-- Check if FortifAI is active (get into compatibility mode)
local isFortifAIActive = Modding.IsModActive("20d1d40c-3085-11e9-b210-d663bd873d93");

-- Including the base-context file
if isFortifAIActive then
	-- FortifAI context (compatibility with FortifAI)
	-- ATTENTION: FortifAI _MUST_ loaded first!
	-- See modinfo <LoadOrder> for this file!
	include("CityBannerManager_FAI_XP2.lua");
else
	-- Basegame context
	include("CityBannerManager");
end

-- Add a log event for loading this
print("Loading CityBannerManager_SUM_XP2.lua");

-- Bind original functions
ORIGINAL_Initialize = Initialize;

function Initialize()
	-- Original initializer
	ORIGINAL_Initialize();

  -- Update the ui after production progress has been made
	Events.CityProductionUpdated.Add(RefreshBanner);
	Events.CityProductionCompleted.Add(RefreshBanner);

	-- Log initialization
	print("Initialized");
end

-- Fire!
Initialize();
