-- ================================================
--	StillAUsefulMaterial Iron
-- ================================================

-- Includes
include("Civ6Common");
include("CitySupport");
include("InstanceManager");
include("Common_SAUM.lua");

-- Configuration
local MIN_AMOUNT_FOR_BOOST = 25; -- Amount of iron that is required before the button shows up (25)
local MIN_ERA_INDEX = 4;         -- After reaching the "Renaissance"-era the button shows up (4)
local AI_THESHOLD = 10;          -- This amount the AI never uses for boosting
local AI_ADD_ERA = 0;            -- This many era later the uses this boosting
local BOOST_RATIO_INCREMENT_PER_ERA = 0.35;  -- Additional multipler based on 1:1
local BOOST_RATIO_BASE_MULTIPLIER = 1.15;      -- Base multipler for the hardcoded 1:1 ratio
local RESOURCE_ID_IRON = 43;

-- Mirrored in ProductionPanel
local LISTMODE = {PRODUCTION = 1, PURCHASE_GOLD = 2, PURCHASE_FAITH = 3, PROD_QUEUE = 4};

-- Create an instance of our button
local ironMaterialBoostButtonIM = InstanceManager:new("IronProductionBoostInstance", "IronProductionBoostButton", Controls.IronProductionBoostStack);

-- Variables for handling
local boostedThisTurn = false;
local selectedCity = nil;
local notifyIfReady = true;

-- Create the button
function createIronMaterialBoostButton()
  -- Inform us!
  WriteToLog("Create material boost button!");

  -- Freshen up the button
	ironMaterialBoostButtonIM:ResetInstances();
	local ironProductionBoostInstance = ironMaterialBoostButtonIM:GetInstance();

  -- Default tooltip
  local tooltip = "ERROR_TOOLTIP_NOT_SET";

  -- State-dependent tooltip
  if boostedThisTurn then
    tooltip = Locale.Lookup("LOC_STILLAUSEFULMATERIAL_IRON_BOOSTED_TOOLTIP");
  elseif not isCityProducing(selectedCity:GetOwner(), selectedCity:GetID()) then
    tooltip = Locale.Lookup("LOC_STILLAUSEFULMATERIAL_NO_PRODUCTION_TOOPTIP");
  else
    -- Default value
    local ironAmountToConsume = 0;
    local productionToBeCompleted = 0;

    -- Fetch values for calculating numbers
    local resourceStockpile = getStrategicResourceStockpileOfCityOwner(selectedCity, "RESOURCE_IRON");
    local requiredProductionNeeded = getProductionAmountNeededForCompletion(selectedCity:GetOwner(), selectedCity:GetID());

    -- Do some very complex math...
    if requiredProductionNeeded <= scaleWithGameSpeed(resourceStockpile * getEraIncrementModifier()) then
      ironAmountToConsume = (requiredProductionNeeded / scaleWithGameSpeed(resourceStockpile * getEraIncrementModifier())) * resourceStockpile;
      productionToBeCompleted = requiredProductionNeeded;
    else
      ironAmountToConsume = resourceStockpile;
      productionToBeCompleted = scaleWithGameSpeed(resourceStockpile * getEraIncrementModifier());
    end
    -- ...done

    -- Set our tooltip
    tooltip = Locale.Lookup("LOC_STILLAUSEFULMATERIAL_IRON_UNBOOSTED_TOOLTIP", math.ceil(ironAmountToConsume), roundNumber(productionToBeCompleted, 0));
  end

  -- Set the disabled state
  local isDisabled = (not isCityProducing(selectedCity:GetOwner(), selectedCity:GetID()) or boostedThisTurn);

	-- Set button data and action handler
	ironProductionBoostInstance.IronProductionBoostButton:SetDisabled(isDisabled);
	ironProductionBoostInstance.IronProductionBoostIcon:SetAlpha((isDisabled and 0.65) or 1);
	ironProductionBoostInstance.IronProductionBoostButton:SetToolTipString(tooltip);

  -- Callback function
	ironProductionBoostInstance.IronProductionBoostButton:RegisterCallback(Mouse.eLClick,
		function(void1, void2)
      -- Our callback plays sound, boost and refreshens the button
			UI.PlaySound("Play_UI_Click");

      -- Execute the boost
      boostProductionInCityWithIron(selectedCity:GetOwner(), selectedCity:GetID());

      -- Memorize state
      boostedThisTurn = true;

      -- Refresh the button in "used"-state
      refreshIronMaterialBoostButton();

      -- Re-enable notification
      notifyIfReady = true;
		end
	);
end

