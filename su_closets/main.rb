# Copyright 2014 Trimble Navigation Ltd.
#
# License: The MIT License (MIT)


require "sketchup.rb"

module Closets

  @@thickness = 0.75.inch
  @@offset    = 4.inch
  @@cleat     = 5.inch

  @@currentEnt

  #=============================================================================
  # Find which unit and format the model is using and define unit_length
  #   accordingly
  #   When LengthUnit = 0
  #     LengthFormat 0 = Decimal inches
  #     LengthFormat 1 = Architectural (feet and inches)
  #     LengthFormat 2 = Engineering (feet)
  #     LengthFormat 3 = Fractional (inches)
  #   When LengthUnit = 1
  #     LengthFormat 0 = Decimal feet
  #   When LengthUnit = 2
  #     LengthFormat 0 = Decimal mm
  #   When LengthUnit = 3
  #     LengthFormat 0 = Decimal cm
  #   When LengthUnit = 4
  #     LengthFormat 0 = Decimal metres

  def self.unit_length
    # Get model units (imperial or metric) and length format.
    model = Sketchup.active_model
    manager = model.options
    if provider = manager["UnitsOptions"] # Check for nil value
      length_unit = provider["LengthUnit"] # Length unit value
      length_format = provider["LengthFormat"] # Length format value

      case length_unit
      when 0 ## Imperial units
        if length_format == 1 || length_format == 2
          # model is using Architectural (feet and inches)
          # or Engineering units (feet)
          unit_length = 1.feet
        else
          ## model is using (decimal or fractional) inches
          unit_length = 1.inch
        end # if
      when 1
        ## Decimal feet
        unit_length = 1.feet
      when 2
        ## model is using metric units - millimetres
        unit_length = 10.mm
      when 3
        ## model is using metric units - centimetres
        unit_length = 10.cm
      when 4
        ## model is using metric units - metres
        unit_length =  1.m
      end #end case

    else
      UI.messagebox " Can't determine model units - please set in Window/ModelInfo"
    end # if
  end

  def self.currentEnt
    @@currentEnt
  end

  def self.startOperation (name)
    model = Sketchup.active_model
    model.start_operation(name, true)
    group = model.active_entities.add_group
    entities = group.entities
    @@currentEnt = entities
  end

  def self.endOperation
    model = Sketchup.active_model
    model.commit_operation
  end

  def self.addFace (addition, push = 0, material = nil)
    group = @@currentEnt.add_group
    face = group.entities.add_face(addition)

    addMaterial(face, material) unless material == nil
    face.pushpull(push) unless push == 0
    group
  end

  def self.addMaterial (face, material)
    materials = Sketchup.active_model.materials
    materials.add(material) unless materials.at(material)
    face.material = materials.at(material)
  end

  def self.addDimension (pt1, pt2, vector)
    @@currentEnt.add_dimension_linear(pt1, pt2, vector)
  end

  def self.fartBox
    input = UI.inputbox(["How many times? "], [nil], "Feeling a little bloated?")
    times = input[0].to_i
    unless times > 10
      message = "*FART* "*times
      UI.messagebox(message)
    end
  end

  def self.buildShelfStack (type, width, depth, height, shelves, sections, floor, placement)
    startOperation('Shelf Stack')

    if (floor)
      spacing = (height-@@cleat-@@thickness)/(shelves - 1)
    else
      spacing = (height-@@thickness)/(shelves - 1)
    end

    # Add gable when in center
    numGables = sections
    numGables += 1 if (placement == "Center")

    width = (width - numGables * @@thickness) / sections if (type == "Total")

    ### Gable Creation ###
    pos = 0

    # Left gable
    addGable(pos, depth, height, [0,0,0]) unless (placement == "Right")

    sections.times do |i|
      # Create shelves
      shelfHeight = height
      shelfPos = pos + @@thickness

      shelves.times do |n|
        addShelf(shelfPos, width, depth, shelfHeight, n==0)
        shelfHeight -= spacing
      end

      if (floor)
        addCleat(shelfPos, depth, height-@@thickness-@@cleat, width)
        addCleat(shelfPos, @@thickness+1, 0, width)
      else
        addCleat(shelfPos, depth, @@thickness, width)
      end
      pos += @@thickness + width

      # Right gable
      addGable(pos, depth, height, [width+@@thickness, 0, 0]) unless (i == (sections - 1) && placement == "Left")
    end


    endOperation
  end

  def self.buildSimpleLH (width)
    startOperation('Simple Long Hang')

    sections = ((width-@@thickness)/(32 + @@thickness)).ceil
    shelfWidth = (width - (sections+1)*@@thickness)/sections

    pos = 0
    # Left gable
    addGable(pos, 12, 10)

    sections.times do |i|
      pos += @@thickness
      addShelf(pos, shelfWidth, 12, 10)
      addRod(pos, 0, 4.25, shelfWidth)
      addCleat(pos, 12, 0, shelfWidth)
      pos += shelfWidth
      addGable(pos, 12, 10)
    end

    endOperation
  end

  def self.buildLH (type, width, depth)
    startOperation('Long Hang Section')

    # Gables
    addGable(0, 12, 24)
    addGable(width+@@thickness, 12, 24)

    # Shelves
    top = 24
    bottom = @@cleat + @@thickness
    mid = (top+bottom)/2
    addShelf(@@thickness, width, depth, top, true)
    addShelf(@@thickness, width, depth, bottom)
    addShelf(@@thickness, width, depth, mid)

    addCleat(@@thickness, depth, 0, width)

    addRod(@@thickness, 0, 0, width)

    endOperation
  end

  def self.buildDH (width, depth)
    startOperation('Double Hang Section')

    # Gables
    addGable(0, 12, 48)
    addGable(width+@@thickness, 12, 48)

    # Shelves
    top = 48
    bottom = @@cleat + @@thickness
    addShelf(@@thickness, width, depth, top, true)
    addShelf(@@thickness, width, depth, bottom)

    addCleat(@@thickness, depth, 0, width)

    addRod(@@thickness, 0, 48-bottom, width)
    addRod(@@thickness, 0, 0, width)

    endOperation
  end

  def self.addTitle(name, pt)
    nameGroup = @@currentEnt.add_group

    # 3D Text
    nameGroup.entities.add_3d_text(name, 1, 'Tahoma', false, false, 10, tolerance = 0.0, 0, true, 3)

    # Move text to pt
    t = Geom::Transformation.new pt
    nameGroup = nameGroup.move!(t)

    # Rotate correctly
    point = pt
    vector = Geom::Vector3d.new(1, 0, 0)
    angle = 90.degrees # Return 45 degrees in radians.
    new_transform = Geom::Transformation.rotation(point, vector, angle)
    nameGroup = nameGroup.transform!(new_transform)

  end

  def self.buildWalls (width, depth, left, right, closetHeight, name = "", wallHeight)
    startOperation('Build Walls')

    leftWall = [
      Geom::Point3d.new(0, 0, 0),
      Geom::Point3d.new(left, 0, 0),
      Geom::Point3d.new(left, -@@offset, 0),
      Geom::Point3d.new(-@@offset, -@@offset, 0),
    ]

    rightWall = [
      Geom::Point3d.new(width-right, 0, 0),
      Geom::Point3d.new(width, 0, 0),
      Geom::Point3d.new(width+@@offset, -@@offset, 0),
      Geom::Point3d.new(width-right, -@@offset, 0),
    ]

    closet = [
      Geom::Point3d.new(0, 0, 0),
      Geom::Point3d.new(0, depth, 0),
      Geom::Point3d.new(width, depth, 0),
      Geom::Point3d.new(width, 0, 0),
      Geom::Point3d.new(width+@@offset, -@@offset, 0),
      Geom::Point3d.new(width+@@offset, depth+@@offset, 0),
      Geom::Point3d.new(-@@offset, depth+@@offset, 0),
      Geom::Point3d.new(-@@offset, -@@offset, 0),
    ]

    closetHeightLine1 = [
      Geom::Point3d.new(0, 0, closetHeight),
      Geom::Point3d.new(0, depth, closetHeight),
    ]
    closetHeightLine2 = [
      Geom::Point3d.new(0, depth, closetHeight),
      Geom::Point3d.new(width, depth, closetHeight),
    ]
    closetHeightLine3 = [
      Geom::Point3d.new(width, depth, closetHeight),
      Geom::Point3d.new(width, 0, closetHeight),
    ]
    @@currentEnt.add_line(closetHeightLine1[0], closetHeightLine1[1])
    @@currentEnt.add_line(closetHeightLine2[0], closetHeightLine2[1])
    @@currentEnt.add_line(closetHeightLine3[0], closetHeightLine3[1])

    leftFace = addFace(leftWall)
    rightFace = addFace(rightWall)
    closetFace = addFace(closet, -wallHeight)

    # Add dimension lines
    addDimension(closet[0], closet[1], [0, 0, 4])
    addDimension(closet[0], closet[1], [0, 0, 4])
    addDimension(closet[1], closet[2], [0, 0, 4])
    addDimension(closet[2], closet[3], [0, 0, 4])

    # Add title
    addTitle(name, Geom::Point3d.new(3, depth, 85)) unless name == ""

    endOperation
  end

  def self.addGable (x, y, height, distance = [])
    compName = "#{y}\" x #{height}\" Gable"
    compDefinition = Sketchup.active_model.definitions[compName]
    if (!compDefinition || distance == [])
      gable = [
        Geom::Point3d.new(x, y, height),
        Geom::Point3d.new(x+@@thickness, y, height),
        Geom::Point3d.new(x+@@thickness, y, 0),
        Geom::Point3d.new(x, y, 0),
      ]
      group = addFace(gable, -y)
      comp = group.to_component
      comp.definition.name = compName
      comp.definition.description = compName
    else
      point = Geom::Point3d.new distance
      transform = Geom::Transformation.new point
      @@currentEnt.add_instance compDefinition, transform
    end
  end

  def self.addShelf (x, width, depth, height, dimension = false)
    compName = "#{width}\" x #{depth}\" Shelf"
    transformation = Geom::Transformation.new([x,0,height])

    compDefinition = Sketchup.active_model.definitions[compName]
    if (!compDefinition)
      shelf = [
        Geom::Point3d.new(0, depth, 0),
        Geom::Point3d.new(width, depth, 0),
        Geom::Point3d.new(width, 0, 0),
        Geom::Point3d.new(0, 0, 0),
      ]
      group = addFace(shelf, @@thickness)
      comp = group.to_component
      comp.definition.name = compName

      comp.move! transformation
    else
      @@currentEnt.add_instance(compDefinition, transformation)
    end


    # Add dimension line
    #addDimension(shelf[2], shelf[3], [0, 0, -5]) if dimension == true
  end

  def self.addCleat (x, y, z, width)
    cleat = [
      Geom::Point3d.new(x, y, z),
      Geom::Point3d.new(x+width, y, z),
      Geom::Point3d.new(x+width, y, z+@@cleat),
      Geom::Point3d.new(x, y, z+@@cleat),
    ]
    compName = "#{width}\" Cleat"
    grp = addFace(cleat, @@thickness)
    grp.name = compName
  end

  def self.addRod (x, y, z, width)
    # x,y,z are the coords of the bottom corner of gable
    rod = [
      Geom::Point3d.new(x, y+2, z+2),
      Geom::Point3d.new(x, y+3, z+2),
      Geom::Point3d.new(x, y+2, z+3.5),
    ]
    face = addFace(rod, width, '[Metal Corrugated Shiny]')
  end

  def self.createSimpleLH
    prompts = ["Total Width (in inches)"]
    defaults = [0*unit_length]
    input = UI.inputbox(prompts, defaults, "Enter Parameters")

    width = input[0]*unit_length

    buildSimpleLH(width)
  end

  def self.createWalls
    prompts = ["Width", "Depth", "Return Left", "Return Right", "Closet Height", "Name", "Wall Height"]
    defaults = [50.0, 23.0, 6.0, 7.0, 84, "", 96]
    input = UI.inputbox(prompts, defaults, "Enter Parameters")

    width = input[0]*unit_length
    depth = input[1]*unit_length
    left  = input[2]*unit_length
    right = input[3]*unit_length
    closet = input[4]*unit_length
    name  = input[5]
    wall = input[6]*unit_length

    buildWalls(width, depth, left, right, closet, name, wall)
  end

  def self.createLH
    prompts = ["Width Type", "Width", "Depth"]
    defaults = ["Shelf", 24, 12]
    list = ["Total|Shelf", "", ""]
    input = UI.inputbox(prompts, defaults, list, "Enter Parameters")

    type  = input[0]
    width = input[1]*unit_length
    depth = input[2]*unit_length

    buildLH(type, width, depth)
  end

  def self.createDH
    prompts = ["Shelf Width", "Depth"]
    defaults = [24, 12]
    input = UI.inputbox(prompts, defaults, "Enter Parameters")

    width = input[0]*unit_length
    depth = input[1]*unit_length

    buildDH(width, depth)
  end

  def self.createShelf
    prompts = ["Width", "Depth"]
    defaults = [24*unit_length, 12*unit_length]
    input = UI.inputbox(prompts, defaults, "Enter Parameters")

    width = input[0]*unit_length
    depth = input[1]*unit_length

    startOperation('Add Shelf')

    addShelf(0, width, depth, @@thickness)

    endOperation
  end

  def self.createShelfStack
    ## Shelf Stack
    selection = Sketchup.active_model.selection

    if (selection.length > 0)
      defaultWidth = (selection[0].length)*unit_length
    else
      defaultWidth = 25.5
    end

    prompts = ["Width Type", "Width", "Depth", "Gable Height", "Shelves/Stack", "# of Sections", "Floor Unit", "Placement"]
    defaults = ["Total", defaultWidth, 18, 72, 5, 1, "No", "Center"]
    list = ["Total|Shelf", "", "", "", "", "", "Yes|No", "Left|Center|Right"]
    input = UI.inputbox(prompts, defaults, list, "Enter Parameters")

    return if (input == false)

    type      = input[0]
    width     = input[1]*unit_length
    depth     = input[2]*unit_length
    height    = input[3]*unit_length
    shelves   = input[4]
    sections  = input[5]
    floor     = (input[6] == "Yes")
    placement  = input[7]

    if (sections > 0)
      buildShelfStack(type, width, depth, height, shelves, sections, floor, placement)
    else
      UI.messagebox("Must have at least 1 section")
      testItem
    end
  end

  # Add a menu for creating 3D shapes
  # Checks if this script file has been loaded before in this SU session
  unless file_loaded?(__FILE__) # If not, create menu entries
    shapes_menu = UI.menu("Plugins").add_submenu("Closets")
    #shapes_menu.add_item("Poop") {fartBox}
    shapes_menu.add_item("Create Walls") {createWalls}
    shapes_menu.add_item("Add Simple Long Hang") {createSimpleLH}
    shapes_menu.add_item("Add Long Hang") {createLH}
    shapes_menu.add_item("Add Double Hang") {createDH}
    shapes_menu.add_item("Add Shelf") {createShelf}
    shapes_menu.add_item("Add Shelf Stack") {createShelfStack}
    file_loaded(__FILE__)
  end

end # module FVCC::Closets
