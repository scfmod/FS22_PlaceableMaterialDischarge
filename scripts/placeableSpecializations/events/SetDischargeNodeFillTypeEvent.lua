---@class SetDischargeNodeFillTypeEvent : Event
---@field placeable PlaceableMaterialDischarge
---@field nodeIndex number
---@field fillTypeIndex number
SetDischargeNodeFillTypeEvent = {}

local SetDischargeNodeFillTypeEvent_mt = Class(SetDischargeNodeFillTypeEvent, Event)

InitEventClass(SetDischargeNodeFillTypeEvent, 'SetDischargeNodeFillTypeEvent')

---@return SetDischargeNodeFillTypeEvent
function SetDischargeNodeFillTypeEvent.emptyNew()
    ---@type SetDischargeNodeFillTypeEvent
    local self = Event.new(SetDischargeNodeFillTypeEvent_mt)
    return self
end

---@param placeable PlaceableMaterialDischarge
---@param nodeIndex number
---@param fillTypeIndex number
---@return SetDischargeNodeFillTypeEvent
---@nodiscard
function SetDischargeNodeFillTypeEvent.new(placeable, nodeIndex, fillTypeIndex)
    local self = SetDischargeNodeFillTypeEvent.emptyNew()

    self.placeable = placeable
    self.nodeIndex = nodeIndex
    self.fillTypeIndex = fillTypeIndex

    return self
end

---@param streamId number
---@param connection Connection
function SetDischargeNodeFillTypeEvent:writeStream(streamId, connection)
    NetworkUtil.writeNodeObject(streamId, self.placeable)
    streamWriteUIntN(streamId, self.nodeIndex, DischargeNode.SEND_NUM_BITS_INDEX)
    streamWriteUIntN(streamId, self.fillTypeIndex, FillTypeManager.SEND_NUM_BITS)
end

---@param streamId number
---@param connection Connection
function SetDischargeNodeFillTypeEvent:readStream(streamId, connection)
    self.placeable = NetworkUtil.readNodeObject(streamId)
    self.nodeIndex = streamReadUIntN(streamId, DischargeNode.SEND_NUM_BITS_INDEX)
    self.fillTypeIndex = streamReadUIntN(streamId, FillTypeManager.SEND_NUM_BITS)

    self:run(connection)
end

---@param connection Connection
function SetDischargeNodeFillTypeEvent:run(connection)
    if not connection:getIsServer() then
        g_server:broadcastEvent(self, nil, connection, self.placeable)
    end

    if self.placeable ~= nil and self.placeable:getIsSynchronized() then
        local dischargeNode = self.placeable:getDischargeNodeByIndex(self.nodeIndex)

        if dischargeNode ~= nil then
            dischargeNode:setFillTypeIndex(self.fillTypeIndex, true)
        end
    end
end

---@param dischargeNode DischargeNode
---@param fillTypeIndex number
---@param noEventSend boolean | nil
function SetDischargeNodeFillTypeEvent.sendEvent(dischargeNode, fillTypeIndex, noEventSend)
    if not noEventSend then
        local event = SetDischargeNodeFillTypeEvent.new(dischargeNode.placeable, dischargeNode.index, fillTypeIndex)

        if g_server ~= nil then
            g_server:broadcastEvent(event, nil, nil, dischargeNode.placeable)
        else
            g_client:getServerConnection():sendEvent(event)
        end
    end
end
