---@class OutputSettingsDialog : MessageDialog
---@field node DischargeNode | nil
---@field headerSubTitle TextElement
---@field boxLayout BoxLayoutElement
---@field enabledOption CheckedOptionElement
---@field litersPerHourInputWrapper GuiElement
---@field litersPerHourInput TextInputElement
---@field litersPerHourInputTitle TextElement
---@field canDischargeToGroundOption CheckedOptionElement
---@field canDischargeToObjectOption CheckedOptionElement
---@field canDischargeToAnyObjectOption CheckedOptionElement
---
---@field superClass fun(): MessageDialog
OutputSettingsDialog = {}

OutputSettingsDialog.CLASS_NAME = 'OutputSettingsDialog'
OutputSettingsDialog.XML_FILENAME = g_currentModDirectory .. 'xml/dialogs/OutputSettingsDialog.xml'
OutputSettingsDialog.CONTROLS = {
    'headerSubTitle',
    'boxLayout',
    'enabledOption',
    'litersPerHourInputWrapper',
    'litersPerHourInput',
    'litersPerHourInputTitle',
    'canDischargeToGroundOption',
    'canDischargeToObjectOption',
    'canDischargeToAnyObjectOption',
}

local OutputSettingsDialog_mt = Class(OutputSettingsDialog, MessageDialog)

---@return OutputSettingsDialog
function OutputSettingsDialog.new()
    ---@type OutputSettingsDialog
    local self = MessageDialog.new(nil, OutputSettingsDialog_mt)

    self:registerControls(OutputSettingsDialog.CONTROLS)

    return self
end

function OutputSettingsDialog:delete()
    self:superClass().delete(self)

    FocusManager.guiFocusData[OutputSettingsDialog.CLASS_NAME] = {
        idToElementMapping = {}
    }
end

function OutputSettingsDialog:load()
    g_gui:loadGui(OutputSettingsDialog.XML_FILENAME, OutputSettingsDialog.CLASS_NAME, self)
end

---@param dischargeNode DischargeNode | nil
function OutputSettingsDialog:show(dischargeNode)
    if dischargeNode ~= nil then
        self.node = dischargeNode
        g_gui:showDialog(OutputSettingsDialog.CLASS_NAME)
    end
end

function OutputSettingsDialog:onOpen()
    self:superClass().onOpen(self)

    self:updateOptions()
    self:updateElementFocus()

    g_messageCenter:subscribe(SetDischargeNodeSettingsEvent, self.onSettingsChanged, self)
    g_messageCenter:subscribe(SetDischargeNodeLitersPerHourEvent, self.onSettingsChanged, self)
    g_messageCenter:subscribe(SetDischargeNodeEnabledEvent, self.onSettingsChanged, self)
end

function OutputSettingsDialog:onClose()
    self:superClass().onClose(self)

    g_messageCenter:unsubscribeAll(self)

    self.node = nil
end

---@param dischargeNode DischargeNode
function OutputSettingsDialog:onSettingsChanged(dischargeNode)
    if self.isOpen and dischargeNode == self.node then
        self:updateOptions()
    end
end

function OutputSettingsDialog:updateElementFocus()
    ---@type GuiElement | nil
    local focusedElement = FocusManager:getFocusedElement()

    if focusedElement == nil or focusedElement.name == OutputSettingsDialog.CLASS_NAME then
        self:setSoundSuppressed(true)
        FocusManager:setFocus(self.boxLayout)
        self:setSoundSuppressed(false)
    end
end

function OutputSettingsDialog:updateOptions()
    ---@type DischargeNode
    local node = self.node

    self.headerSubTitle:setText(node.name)
    self.enabledOption:setIsChecked(node.enabled)

    if node.type == DischargeNode.TYPE_PRODUCTION then
        ---@cast node ProductionDischargeNode
        self.litersPerHourInput:setText(string.format('%.0f', node.emptySpeed * 1000))
        self.litersPerHourInputTitle:setText(g_i18n:getText('ui_inputEmptySpeed'))
    else
        ---@cast node SpawnDischargeNode
        self.litersPerHourInput:setText(string.format('%.0f', node.litersPerHour))
        self.litersPerHourInputTitle:setText(g_i18n:getText('ui_inputLitersPerHour'))
    end

    self.canDischargeToGroundOption:setIsChecked(self.node.canDischargeToGround)
    self.canDischargeToObjectOption:setIsChecked(self.node.canDischargeToObject)
    self.canDischargeToAnyObjectOption:setIsChecked(self.node.canDischargeToAnyObject)
end

---@param state number
---@param element CheckedOptionElement
function OutputSettingsDialog:onClickOption(state, element)
    if element == self.enabledOption then
        self.node:setEnabled(state == CheckedOptionElement.STATE_CHECKED)
    elseif element == self.canDischargeToGroundOption then
        self.node:setCanDischargeToGround(state == CheckedOptionElement.STATE_CHECKED)
    elseif element == self.canDischargeToObjectOption then
        self.node:setCanDischargeToObject(state == CheckedOptionElement.STATE_CHECKED)
    elseif element == self.canDischargeToAnyObjectOption then
        self.node:setCanDischargeToAnyObject(state == CheckedOptionElement.STATE_CHECKED)
    end
end

---@param element TextInputElement
function OutputSettingsDialog:onLitersPerHourInput(element)
    local node = self.node

    if node == nil then
        return
    end

    if element.text ~= '' then
        local value = tonumber(element.text)

        if value ~= nil then
            if node.type == DischargeNode.TYPE_SPAWN then
                ---@cast node SpawnDischargeNode
                node:setLitersPerHour(math.floor(MathUtil.clamp(value, SpawnDischargeNode.LITERS_MIN_VALUE, SpawnDischargeNode.LITERS_MAX_VALUE)))
            else
                ---@cast node ProductionDischargeNode
                value = math.floor(MathUtil.clamp(value, SpawnDischargeNode.EMPTY_SPEED_MIN, SpawnDischargeNode.EMPTY_SPEED_MAX))
                node:setEmptySpeed(value / 1000)
            end
        end
    end

    if node.type == DischargeNode.TYPE_SPAWN then
        ---@cast node SpawnDischargeNode
        element:setText(string.format('%.0f', node.litersPerHour))
    else
        ---@cast node ProductionDischargeNode
        element:setText(string.format('%.0f', node.emptySpeed * 1000))
    end
end
