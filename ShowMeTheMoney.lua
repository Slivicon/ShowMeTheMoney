-- ShowMeTheMoney for Farming Simulator 17
-- @description: This displays the total amount of money available on the server to all players when playing a multiplayer game
-- @author: Slivicon
-- History at end of file.
--

ShowMeTheMoney = {};
ShowMeTheMoney.enabled = true;
ShowMeTheMoney.fontSize = 0.014;
ShowMeTheMoney.money = 0;
ShowMeTheMoney.moneyDisplay = "";
ShowMeTheMoney.playerCount = 1;
ShowMeTheMoney.posX = 0;
ShowMeTheMoney.posY = 0;

local modItem = ModsUtil.findModItemByModName(g_currentModName);
ShowMeTheMoney.version = (modItem and modItem.version) and modItem.version or "?.?.?";

function ShowMeTheMoney:loadMap(name)
  local isMP = g_currentMission.missionDynamicInfo.isMultiplayer;
  if isMP == nil or isMP == false then
    if self == nil then
      print('ShowMeTheMoney:loadMap(23) self is nil');
      ShowMeTheMoney.enabled = false;
    else
      print('ShowMeTheMoney:loadMap disabling');
      self.enabled = false;
    end;
  elseif g_currentMission:getIsServer() then
    local serverMoney = g_currentMission:getTotalMoney();
    print("ShowMeTheMoney:loadMap set self.money to '" .. tostring(serverMoney) .. "', set player count, set money display");
    if self == nil then
      print('ShowMeTheMoney:loadMap(32) self is nil');
      ShowMeTheMoney.money = serverMoney;
    else
      self.money = serverMoney;
    end;
    -- self.playerCount = self:getPlayerCount();
  else
    -- client joining, ask server to send the money value?
    --g_client:getServerConnection():sendEvent(ShowMeTheMoneyEvent:new()); -- generates error in client log "invalid Event ID"
  end;
end;

function ShowMeTheMoney:deleteMap()
end;

function ShowMeTheMoney:mouseEvent(posX, posY, isDown, isUp, button)
end;

function ShowMeTheMoney:keyEvent(unicode, sym, modifier, isDown)
end;

function ShowMeTheMoney:update(dt)
  if self.enabled == true then
    if g_currentMission:getIsServer() then
      local serverMoney = g_currentMission:getTotalMoney();
      if self.money ~= serverMoney then
        print("ShowMeTheMoney:update - self.money '" .. tostring(self.money) .. "' serverMoney '" .. tostring(serverMoney) .. "', sendEvent");
        self.money = serverMoney;
        ShowMeTheMoneyEvent.sendEvent(self.money);
      else
        local currPlayerCount = self:getPlayerCount();
        if currPlayerCount ~= self.playerCount then
          print("ShowMeTheMoney:update - number of players has changed, sendEvent");
          self.playerCount = currPlayerCount;
          ShowMeTheMoneyEvent.sendEvent(self.money);
        end;
      end;
    end;
    -- don't run on dedi, don't run on players logged in as admin
    if not g_currentMission.isMasterUser and g_dedicatedServerInfo == nil then -- todo: find out value of isMasterUser on the dedi
      self.fontSize = g_currentMission.inGameMessage.textSize;
      self.posX = g_currentMission.infoBarBgOverlay.x + g_currentMission.infoBarBgOverlay.width - g_currentMission.moneyTextOffsetX;
      self.posY = g_currentMission.infoBarBgOverlay.y + g_currentMission.moneyTextOffsetY - self.fontSize;
      self.moneyDisplay = tostring(g_i18n:formatNumber(self.money, 0));
    end;
  end;
end;

function ShowMeTheMoney:draw()
  -- only run on multiplayer players who are not logged in as admin
  if self.enabled == true and not g_currentMission.isMasterUser and g_dedicatedServerInfo == nil then
    setTextAlignment(RenderText.ALIGN_RIGHT);
    setTextColor(0.9961, 0.7490, 0.0039, 1); -- money icon colour [R, G, B, Alpha (0-1)]
    renderText(self.posX, self.posY, self.fontSize, self.moneyDisplay);
    setTextColor(1, 1, 1, 1);  -- in case another text rendering function does not set color before rendering text, this resets it to white
    setTextAlignment(RenderText.ALIGN_LEFT);  -- in case another text rendering function does not set alignment, this resets it to left
  end;
end;

function ShowMeTheMoney:getPlayerCount()
  local count = 0;
  local tbl = g_currentMission.players;
  for _ in pairs(tbl) do
    count = count + 1;
  end;
  return count;
end;

