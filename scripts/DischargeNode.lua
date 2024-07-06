---@class DischargeRaycast
---@field node number
---@field yOffset number
---@field useWorldNegYDirection boolean

---@class DischargeInfo
---@field node number
---@field width number
---@field length number
---@field zOffset number
---@field yOffset number
---@field limitToGround boolean
---@field useRaycastHitPosition boolean

---@class DischargeNode
---@field placeable PlaceableMaterialDischarge
---@field index number
---@field type number
---@field state number
---@field enabled boolean
---@field isDirty boolean
---
---@field node number
---@field name string
---@field fillTypes FillTypeObject[]
---
---@field currentFillType FillTypeObject
---@field currentMinValidLiters number
---@field canDischargeToGround boolean
---@field canDischargeToObject boolean
---@field canDischargeToAnyObject boolean
---@field stopDischargeIfNotPossible boolean
---
---@field effects table
---@field effectTurnOffThreshold number
---@field playSound boolean
---@field soundNode number
---@field dischargeSample table | nil
---@field dischargeStateSamples table | nil
---@field animationNodes table
---@field turnOffSoundTimer number | nil
---@field lastEffect table | nil
---@field stopEffectTime number | nil
---@field isEffectActive boolean
---@field isEffectActiveSent boolean
---@field dischargeDistance number
---@field dischargeDistanceSent number
---@field sample table | nil
---@field sharedSample table | nil
---@field lineOffset number
---@field raycast DischargeRaycast
---@field info DischargeInfo
---@field maxDistance number
---@field isAsyncRaycastActive boolean
---@field toolType number
---@field dischargeObject FillUnit | nil
---@field lastDischargeObject FillUnit | nil
---@field dischargeHitObject FillUnit | nil
---@field dischargeHitObjectUnitIndex number | nil
---@field dischargeHitTerrain boolean
---@field dischargeShape number | nil
---@field dischargeFillUnitIndex number
---@field dischargeHit boolean
---@field sentHitDistance number
---
---@field isClient boolean
---@field isServer boolean
---@field isa fun(self, class): boolean
DischargeNode = {}

DischargeNode.RAYCAST_COLLISION_MASK = CollisionFlag.FILLABLE + CollisionFlag.VEHICLE + CollisionFlag.TERRAIN
DischargeNode.SEND_NUM_BITS_INDEX = 4
DischargeNode.MAX_NUM_INDEX = 2 ^ DischargeNode.SEND_NUM_BITS_INDEX - 1
DischargeNode.EMPTY_SPEED_MIN = 1
DischargeNode.EMPTY_SPEED_MAX = 4000

DischargeNode.TYPE_SPAWN = 1
DischargeNode.TYPE_PRODUCTION = 2

---@type table<number, string>
DischargeNode.STATE_TO_TEXT = {
    [Dischargeable.DISCHARGE_STATE_OFF] = 'DISCHARGE_STATE_OFF',
    [Dischargeable.DISCHARGE_STATE_OBJECT] = 'DISCHARGE_STATE_OBJECT',
    [Dischargeable.DISCHARGE_STATE_GROUND] = 'DISCHARGE_STATE_GROUND',
}

