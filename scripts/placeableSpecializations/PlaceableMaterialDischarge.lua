source(g_currentModDirectory .. 'scripts/placeableSpecializations/events/SetDischargeNodeEmptySpeedEvent.lua')
source(g_currentModDirectory .. 'scripts/placeableSpecializations/events/SetDischargeNodeEnabledEvent.lua')
source(g_currentModDirectory .. 'scripts/placeableSpecializations/events/SetDischargeNodeFillTypeEvent.lua')
source(g_currentModDirectory .. 'scripts/placeableSpecializations/events/SetDischargeNodeLitersPerHourEvent.lua')
source(g_currentModDirectory .. 'scripts/placeableSpecializations/events/SetDischargeNodeSettingsEvent.lua')
source(g_currentModDirectory .. 'scripts/placeableSpecializations/events/SetDischargeNodeStateEvent.lua')

---@class PlaceableProductionPointSpecialization
---@field productionPoint ProductionPoint

---@class MaterialDischargeSpecialization
---@field dischargeNodes DischargeNode[]
---@field activatable MaterialDischargeActivatable
---@field dirtyFlagDischarge number

---@class PlaceableMaterialDischarge : Placeable
---@field spec_productionPoint PlaceableProductionPointSpecialization
PlaceableMaterialDischarge = {}

PlaceableMaterialDischarge.SPEC_NAME = 'spec_' .. g_currentModName .. '.materialDischarge'
PlaceableMaterialDischarge.MOD_NAME = g_currentModName

function PlaceableMaterialDischarge.prerequisitesPresent()
    return true
end

---@param schema XMLSchema
function PlaceableMaterialDischarge.registerXMLPaths(schema)
    schema:setXMLSpecializationType('MaterialDischarge')

    MaterialDischargeActivatable.registerXMLPaths(schema, 'placeable.materialDischarge.activationTrigger')
    ProductionDischargeNode.registerXMLPaths(schema, 'placeable.materialDischarge.dischargeNodes.productionDischarge(?)')
    SpawnDischargeNode.registerXMLPaths(schema, 'placeable.materialDischarge.dischargeNodes.spawnDischarge(?)')

    schema:setXMLSpecializationType()
end

---@param schema XMLSchema
---@param key string
function PlaceableMaterialDischarge.registerSavegameXMLPaths(schema, key)
    schema:setXMLSpecializationType('MaterialDischarge')

    DischargeNode.registerSavegameXMLPaths(schema, key .. '.dischargeNode(?)')
    ProductionDischargeNode.registerSavegameXMLPaths(schema, key .. '.dischargeNode(?)')
    SpawnDischargeNode.registerSavegameXMLPaths(schema, key .. '.dischargeNode(?)')

    schema:setXMLSpecializationType()
end

---@param placeableType table
function PlaceableMaterialDischarge.registerFunctions(placeableType)
    SpecializationUtil.registerFunction(placeableType, 'getDischargeNodes', PlaceableMaterialDischarge.getDischargeNodes)
    SpecializationUtil.registerFunction(placeableType, 'getDischargeNodeByIndex', PlaceableMaterialDischarge.getDischargeNodeByIndex)
end

function PlaceableMaterialDischarge.registerEventListeners(placeableType)
    SpecializationUtil.registerEventListener(placeableType, 'onLoad', PlaceableMaterialDischarge)
    SpecializationUtil.registerEventListener(placeableType, 'onFinalizePlacement', PlaceableMaterialDischarge)
    SpecializationUtil.registerEventListener(placeableType, 'onDelete', PlaceableMaterialDischarge)
    SpecializationUtil.registerEventListener(placeableType, 'onUpdate', PlaceableMaterialDischarge)
    SpecializationUtil.registerEventListener(placeableType, 'onUpdateTick', PlaceableMaterialDischarge)

    SpecializationUtil.registerEventListener(placeableType, 'onWriteStream', PlaceableMaterialDischarge)
    SpecializationUtil.registerEventListener(placeableType, 'onReadStream', PlaceableMaterialDischarge)

    SpecializationUtil.registerEventListener(placeableType, 'onWriteUpdateStream', PlaceableMaterialDischarge)
    SpecializationUtil.registerEventListener(placeableType, 'onReadUpdateStream', PlaceableMaterialDischarge)
end

