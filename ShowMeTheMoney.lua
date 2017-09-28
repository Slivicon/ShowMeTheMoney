-- ShowMeTheMoney for Farming Simulator 17
-- @description: This displays the total amount of money available on the server to all players when playing a multiplayer game
-- @author: Slivicon
-- History at end of file.
--

ShowMeTheMoney = {};
ShowMeTheMoney.enabled = true;
ShowMeTheMoney.fontSize = 0.014;
ShowMeTheMoney.money = 42;
ShowMeTheMoney.moneyDisplay = "--";
ShowMeTheMoney.posX = 1.0;
ShowMeTheMoney.posY = 1.0;

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
  if self.enabled == true and g_currentMission:getIsServer() then
    local serverMoney = g_currentMission:getTotalMoney();
    if self.money ~= serverMoney then
      print("self.money '" .. tostring(self.money) .. "' serverMoney '" .. tostring(serverMoney) .. "'");
      self.money = serverMoney;
      ShowMeTheMoneyEvent.sendEvent();
    end;
  end;
  if self.enabled == false or g_currentMission.isMasterUser then
    return;
  end;
  self.fontSize = g_currentMission.inGameMessage.textSize;
  self.posX = g_currentMission.infoBarBgOverlay.x + g_currentMission.infoBarBgOverlay.width - g_currentMission.moneyTextOffsetX;
  self.posY = g_currentMission.infoBarBgOverlay.y + g_currentMission.moneyTextOffsetY - ShowMeTheMoney.fontSize;
--  self.money = tostring(g_i18n:formatNumber(g_currentMission:getTotalMoney(), 0));
  self.moneyDisplay = tostring(g_i18n:formatNumber(self.money, 0));
end;

function ShowMeTheMoney:draw()
  --not g_currentMission.showHudEnv
  if self.enabled == false or g_currentMission.isMasterUser then
    return;
  end;
  setTextAlignment(RenderText.ALIGN_RIGHT);
  setTextColor(0.9961, 0.7490, 0.0039, 1); -- money icon colour [R, G, B, Alpha (0-1)]
  renderText(self.posX, self.posY, self.fontSize, self.moneyDisplay);
  setTextColor(1, 1, 1, 1);  -- in case another text rendering function does not set color before rendering text, this resets it to white
  setTextAlignment(RenderText.ALIGN_LEFT);  -- in case another text rendering function does not set alignment, this resets it to left
end;

addModEventListener(ShowMeTheMoney);

ShowMeTheMoneyEvent = {};
ShowMeTheMoneyEvent_mt = Class(ShowMeTheMoneyEvent, Event);

InitEventClass(ShowMeTheMoneyEvent, "ShowMeTheMoneyEvent");

function ShowMeTheMoneyEvent:emptyNew()
  local self = Event:new(ShowMeTheMoneyEvent_mt);
  self.className = "ShowMeTheMoneyEvent";
  return self;
end;

function ShowMeTheMoneyEvent:new()
  local self = ShowMeTheMoneyEvent:emptyNew()
  return self;
end;

function ShowMeTheMoneyEvent:readStream(streamId, connection)
  local netId = streamReadInt32(streamId);
  if netId == nil then
    print('netId was nil');
    netId = 0;
  end;
  local money = streamReadInt32(streamId);
  local obj = ShowMeTheMoney;
  if netId ~= 0 then
    print('netId is "' .. tostring(netId) .. '"');
    obj = networkGetObject(netId);
  end;
  if obj ~= nil then
    print("ShowMeTheMoneyEvent:readStream - ShowMeTheMoney object not nil, setting money value")
    obj.money = money;
  end;
end;


function ShowMeTheMoneyEvent:writeStream(streamId, connection)
  local obj = ShowMeTheMoney;
  local money = obj.money;
  if money ~= nil then
    local netId = networkGetObjectId(obj);
    if netId == nil then
      print("netId was nil");
      netId = 0;
    end;
    if money == nil then
      print("streamWriteInt32 money was nil.");
      money = 0;
    end;
    streamWriteInt32(streamId, netId);
    streamWriteInt32(streamId, money);
  end;
end;

function ShowMeTheMoneyEvent.sendEvent(noEventSend)
  if noEventSend == nil or noEventSend == false then
    if g_server ~= nil then
      print("g_server:broadcastEvent");
      g_server:broadcastEvent(ShowMeTheMoneyEvent:new());
    end;
  end;
end;

print(string.format("Script loaded: ShowMeTheMoney.lua (v%s)", ShowMeTheMoney.version));

--
-- @history 1.0  2017-09-25  Initial release for Farming Simulator 17
--