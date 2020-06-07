-- ================================================
--	StillAUsefulMaterial Helper
-- ================================================

-- Debugging mode switch
local debugMode = true;

function notify(playerId, headline, content)
  local player = Players[playerId];

  -- Fetch the notified players capital
  local playerCapital = player:GetCities():GetCapitalCity();

  -- Get the notification headline from locales
  local notificationHeadline = Locale.Lookup(headline);
  local notificationContent = Locale.Lookup(content);

  -- The actual notification we send out
  NotificationManager.SendNotification(playerId, 95, notificationHeadline, notificationContent, playerCapital:GetX(), playerCapital:GetY());
end

function getBoostIncrementedValue(minEra, incrementValue)
  if Game.GetEras ~= nil then
    -- Get era data of the game
		local gameEras = Game.GetEras();
		local currentGameEra = GameInfo.Eras[gameEras:GetCurrentEra()].ChronologyIndex;

    -- Default if era is not advanced
    if minEra >= currentGameEra then
      return 1;
    end

    -- Calculate
    return ((currentGameEra - minEra) * incrementValue);
  end

  return 1;
end

function isCityOccupied(ownerId, cityId)
  -- Fetch the city
  local city = CityManager.GetCity(ownerId, cityId);

  -- Get the occupation-status
  return city:IsOccupied();
end

-- Helper to check if a city is currently producing something
function isCityProducing(ownerId, cityId)
  -- Fetch the city
  local city = CityManager.GetCity(ownerId, cityId);

  -- Check needed amount
  return (getProductionAmountNeededForCompletion(ownerId, cityId) ~= 0);
end

-- Helper to determine how much production is needed for completion
function getProductionAmountNeededForCompletion(ownerId, cityId)
  -- Fetch City
  local pCity = CityManager.GetCity(ownerId, cityId)

  -- Fetch queue
  local pBuildQueue = pCity:GetBuildQueue();
	local currentProductionHash = 0;

  -- Fetch the current production
  local currentProductionHash = pBuildQueue:GetCurrentProductionTypeHash();

  -- If there is a production ongoing...
  if(currentProductionHash ~= 0) then
    -- ...get us the data and calculate how much is left
    local currentProductionInfo = GetProductionInfoOfCity(pCity, currentProductionHash);
    local productionNeededForFinish = currentProductionInfo.Cost - currentProductionInfo.Progress;

    -- Transparency!
    WriteToLog("Production needed for finish: "..productionNeededForFinish);

    -- The beautiful result of our very complex calculation!
    return productionNeededForFinish;
	end

  WriteToLog("No production to finish here, move along");
  return 0;
end

-- Helper to check if a player has a research selected and it is boostable
function isPlayerResearching(playerId)
  return (getScienceAmountNeededForCompletion(playerId) > 0);
end

-- Helper to determine how much science is needed for completion
function getScienceAmountNeededForCompletion(playerId)
  local player = Players[playerId];

  -- Fetch the players techs
  local playerTechs = player:GetTechs();

  -- Fetch the current researching tech
  local currentTechID = playerTechs:GetResearchingTech();

  -- Continue if a research is going on
  if(currentTechID >= 0) then
    -- Get progress
    local progress = playerTechs:GetResearchProgress(currentTechID);

    -- Get costs
    local cost = playerTechs:GetResearchCost(currentTechID);

    -- If there is a research ongoing...
    if(cost > 0) then
      -- ...get us the data and calculate how much is left
      local scienceNeededForFinish = cost - progress;

      -- Transparency!
      WriteToLog("Science needed for finish: "..scienceNeededForFinish);

      -- The beautiful result of our very complex calculation!
      return scienceNeededForFinish;
  	end
  end

  WriteToLog("No research to finish here, move along");
  return 0;
end

-- Helper to check if a player has a civic selected and it is boostable
function isPlayerDevelopingCulture(playerId)
  return (getCultureAmountNeededForCompletion(playerId) > 0);
end

-- Helper to determine how much culture is needed for completion
function getCultureAmountNeededForCompletion(playerId)
  local player = Players[playerId];

  -- Fetch the players civics
  local playerCulture = player:GetCulture();

  -- Fetch the current civic tech
  local currentCivicID = playerCulture:GetProgressingCivic();

  -- Continue if a civic is going on
  if(currentCivicID >= 0) then
    -- Get progress
    local progress = playerCulture:GetCulturalProgress(currentCivicID);

    -- Get costs
    local cost = playerCulture:GetCultureCost(currentCivicID);

    -- If there is a civic ongoing...
    if(cost > 0) then
      -- ...get us the data and calculate how much is left
      local cultureNeededForFinish = cost - progress;

      -- Transparency!
      WriteToLog("Culture needed for finish: "..cultureNeededForFinish);

      -- The beautiful result of our very complex calculation!
      return cultureNeededForFinish;
  	end
  end

  WriteToLog("No civic to finish here, move along");
  return 0;
end

-- Fetch a city`s owners stockpile of a resource
function getStrategicResourceStockpileOfCityOwner(city, resourceType)
  -- But only with real cities
  if city ~= nil then
    -- Variables stuff
    local cityId = city:GetID();
    local ownerId = city:GetOwner();
    local player = Players[ownerId];
    return getStrategicResourceStockpileOfPlayer(player, resourceType);
  end

  return 0;
end

-- Fetch a players`s stockpile of a resource
function getStrategicResourceStockpileOfPlayer(player, resourceType)
  -- But only with players
  if player ~= nil then
    -- Variables stuff
    local playerResources = player:GetResources();

    -- Loop the games resources
    for resource in GameInfo.Resources() do
      -- We are interessted in strategics
  	  if resource.ResourceClassType == "RESOURCECLASS_STRATEGIC" then
        -- And from that only the requested resource!
        if resource.ResourceType == resourceType then
          -- Fetch the stockpile of the player, and the current production state
          return playerResources:GetResourceAmount(resource.ResourceType);
        end
  	  end
  	end
  end

  return 0;
end

-- Helper to check if the player mets an era
function hasRequiredEra(player, era)
  local pEraIndex = getPlayerEraIndex(player:GetID());
  return (pEraIndex >= era);
end

-- Helper to get current player era
function getPlayerEraIndex(playerId)
  local player = Players[playerId];
  return GameInfo.Eras[player:GetEra()].ChronologyIndex;
end

-- Checks if the player is an AI civ
function isAI(player)
  if player == nil then
    return false
  end

  return (not player:IsHuman() and not player:IsBarbarian() and player:IsMajor() and player:IsAlive());
end

-- Get the game-speed multipler for scaling purpose
function getGameSpeedMultiplier()
  local gameSpeedType = GameConfiguration.GetGameSpeedType();
  local speedCostMultiplier = GameInfo.GameSpeeds[gameSpeedType].CostMultiplier;
  return (speedCostMultiplier / 100);
end

-- Rounding numbers helper
function roundNumber(num, numDecimalPlaces)
  if numDecimalPlaces and numDecimalPlaces > 0 then
    local mult = 10^numDecimalPlaces
    return math.floor(num * mult + 0.5) / mult
  end
  return math.ceil(num + 0.5)
end

-- Convert a absolute number to a game-speed-scaled version
function scaleWithGameSpeed(number)
  return roundNumber((number * getGameSpeedMultiplier()), 1);
end

-- Debug function for logging
function WriteToLog(message)
	if (debugMode and message ~= nil) then
		print(message);
	end
end