---@param schema XMLSchema
---@param key string
function DischargeNode.registerXMLPaths(schema, key)
    schema:register(XMLValueType.NODE_INDEX, key .. '#node', 'Discharge node', nil, true)
    schema:register(XMLValueType.L10N_STRING, key .. '#name', 'Name to show in control panel GUI')
    schema:register(XMLValueType.STRING, key .. '#fillTypes', 'Fill type(s)', 'STONE', true)

    schema:register(XMLValueType.BOOL, key .. '#defaultEnabled', 'Set default enabled value', true)
    schema:register(XMLValueType.BOOL, key .. '#defaultCanDischargeToGround', nil, true)
    schema:register(XMLValueType.BOOL, key .. '#defaultCanDischargeToObject', nil, true)
    schema:register(XMLValueType.BOOL, key .. '#defaultCanDischargeToAnyObject', nil, false)

    -- Misc
    schema:register(XMLValueType.BOOL, key .. '#stopDischargeIfNotPossible', 'Stop discharge if not possible', false)
    schema:register(XMLValueType.FLOAT, key .. '#effectTurnOffThreshold', 'After this time has passed and nothing has been discharged, the effects are turned off', 0.25)
    schema:register(XMLValueType.FLOAT, key .. '#maxDistance', 'Max discharge distance', 10)

    -- Discharge info
    schema:register(XMLValueType.NODE_INDEX, key .. '.info#node', 'Discharge info node', 'Discharge node')
    schema:register(XMLValueType.FLOAT, key .. '.info#width', 'Discharge info width', 1)
    schema:register(XMLValueType.FLOAT, key .. '.info#length', 'Discharge info length', 1)
    schema:register(XMLValueType.FLOAT, key .. '.info#zOffset', 'Discharge info Z axis offset', 0)
    schema:register(XMLValueType.FLOAT, key .. '.info#yOffset', 'Discharge info Y axis offset', 0)
    schema:register(XMLValueType.BOOL, key .. '.info#limitToGround', 'Discharge info is limited to ground', true)
    schema:register(XMLValueType.BOOL, key .. '.info#useRaycastHitPosition', 'Discharge info uses raycast hit position', false)

    -- Discharge raycast
    schema:register(XMLValueType.NODE_INDEX, key .. '.raycast#node', 'Raycast node', 'Discharge node')
    schema:register(XMLValueType.FLOAT, key .. '.raycast#yOffset', 'Y offset', 0)
    schema:register(XMLValueType.FLOAT, key .. '.raycast#maxDistance', 'Raycast max distance', 10)
    schema:register(XMLValueType.BOOL, key .. '.raycast#useWorldNegYDirection', 'Use world negative Y Direction', true)

    -- Effects, animations and sound
    schema:register(XMLValueType.NODE_INDEX, key .. '#soundNode', 'Sound link node', 'Discharge node')
    schema:register(XMLValueType.BOOL, key .. '#playSound', 'Play discharge sound', true)
    EffectManager.registerEffectXMLPaths(schema, key .. '.effectNodes')
    SoundManager.registerSampleXMLPaths(schema, key, 'dischargeSound')
    SoundManager.registerSampleXMLPaths(schema, key, 'dischargeStateSound(?)')
    schema:register(XMLValueType.BOOL, key .. '.dischargeSound#overwriteSharedSound', 'Overwrite shared discharge sound with sound defined in discharge node', false)
    AnimationManager.registerAnimationNodesXMLPaths(schema, key .. '.animationNodes')
end

---@param schema XMLSchema
---@param key string
function DischargeNode.registerSavegameXMLPaths(schema, key)
    schema:register(XMLValueType.STRING, key .. '#fillType')
    schema:register(XMLValueType.BOOL, key .. '#enabled')
    schema:register(XMLValueType.BOOL, key .. '#canDischargeToGround')
    schema:register(XMLValueType.BOOL, key .. '#canDischargeToObject')
    schema:register(XMLValueType.BOOL, key .. '#canDischargeToAnyObject')
end

---@param placeable PlaceableMaterialDischarge
---@param index number
---@param type number
---@param customMt table
---@return DischargeNode
function DischargeNode.new(placeable, index, type, customMt)
    ---@type DischargeNode
    local self = setmetatable({}, customMt)

    self.placeable = placeable
    self.index = index
    self.type = type
    self.name = string.format('Output #%d', index)
    self.state = Dischargeable.DISCHARGE_STATE_OFF
    self.enabled = false
    self.isDirty = false
    self.toolType = g_toolTypeManager:getToolTypeIndexByName('dischargeable')
    self.currentMinValidLiters = 0
    self.stopDischargeIfNotPossible = false

    self.lineOffset = 0
    self.sentHitDistance = 0
    self.dischargeDistance = 0
    self.dischargeDistanceSent = 0
    self.dischargeHit = false
    self.dischargeHitTerrain = false
    self.isEffectActive = false
    self.isEffectActiveSent = false

    self.isClient = placeable.isClient
    self.isServer = placeable.isServer

    return self
end

function DischargeNode:delete()
    g_effectManager:deleteEffects(self.effects)
    g_soundManager:deleteSample(self.sample)
    g_soundManager:deleteSample(self.dischargeSample)
    g_soundManager:deleteSamples(self.dischargeStateSamples)
    g_animationManager:deleteAnimations(self.animationNodes)
end

---@param xmlFile XMLFile
---@param key string
---@return boolean
---@nodiscard
function DischargeNode:load(xmlFile, key)
    self.node = xmlFile:getValue(key .. '#node', nil, self.placeable.components, self.placeable.i3dMappings)

    if self.node == nil then
        Logging.xmlError(xmlFile, 'Discharge node not found: %s', key .. '#node')
        return false
    end

    self.fillTypes = MaterialDischargeUtils.loadFillTypesFromXML(xmlFile, key .. '#fillTypes')

    if #self.fillTypes == 0 then
        Logging.xmlWarning(xmlFile, 'No valid fillTypes in discharge node: %s', key .. '#fillTypes')
        Logging.warning('Defaulting fillTypes to "STONE"')

        table.insert(self.fillTypes, g_fillTypeManager:getFillTypeByName('STONE'))
    end

    self.name = xmlFile:getValue(key .. '#name', self.name, self.placeable.customEnvironment, false)
    self.enabled = xmlFile:getValue(key .. '#defaultEnabled', true)
    self.canDischargeToGround = xmlFile:getValue(key .. '#defaultCanDischargeToGround', true)
    self.canDischargeToObject = xmlFile:getValue(key .. '#defaultCanDischargeToObject', true)
    self.canDischargeToAnyObject = xmlFile:getValue(key .. '#defaultCanDischargeToAnyObject', false)
    self.stopDischargeIfNotPossible = xmlFile:getValue(key .. '#stopDischargeIfNotPossible', self.stopDischargeIfNotPossible)

    self.maxDistance = xmlFile:getValue(key .. '#maxDistance', xmlFile:getValue(key .. '.raycast#maxDistance')) or 10

    self:loadInfo(xmlFile, key)
    self:loadRaycast(xmlFile, key)
    self:loadEffects(xmlFile, key)

    self:setFillType(self.fillTypes[1], true)

    return true
