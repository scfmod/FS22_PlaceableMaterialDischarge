---@class ProductionDischargeNode : DischargeNode
---@field emptySpeed number
---@field stopDischargeIfNotActive boolean
---@field stopDischargeIfNotRunning boolean
---@field litersToDrop number
---@field superClass fun(): DischargeNode
ProductionDischargeNode = {}

local ProductionDischargeNode_mt = Class(ProductionDischargeNode, DischargeNode)

---@param schema XMLSchema
---@param key string
function ProductionDischargeNode.registerXMLPaths(schema, key)
    DischargeNode.registerXMLPaths(schema, key)

    schema:register(XMLValueType.INT, key .. '#emptySpeed', 'Empty speed in l/sec', 250)
    schema:register(XMLValueType.BOOL, key .. '#stopDischargeIfNotActive', 'Stop discharge if there are no active productions', true)
    schema:register(XMLValueType.BOOL, key .. '#stopDischargeIfNotRunning', 'Stop discharge if there are no running productions', false)
end

---@param schema XMLSchema
---@param key string
function ProductionDischargeNode.registerSavegameXMLPaths(schema, key)
    schema:register(XMLValueType.INT, key .. '#emptySpeed')
end

---@param placeable PlaceableMaterialDischarge
---@param index number
---@return ProductionDischargeNode
---@nodiscard
function ProductionDischargeNode.new(placeable, index)
    ---@type ProductionDischargeNode
    ---@diagnostic disable-next-line: assign-type-mismatch
    local self = DischargeNode.new(placeable, index, DischargeNode.TYPE_PRODUCTION, ProductionDischargeNode_mt)

    self.emptySpeed = 250 / 1000
    self.stopDischargeIfNotActive = true
    self.stopDischargeIfNotRunning = false
    self.litersToDrop = 0

    return self
end

---@param xmlFile XMLFile
---@param key string
---@return boolean
---@nodiscard
function ProductionDischargeNode:load(xmlFile, key)
    if not self:superClass().load(self, xmlFile, key) then
        return false
    end

    self.emptySpeed = xmlFile:getValue(key .. '#emptySpeed', 250) / 1000
    self.stopDischargeIfNotActive = xmlFile:getValue(key .. '#stopDischargeIfNotActive', self.stopDischargeIfNotActive)
    self.stopDischargeIfNotRunning = xmlFile:getValue(key .. '#stopDischargeIfNotRunning', self.stopDischargeIfNotRunning)

    return true
end

---@param xmlFile XMLFile
---@param key string
function ProductionDischargeNode:loadFromXMLFile(xmlFile, key)
    self:superClass().loadFromXMLFile(self, xmlFile, key)

    local emptySpeed = xmlFile:getValue(key .. '#emptySpeed')

    if emptySpeed ~= nil then
        self:setEmptySpeed(emptySpeed / 1000, true)
    end
end

---@param xmlFile XMLFile
---@param key string
function ProductionDischargeNode:saveToXMLFile(xmlFile, key)
    self:superClass().saveToXMLFile(self, xmlFile, key)

    xmlFile:setValue(key .. '#emptySpeed', self.emptySpeed * 1000)
end

-- Override the default setEnabled() function
---@param enabled boolean
---@param noEventSend boolean | nil
function ProductionDischargeNode:setEnabled(enabled, noEventSend)
    if self.enabled ~= enabled then
        SetDischargeNodeEnabledEvent.sendEvent(self, enabled, noEventSend)

        self.enabled = enabled

        if not enabled then
            self:setState(Dischargeable.DISCHARGE_STATE_OFF, true)
        end

        g_messageCenter:publish(SetDischargeNodeEnabledEvent, self, enabled)
    end
end

---@param emptySpeed number
---@param noEventSend boolean | nil
function ProductionDischargeNode:setEmptySpeed(emptySpeed, noEventSend)
    if self.emptySpeed ~= nil then
        SetDischargeNodeEmptySpeedEvent.sendEvent(self, emptySpeed, noEventSend)

        self.emptySpeed = emptySpeed

        g_messageCenter:publish(SetDischargeNodeEmptySpeedEvent, self, emptySpeed)
    end
end

---@param dt number
function ProductionDischargeNode:updateTick(dt)
    if self.state == Dischargeable.DISCHARGE_STATE_OFF then
        if self.dischargeObject ~= nil then
            self:handleFoundDischargeObject()
        end

        return
    elseif self.state == Dischargeable.DISCHARGE_STATE_GROUND and self:getCanDischargeToObject() then
        self:handleFoundDischargeObject()
        return
    end

    local storageFillLevel = self:getStorageFillLevel()
    local hasActiveProductions, hasRunningProductions = self:getProductionsStatus()

    local canDischargeToObject = self.state == Dischargeable.DISCHARGE_STATE_OBJECT and self:getCanDischargeToObject()
    local canDischargeToGround = self.state == Dischargeable.DISCHARGE_STATE_GROUND and self:getCanDischargeToGround()
    local canDischarge = canDischargeToObject or canDischargeToGround

    local allowedToDischarge = self.dischargeObject ~= nil or self:getCanDischargeAtPosition()


    if not hasActiveProductions and self.stopDischargeIfNotActive then
        allowedToDischarge = false
    elseif not hasRunningProductions and self.stopDischargeIfNotRunning then
        allowedToDischarge = false
    elseif storageFillLevel < self.currentMinValidLiters and not hasRunningProductions then
        if self.state == Dischargeable.DISCHARGE_STATE_GROUND then
            allowedToDischarge = false
        elseif self.state == Dischargeable.DISCHARGE_STATE_OBJECT and storageFillLevel == 0 then
            allowedToDischarge = false
        end
    end

    local isReadyToStartDischarge = canDischarge and allowedToDischarge

    self:setDischargeEffectActive(isReadyToStartDischarge)
    self:setDischargeEffectDistance(self.dischargeDistance)

    local isReadyForDischarge = self.lastEffect == nil or self.lastEffect:getIsFullyVisible()

    if isReadyToStartDischarge and isReadyForDischarge and allowedToDischarge then
        local emptyLiters = math.min(storageFillLevel, self.emptySpeed * dt)
        local dischargedLiters, minDropReached, hasMinDropFillLevel = self:discharge(emptyLiters)

        self:handleDischarge(dischargedLiters, minDropReached, hasMinDropFillLevel)
    end
