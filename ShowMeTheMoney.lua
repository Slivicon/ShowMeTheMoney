-- ShowMeTheMoney for Farming Simulator 17
-- @description: This displays the total amount of money available on the server to all players when playing a multiplayer game
-- @author: Slivicon
-- History at end of file. Thanks to timmiej93, kevink98 (Farming Tablet mod), Decker_MMIV (Glance, FollowMe) and the modding community.
--

ShowMeTheMoney = {};
ShowMeTheMoney.dt = 0;
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
  if not g_currentMission.missionDynamicInfo.isMultiplayer then
    self.enabled = false;
  end;
end;

function ShowMeTheMoney:deleteMap()
end;

function ShowMeTheMoney:mouseEvent(posX, posY, isDown, isUp, button)
end;

function ShowMeTheMoney:keyEvent(unicode, sym, modifier, isDown)
end;

function ShowMeTheMoney:update(dt)
  if self.enabled then
    if not self.firstRun then
      if g_server == nil and g_client ~= nil then -- difference between this and "if not g_currentMission:getIsServer() then"?
        g_client:getServerConnection():sendEvent(ShowMeTheMoney_ClientToServer_Event:new());
      end;
      self.firstRun = true;
    end;
    if g_currentMission:getIsServer() then
      self.dt = self.dt + dt;
      if self.dt >= 1000 then
        self.dt = self.dt - 1000;
        ShowMeTheMoney_ServerToClient_Event:sendEvent();
      end;
    end;
    if not g_currentMission.isMasterUser and g_dedicatedServerInfo == nil then -- only run on multiplayer players who are not logged in as admin
      self.fontSize = g_currentMission.inGameMessage.textSize;
      self.posX = g_currentMission.infoBarBgOverlay.x + g_currentMission.infoBarBgOverlay.width - g_currentMission.moneyTextOffsetX;
      self.posY = g_currentMission.infoBarBgOverlay.y + g_currentMission.moneyTextOffsetY - self.fontSize;
      self.moneyDisplay = tostring(g_i18n:formatNumber(self.money, 0));
    end;
  end;
end;

function ShowMeTheMoney:draw()
  if self.enabled then
    if not g_currentMission.isMasterUser and g_dedicatedServerInfo == nil then -- only run on multiplayer players who are not logged in as admin
      setTextAlignment(RenderText.ALIGN_RIGHT);
      setTextColor(0.9961, 0.7490, 0.0039, 1); -- money icon colour [R, G, B, Alpha (0-1)]
      renderText(self.posX, self.posY, self.fontSize, self.moneyDisplay);
      setTextColor(1, 1, 1, 1);  -- in case another text rendering function does not set color before rendering text, this resets it to white
      setTextAlignment(RenderText.ALIGN_LEFT);  -- in case another text rendering function does not set alignment, this resets it to left
    end;
  end;
end;

function ShowMeTheMoney:getMoney()
  return self.money;
end;

function ShowMeTheMoney:setMoney(serverMoney)
  self.money = serverMoney;
end;

addModEventListener(ShowMeTheMoney);

ShowMeTheMoney_ServerToClient_Event = {};
ShowMeTheMoney_ServerToClient_Event_mt = Class(ShowMeTheMoney_ServerToClient_Event, Event);
InitEventClass(ShowMeTheMoney_ServerToClient_Event, "ShowMeTheMoney_ServerToClient_Event");

function ShowMeTheMoney_ServerToClient_Event:emptyNew()
  local self = Event:new(ShowMeTheMoney_ServerToClient_Event_mt);
  return self;
end;

function ShowMeTheMoney_ServerToClient_Event:new()
  local self = ShowMeTheMoney_ServerToClient_Event:emptyNew();
  self.money = g_currentMission:getTotalMoney();
  return self;
end;

function ShowMeTheMoney_ServerToClient_Event:readStream(streamId, connection)
  self.money = streamReadInt32(streamId);	
  if not connection:getIsServer() then
    g_server:broadcastEvent(ShowMeTheMoney_ServerToClient_Event:new(), false, connection);
  else
    self:run();
  end;
end;

function ShowMeTheMoney_ServerToClient_Event:writeStream(streamId, connection)
  streamWriteInt32(streamId, self.money);
end;

function ShowMeTheMoney_ServerToClient_Event:run()
  ShowMeTheMoney:setMoney(self.money);
end;

function ShowMeTheMoney_ServerToClient_Event:sendEvent()
  if g_server ~= nil then
    self.money = g_currentMission:getTotalMoney();
    if self.money ~= ShowMeTheMoney:getMoney() then
      ShowMeTheMoney:setMoney(self.money);
      g_server:broadcastEvent(ShowMeTheMoney_ServerToClient_Event:new()); --g_currentMission:getTotalMoney()
    end;
  else
    g_client:getServerConnection():sendEvent(ShowMeTheMoney_ServerToClient_Event:new())
  end;
end;

ShowMeTheMoney_ClientToServer_Event = {};
ShowMeTheMoney_ClientToServer_Event_mt = Class(ShowMeTheMoney_ClientToServer_Event, Event);
InitEventClass(ShowMeTheMoney_ClientToServer_Event, "ShowMeTheMoney_ClientToServer_Event");

function ShowMeTheMoney_ClientToServer_Event:emptyNew()
  local self = Event:new(ShowMeTheMoney_ClientToServer_Event_mt);
  return self;
end;

function ShowMeTheMoney_ClientToServer_Event:new()
  local self = ShowMeTheMoney_ClientToServer_Event:emptyNew();
  return self;
end;

function ShowMeTheMoney_ClientToServer_Event:readStream(streamId, connection)
  self:run(connection);
end;

function ShowMeTheMoney_ClientToServer_Event:writeStream(streamId, connection)
end;

function ShowMeTheMoney_ClientToServer_Event:run(connection)
  connection:sendEvent(ShowMeTheMoney_ServerToClient_Event:new());
end;

print(string.format("Script loaded: ShowMeTheMoney.lua (v%s)", ShowMeTheMoney.version));

--
-- @history 1.0  2017-09-29  Initial release for Farming Simulator 17
--