---@class SpawnDischargeNode : DischargeNode
---@field litersPerHour number
---@field litersPerMs number
---@field buffer number
---@field bufferMaxSize number
---@field superClass fun(): DischargeNode
SpawnDischargeNode = {}

SpawnDischargeNode.LITERS_MIN_VALUE = 10
SpawnDischargeNode.LITERS_MAX_VALUE = 999999

local SpawnDischargeNode_mt = Class(SpawnDischargeNode, DischargeNode)

---@param schema XMLSchema
---@param key string
function SpawnDischargeNode.registerXMLPaths(schema, key)
    DischargeNode.registerXMLPaths(schema, key)

    schema:register(XMLValueType.INT, key .. '#litersPerHour', 'Liters generated per hour', 1000)
end

---@param schema XMLSchema
---@param key string
function SpawnDischargeNode.registerSavegameXMLPaths(schema, key)
    schema:register(XMLValueType.INT, key .. '#litersPerHour')
end

---@param placeable PlaceableMaterialDischarge
---@param index number
---@return SpawnDischargeNode
---@nodiscard
function SpawnDischargeNode.new(placeable, index)
    ---@type SpawnDischargeNode
    ---@diagnostic disable-next-line: assign-type-mismatch
    local self = DischargeNode.new(placeable, index, DischargeNode.TYPE_SPAWN, SpawnDischargeNode_mt)

    self.litersPerHour = 1000
    self.litersPerMs = self.litersPerHour / 3600 / 1000
    self.buffer = 0
    self.bufferMaxSize = 250

    return self
end

---@param xmlFile XMLFile
---@param key string
---@return boolean
---@nodiscard
function SpawnDischargeNode:load(xmlFile, key)
    if not self:superClass().load(self, xmlFile, key) then
        return false
    end

    self:setLitersPerHour(xmlFile:getValue(key .. '#litersPerHour', self.litersPerHour), true)

    return true
end

---@param xmlFile XMLFile
---@param key string
function SpawnDischargeNode:loadFromXMLFile(xmlFile, key)
    self:superClass().loadFromXMLFile(self, xmlFile, key)

    local litersPerHour = xmlFile:getValue(key .. '#litersPerHour')

    if litersPerHour ~= nil then
        self:setLitersPerHour(litersPerHour, true)
    end
end

---@param xmlFile XMLFile
---@param key string
function SpawnDischargeNode:saveToXMLFile(xmlFile, key)
    self:superClass().saveToXMLFile(self, xmlFile, key)

    xmlFile:setValue(key .. '#litersPerHour', self.litersPerHour)
end

---@param litersPerHour number
---@param noEventSend boolean | nil
function SpawnDischargeNode:setLitersPerHour(litersPerHour, noEventSend)
    if self.litersPerHour ~= litersPerHour then
        SetDischargeNodeLitersPerHourEvent.sendEvent(self, litersPerHour, noEventSend)

        self.litersPerHour = litersPerHour
        self.litersPerMs = litersPerHour / 3600 / 1000

        g_messageCenter:publish(SetDischargeNodeLitersPerHourEvent, self, litersPerHour)
    end
end

-- Override default function
---@param enabled boolean
---@param noEventSend boolean | nil
function SpawnDischargeNode:setEnabled(enabled, noEventSend)
    if self.enabled ~= enabled then
        SetDischargeNodeEnabledEvent.sendEvent(self, enabled, noEventSend)

        self.enabled = enabled

        if not enabled then
            self:setState(Dischargeable.DISCHARGE_STATE_OFF, true)
        elseif not self.stopDischargeIfNotPossible then
            if self.canDischargeToGround then
                self:setState(Dischargeable.DISCHARGE_STATE_GROUND, true)
            elseif self.canDischargeToObject then
                self:setState(Dischargeable.DISCHARGE_STATE_OBJECT, true)
            end
        end

        g_messageCenter:publish(SetDischargeNodeEnabledEvent, self, enabled)
    end
end

---@return boolean
---@nodiscard
function SpawnDischargeNode:getCanDischargeAtPosition()
    if not self.canDischargeToGround then
        return false
    end

    return self:superClass().getCanDischargeAtPosition(self)
end