end

---@param dischargedLiters number
---@param minDropReached boolean
---@param hasMinDropFillLevel boolean
function ProductionDischargeNode:handleDischarge(dischargedLiters, minDropReached, hasMinDropFillLevel)
    if self.state == Dischargeable.DISCHARGE_STATE_GROUND then
        local canDrop = not minDropReached and hasMinDropFillLevel

        if self.stopDischargeIfNotPossible and dischargedLiters == 0 and not canDrop then
            self:setState(Dischargeable.DISCHARGE_STATE_OFF)
        elseif self:getCanDischargeToObject() then
            self:setState(Dischargeable.DISCHARGE_STATE_OBJECT)
        end
    elseif self.stopDischargeIfNotPossible and dischargedLiters == 0 then
        self:setState(Dischargeable.DISCHARGE_STATE_OFF)
    end

    if dischargedLiters > 0 then
        local storage = self:getStorage()
        local fillTypeIndex = self:getFillTypeIndex()
        local fillLevel = storage:getFillLevel(fillTypeIndex)

        storage:setFillLevel(fillLevel - dischargedLiters, fillTypeIndex)
    end
end

---@param object table | nil
---@param shape any | nil
---@param distance number | nil
---@param fillUnitIndex number | nil
---@param hitTerrain boolean | nil
function ProductionDischargeNode:handleDischargeRaycast(object, shape, distance, fillUnitIndex, hitTerrain)
    if object == nil then
        if self.state == Dischargeable.DISCHARGE_STATE_OBJECT then
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
function ProductionDischargeNode:dischargeToGround(emptyLiters)
    if emptyLiters == 0 then
        return 0, false, false
    end

    local fillLevel, fillTypeIndex = self:getStorageFillLevel()
    local minLiterToDrop = g_densityMapHeightManager:getMinValidLiterValue(fillTypeIndex)
    local info = self.info

    self.litersToDrop = math.min(self.litersToDrop + emptyLiters, math.max(self.emptySpeed * 250, minLiterToDrop))

    local minDropReached = minLiterToDrop < self.litersToDrop
    local hasMinDropFillLevel = minLiterToDrop < fillLevel

    local sx, sy, sz = localToWorld(info.node, -info.width, 0, info.zOffset)
    local ex, ey, ez = localToWorld(info.node, info.width, 0, info.zOffset)

    sy = sy + info.yOffset
    ey = ey + info.yOffset

    if info.limitToGround then
        sy = math.max(getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, sx, 0, sz) + 0.1, sy)
        ey = math.max(getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, ex, 0, ez) + 0.1, ey)
    end

    local dropped, lineOffset = DensityMapHeightUtil.tipToGroundAroundLine(self, self.litersToDrop, fillTypeIndex, sx, sy, sz, ex, ey, ez, info.length, nil, self.lineOffset, true, nil, true)

    self.lineOffset = lineOffset
    self.litersToDrop = self.litersToDrop - dropped

    return dropped, minDropReached, hasMinDropFillLevel
end

---@return Storage
---@nodiscard
function ProductionDischargeNode:getStorage()
    return self.placeable.spec_productionPoint.productionPoint.storage
end

---@return number fillLevel
---@return number fillTypeIndex
---@nodiscard
function ProductionDischargeNode:getStorageFillLevel()
    local storage = self:getStorage()
    local fillTypeIndex = self:getFillTypeIndex()

    return storage:getFillLevel(fillTypeIndex), fillTypeIndex
end

---@return { status: number }[]
---@nodiscard
function ProductionDischargeNode:getProductions()
    return self.placeable.spec_productionPoint.productionPoint.productions
end

---@return boolean hasActiveProductions
---@return boolean hasRunningProductions
---@nodiscard
function ProductionDischargeNode:getProductionsStatus()
    local isActive = false
    local isRunning = false

    for _, production in ipairs(self:getProductions()) do
        if production.status ~= ProductionPoint.PROD_STATUS.INACTIVE then
            isActive = true

            if production.status == ProductionPoint.PROD_STATUS.RUNNING then
                isRunning = true
            end
        end
    end

    return isActive, isRunning
end

---@param streamId number
---@param connection Connection
function ProductionDischargeNode:writeStream(streamId, connection)
    self:superClass().writeStream(self, streamId, connection)

    streamWriteFloat32(streamId, self.emptySpeed)
end

---@param streamId number
---@param connection Connection
function ProductionDischargeNode:readStream(streamId, connection)
    self:superClass().readStream(self, streamId, connection)

    self.emptySpeed = streamReadFloat32(streamId)
end
