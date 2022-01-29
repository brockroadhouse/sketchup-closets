# frozen_string_literal: true

module Closets
  # Add a menu for creating 3D shapes
  # Checks if this script file has been loaded before in this SU session
  unless file_loaded?(__FILE__) # If not, create menu entries
    extMenu = UI.menu('Plugins').add_submenu('Closets')
    extMenu.add_item('Create Walls') { showRoomDialog }
    extMenu.add_item('Build Closet') { show_dialog }
    extMenu.add_separator #####################################################
    extMenu.add_item('Build Cabinets') { showCabinetDialog }
    extMenu.add_separator ######################################################
    extMenu.add_item('View Quote') { exportQuote }
    extMenu.add_item('View Cut List') { exportCutList }
    extMenu.add_separator ######################################################
    subMenu = extMenu.add_submenu('Change Units')
    subMenu.add_item('Set to mm') { setModelmm }
    subMenu.add_item('Set to 1/16"') { setModelInch }
    extMenu.add_separator ######################################################
    extMenu.add_item('Settings') { show_settings_dialog }
    extMenu.add_item("test") {testfunction}
    # extMenu.add_item("Export SVG") {exportSvg} #NOTREADY

    file_loaded(__FILE__)
  end
end # Module
