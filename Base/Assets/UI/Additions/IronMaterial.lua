-- ================================================
--	StillAUsefulMaterial Iron
-- ================================================

-- Includes
include("Civ6Common");
include("CitySupport");
include("InstanceManager");

-- Debugging mode switch
local debugMode = true;

-- Configuration
local MIN_AMOUNT_FOR_BOOST = 25; -- Amount of iron that is required before the button shows up
local MIN_ERA_INDEX = 4;         -- After reaching the "Renaissance"-era the button shows up

-- Mirrored in ProductionPanel
local LISTMODE = {PRODUCTION = 1, PURCHASE_GOLD = 2, PURCHASE_FAITH = 3, PROD_QUEUE = 4};

-- Create an instance of our button
local ironMaterialBoostButtonIM = InstanceManager:new("IronProductionBoostInstance", "IronProductionBoostButton", Controls.IronProductionBoostStack);

-- Variables for handling
local boostedThisTurn = false;
local selectedCity = nil;

-- Create the button
function CreateMaterialBoostButton()
  -- Inform us!
  WriteToLog("Create material boost button");

  -- Freshen up the button
	ironMaterialBoostButtonIM:ResetInstances();
	local ironProductionBoostInstance = ironMaterialBoostButtonIM:GetInstance();

  -- Produce our iron icon
  local iconTable = {};
  iconTable.textureOffsetX, iconTable.textureOffsetY, iconTable.textureSheet = IconManager:FindIconAtlasNearestSize("ICON_RESOURCE_IRON", 38);
  ironProductionBoostInstance.IronProductionBoostIcon:SetTexture(iconTable.textureOffsetX, iconTable.textureOffsetY, iconTable.textureSheet);
  ironProductionBoostInstance.IronProductionBoostIcon:SetSizeVal(38, 38);

  -- Default tooltip
  local tooltip = Locale.Lookup("LOC_STILLAUSEFULMATERIAL_IRON_UNBOOSTED_TOOLTIP");

  -- State-dependant tooltip
  if boostedThisTurn then
    tooltip = Locale.Lookup("LOC_STILLAUSEFULMATERIAL_IRON_BOOSTED_TOOLTIP");
  elseif not isCityProducing(selectedCity) then
    tooltip = Locale.Lookup("LOC_STILLAUSEFULMATERIAL_NO_PRODUCTION_TOOPTIP");
  end

  -- Set the disabled state
  local isDisabled = (not isCityProducing(selectedCity) or boostedThisTurn);

	-- Set button data and action handler
	ironProductionBoostInstance.IronProductionBoostButton:SetDisabled(isDisabled);
	ironProductionBoostInstance.IronProductionBoostIcon:SetAlpha((isDisabled and 0.5) or 1);
	ironProductionBoostInstance.IronProductionBoostGear:SetAlpha((isDisabled and 0.5) or 1);
	ironProductionBoostInstance.IronProductionBoostButton:SetToolTipString(tooltip);
	ironProductionBoostInstance.IronProductionBoostButton:RegisterCallback(Mouse.eLClick,
		function(void1, void2)
      -- Our callback plays sound, boost and refreshens the button
			UI.PlaySound("Play_UI_Click");
      boostProductionInCity(selectedCity);
      boostedThisTurn = true;
      refreshMaterialBoostButton();
		end
	);
end

-- Attach our button to the production-panel, where it resides
function attachMaterialBoostBotton()
  if selectedCity ~= nil then
    local localPlayer = Players[Game.GetLocalPlayer()];

    -- If is possible to attach, we will see
    if isBoostWithIronPossible(localPlayer) or boostedThisTurn then
      CreateMaterialBoostButton();

      -- Within the top-stack, top-stack for a top-buton :)
      local currentTopStack = ContextPtr:LookUpControl("/InGame/ProductionPanel/TopStack");

      -- Top-stack isnt just a myth?
    	if currentTopStack ~= nil then
        -- We parented it :)
    		Controls.IronProductionBoostStack:ChangeParent(currentTopStack);

        -- We are now an official child
        currentTopStack:AddChildAtIndex(Controls.IronProductionBoostStack, 1);
    		currentTopStack:CalculateSize();
    		currentTopStack:ReprocessAnchoring();

        -- What happened?
        WriteToLog("Attached material boost button");
    	end
  	end
	end
