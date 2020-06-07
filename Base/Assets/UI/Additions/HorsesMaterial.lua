-- ================================================
--	StillAUsefulMaterial Horses
-- ================================================

-- Includes
include("Civ6Common");
include("CitySupport");
include("InstanceManager");
include("Common_SAUM.lua");

-- Configuration
local MIN_AMOUNT_FOR_BOOST = 25; -- Amount of horses that is required before the button shows up (25)
local MIN_ERA_INDEX = 6;         -- After reaching the "Modern"-era the button shows up (6)
local AI_THESHOLD = 10;          -- This amount the AI never uses for boosting
local AI_ADD_ERA = 0;            -- This many era later the uses this boosting
local BOOST_RATIO_INCREMENT_PER_ERA = 0.85;  -- Additional multipler based on 1:1
local BOOST_RATIO_BASE_MULTIPLIER = 2.15;      -- Base multipler for the hardcoded 1:1 ratio
local RESOURCE_ID_HORSES = 42;

-- Variables for handling
local boostedThisTurn = false;
local civicCompleted = false;
local notifyIfReady = true;

-- Create an instance of our button
local horsesMaterialBoostButtonIM = InstanceManager:new("HorsesCultureBoostInstance", "HorsesCultureBoostButton", Controls.HorsesCultureBoostStack);

-- Create the button
function createHorsesMaterialBoostButton()
  -- Get us the local player id
  local localPlayerId = Game.GetLocalPlayer();

  -- Check for local player
  if localPlayerId ~= nil then
    local player = Players[localPlayerId];

    -- Inform us!
    WriteToLog("Create material boost button!");

    -- Freshen up the button
  	horsesMaterialBoostButtonIM:ResetInstances();
  	local horsesCultureBoostInstance = horsesMaterialBoostButtonIM:GetInstance();

    -- Default tooltip
    local tooltip = "ERROR_TOOLTIP_NOT_SET";

    -- State-dependent tooltip
    if boostedThisTurn then
      tooltip = Locale.Lookup("LOC_STILLAUSEFULMATERIAL_HORSES_BOOSTED_TOOLTIP");
    elseif (not isPlayerDevelopingCulture(localPlayerId) or civicCompleted) then
      tooltip = Locale.Lookup("LOC_STILLAUSEFULMATERIAL_NO_RESEARCH_TOOPTIP");
    else
      -- Default value
      local horsesAmountToConsume = 0;
      local cultureToBeCompleted = 0;

      -- Fetch values for calculating numbers
      local resourceStockpile = getStrategicResourceStockpileOfPlayer(player, "RESOURCE_HORSES");
      local requiredCultureNeeded = getCultureAmountNeededForCompletion(localPlayerId);

      -- Do some very complex math...
      if requiredCultureNeeded <= scaleWithGameSpeed(resourceStockpile * getEraIncrementModifier()) then
        horsesAmountToConsume = (requiredCultureNeeded / scaleWithGameSpeed(resourceStockpile * getEraIncrementModifier())) * resourceStockpile;
        cultureToBeCompleted = requiredCultureNeeded;
      else
        horsesAmountToConsume = resourceStockpile;
        cultureToBeCompleted = scaleWithGameSpeed(resourceStockpile * getEraIncrementModifier());
      end
      -- ...done

      -- Set our tooltip
      tooltip = Locale.Lookup("LOC_STILLAUSEFULMATERIAL_HORSES_UNBOOSTED_TOOLTIP", math.ceil(horsesAmountToConsume), roundNumber(cultureToBeCompleted, 0));
    end

    -- Set the disabled state
    local isDisabled = (not isPlayerDevelopingCulture(localPlayerId) or civicCompleted or boostedThisTurn);

  	-- Set button data and action handler
  	horsesCultureBoostInstance.HorsesCultureBoostButton:SetDisabled(isDisabled);
  	horsesCultureBoostInstance.HorsesCultureBoostIcon:SetAlpha((isDisabled and 0.65) or 1);
  	horsesCultureBoostInstance.HorsesCultureBoostButton:SetToolTipString(tooltip);

    -- Callback function
  	horsesCultureBoostInstance.HorsesCultureBoostButton:RegisterCallback(Mouse.eLClick,
  		function(void1, void2)
        -- Our callback plays sound, boost and refreshens the button
  			UI.PlaySound("Play_UI_Click");

        -- Execute the boost
        boostCultureWithHorses(player);

        -- Memorize state
        boostedThisTurn = true;

        -- Refresh the button in "used"-state
        refreshHorsesMaterialBoostButton();
  		end
  	);
  end
end

-- Refresh out button on the UI
function refreshHorsesMaterialBoostButton()
  detachHorsesMaterialBoostButton();
  attachHorsesMaterialBoostBotton();