end

---@param xmlFile XMLFile
---@param key string
function DischargeNode:loadInfo(xmlFile, key)
    ---@diagnostic disable-next-line: missing-fields
    self.info = {}

    self.info.width = xmlFile:getValue(key .. '.info#width', 1) / 2
    self.info.length = xmlFile:getValue(key .. '.info#length', 1) / 2
    self.info.zOffset = xmlFile:getValue(key .. '.info#zOffset', 0)
    self.info.yOffset = xmlFile:getValue(key .. '.info#yOffset', 0)
    self.info.limitToGround = xmlFile:getValue(key .. '.info#limitToGround', true)

    self.info.node = xmlFile:getValue(key .. '.info#node', self.node, self.placeable.components, self.placeable.i3dMappings)

    if self.info.node == self.node then
        self.info.node = createTransformGroup('dischargeInfoNode')
        link(self.node, self.info.node)
    end
end

---@param xmlFile XMLFile
---@param key string
function DischargeNode:loadEffects(xmlFile, key)
    self.effects = g_effectManager:loadEffect(xmlFile, key .. '.effectNodes', self.placeable.components, self.placeable, self.placeable.i3dMappings)
    self.effectTurnOffThreshold = xmlFile:getValue(key .. '#effectTurnOffThreshold', 0.25)

    if self.isClient then
        self.playSound = xmlFile:getValue(key .. '#playSound', true)
        self.soundNode = xmlFile:getValue(key .. '#soundNode', self.node, self.placeable.components, self.placeable.i3dMappings)

        if self.playSound then
            self.dischargeSample = g_soundManager:loadSampleFromXML(xmlFile, key, "dischargeSound", self.placeable.baseDirectory, self.placeable.components, 0, AudioGroup.ENVIRONMENT, self.placeable.i3dMappings)
        end

        if xmlFile:getValue(key .. ".dischargeSound#overwriteSharedSound", false) then
            self.playSound = false
        end

        self.dischargeStateSamples = g_soundManager:loadSamplesFromXML(xmlFile, key, "dischargeStateSound", self.placeable.baseDirectory, self.placeable.components, 0, AudioGroup.ENVIRONMENT, self.placeable.i3dMappings, self)
        self.animationNodes = g_animationManager:loadAnimations(xmlFile, key .. ".animationNodes", self.placeable.components, self, self.placeable.i3dMappings)
    end

    self.lastEffect = self.effects[#self.effects]
end

---@param xmlFile XMLFile
---@param key string
function DischargeNode:loadRaycast(xmlFile, key)
    ---@diagnostic disable-next-line: missing-fields
    self.raycast = {}

    self.raycast.node = xmlFile:getValue(key .. '.raycast#node', self.node, self.placeable.components, self.placeable.i3dMappings)
    self.raycast.yOffset = xmlFile:getValue(key .. '.raycast#yOffset', 0)
    self.raycast.useWorldNegYDirection = xmlFile:getValue(key .. '.raycast#useWorldNegYDirection', true)
end

---@param xmlFile XMLFile
---@param key string
function DischargeNode:loadFromXMLFile(xmlFile, key)
    self:setEnabled(xmlFile:getValue(key .. '#enabled', self.enabled), true)

    local fillTypeIndex = g_fillTypeManager:getFillTypeIndexByName(xmlFile:getValue(key .. '#fillType'))

    if fillTypeIndex ~= nil then
        self:setFillTypeIndex(fillTypeIndex, true)
    end

    self.canDischargeToGround = xmlFile:getValue(key .. '#canDischargeToGround', self.canDischargeToGround)
    self.canDischargeToObject = xmlFile:getValue(key .. '#canDischargeToObject', self.canDischargeToObject)
    self.canDischargeToAnyObject = xmlFile:getValue(key .. '#canDischargeToAnyObject', self.canDischargeToAnyObject)
end

---@param xmlFile XMLFile
---@param key string
function DischargeNode:saveToXMLFile(xmlFile, key)
    xmlFile:setValue(key .. '#enabled', self.enabled)
    xmlFile:setValue(key .. '#fillType', self:getFillTypeName())
    xmlFile:setValue(key .. '#canDischargeToGround', self.canDischargeToGround)
    xmlFile:setValue(key .. '#canDischargeToObject', self.canDischargeToObject)
    xmlFile:setValue(key .. '#canDischargeToAnyObject', self.canDischargeToAnyObject)
end

function DischargeNode:markAsDirty()
    ---@type MaterialDischargeSpecialization
    local spec = self.placeable[PlaceableMaterialDischarge.SPEC_NAME]

    self.isDirty = true
    self.placeable:raiseDirtyFlags(spec.dirtyFlagDischarge)
end

---@param fillType FillTypeObject
---@param noEventSend boolean | nil
function DischargeNode:setFillType(fillType, noEventSend)
    if fillType == nil then
        Logging.error('DischargeNode:setFillType() fillType is nil')
        return
    elseif not DensityMapHeightUtil.getCanTipToGround(fillType.index) then
        Logging.error('DischargeNode:setFillType() fillType "%s" does not have a valid heightType', fillType.name)
        return
    end

    if self.currentFillType ~= fillType then
        SetDischargeNodeFillTypeEvent.sendEvent(self, fillType.index, noEventSend)

        self.currentFillType = fillType
        self.currentMinValidLiters = g_densityMapHeightManager:getMinValidLiterValue(fillType.index)

        if self.isClient then
            g_effectManager:setFillType(self.effects, fillType.index)
        end

        g_messageCenter:publish(SetDischargeNodeFillTypeEvent, self, fillType.index)
    end
end

---@param fillTypeIndex number
---@param noEventSend boolean | nil
function DischargeNode:setFillTypeIndex(fillTypeIndex, noEventSend)
    local fillType = g_fillTypeManager:getFillTypeByIndex(fillTypeIndex)

    if fillType ~= nil then
        self:setFillType(fillType, noEventSend)
    else
        Logging.warning('DischargeNode:setFillTypeIndex() Unknown fillTypeIndex: %s', tostring(fillTypeIndex))
    end
end

---@return number
---@nodiscard
function DischargeNode:getFillTypeIndex()
    return self.currentFillType.index
end

---@return string
---@nodiscard
function DischargeNode:getFillTypeName()
    return self.currentFillType.name
end

---@return string
---@nodiscard
function DischargeNode:getFillTypeTitle()
    return self.currentFillType.title
end

---@param enabled boolean
---@param noEventSend boolean | nil
function DischargeNode:setEnabled(enabled, noEventSend)
    if self.enabled ~= enabled then
        SetDischargeNodeEnabledEvent.sendEvent(self, enabled, noEventSend)

        self.enabled = enabled

        if not enabled then
            self:setState(Dischargeable.DISCHARGE_STATE_OFF, true)
        end

        g_messageCenter:publish(SetDischargeNodeEnabledEvent, self, enabled)
    end
end

---@param state number
---@param noEventSend boolean | nil
function DischargeNode:setState(state, noEventSend)
    if state ~= self.state then
        SetDischargeNodeStateEvent.sendEvent(self, state, noEventSend)

        self.state = state

        if state == Dischargeable.DISCHARGE_STATE_OFF then
            if self.isServer then
                self:setDischargeEffectActive(false)
            end

            g_animationManager:stopAnimations(self.animationNodes)
        else
            g_animationManager:startAnimations(self.animationNodes)
        end
    end
end

---@param isActive boolean
---@param force boolean | nil
---@param fillTypeIndex number | nil
function DischargeNode:setDischargeEffectActive(isActive, force, fillTypeIndex)
    if isActive then
        if not self.isEffectActiveSent then
            if fillTypeIndex == nil then
                fillTypeIndex = self:getFillTypeIndex()
            end

            g_effectManager:setFillType(self.effects, fillTypeIndex)
            g_effectManager:startEffects(self.effects)
            g_animationManager:startAnimations(self.animationNodes)

            self.isEffectActive = true
        end

        self.stopEffectTime = nil
    elseif not force then
        if self.stopEffectTime == nil then
            self.stopEffectTime = g_time + self.effectTurnOffThreshold
        end
    elseif self.isEffectActive then
        g_effectManager:stopEffects(self.effects)
        g_animationManager:stopAnimations(self.animationNodes)

        self.isEffectActive = false
    end

    if self.isServer and self.isEffectActive ~= self.isEffectActiveSent then
        self.isEffectActiveSent = self.isEffectActive

        self:markAsDirty()
    end
end

---@param distance number
function DischargeNode:setDischargeEffectDistance(distance)
    if self.isEffectActive and self.effects ~= nil and distance ~= math.huge then
        for _, effect in pairs(self.effects) do
            if effect.setDistance ~= nil then
                effect:setDistance(distance, g_currentMission.terrainRootNode)
            end
        end
    end
end

---@return boolean
---@nodiscard
function DischargeNode:getCanDischargeToGround()
    if not self.canDischargeToGround then
        return false
    elseif not self.dischargeHitTerrain then
        return false
    end

    return true
end

---@return boolean
---@nodiscard
function DischargeNode:getCanDischargeAtPosition()
    if self.state == Dischargeable.DISCHARGE_STATE_OFF or self.state == Dischargeable.DISCHARGE_STATE_GROUND then
        local sx, sy, sz = localToWorld(self.info.node, -self.info.width, 0, self.info.zOffset)
        local ex, ey, ez = localToWorld(self.info.node, self.info.width, 0, self.info.zOffset)

        sy = sy + self.info.yOffset
        ey = ey + self.info.yOffset

        if self.info.limitToGround then
            sy = math.max(getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, sx, 0, sz) + 0.1, sy)
            ey = math.max(getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, ex, 0, ez) + 0.1, ey)
        end

        local fillTypeIndex = self:getFillTypeIndex()
        local testDropValue = g_densityMapHeightManager:getMinValidLiterValue(fillTypeIndex)

        if not DensityMapHeightUtil.getCanTipToGroundAroundLine(self, testDropValue, fillTypeIndex, sx, sy, sz, ex, ey, ez, self.info.length, nil, self.lineOffset, true, nil, true) then
            return false
        end
    end

    return true
