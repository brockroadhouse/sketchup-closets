
module Closets

  def self.createWalls

    prompts = ["Name", "Width", "Depth", "Return Left", "Return Right", "Closet Height", "Wall Height"]
    defaults = ["Closet " + @@nameCount.to_s, 50.to_l, 24.inch.to_l, 6.to_l, 6.to_l, 84.to_l, 96.to_l]
    input = UI.inputbox(prompts, defaults, "Enter Parameters")

    return if (input == false)

    name  = input[0]
    width = input[1]
    depth = input[2]
    left  = input[3]
    right = input[4]
    closet = input[5]
    wall = input[6]

    startOperation('Build Walls', true, name)

    buildWalls(name, width, depth, depth, left, right, closet, wall)

    endOperation
  end

  def self.createSimpleLH
    startOperation('Simple Long Hang')

    prompts = ["Total Width"]
    defaults = [defaultWidth.to_l]
    input = UI.inputbox(prompts, defaults, "Enter Parameters")

    return if (input == false)

    width = input[0]

    buildSimpleLH(width)

    endOperation
  end

  def self.createLH
    startOperation('Long Hang')

    prompts = ["Width Type", "Width", "Depth", "Placement"]
    defaults = ["Total", defaultWidth.to_l, @@hangDepth.to_l, "Center"]
    list = ["Total|Shelf", "", "", "Left|Center|Right"]
    input = UI.inputbox(prompts, defaults, list, "Enter Parameters")

    return if (input == false)

    type  = input[0]
    width = input[1]
    depth = input[2]
    placement  = input[3]
    buildLH(type, width, depth, placement)

    endOperation
  end

  def self.createDH
    startOperation('Double Hang')

    prompts = ["Width Type", "Width", "Depth", "Placement"]
    defaults = ["Total", defaultWidth.to_l, 12.to_l, "Center"]
    list = ["Total|Shelf", "", "", "Left|Center|Right"]
    input = UI.inputbox(prompts, defaults, list, "Enter Parameters")

    return if (input == false)

    type  = input[0]
    width = input[1]
    depth = input[2]
    placement  = input[3]

    buildDH(type, width, depth, placement)

    endOperation
  end

  def self.createMixed
    startOperation('Mixed Hang')

    prompts = ["Total Width", "#1", "#2", "#3", "#4", "#5", "Shelves/Stack", "Drawers/Stack", "Stack Height", "Stack Depth", "Stack Width", "Floor Mount"]
    defaults = [defaultWidth.to_l, "Shelves", "-", "-", "-", "-", 5, 0, 72.to_l, 14.to_l, 24.to_l, "No"]
    options = "LH|DH|Shelves|-"
    list = ["", options, options, options, options, options, "", "", "", "", "", "Yes|No"]
    input = UI.inputbox(prompts, defaults, list, "Enter Sections (Left to Right)")

    return if (input == false)

    width     = input[0]
    types     = input[1..5]
    shelves   = input[6]
    drawers   = input[7]
    height    = input[8]
    depth     = input[9]
    stWidth   = input[10]
    floor     = input[11]=='Yes'

    buildMixed(width, types, shelves, drawers, height, depth, stWidth, floor)

    endOperation
  end

  def self.createShelf
    prompts = ["Width", "Depth"]
    defaults = [24*unit_length, 12*unit_length]
    input = UI.inputbox(prompts, defaults, "Enter Parameters")

    width = input[0]
    depth = input[1]

    startOperation('Add Shelf')

    addShelf(width, depth, [0,0,0])

    endOperation
  end

  def self.createShelfStack
    startOperation('Shelf Stack')

    ## Shelf Stack
    @@selection = Sketchup.active_model.selection

    prompts = ["Width Type", "Width", "Depth", "Gable Height", "Shelves/Stack", "# of Drawers", "# of Sections", "Floor Unit", "Placement"]
    defaults = ["Total", defaultWidth.to_l, 15.to_l, 72.to_l, 5, 0, 1, "No", "Center"]
    list = ["Total|Shelf", "", "", "", "", "", "", "Yes|No", "Left|Center|Right"]
    input = UI.inputbox(prompts, defaults, list, "Enter Parameters")

    return if (input == false)

    type      = input[0]
    width     = input[1]
    depth     = input[2]
    height    = input[3]
    shelves   = input[4]
    drawers   = input[5]
    sections  = input[6]
    floor     = (input[7] == "Yes")
    placement  = input[8]

    if (sections > 0)
      buildShelfStack(type, width, depth, height, shelves, drawers, sections, floor, placement)
    else
      UI.messagebox("Must have at least 1 section")
      testItem
    end

    endOperation
  end

  # Add a menu for creating 3D shapes
  # Checks if this script file has been loaded before in this SU session
  unless file_loaded?(__FILE__) # If not, create menu entries
    extMenu = UI.menu("Plugins").add_submenu("Closets")
    #shapes_menu.add_item("Poop") {fartBox}
    extMenu.add_item("Create Walls") {createWalls}
    #extMenu.add_item("Simple Long Hang") {createSimpleLH}
    #extMenu.add_item("Long Hang") {createLH}
    #extMenu.add_item("Double Hang") {createDH}
    #extMenu.add_item("Add Shelf") {createShelf}
    #extMenu.add_item("Shelf Stack") {createShelfStack}
    #extMenu.add_item("Floor Double Hang") {buildFloorDH}
    extMenu.add_item("Build Closet") {createMixed}
    #extMenu.add_item("Dialog") {show_dialog}
    extMenu.add_item("Export Cut List") {exportCutList}
    #extMenu.add_item("Export SVG") {exportSvg} #NOTREADY

    subMenu = extMenu.add_submenu("Change Units")
    subMenu.add_item("Set to mm") {setModelmm}
    subMenu.add_item("Set to 1/16\"") {setModelInch}
    #shapes_menu.add_item("Reload (DEV)") {FVCC::Closets.reload}
    file_loaded(__FILE__)
  end

end # Module