function PlaceableMaterialDischarge:onLoad()
    ---@type MaterialDischargeSpecialization
    local spec = self[PlaceableMaterialDischarge.SPEC_NAME]
    local xmlFile = self.xmlFile

    spec.dirtyFlagDischarge = self:getNextDirtyFlag()

    spec.dischargeNodes = {}

    xmlFile:iterate('placeable.materialDischarge.dischargeNodes.spawnDischarge', function(_, dischargeNodeKey)
        local index = #spec.dischargeNodes + 1

        if index > DischargeNode.MAX_NUM_INDEX then
            Logging.xmlWarning(xmlFile, 'Reached max number of discharge nodes (%i)', index)
            return false
        end

        local node = SpawnDischargeNode.new(self, index)

        if node:load(xmlFile, dischargeNodeKey) then
            table.insert(spec.dischargeNodes, node)
        else
            Logging.xmlWarning(xmlFile, 'Failed to load discharge node: %s', dischargeNodeKey)
        end
    end)

    xmlFile:iterate('placeable.materialDischarge.dischargeNodes.productionDischarge', function(_, dischargeNodeKey)
        local index = #spec.dischargeNodes + 1

        if index > DischargeNode.MAX_NUM_INDEX then
            Logging.xmlWarning(xmlFile, 'Reached max number of discharge nodes (%i)', index)
            return false
        end

        local node = ProductionDischargeNode.new(self, index)

        if node:load(xmlFile, dischargeNodeKey) then
            table.insert(spec.dischargeNodes, node)
        else
            Logging.xmlWarning(xmlFile, 'Failed to load discharge node: %s', dischargeNodeKey)
        end
    end)

    if #spec.dischargeNodes == 0 then
        Logging.xmlWarning(xmlFile, 'No valid discharge nodes registered: placeable.materialDischarge.dischargeNodes')
    end

    spec.activatable = MaterialDischargeActivatable.new(self)
    spec.activatable:load(xmlFile, 'placeable.materialDischarge.activationTrigger')
end

function PlaceableMaterialDischarge:onDelete()
    ---@type MaterialDischargeSpecialization
    local spec = self[PlaceableMaterialDischarge.SPEC_NAME]

    if spec.activatable ~= nil then
        spec.activatable:delete()
    end

    for _, node in ipairs(spec.dischargeNodes) do
        node:delete()
    end

    spec.activatable = nil
    spec.dischargeNodes = {}
end

function PlaceableMaterialDischarge:onFinalizePlacement()
    if self.isServer then
        self:raiseActive()
    end
end

---@param xmlFile XMLFile
---@param key string
function PlaceableMaterialDischarge:loadFromXMLFile(xmlFile, key)
    ---@type MaterialDischargeSpecialization
    local spec = self[PlaceableMaterialDischarge.SPEC_NAME]

    xmlFile:iterate(key .. '.dischargeNode', function(index, nodeKey)
        local dischargeNode = spec.dischargeNodes[index]

        if dischargeNode ~= nil then
            dischargeNode:loadFromXMLFile(xmlFile, nodeKey)
        end
    end)
end

---@param xmlFile XMLFile
---@param key string
function PlaceableMaterialDischarge:saveToXMLFile(xmlFile, key)
    ---@type MaterialDischargeSpecialization
    local spec = self[PlaceableMaterialDischarge.SPEC_NAME]

    for i, dischargeNode in ipairs(spec.dischargeNodes) do
        local nodeKey = string.format('%s.dischargeNode(%i)', key, i - 1)

        dischargeNode:saveToXMLFile(xmlFile, nodeKey)
    end
end

---@return DischargeNode[]
---@nodiscard
function PlaceableMaterialDischarge:getDischargeNodes()
    ---@type MaterialDischargeSpecialization
    local spec = self[PlaceableMaterialDischarge.SPEC_NAME]

    return spec.dischargeNodes
end

---@param index number
---@return DischargeNode | nil
---@nodiscard
function PlaceableMaterialDischarge:getDischargeNodeByIndex(index)
    ---@type MaterialDischargeSpecialization
    local spec = self[PlaceableMaterialDischarge.SPEC_NAME]

    return spec.dischargeNodes[index]
end

---@param dt number
function PlaceableMaterialDischarge:onUpdate(dt)
    ---@type MaterialDischargeSpecialization
    local spec = self[PlaceableMaterialDischarge.SPEC_NAME]

    if self.isClient then
        for _, node in ipairs(spec.dischargeNodes) do
            if node.turnOffSoundTimer ~= nil and node.turnOffSoundTimer > 0 then
                self:raiseActive()
            end
        end
    end
end

---@param dt number
function PlaceableMaterialDischarge:onUpdateTick(dt)
    ---@type MaterialDischargeSpecialization
    local spec = self[PlaceableMaterialDischarge.SPEC_NAME]

    for _, node in ipairs(spec.dischargeNodes) do
        node:onUpdateTick(dt)
    end

    if self.isServer then
        self:raiseActive()
    end
end

---@param streamId number
---@param connection Connection
function PlaceableMaterialDischarge:onWriteStream(streamId, connection)
    ---@type MaterialDischargeSpecialization
    local spec = self[PlaceableMaterialDischarge.SPEC_NAME]

    if not connection:getIsServer() then
        for _, node in ipairs(spec.dischargeNodes) do
            node:writeStream(streamId, connection)
        end
    end
end