-- Attach our button to the production-panel, where it resides
function attachIronMaterialBoostBotton()
  -- Log me a message darling
  WriteToLog("Attaching iron material boost button...");

  -- City is real?
  if selectedCity ~= nil then
    local localPlayer = Players[Game.GetLocalPlayer()];

    -- If is possible to attach, we will see
    if isBoostWithIronPossible(localPlayer:GetID()) or boostedThisTurn then
      -- Create the button
      createIronMaterialBoostButton();

      -- Get ui control where we wanna add our button to
      local ScrollToButtonContainer = ContextPtr:LookUpControl("/InGame/ProductionPanel/ScrollToButtonContainer");

      -- There should only be a single child!
      if ScrollToButtonContainer:GetNumChildren() == 1 then
        -- Who are your children?
        local ScrollToButtonContainerChildren = ScrollToButtonContainer:GetChildren();

        -- We need a children to be there, else we have an issue!
    		if ScrollToButtonContainerChildren ~= nil then

          -- Loop the (one) children XD
    			for i,ScrollToButtonContainerChild in ipairs(ScrollToButtonContainerChildren) do
            -- Rebase our ui-button to the new parent
            Controls.IronProductionBoostStack:ChangeParent(ScrollToButtonContainerChild);

            -- Recalculate the stack to show our button properly
            ScrollToButtonContainerChild:CalculateSize();
            ScrollToButtonContainerChild:ReprocessAnchoring();
          end

          -- Log me another message darling
          WriteToLog("...Attached!");
        else
          -- What happened?
          WriteToLog("ERROR: Not able to attach the boost-iron button!");
        end
      else
        -- What happened?
        WriteToLog("ERROR: Unexpected children count on ui-control!");
      end
    else
      -- Log me a message darling
      WriteToLog("...not attached!");
  	end
  else
    -- Log me a third message baby
    WriteToLog("...no city selected!");
	end
end

-- Remove our button
function detachIronMaterialBoostButton()
  ironMaterialBoostButtonIM:DestroyInstances();
  WriteToLog("Detached material boost button!");
end

-- Helper to check if a player is able to use the boost
function isBoostWithIronPossible(playerId)
  -- Fetch the player
  local player = Players[playerId];

  -- AI amendments
  local minEraForBoost = ((isAI(player) and (MIN_ERA_INDEX + AI_ADD_ERA)) or MIN_ERA_INDEX);

  -- He need to be in the right era!
  if hasRequiredEra(player, minEraForBoost) then
    local playerResources = player:GetResources();

    -- He wil need iron to make it work!
    for resource in GameInfo.Resources() do
      if (resource.ResourceClassType == "RESOURCECLASS_STRATEGIC") then
        if resource.ResourceType == "RESOURCE_IRON" then
          -- Get the players stock
          local ironStockpileAmount = playerResources:GetResourceAmount(resource.ResourceType);

          -- AI amendments
          local minAmountForBoost = ((isAI(player) and (MIN_AMOUNT_FOR_BOOST + AI_THESHOLD)) or MIN_AMOUNT_FOR_BOOST);

          -- If enough iron is present, allow him to boost!
          if ironStockpileAmount >= minAmountForBoost then
            -- I wanna know what happens there!
            WriteToLog("Boost with iron is possible for player: "..player:GetID()..", with iron: "..ironStockpileAmount);
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

-- Refresh out button on the UI
function refreshIronMaterialBoostButton()
  detachIronMaterialBoostButton();
  attachIronMaterialBoostBotton();
end