end

-- Attach our button to the culture-panel
function attachHorsesMaterialBoostBotton()
  -- Log me a message darling
  WriteToLog("Attaching horses material boost button...");

  -- Get the local player
  local localPlayer = Players[Game.GetLocalPlayer()];

  -- Player is real?
  if localPlayer ~= nil then
    -- If is possible to attach, we will see
    if isBoostWithHorsesPossible(localPlayer:GetID()) or boostedThisTurn then
      -- Notify the player
      if notifyIfReady then
        -- Send notification
        notify(
          localPlayer:GetID(),
          Locale.Lookup("LOC_SAUM_BOOST_READY_HEADLINE"),
          Locale.Lookup("LOC_SAUM_BOOST_READY_CONTENT")
        );

        -- Prevent spam
        notifyIfReady = false;
      end

      -- Create the button
      createHorsesMaterialBoostButton();

      -- Get ui control where we wanna add our button to
      local buttonStack = ContextPtr:LookUpControl("/InGame/LaunchBar/ButtonStack");

      -- There should only be a single child!
      if buttonStack ~= nil then
        -- Rebase our ui-button to the new parent
        Controls.HorsesCultureBoostStack:ChangeParent(buttonStack);

        -- Fetch the stacks children
        local buttonStackChildren = buttonStack:GetChildren();

        -- Default stack culture button index
        local buttonStackCultureIndex = 2;

        -- Loop the stacks children
        for buttonStackChildrenIndex, buttonStackChildren in pairs(buttonStackChildren) do
            -- Watch out for the culture button
            if buttonStackChildren:GetID() == "CultureButton" then
              -- Found it
              buttonStackCultureIndex = buttonStackChildrenIndex;
              break;
            end
        end

        -- Attach at specified index after culture button
        buttonStack:AddChildAtIndex(Controls.HorsesCultureBoostStack, buttonStackCultureIndex);

        -- Call a refresh on the launch-bar size
        LuaEvents.RefreshLaunchBar();

        -- Log me another message darling
        WriteToLog("...Attached!");
      else
        -- What happened?
        WriteToLog("ERROR: No ui-control!");
      end
    else
      -- Log me a message darling
      WriteToLog("...not attached!");
  	end
  else
    -- Log me a third message baby
    WriteToLog("...no player selected!");
	end
end

-- Remove our button
function detachHorsesMaterialBoostButton()
  horsesMaterialBoostButtonIM:DestroyInstances();
  WriteToLog("Detached material boost button!");
end

-- The actual culture boost action takes place here
function boostCultureWithHorses(player)
  -- But only with real player
  if player ~= nil then
    local playerId = player:GetID();
    local localPlayer = Game.GetLocalPlayer();

    -- Fetch the stockpile of the player, and the current production state
    local resourceStockpile = getStrategicResourceStockpileOfPlayer(player, "RESOURCE_HORSES");
    local requiredCultureNeeded = getCultureAmountNeededForCompletion(playerId);

    -- Calc variable
    local substractedMaterial = 0;

    -- In case we have more horses that it would cost, complete it!
    -- And save some precious horses
    if requiredCultureNeeded <= scaleWithGameSpeed(resourceStockpile * getEraIncrementModifier()) then
      -- Game-event callback to add civic, substract resource equal to production-cost
    	UI.RequestPlayerOperation(localPlayer, PlayerOperations.EXECUTE_SCRIPT, {
        OnStart = "AddToCivic",
        playerId = playerId,
        amount = requiredCultureNeeded
      });

      -- Subtract amount
      substractedMaterial = math.ceil((requiredCultureNeeded / scaleWithGameSpeed(resourceStockpile * getEraIncrementModifier())) * resourceStockpile);

      -- Logging logging logging
      WriteToLog("FINISHed culture with: "..substractedMaterial.." / "..requiredCultureNeeded);
    else
      -- Game-event callback to add culture, substract resource equal to production-cost
    	UI.RequestPlayerOperation(localPlayer, PlayerOperations.EXECUTE_SCRIPT, {
        OnStart = "AddToCivic",
        playerId = playerId,
        amount = scaleWithGameSpeed(resourceStockpile * getEraIncrementModifier())
      });

      -- Subtract amount
      substractedMaterial = resourceStockpile;

      -- Logging logging logging
      WriteToLog("BOOSTed culture with: "..substractedMaterial.." / "..scaleWithGameSpeed(resourceStockpile * getEraIncrementModifier()));
    end

    -- Game-event callback to change resource-count on player
    UI.RequestPlayerOperation(localPlayer, PlayerOperations.EXECUTE_SCRIPT, {
      OnStart = "ChangeResourceAmount",
      playerId = playerId,
      resourceIndex = GameInfo.Resources["RESOURCE_HORSES"].Index,
      amount = -substractedMaterial
    });
  else
    -- Also here we do our logging :)
    WriteToLog("BOOST not possible, no player selected!");
  end
