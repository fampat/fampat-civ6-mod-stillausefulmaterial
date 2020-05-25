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

-- Fetch a city`s owners stockpile of a resource
function getStrategicResourceStockpileOfCityOwner(city, resourceType)
  -- But only with real cities
  if city ~= nil then
    -- Variables stuff
    local cityId = city:GetID();
    local ownerId = city:GetOwner();
    local player = Players[ownerId];
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

-- Debug function for logging
function WriteToLog(message)
	if (debugMode and message ~= nil) then
		print(message);
	end
end