end

---@return boolean
---@nodiscard
function DischargeNode:getCanDischargeToObject()
    if not self.canDischargeToObject then
        return false
    end

    local object = self.dischargeObject

    if object == nil then
        return false
    end

    local fillTypeIndex = self:getFillTypeIndex()

    if not object:getFillUnitSupportsFillType(self.dischargeFillUnitIndex, fillTypeIndex) then
        return false
    end

    local allowFillType = object:getFillUnitAllowsFillType(self.dischargeFillUnitIndex, fillTypeIndex)

    if not allowFillType then
        return false
    end

    if object.getFillUnitFreeCapacity ~= nil and object:getFillUnitFreeCapacity(self.dischargeFillUnitIndex) <= 0 then
        return false
    end

    return self:getCanFarmAccessDischarge(object:getActiveFarm())
end

---@param farmId number
---@return boolean
---@nodiscard
function DischargeNode:getCanFarmAccessDischarge(farmId)
    local placeableOwnerFarmId = self.placeable:getOwnerFarmId()

    if placeableOwnerFarmId ~= AccessHandler.EVERYONE then
        if not self.canDischargeToAnyObject and farmId ~= placeableOwnerFarmId then
            return false
        end
    end

    return true
end

---@param hitActorId number | nil
---@param x number
---@param y number
---@param z number
---@param distance number
---@param nx number
---@param ny number
---@param nz number
---@param subShapeIndex number | nil
---@param hitShapeId number | nil
---@return boolean | nil
function DischargeNode:raycastCallbackDischargeNode(hitActorId, x, y, z, distance, nx, ny, nz, subShapeIndex, hitShapeId)
    if hitActorId == nil then
        self:finishDischargeRaycast()
        return
    end

    ---@type FillUnit
    local object = g_currentMission:getNodeObject(hitActorId)
    distance = distance - self.raycast.yOffset

    local validObject = object ~= nil

    if validObject and distance < 0 and object.getFillUnitIndexFromNode ~= nil then
        validObject = validObject and object:getFillUnitIndexFromNode(hitShapeId) ~= nil
    end

    if validObject and self.canDischargeToObject then
        if object.getFillUnitIndexFromNode ~= nil then
            ---@type number | nil
            local fillUnitIndex = object:getFillUnitIndexFromNode(hitShapeId)

            if fillUnitIndex ~= nil then
                local fillTypeIndex = self:getFillTypeIndex()

                if object:getFillUnitSupportsFillType(fillUnitIndex, fillTypeIndex) then
                    local allowFillType = object:getFillUnitAllowsFillType(fillUnitIndex, fillTypeIndex)
                    local allowToolType = object:getFillUnitSupportsToolType(fillUnitIndex, self.toolType)
                    local freeSpace = object:getFillUnitFreeCapacity(fillUnitIndex, fillTypeIndex, self.placeable:getOwnerFarmId()) > 0
                    local accessible = self:getCanFarmAccessDischarge(object:getActiveFarm())

                    if allowFillType and allowToolType and freeSpace and accessible then
                        self.dischargeObject = object
                        self.dischargeShape = hitShapeId
                        self.dischargeDistance = distance
                        self.dischargeFillUnitIndex = fillUnitIndex

                        if object.getFillUnitExtraDistanceFromNode ~= nil then
                            self.dischargeExtraDistance = object:getFillUnitExtraDistanceFromNode(hitShapeId)
                        end
                    end
                end

                self.dischargeHit = true
                self.dischargeHitObject = object
                self.dischargeHitObjectUnitIndex = fillUnitIndex
            elseif self.dischargeHit then
                self.dischargeDistance = distance + (self.dischargeExtraDistance or 0)
                self.dischargeExtraDistance = nil

                self:updateDischargeInfo(x, y, z)

                return false
            end
        end
    elseif hitActorId == g_currentMission.terrainRootNode and self.canDischargeToGround then
        self.dischargeDistance = math.min(self.dischargeDistance, distance)
        self.dischargeHitTerrain = true

        self:updateDischargeInfo(x, y, z)

        return false
    end

    return true