-- The actual production boost action takes place here
function boostProductionInCityWithIron(ownerId, cityId)
  -- Fetch the city
  local city = CityManager.GetCity(ownerId, cityId);

  -- But only with real cities
  if city ~= nil then
    -- Variables stuff
    local cityId = city:GetID();
    local ownerId = city:GetOwner();

    -- Fetch the stockpile of the player, and the current production state
    local resourceStockpile = getStrategicResourceStockpileOfCityOwner(city, "RESOURCE_IRON");
    local requiredProductionNeeded = getProductionAmountNeededForCompletion(city:GetOwner(), city:GetID());

    -- Calc variable
    local substractedMaterial = 0;

    -- In case we have more iron that it would cost, complete it!
    -- And save some precious iron
    if requiredProductionNeeded <= scaleWithGameSpeed(resourceStockpile * getEraIncrementModifier()) then
      -- Game-event callback to add production, substract resource equal to production-cost
    	UI.RequestPlayerOperation(Game.GetLocalPlayer(), PlayerOperations.EXECUTE_SCRIPT, {
        OnStart = "CompleteProduction",
        ownerId = ownerId,
        cityId = cityId
      });

      -- Subtract amount
      substractedMaterial = math.ceil((requiredProductionNeeded / scaleWithGameSpeed(resourceStockpile * getEraIncrementModifier())) * resourceStockpile);

      -- Logging logging logging
      WriteToLog("FINISHed production with: "..substractedMaterial.." / "..requiredProductionNeeded);
    else
    	-- Game-event callback to add production, substract resource equal to production-cost
    	UI.RequestPlayerOperation(Game.GetLocalPlayer(), PlayerOperations.EXECUTE_SCRIPT, {
        OnStart = "AddToProduction",
        ownerId = ownerId,
        cityId = cityId,
        amount = scaleWithGameSpeed(resourceStockpile * getEraIncrementModifier())
      });

      -- Subtract amount
      substractedMaterial = resourceStockpile;

      -- Logging logging logging
      WriteToLog("BOOSTed production with: "..substractedMaterial.." / "..scaleWithGameSpeed(resourceStockpile * getEraIncrementModifier()));
    end

    -- Game-event callback to change resource-count on player
    UI.RequestPlayerOperation(Game.GetLocalPlayer(), PlayerOperations.EXECUTE_SCRIPT, {
      OnStart = "ChangeResourceAmount",
      playerId = ownerId,
      resourceIndex = GameInfo.Resources["RESOURCE_IRON"].Index,
      amount = -substractedMaterial
    });
  else
    -- Also here we do our logging :)
    WriteToLog("BOOST not possible, no city selected!");
  end
end

function getEraIncrementModifier()
  return BOOST_RATIO_BASE_MULTIPLIER + getBoostIncrementedValue(MIN_ERA_INDEX, BOOST_RATIO_INCREMENT_PER_ERA);
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

        -- Attach our boost-button via refresh
        refreshIronMaterialBoostButton();
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

        -- ...because we need to refresh the damn UI
        refreshIronMaterialBoostButton();
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
    -- ...to know which city we might boos with our button
    selectedCity = pCity;

    -- ...because we need to refresh the damn UI
    refreshIronMaterialBoostButton();
  end
end

-- Thinigs that happen when the local player turn starts
function OnLocalPlayerTurnBegin()
  -- Who are we?
  local localPlayer = Players[Game.GetLocalPlayer()];

  -- Reset boosted stat
  boostedThisTurn = false;

  -- Button not needed here
  detachIronMaterialBoostButton();

  -- Notify the player
  if notifyIfReady and isBoostWithIronPossible(localPlayer:GetID()) then
    -- Send notification
    notify(
      localPlayer:GetID(),
      Locale.Lookup("LOC_SAUM_BOOST_READY_HEADLINE"),
      Locale.Lookup("LOC_SAUM_BOOST_READY_CONTENT")
    );

    -- Prevent spam
    notifyIfReady = false;
  end

  -- We need to know everything
  WriteToLog("Turn begins, boosted value has been reset!");
end

-- Get triggered on player resource changes
function OnPlayerResourceChanged(playerId, resourceTypeId)
  -- Local player niter amount changed...
  if playerId == Game.GetLocalPlayer() and resourceTypeId == RESOURCE_ID_IRON then  -- Iron
    -- Notify if needed
    if not boostedThisTurn and notifyIfReady and isBoostWithIronPossible(playerId) then
      -- Send notification
      notify(
        playerId,
        Locale.Lookup("LOC_SAUM_BOOST_READY_HEADLINE"),
        Locale.Lookup("LOC_SAUM_BOOST_READY_CONTENT")
      );

      -- Prevent spam
      notifyIfReady = false;
    end
  end
end

-- Initialization stuffs
function Initialize()
  -- Exposed member callbacks
  ExposedMembers.SAUM_Iron_IsCityOccupied = isCityOccupied;
  ExposedMembers.SAUM_Iron_IsCityProducing = isCityProducing;
  ExposedMembers.SAUM_Iron_IsBoostWithIronPossible = isBoostWithIronPossible;
  ExposedMembers.SAUM_Iron_GetProductionAmountNeededForCompletion = getProductionAmountNeededForCompletion;

  -- Listen to when production tabs get changed
  LuaEvents.ProductionPanel_ListModeChanged.Add(OnProductionPanelListModeChanged);

  -- Events we want to hook into for refreshing the UI
  Events.CityProductionQueueChanged.Add(OnCityProductionQueueChanged);
  Events.CitySelectionChanged.Add(OnCitySelectionChanged);

  -- Trigger a boosting reset and UI handling
  Events.LocalPlayerTurnBegin.Add(OnLocalPlayerTurnBegin);

  -- Listen to resource changes
  Events.PlayerResourceChanged.Add(OnPlayerResourceChanged);

  -- Hmm... what might this be good for?
  print("Initialize");
end

-- GOGOGO!
Initialize();
