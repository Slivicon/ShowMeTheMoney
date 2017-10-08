-- ShowMeTheMoney for Farming Simulator 17
-- @description: This displays the total amount of money available on the server to all players (not logged in as admin) when playing a multiplayer game
-- @author: Slivicon
-- History at end of file. Thanks to timmiej93, Xentro, kevink98, Decker_MMIV, Rahkiin and the modding community.
--

ShowMeTheMoney = {};
ShowMeTheMoney.dt = 0;
ShowMeTheMoney.enabled = true;
ShowMeTheMoney.fontSize = 0.014;
ShowMeTheMoney.money = 0;
ShowMeTheMoney.moneyDisplay = "";
ShowMeTheMoney.posX = 0;
ShowMeTheMoney.posY = 0;

local modItem = ModsUtil.findModItemByModName(g_currentModName);
ShowMeTheMoney.version = (modItem and modItem.version) and modItem.version or "?.?.?";

function ShowMeTheMoney:loadMap(name)
  if not g_currentMission.missionDynamicInfo.isMultiplayer then --this mod is only useful in a multiplayer game
    self.enabled = false;
    --print('ShowMeTheMoney:loadMap - self.enabled = false');
  end;
end;

function ShowMeTheMoney:deleteMap()
end;

function ShowMeTheMoney:keyEvent(unicode, sym, modifier, isDown)
end;

function ShowMeTheMoney:mouseEvent(posX, posY, isDown, isUp, button)
end;

function ShowMeTheMoney:draw()
  if self.enabled then
    if self:isDisplayer() then
      setTextAlignment(RenderText.ALIGN_RIGHT);
      setTextColor(0.9961, 0.7490, 0.0039, 1); -- money icon colour [R, G, B, Alpha (0-1)]
      renderText(self.posX, self.posY, self.fontSize, self.moneyDisplay);
      setTextColor(1, 1, 1, 1);  -- in case another text rendering function does not set color before rendering text, this resets it to white
      setTextAlignment(RenderText.ALIGN_LEFT);  -- in case another text rendering function does not set alignment, this resets it to left
    end;
  end;
end;

function ShowMeTheMoney:isDisplayer() --is a player who should display the separate server money value
  if not g_currentMission.isMasterUser and g_dedicatedServerInfo == nil then --only display on non-admin players who are not hosting the game
    return true;
  else
    return false;
  end;
end;

function ShowMeTheMoney:setMoney(serverMoney)
  --print('ShowMeTheMoney:setMoney set self.money "' .. tostring(self.money) .. '" to serverMoney "' .. tostring(serverMoney) .. '"');
  self.money = serverMoney;
end;

function ShowMeTheMoney:update(dt)
  if self.enabled then
    if not self.firstRun then
      if g_server == nil and g_client ~= nil then
        --print('ShowMeTheMoney:update - g_client:getServerConnection():sendEvent');
        g_client:getServerConnection():sendEvent(ShowMeTheMoney_ClientToServer_Event:new());
      end;
      self.firstRun = true;
    end;
    if g_currentMission:getIsServer() then
      self.money = g_currentMission:getTotalMoney();      
      if self.money ~= self.moneyLastUpdate then
        --print('ShowMeTheMoney:update - self.moneyLastUpdate "' .. tostring(self.moneyLastUpdate) .. '" self.money "' .. tostring(self.money) .. '"');
        self.moneyLastUpdate = self.money;
        --print('ShowMeTheMoney:update - self.moneyLastUpdate "' .. tostring(self.moneyLastUpdate) .. '" self.money "' .. tostring(self.money) .. '"');
        self.sendUpdate = true; -- send updates while money changes
        --print('ShowMeTheMoney:update - self.sendUpdate = true');
      end;
    end;
    if self.sendUpdate then
      if self.dt >= 1000 then
        self.dt = 0;
        self.sendUpdate = false;
        --print('ShowMeTheMoney:update - ShowMeTheMoney_ServerToClient_Event:sendEvent');
        ShowMeTheMoney_ServerToClient_Event:sendEvent();
      else
        self.dt = self.dt + dt;
      end;
    end;
    if self:isDisplayer() then
      self.fontSize = g_currentMission.timeScaleTextSize; --smallest infobar base game text; larger option is g_currentMission.inGameMessage.textSize;
      self.moneyDisplay = tostring(g_i18n:formatNumber(self.money, 0));
      self.posX = g_currentMission.infoBarBgOverlay.x + g_currentMission.infoBarBgOverlay.width - g_currentMission.moneyTextOffsetX; --align with player money
      self.posY = g_currentMission.infoBarBgOverlay.y + g_currentMission.moneyTextOffsetY - (self.fontSize * 1.25);
    end;
  end;
