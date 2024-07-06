---@class SetDischargeNodeEnabledEvent : Event
---@field placeable PlaceableMaterialDischarge
---@field nodeIndex number
---@field enabled boolean
SetDischargeNodeEnabledEvent = {}

local SetDischargeNodeEnabledEvent_mt = Class(SetDischargeNodeEnabledEvent, Event)

InitEventClass(SetDischargeNodeEnabledEvent, 'SetDischargeNodeEnabledEvent')

---@return SetDischargeNodeEnabledEvent
function SetDischargeNodeEnabledEvent.emptyNew()
    ---@type SetDischargeNodeEnabledEvent
    local self = Event.new(SetDischargeNodeEnabledEvent_mt)
    return self
end

---@param placeable PlaceableMaterialDischarge
---@param nodeIndex number
---@param enabled boolean
---@return SetDischargeNodeEnabledEvent
---@nodiscard
function SetDischargeNodeEnabledEvent.new(placeable, nodeIndex, enabled)
    local self = SetDischargeNodeEnabledEvent.emptyNew()

    self.placeable = placeable
    self.nodeIndex = nodeIndex
    self.enabled = enabled

    return self
end

---@param streamId number
---@param connection Connection
function SetDischargeNodeEnabledEvent:writeStream(streamId, connection)
    NetworkUtil.writeNodeObject(streamId, self.placeable)
    streamWriteUIntN(streamId, self.nodeIndex, DischargeNode.SEND_NUM_BITS_INDEX)
    streamWriteBool(streamId, self.enabled)
end

---@param streamId number
---@param connection Connection
function SetDischargeNodeEnabledEvent:readStream(streamId, connection)
    self.placeable = NetworkUtil.readNodeObject(streamId)
    self.nodeIndex = streamReadUIntN(streamId, DischargeNode.SEND_NUM_BITS_INDEX)
    self.enabled = streamReadBool(streamId)

    self:run(connection)
end

---@param connection Connection
function SetDischargeNodeEnabledEvent:run(connection)
    if not connection:getIsServer() then
        g_server:broadcastEvent(self, nil, connection, self.placeable)
    end

    if self.placeable ~= nil and self.placeable:getIsSynchronized() then
        local dischargeNode = self.placeable:getDischargeNodeByIndex(self.nodeIndex)

        if dischargeNode ~= nil then
            dischargeNode:setEnabled(self.enabled, true)
        end
    end
end

---@param dischargeNode DischargeNode
---@param enabled boolean
---@param noEventSend boolean | nil
function SetDischargeNodeEnabledEvent.sendEvent(dischargeNode, enabled, noEventSend)
    if not noEventSend then
        local event = SetDischargeNodeEnabledEvent.new(dischargeNode.placeable, dischargeNode.index, enabled)

        if g_server ~= nil then
            g_server:broadcastEvent(event, nil, nil, dischargeNode.placeable)
        else
            g_client:getServerConnection():sendEvent(event)
        end
    end
end
