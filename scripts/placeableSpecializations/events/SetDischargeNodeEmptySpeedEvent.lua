---@class SetDischargeNodeEmptySpeedEvent : Event
---@field placeable PlaceableMaterialDischarge
---@field nodeIndex number
---@field emptySpeed number
SetDischargeNodeEmptySpeedEvent = {}

local SetDischargeNodeEmptySpeedEvent_mt = Class(SetDischargeNodeEmptySpeedEvent, Event)

InitEventClass(SetDischargeNodeEmptySpeedEvent, 'SetDischargeNodeEmptySpeedEvent')

---@return SetDischargeNodeEmptySpeedEvent
function SetDischargeNodeEmptySpeedEvent.emptyNew()
    ---@type SetDischargeNodeEmptySpeedEvent
    local self = setmetatable({}, SetDischargeNodeEmptySpeedEvent_mt)
    return self
end

---@param placeable PlaceableMaterialDischarge
---@param nodeIndex number
---@param emptySpeed number
---@return SetDischargeNodeEmptySpeedEvent
---@nodiscard
function SetDischargeNodeEmptySpeedEvent.new(placeable, nodeIndex, emptySpeed)
    local self = SetDischargeNodeEmptySpeedEvent.emptyNew()

    self.placeable = placeable
    self.nodeIndex = nodeIndex
    self.emptySpeed = emptySpeed

    return self
end

---@param streamId number
---@param connection Connection
function SetDischargeNodeEmptySpeedEvent:writeStream(streamId, connection)
    NetworkUtil.writeNodeObject(streamId, self.placeable)
    streamWriteUIntN(streamId, self.nodeIndex, DischargeNode.SEND_NUM_BITS_INDEX)
    streamWriteInt32(streamId, self.emptySpeed)
end

---@param streamId number
---@param connection Connection
function SetDischargeNodeEmptySpeedEvent:readStream(streamId, connection)
    self.placeable = NetworkUtil.readNodeObject(streamId)
    self.nodeIndex = streamReadUIntN(streamId, DischargeNode.SEND_NUM_BITS_INDEX)
    self.emptySpeed = streamReadFloat32(streamId)

    self:run(connection)
end

---@param connection Connection
function SetDischargeNodeEmptySpeedEvent:run(connection)
    if not connection:getIsServer() then
        g_server:broadcastEvent(self, nil, connection, self.placeable)
    end

    if self.placeable ~= nil and self.placeable:getIsSynchronized() then
        local dischargeNode = self.placeable:getDischargeNodeByIndex(self.nodeIndex)

        if dischargeNode ~= nil then
            dischargeNode:setEmptySpeed(self.emptySpeed, true)
        end
    end
end

---@param dischargeNode ProductionDischargeNode
---@param emptySpeed number
---@param noEventSend boolean | nil
function SetDischargeNodeEmptySpeedEvent.sendEvent(dischargeNode, emptySpeed, noEventSend)
    if not noEventSend then
        local event = SetDischargeNodeEmptySpeedEvent.new(dischargeNode.placeable, dischargeNode.index, emptySpeed)

        if g_server ~= nil then
            g_server:broadcastEvent(event, nil, nil, dischargeNode.placeable)
        else
            g_client:getServerConnection():sendEvent(event)
        end
    end
end