end

-- Remove our button
function detachMaterialBoostButton()
  ironMaterialBoostButtonIM:DestroyInstances();
  WriteToLog("Detached material boost button");
end

-- Helper to check if a player is able to use the boost
function isBoostWithIronPossible(player)
  -- He need to be in the right era!
  if hasRequiredEra(player) then
    local playerResources = player:GetResources();

    -- He wil need iron to make it work!
    for resource in GameInfo.Resources() do
      if (resource.ResourceClassType == "RESOURCECLASS_STRATEGIC") then
        if resource.ResourceType == "RESOURCE_IRON" then
            local ironStockpileAmount = playerResources:GetResourceAmount(resource.ResourceType);

            -- If enough iron is present, allow him to boost!
            if ironStockpileAmount >= MIN_AMOUNT_FOR_BOOST then
              -- I wanna know what happens there!
              WriteToLog("Boost with iron is possible for player: "..player:GetID());
              return true;
            end

            break;
        end
      end
    end
  end

  -- Transparency!
  WriteToLog("Boost with iron is NOT possible for player: "..player:GetID());
  return false;
end

-- Helper to check if the player mets an era
function hasRequiredEra(player)
  local pEra = GameInfo.Eras[player:GetEra()];
  return (pEra.ChronologyIndex >= MIN_ERA_INDEX);
end

-- Refresh out button on the UI
function refreshMaterialBoostButton()
  detachMaterialBoostButton();
  attachMaterialBoostBotton();
end

-- The actual production boost action takes place here
function boostProductionInCity(city)
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
        -- And from that only iron!
        if resource.ResourceType == "RESOURCE_IRON" then
          -- Fetch the stockpile of the player, and the current production state
          local resourceStockpile = playerResources:GetResourceAmount(resource.ResourceType);
          local requiredProductionNeeded = getProductionAmountNeededForCompletion(city);

          local substractedMaterial = 0;

          -- In case we have more iron that it would cost, complete it!
          -- And save some precious iron
          if requiredProductionNeeded <= resourceStockpile then
            -- Finish production, substract resource equl production-cost
            ExposedMembers.MOD_StillAUsefulMaterial.CompleteProduction(ownerId, cityId);
            substractedMaterial = requiredProductionNeeded;
          else
            -- Add to production, substract entire resources
            ExposedMembers.MOD_StillAUsefulMaterial.AddToProduction(ownerId, cityId, resourceStockpile);
            substractedMaterial = resourceStockpile;
          end

          -- Here we call out big brother for help!
          ExposedMembers.MOD_StillAUsefulMaterial.ChangeResourceAmount(ownerId, resource.Index, -substractedMaterial);
          break;
        end
  	  end
  	end

    -- Logging logging logging
    WriteToLog("BOOST production in city: "..city:GetID());
  else
    -- Also here we do our logging :)
    WriteToLog("BOOST not possible, no city selected!");
  end
end

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

-- Tabs get changed on the production-panel
function OnProductionPanelListModeChanged(listMode)
  WriteToLog("Changed production-panel list-mode to: "..listMode)

  -- Get the active city from the ui
  selectedCity = UI.GetHeadSelectedCity();

  -- If the player own it, we want to attach our button
  if selectedCity:GetOwner() == Game.GetLocalPlayer() then
    WriteToLog("City owned by local player!");

    -- Only attach the button on the production tabs
    if (listMode == LISTMODE.PRODUCTION or listMode == LISTMODE.PROD_QUEUE) then
      Controls.IronProductionBoostStack:SetHide(false);

      -- UI Instance, get it, now!
      local uiProductionPanel = ContextPtr:LookUpControl("/InGame/ProductionPanel");

      -- If its there and visible...
      if uiProductionPanel and not uiProductionPanel:IsHidden() then
        local localPlayerID = Game.GetLocalPlayer();
        local localPlayer = Players[localPlayerID];

        -- Attach our boost-button
        attachMaterialBoostBotton();
      end
    else
      WriteToLog("Hide the boost button (no production-tab selected)!");
      Controls.IronProductionBoostStack:SetHide(true);
    end
  end
