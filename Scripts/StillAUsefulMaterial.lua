-- =============================================================================
--	StillAUsefulMaterial
-- =============================================================================

-- Include some helper
include("Common_SAUM.lua");

-- Debugging mode switch
local debugMode = true;

-- Constants
local IRON_AI_THESHOLD = 10; -- This amount the AI never uses for boosting
local NITER_AI_THESHOLD = 10; -- This amount the AI never uses for boosting
local HORSES_AI_THESHOLD = 10; -- This amount the AI never uses for boosting

-- Sets the era at which boosting starts
local IRON_AI_MIN_ERA_INDEX = 4;
local NITER_AI_MIN_ERA_INDEX = 5;
local HORSES_AI_MIN_ERA_INDEX = 6;

-- Additional multipler for the modified base-ratio per era
local IRON_AI_BOOST_RATIO_INCREMENT_PER_ERA = 0.35;
local NITER_AI_BOOST_RATIO_INCREMENT_PER_ERA = 0.6;
local HORSES_AI_BOOST_RATIO_INCREMENT_PER_ERA = 0.85;

-- Base multipler for the hardcoded 1:1 ratio
local IRON_AI_BOOST_RATIO_BASE_MULTIPLIER = 1.15;
local NITER_AI_BOOST_RATIO_BASE_MULTIPLIER = 1.85;
local HORSES_AI_BOOST_RATIO_BASE_MULTIPLIER = 2.15;

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

-- AIs will also get a boost if they can afford it
-- TODO: Implement descision-making for more intelligent boosting, eg.
--       if military production exist, boost that instead of a settler.
function TakeAIActionsForIronBoost(playerAI)
  -- Is boostint possible for this playerAI?
  if ExposedMembers.SAUM_Iron_IsBoostWithIronPossible(playerAI:GetID()) then
    local pCities = playerAI:GetCities();

    -- Loop the playerAI cities
    for _, pCity in pCities:Members() do
			-- Real city?
			if pCity ~= nil then
				-- Get owner-stuff
				local cityOwnerId = pCity:GetOwner();
				local cityId = pCity:GetID();

				-- City validity checks
	      if not ExposedMembers.SAUM_Iron_IsCityOccupied(cityOwnerId, cityId)	and ExposedMembers.SAUM_Iron_IsCityProducing(cityOwnerId, cityId) then
					-- Logging ya know
				  WriteToLog("AIs production boosting begun for player: "..cityOwnerId.." in city: "..cityId);

			    -- Fetch the stockpile of the player, and the current production state
			    local resourceStockpile = getStrategicResourceStockpileOfCityOwner(pCity, "RESOURCE_IRON");
			    local requiredProductionNeeded = ExposedMembers.SAUM_Iron_GetProductionAmountNeededForCompletion(cityOwnerId, cityId);

					-- Do stuff only if possible
					if (resourceStockpile > 0 and requiredProductionNeeded > 0) then
				    -- Calc variable
				    local substractedMaterial = 0;

						-- Calc the era boost multipler
						local eraBoostMultiplier = IRON_AI_BOOST_RATIO_BASE_MULTIPLIER + getBoostIncrementedValue(IRON_AI_MIN_ERA_INDEX, IRON_AI_BOOST_RATIO_INCREMENT_PER_ERA);

				    -- In case we have more iron that it would cost, complete it!
				    -- And save some precious iron
				    if requiredProductionNeeded <= scaleWithGameSpeed(resourceStockpile * eraBoostMultiplier) then
							-- Complete the AIs production
							OnCompleteProduction(nil, {
								ownerId = cityOwnerId,
								cityId = cityId
							});

				      -- Subtract amount
				      substractedMaterial = requiredProductionNeeded;
				    else
			        local thresholdedAIResourceStock = resourceStockpile - IRON_AI_THESHOLD;

			        -- AI Boost logging
			        WriteToLog("BOOST is AI threshold-safe!: "..resourceStockpile.." -> "..thresholdedAIResourceStock);

			        -- Thresholded AI resource stock
			        resourceStockpile = thresholdedAIResourceStock;

							-- Add to production
							OnAddToProduction(nil, {
				        ownerId = cityOwnerId,
				        cityId = cityId,
				        amount = scaleWithGameSpeed(resourceStockpile * eraBoostMultiplier)
				      });

				      -- Subtract amount
				      substractedMaterial = resourceStockpile;
				    end

						-- Change resource amount
						OnChangeResourceAmount(nil, {
				      playerId = cityOwnerId,
				      resourceIndex = GameInfo.Resources["RESOURCE_IRON"].Index,
				      amount = -substractedMaterial
				    });

						-- Logging to make clear what the AI is getting
	          local AIPlayerConfiguration = PlayerConfigurations[cityOwnerId];
	          WriteToLog("AI ("..AIPlayerConfiguration:GetLeaderName()..") boosted in city: "..pCity:GetName());

						-- No more boosting this turn
	          break;
				  end
	      end
	    end
    end
  end
