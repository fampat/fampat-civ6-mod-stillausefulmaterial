-- ================================================
--	StillAUsefulMaterial Niter
-- ================================================

-- Includes
include("Civ6Common");
include("CitySupport");
include("InstanceManager");
include("Common_SAUM.lua");

-- Configuration
local MIN_AMOUNT_FOR_BOOST = 25;  -- Amount of niter that is required before the button shows up
local MIN_ERA_INDEX = 5;          -- After reaching the "Industrial"-era the button shows up
local RESOURCE_ID_NITER = 44;

-- Variables for handling
local boostedThisTurn = false;
local researchCompleted = false;

-- Create an instance of our button
local niterMaterialBoostButtonIM = InstanceManager:new("NiterResearchBoostInstance", "NiterResearchBoostButton", Controls.NiterResearchBoostStack);

-- Create the button
function createNiterMaterialBoostButton()
  -- Get us the local player id
  local localPlayerId = Game.GetLocalPlayer();

  -- Check for local player
  if localPlayerId ~= nil then
    local player = Players[localPlayerId];

    -- Inform us!
    WriteToLog("Create material boost button!");

    -- Freshen up the button
  	niterMaterialBoostButtonIM:ResetInstances();
  	local niterResearchBoostInstance = niterMaterialBoostButtonIM:GetInstance();

    -- Default tooltip
    local tooltip = "ERROR_TOOLTIP_NOT_SET";

    -- State-dependent tooltip
    if boostedThisTurn then
      tooltip = Locale.Lookup("LOC_STILLAUSEFULMATERIAL_NITER_BOOSTED_TOOLTIP");
    elseif (not isPlayerResearching(player) or researchCompleted) then
      tooltip = Locale.Lookup("LOC_STILLAUSEFULMATERIAL_NO_RESEARCH_TOOPTIP");
    else
      -- Default value
      local niterAmountToConsume = 0;
      local researchToBeCompleted = 0;

      -- Fetch values for calculating numbers
      local resourceStockpile = getStrategicResourceStockpileOfPlayer(player, "RESOURCE_NITER");
      local requiredResearchNeeded = getScienceAmountNeededForCompletion(player);

      -- Do some very complex math...
      if requiredResearchNeeded <= resourceStockpile then
        niterAmountToConsume = requiredResearchNeeded;
        researchToBeCompleted = requiredResearchNeeded;
      else
        niterAmountToConsume = resourceStockpile;
        researchToBeCompleted = resourceStockpile;
      end
      -- ...done

      -- Set our tooltip
      tooltip = Locale.Lookup("LOC_STILLAUSEFULMATERIAL_NITER_UNBOOSTED_TOOLTIP", niterAmountToConsume, researchToBeCompleted);
    end

    -- Set the disabled state
    local isDisabled = (not isPlayerResearching(player) or researchCompleted or boostedThisTurn);

  	-- Set button data and action handler
  	niterResearchBoostInstance.NiterResearchBoostButton:SetDisabled(isDisabled);
  	niterResearchBoostInstance.NiterResearchBoostIcon:SetAlpha((isDisabled and 0.65) or 1);
  	niterResearchBoostInstance.NiterResearchBoostButton:SetToolTipString(tooltip);

    -- Callback function
  	niterResearchBoostInstance.NiterResearchBoostButton:RegisterCallback(Mouse.eLClick,
  		function(void1, void2)
        -- Our callback plays sound, boost and refreshens the button
  			UI.PlaySound("Play_UI_Click");

        -- Execute the boost
        boostResearchWithNiter(player);

        -- Memorize state
        boostedThisTurn = true;

        -- Refresh the button in "used"-state
        refreshNiterMaterialBoostButton();
  		end
  	);
  end
end

-- Refresh out button on the UI
function refreshNiterMaterialBoostButton()
  detachNiterMaterialBoostButton();
  attachNiterMaterialBoostBotton();
end

-- Attach our button to the research-panel
function attachNiterMaterialBoostBotton()
  -- Log me a message darling
  WriteToLog("Attaching niter material boost button...");

  -- Get the local player
  local localPlayer = Players[Game.GetLocalPlayer()];

  -- Player is real?
  if localPlayer ~= nil then
    -- If is possible to attach, we will see
    if isBoostWithNiterPossible(localPlayer) or boostedThisTurn then
      -- Create the button
      createNiterMaterialBoostButton();

      -- Get ui control where we wanna add our button to
      local ButtonStack = ContextPtr:LookUpControl("/InGame/LaunchBar/ButtonStack");

      -- There should only be a single child!
      if ButtonStack ~= nil then
        -- Rebase our ui-button to the new parent
        Controls.NiterResearchBoostStack:ChangeParent(ButtonStack);

        -- Attach at specified index after research button
        ButtonStack:AddChildAtIndex(Controls.NiterResearchBoostStack, 2);

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
function detachNiterMaterialBoostButton()
  niterMaterialBoostButtonIM:DestroyInstances();
  WriteToLog("Detached material boost button!");
end