---@private
---@param dt number
function SpawnDischargeNode:updateTick(dt)
    local amount = g_currentMission:getEffectiveTimeScale() * dt * self.litersPerMs

    self.buffer = math.min(self.buffer + amount, self.currentMinValidLiters * 10)

    if self.state == Dischargeable.DISCHARGE_STATE_OFF then
        if self.dischargeObject ~= nil then
            self:handleFoundDischargeObject()
        end
    elseif self.state == Dischargeable.DISCHARGE_STATE_GROUND and self:getCanDischargeToObject() then
        self:handleFoundDischargeObject()
    else
        local canDischargeToObject = self.state == Dischargeable.DISCHARGE_STATE_OBJECT and self:getCanDischargeToObject()
        local canDischargeToGround = self.state == Dischargeable.DISCHARGE_STATE_GROUND and self:getCanDischargeToGround()
        local canDischarge = canDischargeToObject or canDischargeToGround
        local isAllowedToDischarge = self.dischargeObject ~= nil or self:getCanDischargeAtPosition()

        local isReadyToStartDischarge = isAllowedToDischarge and canDischarge

        if not self.stopDischargeIfNotPossible then
            isReadyToStartDischarge = true
        end

        self:setDischargeEffectActive(isReadyToStartDischarge)
        self:setDischargeEffectDistance(self.dischargeDistance)

        local isReadyForDischarge = self.lastEffect == nil or self.lastEffect:getIsFullyVisible()

        if isReadyToStartDischarge and isReadyForDischarge and isAllowedToDischarge then
            local emptyLiters = self.buffer
            local dischargedLiters, minDropReached, hasMinDropFillLevel = self:discharge(emptyLiters)

            self:handleDischarge(dischargedLiters, minDropReached, hasMinDropFillLevel)
        end
    end
end

---@param dischargedLiters number
---@param minDropReached boolean
---@param hasMinDropFillLevel boolean
function SpawnDischargeNode:handleDischarge(dischargedLiters, minDropReached, hasMinDropFillLevel)
    if self.state == Dischargeable.DISCHARGE_STATE_GROUND then
        local canDrop = not minDropReached and hasMinDropFillLevel

        if self.stopDischargeIfNotPossible and dischargedLiters == 0 and not canDrop then
            -- void
        elseif self:getCanDischargeToObject() then
            self:setState(Dischargeable.DISCHARGE_STATE_OBJECT)
        end
    elseif self.stopDischargeIfNotPossible and dischargedLiters == 0 then
        self:setState(Dischargeable.DISCHARGE_STATE_OFF)
    end

    if dischargedLiters > 0 then
        self.buffer = 0
    end
end

---@param object table | nil
---@param shape any | nil
---@param distance number | nil
---@param fillUnitIndex number | nil
---@param hitTerrain boolean | nil
function SpawnDischargeNode:handleDischargeRaycast(object, shape, distance, fillUnitIndex, hitTerrain)
    if object == nil then
        if self.state == Dischargeable.DISCHARGE_STATE_OBJECT and self.stopDischargeIfNotPossible then
            self:setState(Dischargeable.DISCHARGE_STATE_OFF)
        end

        if self:getCanDischargeToGround() then
            self:setState(Dischargeable.DISCHARGE_STATE_GROUND)
        end
    end
end

---@param emptyLiters number
---@return number dischargedLiters
---@return boolean minDropReached
---@return boolean hasMinDropFillLevel
function SpawnDischargeNode:dischargeToGround(emptyLiters)
    if emptyLiters == 0 then
        return 0, false, false
    end

    local fillTypeIndex = self:getFillTypeIndex()
    local fillLevel = self.buffer
    local minLiterToDrop = g_densityMapHeightManager:getMinValidLiterValue(fillTypeIndex)

    if fillLevel < minLiterToDrop then
        return 0, false, false
    end

    local info = self.info

    local sx, sy, sz = localToWorld(info.node, -info.width, 0, info.zOffset)
    local ex, ey, ez = localToWorld(info.node, info.width, 0, info.zOffset)

    sy = sy + info.yOffset
    ey = ey + info.yOffset

    if info.limitToGround then
        sy = math.max(getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, sx, 0, sz) + 0.1, sy)
        ey = math.max(getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, ex, 0, ez) + 0.1, ey)
    end

    local dropped, lineOffset = DensityMapHeightUtil.tipToGroundAroundLine(nil, emptyLiters, fillTypeIndex, sx, sy, sz, ex, ey, ez, info.length, nil, self.lineOffset, true, nil, true)

    self.lineOffset = lineOffset

    return dropped, true, true
end

---@param streamId number
---@param connection Connection
function SpawnDischargeNode:writeStream(streamId, connection)
    self:superClass().writeStream(self, streamId, connection)

    streamWriteInt32(streamId, self.litersPerHour)
end

---@param streamId number
---@param connection Connection
function SpawnDischargeNode:readStream(streamId, connection)
    self:superClass().readStream(self, streamId, connection)

    self.litersPerHour = streamReadInt32(streamId)
end