end

-- Listen to city-selection changes...
function OnCitySelectionChanged(ownerId, cityId, i, j, k, isSelected, isEditable)
  selectedCity = nil;

  local localPlayerId = Game.GetLocalPlayer();

	if ownerId == localPlayerId and isSelected then
    local localPlayer = Players[localPlayerId];

    for _, pCity in localPlayer:GetCities():Members() do
      if cityId == pCity:GetID() then
        -- ...to know which city we might boos with our button
        selectedCity = pCity;
        break;
      end
    end
	end
end

-- Listen to production-queue changes...
function OnCityProductionQueueChanged(playerId, cityId, changeType, queueIndex)
	if playerId ~= Game.GetLocalPlayer() then
		return;
	end

  local localPlayer = Players[playerId];
  pCity = localPlayer:GetCities():FindID(cityId);

  if pCity ~= nil then
    selectedCity = pCity;

    -- ...because we need to refresh the damn UI
    refreshMaterialBoostButton();
  end
end

-- Thinigs that happen when the turn starts
function OnTurnBegin()
  -- Reset boosted stat
  boostedThisTurn = false;

  -- Button not needed here
  detachMaterialBoostButton();

  -- We need to know everything
  WriteToLog("Turn begins, boosted value has been reset!");

  -- Its AIs turn to boost baby!
  TakeAIActions();
end

-- AIs will also get a boost if they can afford it
-- TODO: Implement descision-making for more intelligent boosting, eg.
--       if military production exist, boost that instead of a settler.
function TakeAIActions()
  WriteToLog("AIs boosting begun!");

  -- Get alive players (only major civs)
	local players = Game.GetPlayers{Alive = true, Major = true};

  -- Memorize old values
  local MIN_AMOUNT_FOR_BOOST_BAK = MIN_AMOUNT_FOR_BOOST;
  local MIN_ERA_INDEX_BAK = MIN_ERA_INDEX;

  -- AI does to all this a bit later, we dont wanna criple it
  MIN_AMOUNT_FOR_BOOST = MIN_AMOUNT_FOR_BOOST + 10; -- Tweaked amount for AI
  MIN_ERA_INDEX = MIN_ERA_INDEX + 0;                -- Tweaked era for AI (disabled atm, needs more testing)

	-- Player is real?
	for _, player in ipairs(players) do
    -- Is the player an AI?
    if (player ~= nil and not player:IsHuman() and not player:IsBarbarian()) then
      -- Is boostint possible for this player?
      if isBoostWithIronPossible(player) then
        local pCities = player:GetCities();

        -- Loop the player cities
        for _, pCity in pCities:Members() do
          if isCityProducing(pCity) then
            -- Boost the AI´s city
            boostProductionInCity(pCity);

            -- Logging to make clear what the AI is getting
            local AIPlayerConfiguration = PlayerConfigurations[player:GetID()];
            WriteToLog("AI ("..AIPlayerConfiguration:GetLeaderName()..") boosted in city: "..pCity:GetName());
            break;
          end
        end
      end
    end
	end

  MIN_AMOUNT_FOR_BOOST = MIN_AMOUNT_FOR_BOOST_BAK;
  MIN_ERA_INDEX = MIN_ERA_INDEX_BAK;
end

-- Debug function for logging
function WriteToLog(message)
	if (debugMode and message ~= nil) then
		print(message);
	end
end

-- Initialization stuffs
function Initialize()
  -- Listen to when production tabs get changed
  LuaEvents.ProductionPanel_ListModeChanged.Add(OnProductionPanelListModeChanged);

  -- Events we want to hook into for refreshing the UI
  Events.CityProductionQueueChanged.Add(OnCityProductionQueueChanged);
  Events.CitySelectionChanged.Add(OnCitySelectionChanged);

  -- Trigger a boosting reset and the AI handling
  Events.TurnBegin.Add(OnTurnBegin);

  -- Hmm... what might this be good for?
  print("Initialize");
end

-- GOGOGO!
Initialize();
