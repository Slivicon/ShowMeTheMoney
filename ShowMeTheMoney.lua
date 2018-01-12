-- ShowMeTheMoney for Farming Simulator 17
-- @description: description and change log in modDesc.xml
-- @author: Slivicon
--

ShowMeTheMoney = {};

local modItem = ModsUtil.findModItemByModName(g_currentModName);
ShowMeTheMoney.version = (modItem and modItem.version) and modItem.version or "?.?.?";

function ShowMeTheMoney:loadMap(name)
  g_currentMission:addOnUserEventCallback(ShowMeTheMoney.onUserEventCallback, self);
end;

function ShowMeTheMoney:deleteMap()
  ShowMeTheMoney.isInitialized = false;
  g_currentMission:removeOnUserEventCallback(ShowMeTheMoney.onUserEventCallback);
end;

function ShowMeTheMoney:keyEvent(unicode, sym, modifier, isDown)
end;

function ShowMeTheMoney:draw()
  if g_currentMission.missionDynamicInfo.isMultiplayer and ShowMeTheMoney.isInitialized and ShowMeTheMoney:isDisplayer() then
      setTextAlignment(RenderText.ALIGN_RIGHT);
      setTextColor(0.9961, 0.7490, 0.0039, 1); -- money icon colour [R, G, B, Alpha (0-1)]
      renderText(ShowMeTheMoney.posX, ShowMeTheMoney.posY, ShowMeTheMoney.fontSize, ShowMeTheMoney.moneyDisplay);
      setTextColor(1, 1, 1, 1);  -- in case another text rendering function does not set color before rendering text, this resets it to white
      setTextAlignment(RenderText.ALIGN_LEFT);  -- in case another text rendering function does not set alignment, this resets it to left
  end;
end;

function ShowMeTheMoney:initialize()
  if ShowMeTheMoney.isInitialized then
    return;
  end;
  ShowMeTheMoney.dt = 0;
  ShowMeTheMoney.fontSize = g_currentMission.timeScaleTextSize; -- smallest infobar base game text; larger option is g_currentMission.inGameMessage.textSize
  ShowMeTheMoney.money = g_currentMission:getTotalMoney(); 
  ShowMeTheMoney.moneyDisplay = tostring(g_i18n:formatNumber(ShowMeTheMoney.money, 0));
  ShowMeTheMoney.posX = g_currentMission.infoBarBgOverlay.x + g_currentMission.infoBarBgOverlay.width - g_currentMission.moneyTextOffsetX; --align with player money
  ShowMeTheMoney.posY = g_currentMission.infoBarBgOverlay.y + g_currentMission.moneyTextOffsetY - (ShowMeTheMoney.fontSize * 1.25);
  if not g_currentMission:getIsServer() then
    if g_client ~= nil then
      --print('ShowMeTheMoney:initialize() - ShowMeTheMoney_Event:sendEvent([ShowMeTheMoney.money=' .. tostring(ShowMeTheMoney.money) .. '])');
      ShowMeTheMoney_Event:sendEvent(ShowMeTheMoney.money);
    end;
  else
    ShowMeTheMoney:XmlLoad();
    ShowMeTheMoney.lastNumP = 0;
  end;
  ShowMeTheMoney.isInitialized = true;
end

function ShowMeTheMoney:isDisplayer() -- is a scenario where the total shared money value should be drawn
  local bIsNotDedi = g_dedicatedServerInfo == nil;
  local bIsHost = bIsNotDedi and g_server ~= nil;
  local bIsAdmin = g_currentMission.isMasterUser or (bIsNotDedi and bIsHost);
  local bIsAdminWithOwnMoney = bIsAdmin and g_currentMission.clientPermissionSettings.ownMoney;
  local bIsHudShown = g_currentMission.renderTime;
  return bIsNotDedi and bIsHudShown and ((bIsAdminWithOwnMoney) or (not bIsAdmin));
end;

function ShowMeTheMoney:mouseEvent(posX, posY, isDown, isUp, button)
end;