end

-- Helper to check if a player is able to use the boost
function isBoostWithHorsesPossible(playerId)
  local player = Players[playerId];

  -- AI amendments
  local minEraForBoost = ((isAI(player) and (MIN_ERA_INDEX + AI_ADD_ERA)) or MIN_ERA_INDEX);

    -- He need to be in the right era!
  if hasRequiredEra(player, MIN_ERA_INDEX) then
    local playerResources = player:GetResources();

    -- He will need horses to make it work!
    for resource in GameInfo.Resources() do
      if (resource.ResourceClassType == "RESOURCECLASS_STRATEGIC") then
        if resource.ResourceType == "RESOURCE_HORSES" then
          -- Get the players stock
          local horsesStockpileAmount = playerResources:GetResourceAmount(resource.ResourceType);

          -- AI amendments
          local minAmountForBoost = ((isAI(player) and (MIN_AMOUNT_FOR_BOOST + AI_THESHOLD)) or MIN_AMOUNT_FOR_BOOST);

          -- If enough horses is present, allow him to boost!
          if horsesStockpileAmount >= minAmountForBoost then
            -- I wanna know what happens there!
            WriteToLog("Boost with horses is possible for player: "..player:GetID()..", with horses: "..horsesStockpileAmount);
            return true;
          end

          break;
        end
      end
    end
  end

  -- Transparency!
  WriteToLog("Boost with horses is NOT possible for player: "..player:GetID());
  return false;
end

function getEraIncrementModifier()
  return BOOST_RATIO_BASE_MULTIPLIER + getBoostIncrementedValue(MIN_ERA_INDEX, BOOST_RATIO_INCREMENT_PER_ERA);
end

-- Get triggered on player resource changes
function OnPlayerResourceChanged(playerId, resourceTypeId)
  -- Local player horses amount changed...
  if playerId == Game.GetLocalPlayer() and resourceTypeId == RESOURCE_ID_HORSES then  -- Horses
    -- ..refresh the button
    refreshHorsesMaterialBoostButton();
  end
end

-- Event handle
function OnCivicChanged(playerId)
  -- Local player horses amount changed...
  if playerId == Game.GetLocalPlayer() then
    -- Flag culture as uncompleted
    civicCompleted = false;

    -- Refresh the button
    refreshHorsesMaterialBoostButton();
  end
end

-- Event handle
function OnCivicCompleted(playerId)
  -- Local player horses amount changed...
  if playerId == Game.GetLocalPlayer() then
    -- Flag culture als completed
    civicCompleted = true;

    -- Refresh the button
    refreshHorsesMaterialBoostButton();
  end
end

-- Event handle
function OnLocalPlayerTurnEnd()
  -- Flag culture as uncompleted
  civicCompleted = false;
end

-- Local player starts turn!
function OnLocalPlayerTurnBegin()
  -- We need to know everything
  WriteToLog("Turn begins, boosted value has been reset!");

  -- Reset boost notification...
  if boostedThisTurn then
    -- ...if the button has been used
    notifyIfReady = true;
  end

  -- Reset boosted stat
  boostedThisTurn = false;

  -- Refresh
  refreshHorsesMaterialBoostButton();
end

-- Inilizer!
function Initialize()
  -- Exposed member callbacks
  ExposedMembers.SAUM_Niter_IsPlayerDevelopingCulture = isPlayerDevelopingCulture;
  ExposedMembers.SAUM_Niter_IsBoostWithHorsesPossible = isBoostWithHorsesPossible;
  ExposedMembers.SAUM_Niter_GetCultureAmountNeededForCompletion = getCultureAmountNeededForCompletion;

  -- Trigger a boosting button refresh onload
  Events.LoadGameViewStateDone.Add(OnLocalPlayerTurnBegin);

  -- Trigger a boosting button refresh
  Events.LocalPlayerTurnBegin.Add(OnLocalPlayerTurnBegin);

  --Local players turn end
  Events.LocalPlayerTurnEnd.Add(OnLocalPlayerTurnEnd);

  -- Listen to resource changes
  Events.PlayerResourceChanged.Add(OnPlayerResourceChanged);

  -- Listen for civic changes
  Events.CivicChanged.Add(OnCivicChanged);

  -- Listen for civic completed
  Events.CivicCompleted.Add(OnCivicCompleted);

  -- Hmm... what might this be good for?
  print("Initialize");
end

Initialize();