-- The actual science boost action takes place here
function boostResearchWithNiter(player)
  -- But only with real player
  if player ~= nil then
    local playerId = player:GetID();

    -- Fetch the stockpile of the player, and the current production state
    local resourceStockpile = getStrategicResourceStockpileOfPlayer(player, "RESOURCE_NITER");
    local requiredScienceNeeded = getScienceAmountNeededForCompletion(player);

    -- Calc variable
    local substractedMaterial = 0;

    -- In case we have more niter that it would cost, complete it!
    -- And save some precious niter
    if requiredScienceNeeded <= resourceStockpile then
      -- Finish science, substract resource equl production-cost
      ExposedMembers.MOD_StillAUsefulMaterial.AddToResearch(playerId, requiredScienceNeeded);
      substractedMaterial = requiredScienceNeeded;
    else
      -- Add to science, substract entire resources
      ExposedMembers.MOD_StillAUsefulMaterial.AddToResearch(playerId, resourceStockpile);
      substractedMaterial = resourceStockpile;
    end

    -- Here we call out big brother for help!
    ExposedMembers.MOD_StillAUsefulMaterial.ChangeResourceAmount(playerId, GameInfo.Resources["RESOURCE_NITER"].Index, -substractedMaterial);

    -- Logging logging logging
    WriteToLog("BOOSTed research with niter cost: "..substractedMaterial);
  else
    -- Also here we do our logging :)
    WriteToLog("BOOST not possible, no player selected!");
  end
end

-- Helper to check if a player is able to use the boost
function isBoostWithNiterPossible(player)
  -- He need to be in the right era!
  if hasRequiredEra(player, MIN_ERA_INDEX) then
    local playerResources = player:GetResources();

    -- He will need niter to make it work!
    for resource in GameInfo.Resources() do
      if (resource.ResourceClassType == "RESOURCECLASS_STRATEGIC") then
        if resource.ResourceType == "RESOURCE_NITER" then
          -- Get the players stock
          local niterStockpileAmount = playerResources:GetResourceAmount(resource.ResourceType);

          -- If enough niter is present, allow him to boost!
          if niterStockpileAmount >= MIN_AMOUNT_FOR_BOOST then
            -- I wanna know what happens there!
            WriteToLog("Boost with niter is possible for player: "..player:GetID()..", with niter: "..niterStockpileAmount);
            return true;
          end

          break;
        end
      end
    end
  end

  -- Transparency!
  WriteToLog("Boost with niter is NOT possible for player: "..player:GetID());
  return false;
end

-- AIs will also get a boost if they can afford it
-- TODO: Implement descision-making for more intelligent boosting, eg.
--       if military production exist, boost that instead of a settler.
function TakeAIActionsForNiterBoost()
  WriteToLog("AIs science boosting begun!");

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
      -- Is boosting possible for this player?
      if isBoostWithNiterPossible(player) and isPlayerResearching(player) then
        -- Actual boost
        boostResearchWithNiter(player);

        -- Logging to make clear what the AI is getting
        local AIPlayerConfiguration = PlayerConfigurations[player:GetID()];
        WriteToLog("AI ("..AIPlayerConfiguration:GetLeaderName()..") boosted his science!");
      end
    end
	end

  MIN_AMOUNT_FOR_BOOST = MIN_AMOUNT_FOR_BOOST_BAK;
  MIN_ERA_INDEX = MIN_ERA_INDEX_BAK;
end

-- Get triggered on player resource changes
function OnPlayerResourceChanged(playerId, resourceTypeId)
  -- Local player niter amount changed...
  if playerId == Game.GetLocalPlayer() and resourceTypeId == RESOURCE_ID_NITER then  -- Niter
    -- ..refresh the button
    refreshNiterMaterialBoostButton();
  end
end

-- Event handle
function OnResearchChanged(playerId)
  -- Local player niter amount changed...
  if playerId == Game.GetLocalPlayer() then
    -- Flag research as uncompleted
    researchCompleted = false;

    -- Refresh the button
    refreshNiterMaterialBoostButton();
  end
end

-- Event handle
function OnResearchCompleted(playerId)
  -- Local player niter amount changed...
  if playerId == Game.GetLocalPlayer() then
    -- Flag research als completed
    researchCompleted = true;

    -- Refresh the button
    refreshNiterMaterialBoostButton();
  end
end

-- Event handle
function OnLocalPlayerTurnEnd()
  -- Flag research as uncompleted
  researchCompleted = false;
end

function OnLocalPlayerTurnBegin()
  -- We need to know everything
  WriteToLog("Turn begins, boosted value has been reset!");

  -- Reset boosted stat
  boostedThisTurn = false;

  -- Refresh
  refreshNiterMaterialBoostButton();
end

-- Thinigs that happen when the turn starts
function OnTurnBegin()
  -- Its AIs turn to boost baby!
  TakeAIActionsForNiterBoost();
end

function Initialize()
  -- Trigger a boosting button refresh onload
  Events.LoadGameViewStateDone.Add(OnLocalPlayerTurnBegin);

  -- Trigger a boosting button refresh
  Events.LocalPlayerTurnBegin.Add(OnLocalPlayerTurnBegin);

  --Local players turn end
  Events.LocalPlayerTurnEnd.Add(OnLocalPlayerTurnEnd);

  -- Trigger a boosting reset and the AI handling
  Events.TurnBegin.Add(OnTurnBegin);

  -- Listen to resource changes
  Events.PlayerResourceChanged.Add(OnPlayerResourceChanged);

  -- Listen for research changes
  Events.ResearchChanged.Add(OnResearchChanged);

  -- Listen for researches completed
  Events.ResearchCompleted.Add(OnResearchCompleted);

  -- Hmm... what might this be good for?
  print("Initialize");
end

Initialize();