end

function DischargeNode:updateRaycast()
    if self.raycast.node == nil then
        return
    end

    self.lastDischargeObject = self.dischargeObject
    self.dischargeObject = nil
    self.dischargeHitObject = nil
    self.dischargeHitObjectUnitIndex = nil
    self.dischargeHitTerrain = false
    self.dischargeShape = nil
    self.dischargeDistance = math.huge
    self.dischargeFillUnitIndex = nil
    self.dischargeHit = false

    local x, y, z = getWorldTranslation(self.raycast.node)
    local dx = 0
    local dy = -1
    local dz = 0
    y = y + self.raycast.yOffset

    if not self.raycast.useWorldNegYDirection then
        dx, dy, dz = localDirectionToWorld(self.raycast.node, 0, -1, 0)
    end

    self.isAsyncRaycastActive = true

    raycastAll(x, y, z, dx, dy, dz, "raycastCallbackDischargeNode", self.maxDistance, self, DischargeNode.RAYCAST_COLLISION_MASK, false, false)

    ---@diagnostic disable-next-line: missing-parameter
    self:raycastCallbackDischargeNode(nil)
end

function DischargeNode:updateDischargeInfo(x, y, z)
    if self.info.useRaycastHitPosition then
        setWorldTranslation(self.info.node, x, y, z)
    end
