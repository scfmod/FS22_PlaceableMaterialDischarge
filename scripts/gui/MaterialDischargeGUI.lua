---@class MaterialDischargeGUI
MaterialDischargeGUI = {}

MaterialDischargeGUI.PROFILES_FILENAME = g_currentModDirectory .. 'xml/guiProfiles.xml'

local MaterialDischargeGUI_mt = Class(MaterialDischargeGUI)

function MaterialDischargeGUI.new()
    ---@type MaterialDischargeGUI
    local self = setmetatable({}, MaterialDischargeGUI_mt)

    if g_debugMaterialDischarge then
        addConsoleCommand('mdToggle', '', 'consoleToggleOption', self)
        addConsoleCommand('mdReloadGui', '', 'consoleReloadGui', self)
    end

    return self
end

function MaterialDischargeGUI:consoleReloadGui()
    self:reload()

    return 'GUI reloaded'
end

function MaterialDischargeGUI:load()
    self:loadProfiles()
    self:loadDialogs()
end

function MaterialDischargeGUI:delete()
    if g_outputMaterialDialog.isOpen then
        g_outputMaterialDialog:close()
    end

    if g_outputSettingsDialog.isOpen then
        g_outputSettingsDialog:close()
    end

    if g_controlPanelDialog.isOpen then
        g_controlPanelDialog:close()
    end

    g_outputMaterialDialog:delete()
    g_outputSettingsDialog:delete()
    g_controlPanelDialog:delete()
end

function MaterialDischargeGUI:loadProfiles()
    g_gui.currentlyReloading = true

    if not g_gui:loadProfiles(MaterialDischargeGUI.PROFILES_FILENAME) then
        Logging.error('Failed to load profiles: %s', MaterialDischargeGUI.PROFILES_FILENAME)
    end

    g_gui.currentlyReloading = false
end

function MaterialDischargeGUI:loadDialogs()
    ---@diagnostic disable-next-line: lowercase-global
    g_controlPanelDialog = ControlPanelDialog.new()
    g_controlPanelDialog:load()

    ---@diagnostic disable-next-line: lowercase-global
    g_outputSettingsDialog = OutputSettingsDialog.new()
    g_outputSettingsDialog:load()

    ---@diagnostic disable-next-line: lowercase-global
    g_outputMaterialDialog = OutputMaterialDialog.new()
    g_outputMaterialDialog:load()
end

function MaterialDischargeGUI:reload()
    local selectedPlaceable
    local selectedSettingsNode
    local selectedMaterialNode

    if g_controlPanelDialog.isOpen then
        selectedPlaceable = g_controlPanelDialog.placeable
    end

    if g_outputSettingsDialog.isOpen then
        selectedSettingsNode = g_outputSettingsDialog.node
    elseif g_outputMaterialDialog.isOpen then
        selectedMaterialNode = g_outputMaterialDialog.node
    end

    self:delete()

    Logging.info('Reloading GUI ..')

    self:loadProfiles()
    self:loadDialogs()

    if selectedPlaceable ~= nil then
        g_controlPanelDialog:show(selectedPlaceable)
    end

    if selectedSettingsNode ~= nil then
        g_outputSettingsDialog:show(selectedSettingsNode)
    elseif selectedMaterialNode ~= nil then
        g_outputMaterialDialog:show(selectedMaterialNode)
    end
end

---@param name string | nil
function MaterialDischargeGUI:consoleToggleOption(name)
    local node

    if g_outputMaterialDialog.isOpen then
        node = g_outputMaterialDialog.node
    elseif g_outputSettingsDialog.isOpen then
        node = g_outputSettingsDialog.node
    elseif g_controlPanelDialog.isOpen then
        node = g_controlPanelDialog:getSelectedItem()
    end

    if node == nil then
        return 'Discharge node not found'
    end

    if name == 'stopDischargeIfNotPossible' then
        node.stopDischargeIfNotPossible = not node.stopDischargeIfNotPossible
        return 'stopDischargeIfNotPossible: ' .. tostring(node.stopDischargeIfNotPossible)
    elseif name == 'stopDischargeOnEmpty' then
        node.stopDischargeOnEmpty = not node.stopDischargeOnEmpty
        return 'stopDischargeOnEmpty: ' .. tostring(node.stopDischargeOnEmpty)
    end

    return 'Unknown option, available options: stopDischargeIfNotPossible, stopDischargeOnEmpty'
end