end;

addModEventListener(ShowMeTheMoney);

ShowMeTheMoney_ServerToClient_Event = {};
ShowMeTheMoney_ServerToClient_Event_mt = Class(ShowMeTheMoney_ServerToClient_Event, Event);
InitEventClass(ShowMeTheMoney_ServerToClient_Event, "ShowMeTheMoney_ServerToClient_Event");

function ShowMeTheMoney_ServerToClient_Event:emptyNew()
  --print('ShowMeTheMoney_ServerToClient_Event:emptyNew');
  local self = Event:new(ShowMeTheMoney_ServerToClient_Event_mt);
  self.className = "ShowMeTheMoney_ServerToClient_Event";
  return self;
end;

function ShowMeTheMoney_ServerToClient_Event:new()
  --print('ShowMeTheMoney_ServerToClient_Event:new');
  local self = ShowMeTheMoney_ServerToClient_Event:emptyNew();
  self.money = g_currentMission:getTotalMoney();
  return self;
end;

function ShowMeTheMoney_ServerToClient_Event:readStream(streamId, connection)
  self.money = streamReadInt32(streamId);	
  if not connection:getIsServer() then
    --print('ShowMeTheMoney_ServerToClient_Event:readStream - g_server:broadcastEvent');
    g_server:broadcastEvent(ShowMeTheMoney_ServerToClient_Event:new(), false, connection);
  else
    --print('ShowMeTheMoney_ServerToClient_Event:readStream - self:run');
    self:run();
  end;
end;

function ShowMeTheMoney_ServerToClient_Event:run()
  --print('ShowMeTheMoney_ServerToClient_Event:run');
  ShowMeTheMoney:setMoney(self.money);
end;

function ShowMeTheMoney_ServerToClient_Event:sendEvent()
  if g_currentMission:getIsServer() then
    --print('ShowMeTheMoney_ServerToClient_Event:sendEvent - g_server:broadcastEvent');
    g_server:broadcastEvent(ShowMeTheMoney_ServerToClient_Event:new());
  else
    --print('ShowMeTheMoney_ServerToClient_Event:sendEvent - g_client:getServerConnection():sendEvent');
    g_client:getServerConnection():sendEvent(ShowMeTheMoney_ServerToClient_Event:new())
  end;
end;

function ShowMeTheMoney_ServerToClient_Event:writeStream(streamId, connection)
  --print('ShowMeTheMoney_ServerToClient_Event:writeStream');
  streamWriteInt32(streamId, self.money);
end;

ShowMeTheMoney_ClientToServer_Event = {};
ShowMeTheMoney_ClientToServer_Event_mt = Class(ShowMeTheMoney_ClientToServer_Event, Event);
InitEventClass(ShowMeTheMoney_ClientToServer_Event, "ShowMeTheMoney_ClientToServer_Event");

function ShowMeTheMoney_ClientToServer_Event:emptyNew()
  --print('ShowMeTheMoney_ClientToServer_Event:emptyNew');
  local self = Event:new(ShowMeTheMoney_ClientToServer_Event_mt);
  self.className = "ShowMeTheMoney_ClientToServer_Event";
  return self;
end;

function ShowMeTheMoney_ClientToServer_Event:new()
  --print('ShowMeTheMoney_ClientToServer_Event:new');
  local self = ShowMeTheMoney_ClientToServer_Event:emptyNew();
  return self;
end;

function ShowMeTheMoney_ClientToServer_Event:readStream(streamId, connection)
  --print('ShowMeTheMoney_ClientToServer_Event:readStream');
  self:run(connection);
end;

function ShowMeTheMoney_ClientToServer_Event:run(connection)
  --print('ShowMeTheMoney_ClientToServer_Event:run - connection:sendEvent');
  connection:sendEvent(ShowMeTheMoney_ServerToClient_Event:new());
end;

function ShowMeTheMoney_ClientToServer_Event:writeStream(streamId, connection)
  --print('ShowMeTheMoney_ClientToServer_Event:writeStream');
end;

print(string.format("Script loaded: ShowMeTheMoney.lua (v%s)", ShowMeTheMoney.version));

--
-- @history 1.0.0.0  2017-10-01  Initial release for Farming Simulator 17
--          1.0.0.1  2017-10-05  Fix issue where 2nd player gets invalid event ID error
--          1.0.0.2  2017-10-08  Fix issue where subsequent updates are sometimes not sent to the client
--