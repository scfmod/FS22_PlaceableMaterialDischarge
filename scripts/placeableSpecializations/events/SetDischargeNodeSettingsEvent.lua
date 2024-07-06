---@class SetDischargeNodeSettingsEvent : Event
---@field placeable PlaceableMaterialDischarge
---@field nodeIndex number
---@field canDischargeToGround boolean
---@field canDischargeToObject boolean
---@field canDischargeToAnyObject boolean
SetDischargeNodeSettingsEvent = {}

local SetDischargeNodeSettingsEvent_mt = Class(SetDischargeNodeSettingsEvent, Event)

InitEventClass(SetDischargeNodeSettingsEvent, 'SetDischargeNodeSettingsEvent')

---@return SetDischargeNodeSettingsEvent
function SetDischargeNodeSettingsEvent.emptyNew()
    ---@type SetDischargeNodeSettingsEvent
    local self = Event.new(SetDischargeNodeSettingsEvent_mt)
    return self
end

---@param placeable PlaceableMaterialDischarge
---@param nodeIndex number
---@param canDischargeToGround boolean
---@param canDischargeToObject boolean
---@param canDischargeToAnyObject boolean
---@return SetDischargeNodeSettingsEvent
---@nodiscard
function SetDischargeNodeSettingsEvent.new(placeable, nodeIndex, canDischargeToGround, canDischargeToObject, canDischargeToAnyObject)
    local self = SetDischargeNodeSettingsEvent.emptyNew()

    self.placeable = placeable
    self.nodeIndex = nodeIndex
    self.canDischargeToGround = canDischargeToGround
    self.canDischargeToObject = canDischargeToObject
    self.canDischargeToAnyObject = canDischargeToAnyObject

    return self
end

---@param streamId number
---@param connection Connection
function SetDischargeNodeSettingsEvent:writeStream(streamId, connection)
    NetworkUtil.writeNodeObject(streamId, self.placeable)
    streamWriteUIntN(streamId, self.nodeIndex, DischargeNode.SEND_NUM_BITS_INDEX)
    streamWriteBool(streamId, self.canDischargeToGround)
    streamWriteBool(streamId, self.canDischargeToObject)
    streamWriteBool(streamId, self.canDischargeToAnyObject)
end

---@param streamId number
---@param connection Connection
function SetDischargeNodeSettingsEvent:readStream(streamId, connection)
    self.placeable = NetworkUtil.readNodeObject(streamId)
    self.nodeIndex = streamReadUIntN(streamId, DischargeNode.SEND_NUM_BITS_INDEX)
    self.canDischargeToGround = streamReadBool(streamId)
    self.canDischargeToObject = streamReadBool(streamId)
    self.canDischargeToAnyObject = streamReadBool(streamId)

    self:run(connection)
end

---@param connection Connection
function SetDischargeNodeSettingsEvent:run(connection)
    if not connection:getIsServer() then
        g_server:broadcastEvent(self, nil, connection, self.placeable)
    end

    if self.placeable ~= nil and self.placeable:getIsSynchronized() then
        local dischargeNode = self.placeable:getDischargeNodeByIndex(self.nodeIndex)

        if dischargeNode ~= nil then
            dischargeNode:setCanDischargeToGround(self.canDischargeToGround, true, true)
            dischargeNode:setCanDischargeToObject(self.canDischargeToGround, true, true)
            dischargeNode:setCanDischargeToAnyObject(self.canDischargeToGround, true, true)

            g_messageCenter:publish(SetDischargeNodeSettingsEvent, dischargeNode)
        end
    end
end

---@param dischargeNode DischargeNode
---@param canDischargeToGround boolean
---@param canDischargeToObject boolean
---@param canDischargeToAnyObject boolean
---@param noEventSend boolean | nil
function SetDischargeNodeSettingsEvent.sendEvent(dischargeNode, canDischargeToGround, canDischargeToObject, canDischargeToAnyObject, noEventSend)
    if not noEventSend then
        local event = SetDischargeNodeSettingsEvent.new(dischargeNode.placeable, dischargeNode.index, canDischargeToGround, canDischargeToObject, canDischargeToAnyObject)

        if g_server ~= nil then
            g_server:broadcastEvent(event, nil, nil, dischargeNode.placeable)
        else
            g_client:getServerConnection():sendEvent(event)
        end
    end
end
