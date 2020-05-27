-- =============================================================================
--	StillAUsefulMaterial
-- =============================================================================

-- Debugging mode switch
local debugMode = true;

-- Big brother to get stuff done the context cant
function OnChangeResourceAmount(playerId, resourceIndex, amount)
	local player = Players[playerId];
	local playerResources = player:GetResources();

	-- Changing the resource amounts for example
	playerResources:ChangeResourceAmount(resourceIndex, amount);
end

-- Also helps out...
function OnCompleteProduction(playerId, cityId)
	local pCity = Players[playerId]:GetCities():FindID(cityId);
	local cityBuildQueue = pCity:GetBuildQueue();

	-- ...by finishing productions
	cityBuildQueue:FinishProgress();

	WriteToLog("Finished production in city: "..cityId);
end

-- Another one here...
function OnAddToProduction(playerId, cityId, amount)
	local pCity = Players[playerId]:GetCities():FindID(cityId);
	local cityBuildQueue = pCity:GetBuildQueue();

	-- ...who add production (boost)
	cityBuildQueue:AddProgress(amount);

  -- Transparency!
	WriteToLog("Added to production: "..amount);
end

-- Also helps out...
function OnAddToResearch(playerId, amount)
	local player = Players[playerId];

	-- ...by adding science
	player:GetTechs():ChangeCurrentResearchProgress(amount);

	-- What happened?
	WriteToLog("Added "..amount.." science for player: "..playerId);
end

-- Debug function for logging
function WriteToLog(message)
	if (debugMode and message ~= nil) then
		print(message);
	end
end

-- Main function for initialization
function Initialize()
	-- Create a namespace for our mod
	if (not ExposedMembers.MOD_StillAUsefulMaterial) then ExposedMembers.MOD_StillAUsefulMaterial = {}; end

	-- Communication uplink to our context-sister! HELLO WORLD!
	ExposedMembers.MOD_StillAUsefulMaterial.ChangeResourceAmount = OnChangeResourceAmount;
	ExposedMembers.MOD_StillAUsefulMaterial.CompleteProduction = OnCompleteProduction;
	ExposedMembers.MOD_StillAUsefulMaterial.AddToProduction = OnAddToProduction;
	ExposedMembers.MOD_StillAUsefulMaterial.AddToResearch = OnAddToResearch;

	-- Init message log
	print("Initialized.");
end

-- Initialize the script
Initialize();