---@param streamId number
---@param connection Connection
function PlaceableMaterialDischarge:onReadStream(streamId, connection)
    ---@type MaterialDischargeSpecialization
    local spec = self[PlaceableMaterialDischarge.SPEC_NAME]

    if connection:getIsServer() then
        for _, node in ipairs(spec.dischargeNodes) do
            node:readStream(streamId, connection)
        end
    end
end

---@param streamId number
---@param connection Connection
---@param dirtyMask number
function PlaceableMaterialDischarge:onWriteUpdateStream(streamId, connection, dirtyMask)
    ---@type MaterialDischargeSpecialization
    local spec = self[PlaceableMaterialDischarge.SPEC_NAME]

    if not connection:getIsServer() then
        if streamWriteBool(streamId, bitAND(dirtyMask, spec.dirtyFlagDischarge) ~= 0) then
            for _, node in ipairs(spec.dischargeNodes) do
                node:writeUpdateStream(streamId, connection)
            end
        end
    end
end

---@param streamId number
---@param timestamp number
---@param connection Connection
function PlaceableMaterialDischarge:onReadUpdateStream(streamId, timestamp, connection)
    ---@type MaterialDischargeSpecialization
    local spec = self[PlaceableMaterialDischarge.SPEC_NAME]

    if connection:getIsServer() then
        if streamReadBool(streamId) then
            for _, node in ipairs(spec.dischargeNodes) do
                node:readUpdateStream(streamId, connection)
            end
        end
    end
end

---@class MaterialDischargeActivatable
---@field placeable PlaceableMaterialDischarge
---@field triggerNode number | nil
---@field activateText string
MaterialDischargeActivatable = {}

MaterialDischargeActivatable.L10N_TEXTS = {
    ACTIVATE = g_i18n:getText('action_openControlPanel')
}

local MaterialDischargeActivatable_mt = Class(MaterialDischargeActivatable)

---@param schema XMLSchema
---@param key string
function MaterialDischargeActivatable.registerXMLPaths(schema, key)
    schema:register(XMLValueType.NODE_INDEX, key .. '#node', 'Activation trigger node for opening control panel', nil, false)
end

---@param placeable PlaceableMaterialDischarge
---@return MaterialDischargeActivatable
---@nodiscard
function MaterialDischargeActivatable.new(placeable)
    ---@type MaterialDischargeActivatable
    local self = setmetatable({}, MaterialDischargeActivatable_mt)

    self.placeable = placeable
    self.activateText = MaterialDischargeActivatable.L10N_TEXTS.ACTIVATE

    return self
end

function MaterialDischargeActivatable:delete()
    g_currentMission.activatableObjectsSystem:removeActivatable(self)

    if self.triggerNode ~= nil then
        removeTrigger(self.triggerNode)
    end
end

---@param xmlFile XMLFile
---@param key string
function MaterialDischargeActivatable:load(xmlFile, key)
    if self.placeable.isClient then
        self.triggerNode = xmlFile:getValue(key .. '#node', nil, self.placeable.components, self.placeable.i3dMappings)

        if self.triggerNode ~= nil then
            if CollisionFlag.getHasFlagSet(self.triggerNode, CollisionFlag.TRIGGER_PLAYER) then
                addTrigger(self.triggerNode, 'activationTriggerCallback', self)
            else
                Logging.xmlWarning(xmlFile, 'Missing TRIGGER_PLAYER collision flag (bit 20) on node: %s', key .. '#node')
            end
        else
            Logging.xmlInfo(xmlFile, 'MaterialDischargeActivatable:load() No activation trigger node set: %s', key .. '#node')
        end
    end
end

function MaterialDischargeActivatable:run()
    g_controlPanelDialog:show(self.placeable)
end

---@return boolean
function MaterialDischargeActivatable:getIsActivatable()
    return g_currentMission:getHasPlayerPermission(Farm.PERMISSION.MANAGE_RIGHTS, nil, self.placeable:getOwnerFarmId())
end

---@param x number
---@param y number
---@param z number
function MaterialDischargeActivatable:getDistance(x, y, z)
    local tx, ty, tz = getWorldTranslation(self.triggerNode)

    return MathUtil.vector3Length(x - tx, y - ty, z - tz)
end

---@param triggerId number
---@param otherActorId number | nil
---@param onEnter boolean
---@param onLeave boolean
---@param onStay boolean
---@param otherShapeId number | nil
function MaterialDischargeActivatable:activationTriggerCallback(triggerId, otherActorId, onEnter, onLeave, onStay, otherShapeId)
    if (onEnter or onLeave) and g_currentMission.player ~= nil and otherActorId == g_currentMission.player.rootNode then
        if onEnter then
            g_currentMission.activatableObjectsSystem:addActivatable(self)
        else
            g_currentMission.activatableObjectsSystem:removeActivatable(self)
        end
    end
end
