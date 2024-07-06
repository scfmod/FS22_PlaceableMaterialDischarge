---@class SetDischargeNodeLitersPerHourEvent : Event
---@field placeable PlaceableMaterialDischarge
---@field nodeIndex number
---@field litersPerHour number
SetDischargeNodeLitersPerHourEvent = {}

local SetDischargeNodeLitersPerHourEvent_mt = Class(SetDischargeNodeLitersPerHourEvent, Event)

InitEventClass(SetDischargeNodeLitersPerHourEvent, 'SetDischargeNodeLitersPerHourEvent')

---@return SetDischargeNodeLitersPerHourEvent
function SetDischargeNodeLitersPerHourEvent.emptyNew()
    ---@type SetDischargeNodeLitersPerHourEvent
    local self = Event.new(SetDischargeNodeLitersPerHourEvent_mt)
    return self
end

---@param placeable PlaceableMaterialDischarge
---@param nodeIndex number
---@param litersPerHour number
---@return SetDischargeNodeLitersPerHourEvent
---@nodiscard
function SetDischargeNodeLitersPerHourEvent.new(placeable, nodeIndex, litersPerHour)
    local self = SetDischargeNodeLitersPerHourEvent.emptyNew()

    self.placeable = placeable
    self.nodeIndex = nodeIndex
    self.litersPerHour = litersPerHour

    return self
end

---@param streamId number
---@param connection Connection
function SetDischargeNodeLitersPerHourEvent:writeStream(streamId, connection)
    NetworkUtil.writeNodeObject(streamId, self.placeable)
    streamWriteUIntN(streamId, self.nodeIndex, DischargeNode.SEND_NUM_BITS_INDEX)
    streamWriteInt32(streamId, self.litersPerHour)
end

---@param streamId number
---@param connection Connection
function SetDischargeNodeLitersPerHourEvent:readStream(streamId, connection)
    self.placeable = NetworkUtil.readNodeObject(streamId)
    self.nodeIndex = streamReadUIntN(streamId, DischargeNode.SEND_NUM_BITS_INDEX)
    self.litersPerHour = streamReadInt32(streamId)

    self:run(connection)
end

---@param connection Connection
function SetDischargeNodeLitersPerHourEvent:run(connection)
    if not connection:getIsServer() then
        g_server:broadcastEvent(self, nil, connection, self.placeable)
    end

    if self.placeable ~= nil and self.placeable:getIsSynchronized() then
        local dischargeNode = self.placeable:getDischargeNodeByIndex(self.nodeIndex)

        if dischargeNode ~= nil then
            dischargeNode:setLitersPerHour(self.litersPerHour, true)
        end
    end
end

---@param dischargeNode SpawnDischargeNode
---@param litersPerHour number
---@param noEventSend boolean | nil
function SetDischargeNodeLitersPerHourEvent.sendEvent(dischargeNode, litersPerHour, noEventSend)
    if not noEventSend then
        local event = SetDischargeNodeLitersPerHourEvent.new(dischargeNode.placeable, dischargeNode.index, litersPerHour)

        if g_server ~= nil then
            g_server:broadcastEvent(event, nil, nil, dischargeNode.placeable)
        else
            g_client:getServerConnection():sendEvent(event)
        end
    end
end
