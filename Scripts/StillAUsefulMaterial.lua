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
function TakeAIActionsForIronBoost()
  WriteToLog("AIs production boosting begun!");

  -- Get alive players (only major civs)
	local players = Game.GetPlayers{Alive = true, Major = true};

	-- Player is real?
	for _, player in ipairs(players) do
    -- Is the player an AI?
    if isAI(player) then
      -- Is boostint possible for this player?
      if ExposedMembers.SAUM_Iron_IsBoostWithIronPossible(player:GetID()) then
        local pCities = player:GetCities();

        -- Loop the player cities
        for _, pCity in pCities:Members() do
          if ExposedMembers.SAUM_Iron_IsCityProducing(pCity:GetOwner(), pCity:GetID()) then
					  -- Boost the AI´s city, but only with real cities
					  if pCity ~= nil then
					    -- Variables stuff
					    local cityId = pCity:GetID();
					    local ownerId = pCity:GetOwner();

					    -- Fetch the stockpile of the player, and the current production state
					    local resourceStockpile = getStrategicResourceStockpileOfCityOwner(pCity, "RESOURCE_IRON");
					    local requiredProductionNeeded = ExposedMembers.SAUM_Iron_GetProductionAmountNeededForCompletion(ownerId, cityId);

					    -- Calc variable
					    local substractedMaterial = 0;

					    -- In case we have more iron that it would cost, complete it!
					    -- And save some precious iron
					    if requiredProductionNeeded <= scaleWithGameSpeed(resourceStockpile) then
								-- Complete the AIs production
								OnCompleteProduction(Game.GetLocalPlayer(), {
									ownerId = ownerId,
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
								OnAddToProduction(Game.GetLocalPlayer(), {
					        ownerId = ownerId,
					        cityId = cityId,
					        amount = scaleWithGameSpeed(resourceStockpile)
					      });

					      -- Subtract amount
					      substractedMaterial = resourceStockpile;
					    end

							-- Change resource amount
							OnChangeResourceAmount(Game.GetLocalPlayer(), {
					      playerId = ownerId,
					      resourceIndex = GameInfo.Resources["RESOURCE_IRON"].Index,
					      amount = -substractedMaterial
					    });

							-- Logging to make clear what the AI is getting
	            local AIPlayerConfiguration = PlayerConfigurations[player:GetID()];
	            WriteToLog("AI ("..AIPlayerConfiguration:GetLeaderName()..") boosted in city: "..pCity:GetName());

							-- No more boosting this turn
	            break;
					  end
          end
        end
      end
    end
	end
end

-- AIs will also get a boost if they can afford it
function TakeAIActionsForNiterBoost()
  WriteToLog("AIs science boosting begun!");

  -- Get alive players (only major civs)
	local players = Game.GetPlayers{Alive = true, Major = true};

	-- Player is real?
	for _, player in ipairs(players) do
    -- Is the player an AI?
    if isAI(player) then
      -- Is boosting possible for this player?
      if ExposedMembers.SAUM_Niter_IsPlayerResearching(player:GetID()) and ExposedMembers.SAUM_Niter_IsBoostWithNiterPossible(player:GetID()) then
				-- But only with real player
			  if player ~= nil then
			    local playerId = player:GetID();

			    -- Fetch the stockpile of the player, and the current production state
			    local resourceStockpile = getStrategicResourceStockpileOfPlayer(player, "RESOURCE_NITER");
			    local requiredScienceNeeded = ExposedMembers.SAUM_Niter_GetScienceAmountNeededForCompletion(playerId);

			    -- Calc variable
			    local substractedMaterial = 0;

			    -- In case we have more niter that it would cost, complete it!
			    -- And save some precious niter
			    if requiredScienceNeeded <= scaleWithGameSpeed(resourceStockpile) then
						OnAddToResearch(Game.GetLocalPlayer(), {
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
						OnAddToResearch(Game.GetLocalPlayer(), {
			        playerId = playerId,
			        amount = scaleWithGameSpeed(resourceStockpile)
			      });

			      -- Subtract amount
			      substractedMaterial = resourceStockpile;
			    end

					-- Game-event callback to change resource-count on player
  				OnChangeResourceAmount(Game.GetLocalPlayer(), {
			      playerId = playerId,
			      resourceIndex = GameInfo.Resources["RESOURCE_NITER"].Index,
			      amount = -substractedMaterial
			    });

					-- Logging to make clear what the AI is getting
	        local AIPlayerConfiguration = PlayerConfigurations[player:GetID()];
	        WriteToLog("AI ("..AIPlayerConfiguration:GetLeaderName()..") boosted his science!");
	  		end
      end
    end
	end
end

-- AIs will also get a boost if they can afford it
function TakeAIActionsForHorsesBoost()
  WriteToLog("AIs culture boosting begun!");

  -- Get alive players (only major civs)
	local players = Game.GetPlayers{Alive = true, Major = true};

	-- Player is real?
	for _, player in ipairs(players) do
    -- Is the player an AI?
    if isAI(player) then
      -- Is boosting possible for this player?
      if ExposedMembers.SAUM_Niter_IsPlayerDevelopingCulture(player:GetID()) and ExposedMembers.SAUM_Niter_IsBoostWithHorsesPossible(player:GetID()) then
				-- Boost, but only with real player
			  if player ~= nil then
			    local playerId = player:GetID();
			    local localPlayer = Game.GetLocalPlayer();

			    -- Fetch the stockpile of the player, and the current production state
			    local resourceStockpile = getStrategicResourceStockpileOfPlayer(player, "RESOURCE_HORSES");
			    local requiredCultureNeeded = ExposedMembers.SAUM_Niter_GetCultureAmountNeededForCompletion(playerId);

			    -- Calc variable
			    local substractedMaterial = 0;

			    -- In case we have more horses that it would cost, complete it!
			    -- And save some precious horses
			    if requiredCultureNeeded <= scaleWithGameSpeed(resourceStockpile) then
			      -- Game-event callback to add civic, substract resource equal to production-cost
						OnAddToCivic(localPlayer, {
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
						OnAddToCivic(localPlayer, {
			        OnStart = "AddToCivic",
			        playerId = playerId,
			        amount = scaleWithGameSpeed(resourceStockpile)
			      });

			      -- Subtract amount
			      substractedMaterial = resourceStockpile;
			    end

					-- Game-event callback to change resource-count on player
					OnChangeResourceAmount(localPlayer, {
			      playerId = playerId,
			      resourceIndex = GameInfo.Resources["RESOURCE_HORSES"].Index,
			      amount = -substractedMaterial
			    });

					-- Logging to make clear what the AI is getting
	        local AIPlayerConfiguration = PlayerConfigurations[player:GetID()];
	        WriteToLog("AI ("..AIPlayerConfiguration:GetLeaderName()..") boosted his culture!");
			  end
      end
    end
	end
end

-- Thinigs that happen when the turn starts
function OnTurnBegin()
	-- Its AIs turn to boost baby!
	TakeAIActionsForIronBoost();
	TakeAIActionsForNiterBoost();
	TakeAIActionsForHorsesBoost();
end

-- Main function for initialization
function Initialize()
	-- Turn begins
  Events.TurnBegin.Add(OnTurnBegin);

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