end

-- AIs will also get a boost if they can afford it
function TakeAIActionsForNiterBoost(playerAI)
	-- But only with real player
	if playerAI ~= nil then
    local playerId = playerAI:GetID();

		-- Logging ya know
	  WriteToLog("AIs research boosting begun for player: "..playerId);

	  -- Is boosting possible for this player?
	  if ExposedMembers.SAUM_Niter_IsPlayerResearching(playerId) and ExposedMembers.SAUM_Niter_IsBoostWithNiterPossible(playerId) then
	    -- Fetch the stockpile of the player, and the current production state
	    local resourceStockpile = getStrategicResourceStockpileOfPlayer(playerAI, "RESOURCE_NITER");
	    local requiredScienceNeeded = ExposedMembers.SAUM_Niter_GetScienceAmountNeededForCompletion(playerId);

			-- Do stuff only if possible
			if (resourceStockpile > 0 and requiredScienceNeeded > 0) then
		    -- Calc variable
		    local substractedMaterial = 0;

				-- Calc the era boost multipler
				local eraBoostMultiplier = NITER_AI_BOOST_RATIO_BASE_MULTIPLIER + getBoostIncrementedValue(NITER_AI_MIN_ERA_INDEX, NITER_AI_BOOST_RATIO_INCREMENT_PER_ERA);


		    -- In case we have more niter that it would cost, complete it!
		    -- And save some precious niter
		    if requiredScienceNeeded <= scaleWithGameSpeed(resourceStockpile * eraBoostMultiplier) then
					OnAddToResearch(nil, {
		        playerId = playerId,
		        amount = requiredScienceNeeded
		      });

		      -- Subtract amount
		      substractedMaterial = requiredScienceNeeded;
		    else
		      -- The AI will want to keep its threshold
	        local thresholdedAIResourceStock = resourceStockpile - NITER_AI_THESHOLD;

	        -- AI Boost logging
	        WriteToLog("BOOST is AI threshold-safe!: "..resourceStockpile.." -> "..thresholdedAIResourceStock);

	        -- Thresholded AI resource stock
	        resourceStockpile = thresholdedAIResourceStock;

					-- Game-event callback to add science, substract resource equal to production-cost
					OnAddToResearch(nil, {
		        playerId = playerId,
		        amount = scaleWithGameSpeed(resourceStockpile * eraBoostMultiplier)
		      });

		      -- Subtract amount
		      substractedMaterial = resourceStockpile;
		    end

				-- Game-event callback to change resource-count on player
				OnChangeResourceAmount(nil, {
		      playerId = playerId,
		      resourceIndex = GameInfo.Resources["RESOURCE_NITER"].Index,
		      amount = -substractedMaterial
		    });

				-- Logging to make clear what the AI is getting
	      local AIPlayerConfiguration = PlayerConfigurations[playerId];
	      WriteToLog("AI ("..AIPlayerConfiguration:GetLeaderName()..") boosted his science!");
			end
		end
	end