end

---@param dt number
function DischargeNode:updateDischargeSound(dt)
    local fillTypeIndex = self:getFillTypeIndex()
    local isInDischargeState = self.state ~= Dischargeable.DISCHARGE_STATE_OFF and self.enabled == true
    local isEffectActive = self.isEffectActive and fillTypeIndex ~= FillType.UNKNOWN
    local lastEffectVisible = self.lastEffect == nil or self.lastEffect:getIsVisible()
    local effectsStillActive = self.lastEffect ~= nil and self.lastEffect:getIsVisible()

    if (isInDischargeState and isEffectActive or effectsStillActive) and lastEffectVisible then
        if self.playSound and fillTypeIndex ~= FillType.UNKNOWN then
            local sharedSample = g_fillTypeManager:getSampleByFillType(fillTypeIndex)

            if sharedSample ~= nil then
                if sharedSample ~= self.sharedSample then
                    if self.sample ~= nil then
                        g_soundManager:deleteSample(self.sample)
                    end

                    self.sample = g_soundManager:cloneSample(sharedSample, self.node or self.soundNode, self)
                    self.sharedSample = sharedSample

                    g_soundManager:playSample(self.sample)
                elseif not g_soundManager:getIsSamplePlaying(self.sample) then
                    g_soundManager:playSample(self.sample)
                end
            end
        end

        if self.dischargeSample ~= nil and not g_soundManager:getIsSamplePlaying(self.dischargeSample) then
            g_soundManager:playSample(self.dischargeSample)
        end

        self.turnOffSoundTimer = 250
    elseif self.turnOffSoundTimer ~= nil and self.turnOffSoundTimer > 0 then
        self.turnOffSoundTimer = self.turnOffSoundTimer - dt

        if self.turnOffSoundTimer <= 0 then
            if self.playSound and g_soundManager:getIsSamplePlaying(self.sample) then
                g_soundManager:stopSample(self.sample)
            end

            if self.dischargeSample ~= nil and g_soundManager:getIsSamplePlaying(self.dischargeSample) then
                g_soundManager:stopSample(self.dischargeSample)
            end

            self.turnOffSoundTimer = 0
        end
    end

    if self.dischargeStateSamples ~= nil and #self.dischargeStateSamples > 0 then
        for _, sample in ipairs(self.dischargeStateSamples) do
            if isInDischargeState then
                if not g_soundManager:getIsSamplePlaying(sample) then
                    g_soundManager:playSample(sample)
                end
            elseif g_soundManager:getIsSamplePlaying(sample) then
                g_soundManager:stopSample(sample)
            end
        end
    end
end

---@param dt number
function DischargeNode:onUpdateTick(dt)
    if self.isServer then
        if self.enabled and not self.isAsyncRaycastActive then
            self:updateRaycast()
        elseif not self.enabled then
            self.dischargeObject = nil
            self.dischargeFillUnitIndex = nil
            self.dischargeHitObject = nil
            self.dischargeHitObjectUnitIndex = nil
            self.dischargeShape = nil
        end
    end

    if self.isClient then
        self:updateDischargeSound(dt)
    end

    if self.isServer then
        if self.enabled then
            self:updateTick(dt)
        end

        if self.isEffectActive ~= self.isEffectActiveSent or math.abs(self.dischargeDistanceSent - self.dischargeDistance) > 0.05 then
            self:markAsDirty()

            self.dischargeDistanceSent = self.dischargeDistance
            self.isEffectActiveSent = self.isEffectActive
        end

        if self.stopEffectTime ~= nil then
            if self.stopEffectTime < g_time then
                self:setDischargeEffectActive(false, true)
                self.stopEffectTime = nil
            end
        end
    end