function ShowMeTheMoney:onUserEventCallback()
  if not g_currentMission.missionDynamicInfo.isMultiplayer or not g_currentMission:getIsServer() or not g_currentMission.clientPermissionSettings.ownMoney then
    return;
  end;
  if not ShowMeTheMoney.isInitialized then
    ShowMeTheMoney:initialize();
  end;
  if #g_server.clients ~= ShowMeTheMoney.lastNumP then
    --print('ShowMeTheMoney:onUserEventCallback() - number of players has changed from [' .. tostring(ShowMeTheMoney.lastNumP) .. '] to [' .. tostring(#g_server.clients) .. ']');
    ShowMeTheMoney.lastNumP = #g_server.clients;
    for i = 1, #g_currentMission.users do
      local u = g_currentMission.users[i];
      --print('ShowMeTheMoney:onUserEventCallback() - BEGIN processing g_currentMission.users[' .. tostring(i) .. '].nickname=[' .. tostring(u.nickname) .. '],.connection.streamId=[' .. tostring(u.connection.streamId) .. '],.isSaved=[' .. tostring(u.isSaved) .. '],.isOnline=[' .. tostring(u.isOnline) .. ']');
      if not u.isMasterUser then -- don't bother dedicated server Admin user, who uses host "server" money which is managed by the default game
        u.isOnline = false;
        u.isSaved = false;
        for j = 1, #g_server.clients do -- check if user is a connected player (client)
          if u.connection.streamId == g_server.clients[j] then
            u.isOnline = true; -- only a connected client player (not the host) is tracked
            break;
          end;
        end;
        for savedPlayerKey, savedPlayer in ipairs(ShowMeTheMoney.players) do
          --print('ShowMeTheMoney:onUserEventCallback() - BEGIN processing saved player name=[' .. tostring(savedPlayer.name) .. '], saved money=[' .. tostring(savedPlayer.money) .. '], isOnline=[' .. tostring(savedPlayer.isOnline) .. '], isOwed=[' .. tostring(savedPlayer.isOwed) .. ']');
          if u.nickname == savedPlayer.name then
            u.isSaved = true;
            if u.isOnline then 
              if savedPlayer.isOwed and savedPlayer.money > 0 then -- send saved money back to online player
                --print('ShowMeTheMoney::onUserEventCallback() - g_currentMission.missionStats.money = [' .. tostring(g_currentMission.missionStats.money) .. '],g_currentMission.users[' .. tostring(i) .. '],.money = [' .. tostring(u.money) .. '],.nickname = [' .. tostring(u.nickname) .. '],saved money = [' .. tostring(savedPlayer.money) .. ']');
                g_currentMission.missionStats.money = g_currentMission.missionStats.money - savedPlayer.money; -- debit money owed from server
                g_currentMission.users[i].money = u.money + savedPlayer.money; -- credit money owed to player
                ShowMeTheMoney.players[savedPlayerKey].money = 0; -- at this point there is no money to "save", as it has been transferred back to the player in the game
                ShowMeTheMoney.players[savedPlayerKey].isOwed = false;
              end;
            else
              --print('ShowMeTheMoney:onUserEventCallback() - setting player [' .. tostring(ShowMeTheMoney.players[savedPlayerKey].name) .. '] .isOwed to true since they are offline');
              ShowMeTheMoney.players[savedPlayerKey].isOwed = true;
            end;
            ShowMeTheMoney.players[savedPlayerKey].isOnline = u.isOnline;
          end;
          --print('ShowMeTheMoney:onUserEventCallback() - END processing saved player name=[' .. tostring(savedPlayer.name) .. '], saved money=[' .. tostring(savedPlayer.money) .. '], isOnline=[' .. tostring(savedPlayer.isOnline) .. '], isOwed=[' .. tostring(savedPlayer.isOwed) .. ']');
        end;
        if not u.isSaved and u.isOnline then -- add new players not found in save data
          --print('ShowMeTheMoney::onUserEventCallback() - adding new player not found in save data [' .. tostring(u.nickname) .. '],money=[' .. tostring(u.money) .. ']');
          local p = {};
          p.money = math.max(0, u.money); -- negative amounts are left to the default game to manage
          p.name = u.nickname;
          p.isOnline = u.isOnline;
          table.insert(ShowMeTheMoney.players, p);
          u.isSaved = true;
        end;
      end;
      --print('ShowMeTheMoney:onUserEventCallback() - END processing g_currentMission.users[' .. tostring(i) .. '].nickname=[' .. tostring(u.nickname) .. '],.connection.streamId=[' .. tostring(u.connection.streamId) .. '],.isSaved=[' .. tostring(u.isSaved) .. '],.isOnline=[' .. tostring(u.isOnline) .. ']');
    end;
  end;
end

function ShowMeTheMoney:update(dt)
  if not g_currentMission.missionDynamicInfo.isMultiplayer then
    return;
  end;
  if not ShowMeTheMoney.isInitialized then
    ShowMeTheMoney:initialize();
  end;
  if g_currentMission:getIsServer() then
    ShowMeTheMoney.money = g_currentMission:getTotalMoney();      
    if ShowMeTheMoney.money ~= ShowMeTheMoney.moneyLastUpdate then
      --print('ShowMeTheMoney:update() - ShowMeTheMoney.moneyLastUpdate "' .. tostring(ShowMeTheMoney.moneyLastUpdate) .. '" ShowMeTheMoney.money "' .. tostring(ShowMeTheMoney.money) .. '"');
      ShowMeTheMoney.moneyLastUpdate = ShowMeTheMoney.money;
      --print('ShowMeTheMoney:update() - ShowMeTheMoneymoney.LastUpdate "' .. tostring(ShowMeTheMoney.moneyLastUpdate) .. '" ShowMeTheMoney.money "' .. tostring(ShowMeTheMoney.money) .. '"');
      ShowMeTheMoney.sendUpdate = true; -- send updates while money changes
      --print('ShowMeTheMoney:update() - ShowMeTheMoney.sendUpdate = true');
    end;
    if g_currentMission.clientPermissionSettings.ownMoney then
      for savedPlayerKey, savedPlayer in ipairs(ShowMeTheMoney.players) do
        if savedPlayer.isOnline then
          local isOnline = false;
          for k, v in pairs(g_currentMission.users) do
            if v.nickname == savedPlayer.name then
              if not v.isMasterUser then -- only update tracked money values for non-Admin online players
                ShowMeTheMoney.players[savedPlayerKey].money = math.max(0, v.money);
                isOnline = true;
              else
                --print('ShowMeTheMoney:update() - player [' .. tostring(savedPlayer.name) .. '] logged in as Admin, setting .isOnline to false and .isOwed to true');
                isOnline = false;
                ShowMeTheMoney.players[savedPlayerKey].isOnline = isOnline;
                ShowMeTheMoney.players[savedPlayerKey].isOwed = true;
              end;
              break;
            end;
          end;
          if not isOnline then
            --print('ShowMeTheMoney:update() - player [' .. tostring(savedPlayer.name) .. '] has gone offline, setting .isOnline to false and .isOwed to true');
            ShowMeTheMoney.players[savedPlayerKey].isOnline = isOnline;
            ShowMeTheMoney.players[savedPlayerKey].isOwed = true;
          end;
        end;
      end;
    end;
  end;
  if ShowMeTheMoney.sendUpdate then
    if self.dt >= 1000 then
      self.dt = 0;
      ShowMeTheMoney.sendUpdate = false;
      ShowMeTheMoney_Event:sendEvent(g_currentMission:getTotalMoney());
    else
      self.dt = self.dt + dt;
    end;
  end;
  if ShowMeTheMoney:isDisplayer() then
    ShowMeTheMoney.fontSize = g_currentMission.timeScaleTextSize; -- smallest infobar base game text; larger option is g_currentMission.inGameMessage.textSize;
    ShowMeTheMoney.moneyDisplay = tostring(g_i18n:formatNumber(ShowMeTheMoney.money, 0));
    ShowMeTheMoney.posX = g_currentMission.infoBarBgOverlay.x + g_currentMission.infoBarBgOverlay.width - g_currentMission.moneyTextOffsetX; -- align with player money
    ShowMeTheMoney.posY = g_currentMission.infoBarBgOverlay.y + g_currentMission.moneyTextOffsetY - (ShowMeTheMoney.fontSize * 1.25);
  end;
end;

function ShowMeTheMoney:XmlLoad()
  if not g_currentMission:getIsServer() then
    return;
  end;
  local xmlFile = nil;
  if g_currentMission.missionInfo.isValid then
    xmlFile = g_currentMission.missionInfo.xmlFile;
  end;
  if xmlFile == nil then
    return;
  end;
  local modKey = g_currentMission.missionInfo.xmlKey .. ".ShowMeTheMoney";
  local players = {};
  local i = 0;
  while true do
    local key = string.format(modKey .. ".players.player(%d)", i);
    if not hasXMLProperty(xmlFile, key) then
      break;
    end;
    local player = {};
    player.name = Utils.getNoNil(getXMLString(xmlFile, key .. "#name"), "");
    if player.name ~= "" then
      player.money = math.floor(Utils.getNoNil(getXMLInt(xmlFile, key .. "#money"), 0));
      if player.money > 0 then
        player.isOwed = true;
        --print('ShowMeTheMoney:XmlLoad() - name=[' .. tostring(player.name) .. '],money=[' .. tostring(player.money) .. ']');
        table.insert(players, player);
      end;
    end;
    i = i + 1;
  end;
  ShowMeTheMoney.players = players;
end

function ShowMeTheMoney.XmlSave(self)
  if not g_currentMission:getIsServer() then
    return;
  end;
  if g_currentMission.missionDynamicInfo.isMultiplayer and self.isValid and self.xmlKey ~= nil and self.xmlFile ~= nil then
    local modKey = self.xmlKey .. ".ShowMeTheMoney";
    if hasXMLProperty(self.xmlFile, modKey) then
      removeXMLProperty(self.xmlFile, modKey);
    end;
    local key = modKey .. ".players";
    for i = 1, #ShowMeTheMoney.players do
      local v = ShowMeTheMoney.players[i];
      local m = math.floor(v.money);
      if m > 0 then
        local j = i - 1;
        --print('ShowMeTheMoney:XmlSave() - name=[' .. tostring(v.name) .. '],money=[' .. tostring(m) .. ']');
        setXMLString(self.xmlFile, string.format("%s.player(%d)#name", key, j), v.name);
        setXMLInt(self.xmlFile, string.format("%s.player(%d)#money", key, j), m);
      end;
    end;
  end;
end

FSCareerMissionInfo.saveToXML = Utils.appendedFunction(FSCareerMissionInfo.saveToXML, ShowMeTheMoney.XmlSave); -- add tracked player money to savegame

addModEventListener(ShowMeTheMoney);

ShowMeTheMoney_Event = {};
ShowMeTheMoney_Event_mt = Class(ShowMeTheMoney_Event, Event);
InitEventClass(ShowMeTheMoney_Event, "ShowMeTheMoney_Event");

function ShowMeTheMoney_Event:emptyNew()
  --print('ShowMeTheMoney_Event:emptyNew');
  local self = Event:new(ShowMeTheMoney_Event_mt);
  self.className = "ShowMeTheMoney_Event";
  return self;
end;

function ShowMeTheMoney_Event:new(money)
  --print('ShowMeTheMoney_Event:new(money=[' .. tostring(money) ..'])');
  local self = ShowMeTheMoney_Event:emptyNew();
  self.money = money;
  ShowMeTheMoney.money = self.money;
  return self;
end;

function ShowMeTheMoney_Event:readStream(streamId, connection)
  --print('ShowMeTheMoney_Event:readStream');
  self.money = streamReadInt32(streamId);	
  ShowMeTheMoney.money = self.money;
  if not connection:getIsServer() then
    g_server:broadcastEvent(ShowMeTheMoney_Event:new(self.money), nil, connection);
  end;
end;

function ShowMeTheMoney_Event:sendEvent(money)
  if g_server ~= nil then
    --print('ShowMeTheMoney_Event:sendEvent([money=' .. tostring(money) .. ']) - g_server:broadcastEvent');
    g_server:broadcastEvent(ShowMeTheMoney_Event:new(money));
  else
    --print('ShowMeTheMoney_Event:sendEvent([money=' .. tostring(money) .. ']) - g_client:getServerConnection():sendEvent');
    g_client:getServerConnection():sendEvent(ShowMeTheMoney_Event:new(money))
  end;
end;

function ShowMeTheMoney_Event:writeStream(streamId, connection)
  --print('ShowMeTheMoney_Event:writeStream');
  streamWriteInt32(streamId, self.money);
end;

print(string.format("Script loaded: ShowMeTheMoney.lua (v%s)", ShowMeTheMoney.version));
