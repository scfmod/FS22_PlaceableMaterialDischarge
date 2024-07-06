---@class MaterialDischargeUtils
MaterialDischargeUtils = {}

---@class ProductionPointObjectOutput
---@field type number fillTypeIndex
---@field sellDirectly boolean
---@field amount number

---@class ProductionPointObject
---@field id number
---@field name string
---@field status number
---@field outputs table

---@param placeable PlaceableMaterialDischarge
---@return boolean
---@nodiscard
function MaterialDischargeUtils.getIsProductionPointActive(placeable)
    local productionPoint = placeable.spec_productionPoint.productionPoint

    for _, production in ipairs(productionPoint.productions) do
        if production.status == ProductionPoint.PROD_STATUS.RUNNING then
            return true
        end
    end

    return false
end

---@param xmlFile XMLFile
---@param key string
---@return FillTypeObject[]
---@nodiscard
function MaterialDischargeUtils.loadFillTypesFromXML(xmlFile, key)
    local str = xmlFile:getValue(key)

    ---@type FillTypeObject[]
    local fillTypes = {}

    if str ~= nil then
        ---@type string[]
        local fillTypeNames = string.split(str, ' ')
        ---@type table<number, boolean>
        local registered = {}

        for _, name in ipairs(fillTypeNames) do
            name = name:upper()

            ---@type FillTypeObject | nil
            local fillType = g_fillTypeManager.nameToFillType[name]

            if fillType ~= nil then
                if not DensityMapHeightUtil.getCanTipToGround(fillType.index) then
                    Logging.xmlWarning(xmlFile, 'Fill type "%s" does not have a valid heightType, skipping. (%s)', fillType.name, key)
                elseif registered[fillType.index] ~= true then
                    table.insert(fillTypes, fillType)
                    registered[fillType.index] = true
                end
            else
                Logging.xmlWarning(xmlFile, 'Fill type "%s" not found, skipping. (%s)', name, key)
            end
        end
    end

    return fillTypes
end

---@param value number
---@return string
---@nodiscard
function MaterialDischargeUtils.formatNumber(value)
    local str = string.format("%d", math.floor(value))
    local pos = string.len(str) % 3

    if pos == 0 then
        pos = 3
    end

    return string.sub(str, 1, pos) .. string.gsub(string.sub(str, pos + 1), "(...)", ",%1")
end