end

function DischargeNode:handleFoundDischargeObject()
    self:setState(Dischargeable.DISCHARGE_STATE_OBJECT)
end

function DischargeNode:finishDischargeRaycast()
    self:handleDischargeRaycast(self.lastDischargeObject)
    self.isAsyncRaycastActive = false
end

---@param emptyLiters number
---@return number
---@return boolean
---@return boolean
function DischargeNode:discharge(emptyLiters)
    local dischargedLiters = 0
    local minDropReached = true
    local hasMinDropFillLevel = true
    local object, fillUnitIndex = self.dischargeObject, self.dischargeFillUnitIndex

    self.currentDischargeObject = nil

    if object ~= nil then
        if self.state == Dischargeable.DISCHARGE_STATE_OBJECT then
            dischargedLiters = self:dischargeToObject(emptyLiters, object, fillUnitIndex)
        end
    elseif self.dischargeHitTerrain and self.state == Dischargeable.DISCHARGE_STATE_GROUND then
        dischargedLiters, minDropReached, hasMinDropFillLevel = self:dischargeToGround(emptyLiters)
    end

    return dischargedLiters, minDropReached, hasMinDropFillLevel
end

---@param emptyLiters number
---@param object FillUnit
---@param targetFillUnitIndex number
---@return number
---@nodiscard
function DischargeNode:dischargeToObject(emptyLiters, object, targetFillUnitIndex)
    if emptyLiters == 0 then
        return 0
    end

    local fillTypeIndex = self:getFillTypeIndex()

    if object:getFillUnitAllowsFillType(targetFillUnitIndex, fillTypeIndex) then
        self.currentDischargeObject = object

        return object:addFillUnitFillLevel(self.placeable:getOwnerFarmId(), targetFillUnitIndex, emptyLiters, fillTypeIndex, self.toolType, self.info)
    end

    return 0
end

--[[

    Functions that needs to be implemented by inherited class.

]]

---@private
---@param dt number
function DischargeNode:updateTick(dt)
    -- Implemented by inherited class

    assert(nil, 'DischargeNode:updateTick() needs to be implemented by inherited class!')
end

---@param emptySpeed number
---@param noEventSend boolean | nil
function DischargeNode:setEmptySpeed(emptySpeed, noEventSend)
    -- Implemented by inherited class
end

---@param object table | nil
---@param shape any | nil
---@param distance number | nil
---@param fillUnitIndex number | nil
---@param hitTerrain boolean | nil
function DischargeNode:handleDischargeRaycast(object, shape, distance, fillUnitIndex, hitTerrain)
    -- Implemented by inherited class

    assert(nil, 'DischargeNode:handleDischargeRaycast() needs to be implemented by inherited class!')
end

---@param dischargedLiters number
---@param minDropReached boolean
---@param hasMinDropFillLevel boolean
function DischargeNode:handleDischarge(dischargedLiters, minDropReached, hasMinDropFillLevel)
    -- Implemented by inherited class

    assert(nil, 'DischargeNode:handleDischarge() needs to be implemented by inherited class!')
end

---@param emptyLiters number
---@return number
---@return boolean
---@return boolean
---@nodiscard
function DischargeNode:dischargeToGround(emptyLiters)
    -- Implemented by inherited class

    ---@diagnostic disable-next-line: missing-return
    assert(nil, 'DischargeNode:dischargeToGround() needs to be implemented by inherited class!')
end

--[[
    Network
]]

---@param streamId number
---@param connection Connection
function DischargeNode:writeStream(streamId, connection)
    if streamWriteBool(streamId, self.isEffectActiveSent) then
        streamWriteUIntN(streamId, MathUtil.clamp(math.floor(self.dischargeDistanceSent / self.maxDistance * 255), 1, 255), 8)
        streamWriteUIntN(streamId, self:getFillTypeIndex(), FillTypeManager.SEND_NUM_BITS)
    end

    streamWriteBool(streamId, self.canDischargeToGround)
    streamWriteBool(streamId, self.canDischargeToObject)
    streamWriteBool(streamId, self.canDischargeToAnyObject)

    streamWriteUIntN(streamId, self:getFillTypeIndex(), FillTypeManager.SEND_NUM_BITS)
    streamWriteUIntN(streamId, self.state, Dischargeable.SEND_NUM_BITS_DISCHARGE_STATE)
    streamWriteBool(streamId, self.enabled)
end

