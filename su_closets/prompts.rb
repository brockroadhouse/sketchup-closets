
module Closets

  def self.createWalls
    startOperation('Build Walls')

    prompts = ["Width", "Depth", "Return Left", "Return Right", "Closet Height", "Name", "Wall Height"]
    defaults = [50.to_l, 24.to_l, 6.to_l, 6.to_l, 84.to_l, "", 96.to_l]
    input = UI.inputbox(prompts, defaults, "Enter Parameters")

    return if (input == false)

    width = input[0]*unit_length
    depth = input[1]*unit_length
    left  = input[2]*unit_length
    right = input[3]*unit_length
    closet = input[4]*unit_length
    name  = input[5]
    wall = input[6]*unit_length

    buildWalls(width, depth, left, right, closet, name, wall)

    endOperation
  end

  def self.createSimpleLH
    startOperation('Simple Long Hang')

    prompts = ["Total Width (in inches)"]

    if (selectionIsEdge)
      defaultWidth = (@@selection[0].length)
    else
      defaultWidth = 25.5
    end
    defaults = [defaultWidth.to_l]
    input = UI.inputbox(prompts, defaults, "Enter Parameters")

    return if (input == false)

    width = input[0]*unit_length

    buildSimpleLH(width)

    endOperation
  end

  def self.createLH
    startOperation('Long Hang')

    if(selectionIsEdge)
      defaultWidth = (@@selection[0].length)
    else
      defaultWidth = 25.5
    end

    prompts = ["Width Type", "Width", "Depth", "Placement"]
    defaults = ["Total", defaultWidth.to_l, 12, "Center"]
    list = ["Total|Shelf", "", "", "Left|Center|Right"]
    input = UI.inputbox(prompts, defaults, list, "Enter Parameters")

    return if (input == false)

    type  = input[0]
    width = input[1]*unit_length
    depth = input[2]*unit_length
    placement  = input[3]

    buildLH(type, width, depth, placement)

    endOperation
  end

  def self.createDH
    startOperation('Double Hang')

    if(selectionIsEdge)
      defaultWidth = (@@selection[0].length)
    else
      defaultWidth = 25.5
    end

    prompts = ["Width Type", "Width", "Depth", "Placement"]
    defaults = ["Total", defaultWidth.to_l, 12.to_l, "Center"]
    list = ["Total|Shelf", "", "", "Left|Center|Right"]
    input = UI.inputbox(prompts, defaults, list, "Enter Parameters")

    return if (input == false)

    type  = input[0]
    width = input[1]*unit_length
    depth = input[2]*unit_length
    placement  = input[3]

    buildDH(type, width, depth, placement)

    endOperation
  end

  def self.createMixed
    startOperation('Mixed Hang')

    if(selectionIsEdge)
      defaultWidth = (@@selection[0].length)
    else
      defaultWidth = 50
    end

    prompts = ["Total Width", "#1", "#2", "#3", "#4", "#5", "Shelves/Stack", "Drawers/Stack", "Stack Height", "Stack Depth", "Stack Width"]
    defaults = [defaultWidth.to_l, "LH", "DH", "N/A", "N/A", "N/A", 5, 0, 72.to_l, 14.to_l, 24.to_l]
    options = "LH|DH|Shelves|N/A"
    list = ["", options, options, options, options, options, "", "", "", "", ""]
    input = UI.inputbox(prompts, defaults, list, "Enter Sections (Left to Right)")

    return if (input == false)

    width     = input[0]*unit_length
    types     = input[1..5]
    shelves   = input[6]
    drawers   = input[7]
    height    = input[8]*unit_length
    depth     = input[9]*unit_length
    stWidth   = input[10]*unit_length

    buildMixed(width, types, shelves, drawers, height, depth, stWidth)

    endOperation
  end

  def self.createShelf
    prompts = ["Width", "Depth"]
    defaults = [24*unit_length, 12*unit_length]
    input = UI.inputbox(prompts, defaults, "Enter Parameters")

    width = input[0]*unit_length
    depth = input[1]*unit_length

    startOperation('Add Shelf')

    addShelf(width, depth, [0,0,0])

    endOperation
  end

  def self.createShelfStack
    startOperation('Shelf Stack')

    ## Shelf Stack
    @@selection = Sketchup.active_model.selection

    if(selectionIsEdge)
      defaultWidth = (@@selection[0].length)
    else
      defaultWidth = 25.5
    end

    prompts = ["Width Type", "Width", "Depth", "Gable Height", "Shelves/Stack", "# of Drawers", "# of Sections", "Floor Unit", "Placement"]
    defaults = ["Total", defaultWidth.to_l, 15.to_l, 72.to_l, 5, 0, 1, "No", "Center"]
    list = ["Total|Shelf", "", "", "", "", "", "", "Yes|No", "Left|Center|Right"]
    input = UI.inputbox(prompts, defaults, list, "Enter Parameters")

    return if (input == false)

    type      = input[0]
    width     = input[1]*unit_length
    depth     = input[2]*unit_length
    height    = input[3]*unit_length
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
    shapes_menu = UI.menu("Plugins").add_submenu("Closets")
    #shapes_menu.add_item("Poop") {fartBox}
    shapes_menu.add_item("Create Walls") {createWalls}
    shapes_menu.add_item("Simple Long Hang") {createSimpleLH}
    shapes_menu.add_item("Long Hang") {createLH}
    shapes_menu.add_item("Double Hang") {createDH}
    #shapes_menu.add_item("Add Shelf") {createShelf}
    shapes_menu.add_item("Shelf Stack") {createShelfStack}
    shapes_menu.add_item("Mixed Hang Space") {createMixed}
    shapes_menu.add_item("Export Cut List") {exportCutList}
    shapes_menu.add_item("Reload (DEV)") {FVCC::Closets.reload}
    file_loaded(__FILE__)
  end

end # Module