end

-- AIs will also get a boost if they can afford it
function TakeAIActionsForHorsesBoost(playerAI)
	-- Boost, but only with real player
	if playerAI ~= nil then
		local playerId = playerAI:GetID();

		-- Logging ya know
	  WriteToLog("AIs culture boosting begun for player: "..playerId);

	  -- Is boosting possible for this player?
	  if ExposedMembers.SAUM_Niter_IsPlayerDevelopingCulture(playerId) and ExposedMembers.SAUM_Niter_IsBoostWithHorsesPossible(playerId) then
	    -- Fetch the stockpile of the player, and the current production state
	    local resourceStockpile = getStrategicResourceStockpileOfPlayer(playerAI, "RESOURCE_HORSES");
	    local requiredCultureNeeded = ExposedMembers.SAUM_Niter_GetCultureAmountNeededForCompletion(playerId);

			-- Do stuff only if possible
			if (resourceStockpile > 0 and requiredCultureNeeded > 0) then
		    -- Calc variable
		    local substractedMaterial = 0;

				-- Calc the era boost multipler
				local eraBoostMultiplier = HORSES_AI_BOOST_RATIO_BASE_MULTIPLIER + getBoostIncrementedValue(HORSES_AI_MIN_ERA_INDEX, HORSES_AI_BOOST_RATIO_INCREMENT_PER_ERA);

		    -- In case we have more horses that it would cost, complete it!
		    -- And save some precious horses
		    if requiredCultureNeeded <= scaleWithGameSpeed(resourceStockpile * eraBoostMultiplier) then
		      -- Game-event callback to add civic, substract resource equal to production-cost
					OnAddToCivic(nil, {
		        OnStart = "AddToCivic",
		        playerId = playerId,
		        amount = requiredCultureNeeded
		      });

		      -- Subtract amount
		      substractedMaterial = requiredCultureNeeded;
		    else
	        local thresholdedAIResourceStock = resourceStockpile - HORSES_AI_THESHOLD;

	        -- AI Boost logging
	        WriteToLog("BOOST is AI threshold-safe!: "..resourceStockpile.." -> "..thresholdedAIResourceStock);

	        -- Thresholded AI resource stock
	        resourceStockpile = thresholdedAIResourceStock;

		      -- Game-event callback to add culture, substract resource equal to production-cost
					OnAddToCivic(nil, {
		        OnStart = "AddToCivic",
		        playerId = playerId,
		        amount = scaleWithGameSpeed(resourceStockpile * eraBoostMultiplier)
		      });

		      -- Subtract amount
		      substractedMaterial = resourceStockpile;
		    end

				-- Game-event callback to change resource-count on player
				OnChangeResourceAmount(nil, {
		      playerId = playerId,
		      resourceIndex = GameInfo.Resources["RESOURCE_HORSES"].Index,
		      amount = -substractedMaterial
		    });

				-- Logging to make clear what the AI is getting
	      local AIPlayerConfiguration = PlayerConfigurations[playerId];
	      WriteToLog("AI ("..AIPlayerConfiguration:GetLeaderName()..") boosted his culture!");
		  end
	  end
  end
end

-- Thinigs that happen when the turn starts
function OnPlayerTurnActivated(playerId, firstActivation)
	if firstActivation then
		-- Get the player
		local player = Players[playerId];

		-- Is the player an AI?
	  if isAI(player) then
			-- Its AIs turn to boost baby!
			TakeAIActionsForIronBoost(player);
			TakeAIActionsForNiterBoost(player);
			TakeAIActionsForHorsesBoost(player);
		end
	end
end

-- Main function for initialization
function Initialize()
	-- Trigger on player turn activation
	Events.PlayerTurnActivated.Add(OnPlayerTurnActivated);

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