function ShowMeTheMoney:setServerMoney(intMoney)
  print("ShowMeTheMoney:setServerMoney '" .. tostring(intMoney) .. "'");
  if self == nil then
    print('ShowMeTheMoney:setServerMoney self is nil');
    ShowMeTheMoney.money = intMoney;
  else
    print('ShowMeTheMoney:setServerMoney self is not nil, setting self.money to "' .. tostring(intMoney) .. '"');
    self.money = intMoney;
  end;
end;

addModEventListener(ShowMeTheMoney);

ShowMeTheMoneyEvent = {};
ShowMeTheMoneyEvent_mt = Class(ShowMeTheMoneyEvent, Event);

InitEventClass(ShowMeTheMoneyEvent, "ShowMeTheMoneyEvent");

function ShowMeTheMoneyEvent:emptyNew()
  local self = Event:new(ShowMeTheMoneyEvent_mt);
  return self;
end;

function ShowMeTheMoneyEvent:new(intMoney)
  local self = ShowMeTheMoneyEvent:emptyNew();
  --local obj = ShowMeTheMoney;
  --self.obj = obj;
  --self.obj = obj;
  if intMoney == nil then
    intMoney = ShowMeTheMoney.money;
  end;
  self.intMoney = intMoney;
  return self;
end;

function ShowMeTheMoneyEvent:readStream(streamId, connection)
  --values are read in the same order they are written by writeStream
  --local id = streamReadInt8(streamId); -- writeStream item 1
  if self == nil then
    print('ShowMeTheMoneyEvent:readStream self is nil');
  else
    -- modding handbook example for HonkEvent.lua is different than GDN LUADOC :/
    --self.obj = readNetworkNodeObject(streamId);
    
    self.intMoney = streamReadInt32(streamId); -- writeStream item 2
    --self.obj = networkGetObject(id);
    print("ShowMeTheMoneyEvent:readStream self.intMoney'" .. tostring(self.intMoney) .. "'");
    self:run(connection);
  end;
end;

function ShowMeTheMoneyEvent:writeStream(streamId, connection)
  --values are read in the same order they are written by writeStream
  if self == nil then
    print('ShowMeTheMoneyEvent:writeStream self is nil');
  else
    -- modding handbook example for HonkEvent.lua is different than GDN LUADOC :/
    --writeNetworkNodeObject(streamId, self.obj);
    --local id = networkGetObjectId(self.obj);
    --print('ShowMeTheMoneyEvent:writeStream id "' .. tostring(id) .. '" intMoney "' .. tostring(self.intMoney) .. '"');
    --streamWriteInt8(streamId, id); -- item 1
    print('ShowMeTheMoneyEvent:writeStream intMoney "' .. tostring(self.intMoney) .. '"');
    streamWriteInt32(streamId, self.intMoney); -- item 2
  end;
end;

function ShowMeTheMoneyEvent:run(connection)
  if self == nil then
    print('ShowMeTheMoneyEvent:run self is nil');
--  elseif self.obj == nil then
--    print('ShowMeTheMoneyEvent:run self.obj is nil');
  else
    print("ShowMeTheMoneyEvent:run setServerMoney self.intMoney '" .. tostring(self.intMoney) .. "'");
    --self.obj:setServerMoney(self.intMoney);
    ShowMeTheMoney:setServerMoney(self.intMoney);
--    if not connection:getIsServer() then
--      print("ShowMeTheMoneyEvent:run broadcastEvent");
--      g_server:broadcastEvent(ShowMeTheMoneyEvent:new(self.obj, self.intMoney), nil, connection, self.obj);
--    end;
  end;
end;

function ShowMeTheMoneyEvent.sendEvent(intMoney, noEventSend)
  if noEventSend == nil or noEventSend == false then
    if g_server ~= nil then
      if intMoney == nil then
        intMoney = ShowMeTheMoneyEvent.intMoney;
        print("ShowMeTheMoneyEvent.sendEvent intMoney was nil");
        if intMoney == nil then
          print("ShowMeTheMoneyEvent.sendEvent ShowMeTheMoneyEvent.intMoney was nil");
          intMoney = ShowMeTheMoney.money;
        end;
      end;
      print("ShowMeTheMoneyEvent.sendEvent server initiated intMoney '" .. tostring(intMoney) .. "'");
      g_server:broadcastEvent(ShowMeTheMoneyEvent:new(intMoney));
    else
      -- don't think this will be needed as for this mod, it should always be the server
      -- todo: maybe find a way for client to initiate sending the event upon join so that server doesn't have to calculate player count every frame
      --print("ShowMeTheMoneyEvent.sendEvent client initiated intMoney '" .. tostring(intMoney) .. "'");
      --g_client:getServerConnection():sendEvent(ShowMeTheMoneyEvent:new());
    end;
  end;
end;

print(string.format("Script loaded: ShowMeTheMoney.lua (v%s)", ShowMeTheMoney.version));

--
-- @history 1.0  2017-09-25  Initial release for Farming Simulator 17
--