---@param streamId number
---@param connection Connection
function DischargeNode:readStream(streamId, connection)
    if streamReadBool(streamId) then
        local distance = streamReadUIntN(streamId, 8) * self.maxDistance / 255
        local fillTypeIndex = streamReadUIntN(streamId, FillTypeManager.SEND_NUM_BITS)

        self.dischargeDistance = distance

        self:setDischargeEffectActive(true, true, fillTypeIndex)
        self:setDischargeEffectDistance(distance)
    else
        self:setDischargeEffectActive(false, true)
    end

    self.canDischargeToGround = streamReadBool(streamId)
    self.canDischargeToObject = streamReadBool(streamId)
    self.canDischargeToAnyObject = streamReadBool(streamId)

    self:setFillTypeIndex(streamReadUIntN(streamId, FillTypeManager.SEND_NUM_BITS), true)
    self:setState(streamReadUIntN(streamId, Dischargeable.SEND_NUM_BITS_DISCHARGE_STATE), true)
    self:setEnabled(streamReadBool(streamId), true)
end

---@param streamId number
---@param connection Connection
function DischargeNode:writeUpdateStream(streamId, connection)
    if streamWriteBool(streamId, self.isDirty) then
        if streamWriteBool(streamId, self.isEffectActiveSent) then
            streamWriteUIntN(streamId, MathUtil.clamp(math.floor(self.dischargeDistanceSent / self.maxDistance * 255), 1, 255), 8)
            streamWriteUIntN(streamId, self:getFillTypeIndex(), FillTypeManager.SEND_NUM_BITS)
        end

        self.isDirty = false
    end
end

---@param streamId number
---@param connection Connection
function DischargeNode:readUpdateStream(streamId, connection)
    if streamReadBool(streamId) then
        if streamReadBool(streamId) then
            self.dischargeDistance = streamReadUIntN(streamId, 8) * self.maxDistance / 255

            local fillTypeIndex = streamReadUIntN(streamId, FillTypeManager.SEND_NUM_BITS)

            self:setDischargeEffectActive(true, true, fillTypeIndex)
            self:setDischargeEffectDistance(self.dischargeDistance)
        else
            self:setDischargeEffectActive(false, true)
        end
    end
end

--[[
    Settings
]]

---@param canDischargeToGround boolean
---@param noEventSend boolean | nil
---@param noMessageSend boolean | nil
function DischargeNode:setCanDischargeToGround(canDischargeToGround, noEventSend, noMessageSend)
    if self.canDischargeToGround ~= canDischargeToGround then
        SetDischargeNodeSettingsEvent.sendEvent(self, canDischargeToGround, self.canDischargeToObject, self.canDischargeToAnyObject, noEventSend)

        self.canDischargeToGround = canDischargeToGround

        if self.isServer and self.state == Dischargeable.DISCHARGE_STATE_GROUND and not canDischargeToGround then
            if self.stopDischargeIfNotPossible or not self.enabled then
                self:setState(Dischargeable.DISCHARGE_STATE_OFF)
            end
        end

        if not noMessageSend then
            g_messageCenter:publish(SetDischargeNodeSettingsEvent, self)
        end
    end
end

---@param canDischargeToObject boolean
---@param noEventSend boolean | nil
---@param noMessageSend boolean | nil
function DischargeNode:setCanDischargeToObject(canDischargeToObject, noEventSend, noMessageSend)
    if self.canDischargeToObject ~= canDischargeToObject then
        SetDischargeNodeSettingsEvent.sendEvent(self, self.canDischargeToGround, canDischargeToObject, self.canDischargeToAnyObject, noEventSend)

        self.canDischargeToObject = canDischargeToObject

        if self.isServer and self.state == Dischargeable.DISCHARGE_STATE_OBJECT and not canDischargeToObject then
            if self.stopDischargeIfNotPossible or not self.enabled then
                self:setState(Dischargeable.DISCHARGE_STATE_OFF)
            end
        end

        if not noMessageSend then
            g_messageCenter:publish(SetDischargeNodeSettingsEvent, self)
        end
    end
end

---@param canDischargeToAnyObject boolean
---@param noEventSend boolean | nil
---@param noMessageSend boolean | nil
function DischargeNode:setCanDischargeToAnyObject(canDischargeToAnyObject, noEventSend, noMessageSend)
    if self.canDischargeToAnyObject ~= canDischargeToAnyObject then
        SetDischargeNodeSettingsEvent.sendEvent(self, self.canDischargeToGround, self.canDischargeToObject, canDischargeToAnyObject, noEventSend)

        self.canDischargeToAnyObject = canDischargeToAnyObject

        if not noMessageSend then
            g_messageCenter:publish(SetDischargeNodeSettingsEvent, self)
        end
    end
end

---@param litersPerHour number
---@param noEventSend boolean | nil
function DischargeNode:setLitersPerHour(litersPerHour, noEventSend)
    -- void
end
