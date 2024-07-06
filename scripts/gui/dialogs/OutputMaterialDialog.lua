---@class OutputMaterialDialog : MessageDialog
---@field node DischargeNode | nil
---@field list SmoothListElement
---@field headerSubTitle TextElement
---
---@field superClass fun(): MessageDialog
OutputMaterialDialog = {}

OutputMaterialDialog.CLASS_NAME = 'OutputMaterialDialog'
OutputMaterialDialog.XML_FILENAME = g_currentModDirectory .. 'xml/dialogs/OutputMaterialDialog.xml'
OutputMaterialDialog.CONTROLS = {
    'list',
    'headerSubTitle'
}

local OutputMaterialDialog_mt = Class(OutputMaterialDialog, MessageDialog)

---@return OutputMaterialDialog
function OutputMaterialDialog.new()
    ---@type OutputMaterialDialog
    local self = MessageDialog.new(nil, OutputMaterialDialog_mt)

    self:registerControls(OutputMaterialDialog.CONTROLS)

    return self
end

function OutputMaterialDialog:delete()
    self:superClass().delete(self)

    FocusManager.guiFocusData[OutputMaterialDialog.CLASS_NAME] = {
        idToElementMapping = {}
    }
end

function OutputMaterialDialog:load()
    g_gui:loadGui(OutputMaterialDialog.XML_FILENAME, OutputMaterialDialog.CLASS_NAME, self)
end

function OutputMaterialDialog:onGuiSetupFinished()
    self:superClass().onGuiSetupFinished(self)

    self.list:setDataSource(self)
end

---@param dischargeNode DischargeNode | nil
function OutputMaterialDialog:show(dischargeNode)
    if dischargeNode ~= nil then
        self.node = dischargeNode
        g_gui:showDialog(OutputMaterialDialog.CLASS_NAME)
    end
end

function OutputMaterialDialog:onOpen()
    self:superClass().onOpen(self)

    self.headerSubTitle:setText(self.node.name)

    self:updateFilltypes()

    for index, fillType in ipairs(self.node.fillTypes) do
        if fillType == self.node.currentFillType then
            self.list:setSelectedIndex(index)
            break
        end
    end
end

function OutputMaterialDialog:onClose()
    self:superClass().onClose(self)

    self.node = nil
end

function OutputMaterialDialog:updateFilltypes()
    self.list:reloadData()
end

---@return number
function OutputMaterialDialog:getNumberOfItemsInSection()
    return #self.node.fillTypes
end

---@param list SmoothListElement
---@param section number
---@param index number
---@param cell ListItemElement
function OutputMaterialDialog:populateCellForItemInSection(list, section, index, cell)
    local fillType = self.node.fillTypes[index]

    if fillType ~= nil then
        cell:getAttribute('title'):setText(fillType.title)
        cell:getAttribute('icon'):setImageFilename(fillType.hudOverlayFilename)
    end
end

---@param list SmoothListElement
---@param section number
---@param index number
---@param cell ListItemElement
function OutputMaterialDialog:onItemDoubleClick(list, section, index, cell)
    self:applyOutputMaterial(index)
end

function OutputMaterialDialog:onClickApply()
    self:applyOutputMaterial(self.list:getSelectedIndexInSection())
end

---@param index number
function OutputMaterialDialog:applyOutputMaterial(index)
    local fillType = self.node.fillTypes[index]

    if fillType ~= nil then
        self.node:setFillType(fillType)
    else
        Logging.warning('OutputMaterialDialog:applyOutputMaterial() index not found: %s', tostring(index))
    end

    self:close()
end
