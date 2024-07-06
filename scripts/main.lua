---@diagnostic disable-next-line: lowercase-global
g_materialDischargeUIFilename = g_currentModDirectory .. 'textures/ui_elements.png'

---@param path string
local function load(path)
    source(g_currentModDirectory .. 'scripts/' .. path)
end

---@diagnostic disable-next-line: lowercase-global
g_debugMaterialDischarge = fileExists(g_currentModDirectory .. 'scripts/debug.lua')

local generateSchema = false

if generateSchema then
    load('utils/schema.lua')
end

-- Utils
load('utils/MaterialDischargeUtils.lua')

-- Base classes
load('DischargeNode.lua')
load('ProductionDischargeNode.lua')
load('SpawnDischargeNode.lua')

-- GUI
load('gui/MaterialDischargeGUI.lua')
load('gui/dialogs/ControlPanelDialog.lua')
load('gui/dialogs/OutputMaterialDialog.lua')
load('gui/dialogs/OutputSettingsDialog.lua')

-- Base game extensions
load('extensions/GuiOverlayExtension.lua')

---@diagnostic disable-next-line: lowercase-global
g_materialDischargeGUI = MaterialDischargeGUI.new()

if g_client ~= nil then
    g_materialDischargeGUI:load()
end
