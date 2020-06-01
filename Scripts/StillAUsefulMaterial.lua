-- =============================================================================
--	StillAUsefulMaterial
-- =============================================================================

-- Debugging mode switch
local debugMode = true;

-- Big brother to get stuff done the context cant
function OnChangeResourceAmount(localPlayerID, params)
	local player = Players[params.playerId];
	local playerResources = player:GetResources();

	-- Changing the resource amounts for example
	playerResources:ChangeResourceAmount(params.resourceIndex, params.amount);
end

-- Also helps out...
function OnCompleteProduction(localPlayerID, params)
	local pCity = Players[params.ownerId]:GetCities():FindID(params.cityId);
	local cityBuildQueue = pCity:GetBuildQueue();

	-- ...by finishing productions
	cityBuildQueue:FinishProgress();

	WriteToLog("Finished production in city: "..params.cityId);
end

-- Another one here...
function OnAddToProduction(localPlayerID, params)
	local pCity = Players[params.ownerId]:GetCities():FindID(params.cityId);
	local cityBuildQueue = pCity:GetBuildQueue();

	-- ...who add production (boost)
	cityBuildQueue:AddProgress(params.amount);

  -- Transparency!
	WriteToLog("Added to production: "..params.amount);
end

-- Also helps out...
function OnAddToResearch(localPlayerID, params)
	local player = Players[params.playerId];

	-- ...by adding science
	player:GetTechs():ChangeCurrentResearchProgress(params.amount);

	-- What happened?
	WriteToLog("Added "..params.amount.." science for player: "..params.playerId);
end

-- Also helps out...
function OnAddToCivic(localPlayerID, params)
	local player = Players[params.playerId];

	-- ...by adding culture
	player:GetCulture():ChangeCurrentCulturalProgress(params.amount);

	-- What happened?
	WriteToLog("Added "..params.amount.." culture for player: "..params.playerId);
end

-- Debug function for logging
function WriteToLog(message)
	if (debugMode and message ~= nil) then
		print(message);
	end
end

-- Main function for initialization
function Initialize()
	-- Communication uplink to our context-sister! HELLO WORLD!
	GameEvents.ChangeResourceAmount.Add(OnChangeResourceAmount);
	GameEvents.CompleteProduction.Add(OnCompleteProduction);
	GameEvents.AddToProduction.Add(OnAddToProduction);
	GameEvents.AddToResearch.Add(OnAddToResearch);
	GameEvents.AddToCivic.Add(OnAddToCivic);

	-- Init message log
	print("Initialized.");
end

-- Initialize the script
Initialize();
