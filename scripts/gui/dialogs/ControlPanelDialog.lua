---@class ControlPanelDialog : MessageDialog
---@field placeable PlaceableMaterialDischarge | nil
---@field dischargeNodes DischargeNode[]
---@field list SmoothListElement
---@field selectMaterialButton ButtonElement
---@field settingsButton ButtonElement
---
---@field superClass fun(): MessageDialog
ControlPanelDialog = {}

ControlPanelDialog.CLASS_NAME = 'ControlPanelDialog'
ControlPanelDialog.XML_FILENAME = g_currentModDirectory .. 'xml/dialogs/ControlPanelDialog.xml'
ControlPanelDialog.CONTROLS = {
    'list',
    'selectMaterialButton',
    'settingsButton'
}

local ControlPanelDialog_mt = Class(ControlPanelDialog, MessageDialog)

---@return ControlPanelDialog
function ControlPanelDialog.new()
    ---@type ControlPanelDialog
    local self = MessageDialog.new(nil, ControlPanelDialog_mt)

    self:registerControls(ControlPanelDialog.CONTROLS)

    self.dischargeNodes = {}

    return self
end

function ControlPanelDialog:delete()
    self:superClass().delete(self)

    FocusManager.guiFocusData[ControlPanelDialog.CLASS_NAME] = {
        idToElementMapping = {}
    }
end

function ControlPanelDialog:load()
    g_gui:loadGui(ControlPanelDialog.XML_FILENAME, ControlPanelDialog.CLASS_NAME, self)
end

function ControlPanelDialog:onGuiSetupFinished()
    self:superClass().onGuiSetupFinished(self)

    self.list:setDataSource(self)
end

---@param placeable PlaceableMaterialDischarge
function ControlPanelDialog:show(placeable)
    if placeable ~= nil then
        self.placeable = placeable
        g_gui:showDialog(ControlPanelDialog.CLASS_NAME)
    end
end

function ControlPanelDialog:onOpen()
    self:superClass().onOpen(self)

    self:updateList()
    self:updateMenuButtons()

    g_messageCenter:subscribe(SetDischargeNodeFillTypeEvent, self.onDischargeNodeChanged, self)
    g_messageCenter:subscribe(SetDischargeNodeSettingsEvent, self.onDischargeNodeChanged, self)
    g_messageCenter:subscribe(SetDischargeNodeLitersPerHourEvent, self.onDischargeNodeChanged, self)
    g_messageCenter:subscribe(SetDischargeNodeEmptySpeedEvent, self.onDischargeNodeChanged, self)
    g_messageCenter:subscribe(SetDischargeNodeEnabledEvent, self.onDischargeNodeChanged, self)
end

function ControlPanelDialog:onClose()
    self:superClass().onClose(self)

    g_messageCenter:unsubscribeAll(self)

    self.dischargeNodes = {}
    self.placeable = nil
end

---@return DischargeNode | nil
function ControlPanelDialog:getSelectedItem()
    return self.dischargeNodes[self.list:getSelectedIndexInSection()]
end

function ControlPanelDialog:updateList()
    self.dischargeNodes = self.placeable:getDischargeNodes()
    self.list:reloadData()
end

function ControlPanelDialog:updateMenuButtons()
    local node = self:getSelectedItem()

    if node ~= nil then
        self.selectMaterialButton:setVisible(#node.fillTypes > 1)
        self.settingsButton:setVisible(true)
    else
        self.selectMaterialButton:setVisible(false)
        self.settingsButton:setVisible(false)
    end
end

---@param dischargeNode DischargeNode
function ControlPanelDialog:onDischargeNodeChanged(dischargeNode)
    if self.isOpen and dischargeNode.placeable == self.placeable then
        self:updateList()
        self:updateMenuButtons()
    end
end

---@return number
function ControlPanelDialog:getNumberOfItemsInSection()
    return #self.dischargeNodes
end

---@param list SmoothListElement
---@param section number
---@param index number
---@param cell ListItemElement
function ControlPanelDialog:populateCellForItemInSection(list, section, index, cell)
    local node = self.dischargeNodes[index]

    if node ~= nil then
        cell:getAttribute('name'):setText(node.name)

        if node.type == DischargeNode.TYPE_PRODUCTION then
            ---@cast node ProductionDischargeNode
            cell:getAttribute('litersPerHour'):setText(string.format('%.0f liters/s', node.emptySpeed * 1000))
        else
            ---@cast node SpawnDischargeNode
            cell:getAttribute('litersPerHour'):setText(string.format('%.0f liters/h', node.litersPerHour))
        end
        cell:getAttribute('fillType'):setText(node:getFillTypeTitle() or 'INVALID')

        local status = cell:getAttribute('status')

        if node.enabled ~= true then
            status:setDisabled(true)
            status:setText('Disabled')
        else
            status:setDisabled(false)
            status:setText('Enabled')
        end
    end
end

function ControlPanelDialog:onListSelectionChanged()
    self:updateMenuButtons()
end

function ControlPanelDialog:onItemDoubleClick()
    local dischargeNode = self:getSelectedItem()

    if dischargeNode ~= nil and #dischargeNode.fillTypes > 0 then
        g_outputMaterialDialog:show()
    end
end

function ControlPanelDialog:onClickSelectMaterial()
    g_outputMaterialDialog:show(self:getSelectedItem())
end

function ControlPanelDialog:onClickSettings()
    g_outputSettingsDialog:show(self:getSelectedItem())
end
