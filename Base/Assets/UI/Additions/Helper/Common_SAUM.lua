-- ================================================
--	StillAUsefulMaterial Helper
-- ================================================

-- Debugging mode switch
local debugMode = true;

-- Helper to check if a city is currently producing something
function isCityProducing(city)
  return (getProductionAmountNeededForCompletion(city) ~= 0);
end

-- Helper to determine how much production is needed for completion
function getProductionAmountNeededForCompletion(pCity)
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
function isPlayerResearching(player)
  return (getScienceAmountNeededForCompletion(player) > 0);
end

-- Helper to determine how much science is needed for completion
function getScienceAmountNeededForCompletion(player)
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
function isPlayerDevelopingCulture(player)
  return (getCultureAmountNeededForCompletion(player) > 0);
end

-- Helper to determine how much culture is needed for completion
function getCultureAmountNeededForCompletion(player)
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
  local pEra = GameInfo.Eras[player:GetEra()];
  return (pEra.ChronologyIndex >= era);
end

-- Debug function for logging
function WriteToLog(message)
	if (debugMode and message ~= nil) then
		print(message);
	end
end
