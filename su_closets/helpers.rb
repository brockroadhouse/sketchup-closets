# frozen_string_literal: true

module Closets

    HANDLE_TOP_RIGHT    = 1
    HANDLE_TOP_LEFT     = 2
    HANDLE_BOTTOM_RIGHT = 3
    HANDLE_BOTTOM_LEFT  = 4

  def self.unit_length
    # Get model units (imperial or metric) and length format.
    model = Sketchup.active_model
    manager = model.options
    if provider = manager['UnitsOptions'] # Check for nil value
      length_unit = provider['LengthUnit'] # Length unit value
      length_format = provider['LengthFormat'] # Length format value

      case length_unit
      when 0 ## Imperial units
        unit_length = if length_format == 1 || length_format == 2
                        # model is using Architectural (feet and inches)
                        # or Engineering units (feet)
                        1.feet
                      else
                        ## model is using (decimal or fractional) inches
                        1.inch
                      end # if
      when 1
        ## Decimal feet
        unit_length = 1.feet
      when 2
        ## model is using metric units - millimetres
        unit_length = 1.mm
      when 3
        ## model is using metric units - centimetres
        unit_length = 1.cm
      when 4
        ## model is using metric units - metres
        unit_length = 1.m
      end # end case

    else
      UI.messagebox " Can't determine model units - please set in Window/ModelInfo"
    end # if
  end

  def self.setUnits(unit, precision = 0, lengthFormat = 0)
    model = Sketchup.active_model
    manager = model.options
    if provider = manager['UnitsOptions']
      provider['LengthUnit']      = unit
      provider['LengthPrecision'] = precision
      provider['LengthFormat']    = lengthFormat
      model.active_view.invalidate
    end
  end

  def self.setModelmm
    setUnits(2) ## Decimal/0mm
  end

  def self.setModelInch
    setUnits(0, 4, 3) ## Fractional / 1/16" / Inches
  end

  def self.currentEnt
    @@currentEnt
  end

  def self.defaultWidth
    if selectionIsEdge
      defaultWidth = @@selection[0].length
      i = 1
      while @@selection[i].is_a?(Sketchup::Edge)
        defaultWidth += @@selection[i].length
        i += 1
      end
    else
      defaultWidth = @@defaultW
    end
    defaultWidth
  end

  def self.setSelection
    @@selection = Sketchup.active_model.selection
  end

  def self.startOperation(name, newGroup = true, groupName = '')
    @@model = Sketchup.active_model
    @@model.start_operation(name, true)
    setSelection
    addGroup(groupName) if newGroup == true
  end

  def self.abort
    @@model.abort_operation
  end

  def self.endOperation
    @@model.commit_operation
  end

  def self.addGroup(name = '')
    @currentGroup = @@model.active_entities.add_group
    @currentGroup.name = name
    @@currentEnt = @currentGroup.entities
  end

  def self.addFace(addition, push = 0, material = nil, _test = 0)
    group = @@currentEnt.add_group
    face = group.entities.add_face(addition)

    addMaterial(face, material) unless material.nil?
    face.pushpull(push) unless push == 0
    group
  end

  def self.addComponent(x, y, _z, name, _dimension = false)
    face = [
      Geom::Point3d.new(0, 0, 0),
      Geom::Point3d.new(x, 0, 0),
      Geom::Point3d.new(x, y, 0),
      Geom::Point3d.new(0, y, 0)
    ]
    group = addFace(face, @@opts['thickness'])
    comp = group.to_component
    comp.definition.name = name
    comp
  end

  def self.addMaterial(face, _addit)
    filename = 'Materials/Metal/Metal Corrugated Shiny.skm'
    path = Sketchup.find_support_file(filename)
    materials = Sketchup.active_model.materials
    if path
      material = materials.load(path)
      face.material = material
    end
  end

  def self.addDimension(pt1, pt2, vector)
    @@currentEnt.add_dimension_linear(pt1, pt2, vector)
  end

  def self.selectionIsEdge
    defined?(@@selection) ? @@selection.first.is_a?(Sketchup::Edge) : false
  end

  def self.selectionHeight
    height = 0
    height = @@selection[0].start.position[2] if selectionIsEdge
    height
  end

  def self.moveTo(pt)
    t = Geom::Transformation.new pt
    @currentGroup = @currentGroup.move! t
  end

  def self.place_group()
    compGrp = @currentGroup.to_component.definition
    @@model.place_component(compGrp)
    #@@currentEnt.erase_entities(@currentGroup)
  end

  def self.rotateTo(location, left)
    pt = Geom::Point3d.new location
    vector = left ? Geom::Vector3d.new(0, 0, 1) : Geom::Vector3d.new(0, 0, -1)
    angle = 90.degrees
    t = Geom::Transformation.rotation(pt, vector, angle)
    @currentGroup = @currentGroup.transform! t
  end

  def self.moveToSelection(depth, height, floor = false)
    return if (@@move == false)

    unless selectionIsEdge
      place_group()
      return
    end
    

    location = @@selection[0].start.position
    moveHeight = floor ? 0 : location[2] - height
    pt = Geom::Point3d.new(location[0], location[1] - depth, moveHeight)

    moveTo(pt)

    diff = @@selection[0].end.position[1] - @@selection[0].start.position[1]
    rotateTo(location, diff > 0) unless diff.abs < 1
  end

  def self.addTitle(name, pt)
    nameGroup = @@currentEnt.add_group

    # 3D Text
    nameGroup.entities.add_3d_text(name, TextAlignRight, 'Tahoma', false, false, 6, 0, 0, true, 3)

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

  def self.addGable(width, height, location = [0, 0, 0], closet=nil)
    thickness = ((closet && closet['thickness']) ? closet['thickness'] : @@opts['thickness']).to_l
    compName = "#{width} x #{height} x #{thickness}\" Gable"
    comp = Sketchup.active_model.definitions[compName]
    transformation = Geom::Transformation.new(location)
    if !comp
        cleat = @@opts['cleat'];
      gable = [
        Geom::Point3d.new(0, 0, 0),
        Geom::Point3d.new(0, width, 0),
        Geom::Point3d.new(0, width, height),
        Geom::Point3d.new(0, 0, height)
      ]
      # gable = [
      #   Geom::Point3d.new(0, 0, cleat),
      #   Geom::Point3d.new(0, 2, cleat),
      #   Geom::Point3d.new(0, 2, 0),
      #   Geom::Point3d.new(0, width, 0),
      #   Geom::Point3d.new(0, width, height),
      #   Geom::Point3d.new(0, 0, height)
      # ]
      group = addFace(gable, thickness)
      comp = group.to_component
      comp.definition.name = compName

      comp.move! transformation
    else
      @@currentEnt.add_instance comp, transformation
    end
    attributes = {
      'name' => 'gable',
      'width' => width,
      'depth' => height,
    }
    set_attributes(comp, attributes)
  end

  def self.addShelves(width, depth, locations, _dimension = true)
    locations.each_with_index do |location, i|
      addShelf(width, depth, location, i == 0)
    end
  end

  def self.addShelf(width, depth, location, dimension = false)
    compName = "#{width} x #{depth} x #{@@opts['thickness']}\" Shelf"
    compDefinition = Sketchup.active_model.definitions[compName]
    transformation = Geom::Transformation.new(location)
    if !compDefinition
      comp = addComponent(width, depth, @@opts['thickness'], compName)
      comp.move! transformation
    else
      comp = @@currentEnt.add_instance(compDefinition, transformation)
    end

    # Add dimension line
    if dimension == true
      xStart  = location[0]
      xEnd    = location[0] + width
      y       = location[1]
      z       = location[2]

      addDimension([xStart, y, z], [xEnd, y, z], [0, 0, -5])
    end
    attributes = {
      'name' => 'fixedShelf',
      'width' => width,
      'depth' => depth,
    }
    set_attributes(comp, attributes)
  end

  def self.addCleat(width, location)
    compName = "#{width} x #{@@opts['cleat']}\" x #{@@opts['thickness']}\" Cleat"

    comp = Sketchup.active_model.definitions[compName]
    transformation = Geom::Transformation.new(location)
    if !comp
      cleat = [
        Geom::Point3d.new(0, 0, 0),
        Geom::Point3d.new(width, 0, 0),
        Geom::Point3d.new(width, 0, @@opts['cleat']),
        Geom::Point3d.new(0, 0, @@opts['cleat'])
      ]
      group = addFace(cleat, @@opts['thickness'])
      comp = group.to_component
      comp.definition.name = compName

      comp.move! transformation
    else
      @@currentEnt.add_instance(comp, transformation)
    end
    attributes = {
      'name' => 'cleat',
      'width' => width,
      'depth' => @@opts['thickness'],
    }
    set_attributes(comp, attributes)
  end

  def self.getHandle(handleFile = 'handle.skp')
      handle = plugin_filepath('handle.skp')
      @@model.definitions.load(handle)
  end

  # def self.addHandle(x, z, transformation)
  #     handle = getHandle()
  #     cinst = group.entities.add_instance(handle, transformation)
  # end
  def self.handleTransformation(handlePosition, width, height)
      y = -@@opts['thickness']
      case handlePosition
      when HANDLE_TOP_LEFT
          puts 'tl'
          point = Geom::Point3d::new(3, y, height-6)
      when HANDLE_TOP_RIGHT
          puts 'tr'
          point = Geom::Point3d::new(width-3, y, height-6)
      when HANDLE_BOTTOM_LEFT
          puts 'bl'
          point = Geom::Point3d::new(4, y, 4)
      when HANDLE_BOTTOM_RIGHT
          puts 'br'
          point = Geom::Point3d::new(width-4, y, 4)
      else
          point = Geom::Point3d::new(0, 0, 0)
      end

      trans = Geom::Transformation::new(
          Geom::Vector3d.new(0, 0, -1),
          Geom::Vector3d.new(0, 1, 0),
          Geom::Vector3d.new(1, 0, 0),
          point,
       )
  end

  def self.addDrawer(width, height, location = [0, 0, 0])
    compName = "#{width} x #{height} x #{@@opts['thickness']}\" Drawer"

    comp = Sketchup.active_model.definitions[compName]
    transformation = Geom::Transformation.new(location)
    if !comp
      drawer = [
        Geom::Point3d.new(0, 0, 0),
        Geom::Point3d.new(width, 0, 0),
        Geom::Point3d.new(width, 0, height),
        Geom::Point3d.new(0, 0, height)
      ]
      group = addFace(drawer, @@opts['thickness'])

      point = Geom::Point3d::new(width/2,-@@opts['thickness'], height/2)
      group.entities.add_instance(
          getHandle(),
          Geom::Transformation::new( point )
      )

      comp = group.to_component
      comp.definition.name = compName

      comp.move! transformation
    else
      @@currentEnt.add_instance(comp, transformation)
    end
    comp.set_attribute('cnc', 'name', 'drawer')
  end

  def self.addDoor(width, height, location = [0, 0, 0], handlePos = false)
    compName = "#{width} x #{height} x #{@@opts['thickness']}\" Door"

    compDefinition = Sketchup.active_model.definitions[compName]
    transformation = Geom::Transformation.new(location)
    if (!compDefinition || !(compDefinition.get_attribute("handle", "handlePos").eql? handlePos))
      door = [
        Geom::Point3d.new(0, 0, 0),
        Geom::Point3d.new(width, 0, 0),
        Geom::Point3d.new(width, 0, height),
        Geom::Point3d.new(0, 0, height)
      ]
      group = addFace(door, @@opts['thickness'])

      if handlePos
        group.entities.add_instance(
            getHandle(),
            handleTransformation(handlePos, width, height)
        )
      end

      comp = group.to_component
      comp.definition.name = compName
      attributes = {
        'handlePos' => handlePos
      }
      set_attributes(comp, attributes, 'handle')

      comp.move! transformation
    else
      comp = @@currentEnt.add_instance(compDefinition, transformation)
    end
    addToLayer(comp, 'Doors')
    attributes = {
      'name' => 'door',
      'width' => width,
      'depth' => height,
    }
    set_attributes(comp, attributes)
  end

  def self.addToLayer(component, layerName)
    layer = @@model.layers[layerName] || @@model.layers.add(layerName)
    component.layer = layer
  end

  def self.addRod(width, location)
    # location[x,y,z] are the coords of the bottom corner of shelf
    compName = "#{width} Closet Rod"

    compDefinition = Sketchup.active_model.definitions[compName]
    transformation = Geom::Transformation.new([location[0] + 0, location[1] + 2, location[2] - (1.5 + @@opts['thickness'])])
    if !compDefinition
      rod = [
        Geom::Point3d.new(0, 0, 0),
        Geom::Point3d.new(0, 0, -1.5),
        Geom::Point3d.new(0, 1, -1.5)
      ]
      group = addFace(rod, width, true)
      comp = group.to_component
      comp.definition.name = compName

      comp.move! transformation
    else
      @@currentEnt.add_instance(compDefinition, transformation)
    end
  end

  def self.addWallRail(width, location)
    compName = "#{width} Wall Rail"

    compDefinition = Sketchup.active_model.definitions[compName]
    transformation = Geom::Transformation.new(location)
    if !compDefinition
      rail = [
        Geom::Point3d.new(0, 0, 0),
        Geom::Point3d.new(width, 0, 0),
        Geom::Point3d.new(width, 0, 1.25.inch),
        Geom::Point3d.new(0, 0, 1.25.inch)
      ]
      group = addFace(rail, -1)
      comp = group.to_component
      comp.definition.name = compName

      comp.move! transformation
    else
      @@currentEnt.add_instance(compDefinition, transformation)
    end
  end

  def self.splitWidth(width, _place)
    numGables = if placement == 'Center'
                  0
                elsif placement == 'Shelves'
                  2
                else
                  1
                end

    sections = ((width - @@opts['thickness']) / (32 + @@opts['thickness'])).ceil
    width = (width - (sections + 1 - numGables) * @@opts['thickness']) / sections
    { sections: sections, width: width }
  end

  def self.dividedWidth(closets, params)
    dividedWidth = params['width'].to_l - params['gapLeft'].to_l - params['gapRight'].to_l
    dividedWidth -= @@opts['thickness'] if params['placement'] == 'Center'
    sections = 0
    closets.each do |closet|
      sections += 1 if closet['width'].empty?
      dividedWidth -= (closet['width'].to_l + @@opts['thickness'])
      dividedWidth += @@opts['thickness'] if closet['type'] == 'Corner'
    end

    params['sectionWidth'] = dividedWidth / sections
  end

  def self.setHeights(closets, params)
    floorHeight = params['height'].empty? ? @@floorHeight : params['height'].to_l
    buildHeight = 0
    buildDepth = 0

    closets.each do |closet|
      floor = closet['floor']
      case closet['type']
      when 'LH'
        depth  = closet['depth'].empty? ? (floor ? @@floorDepth : @@hangDepth) : closet['depth']
        height = floor ? floorHeight : @@lhHeight
      when 'DH'
        depth  = closet['depth'].empty? ? (floor ? @@floorDepth : @@hangDepth) : closet['depth']
        height = floor ? floorHeight : @@dhHeight
      when 'VH'
        closet['shelves'] = closet['shelves'].empty? ? 2 : closet['shelves'].to_i
        depth = closet['depth'].empty? ? (floor ? @@floorDepth : @@hangDepth) : closet['depth']
        height = floor ? floorHeight : (closet['height'].empty? ? @@lhHeight : closet['height'])
      when 'Corner'
        closet['shelves'] = floor ? 2 : 1
        depth = closet['depth'].empty? ? (floor ? @@floorDepth : @@hangDepth) : closet['depth']
        height = floor ? floorHeight : (closet['height'].empty? ? @@lhHeight : closet['height'])
      when 'Shelves'
        closet['shelves'] = closet['shelves'].empty? ? 5 : closet['shelves'].to_i
        closet['drawers'] = closet['drawers'].nil? ? 0 : closet['drawers'].to_i
        depth = closet['depth'].empty? ? @@floorDepth : closet['depth']
        height = floor ? floorHeight : (closet['height'].empty? ? 76.inch : closet['height'])
      end
      closet['width']   = closet['width'].empty? ? params['sectionWidth'].to_l : closet['width'].to_l
      closet['depth']   = depth.to_l
      closet['height']  = height.to_l
      buildHeight = closet['height'] if closet['height'] > buildHeight
      buildDepth = closet['depth'] if closet['depth'] > buildDepth
    end
    params['buildHeight'] = buildHeight.to_l
    params['buildDepth'] = buildDepth.to_l
  end

  def self.setPlacements(build, params)
    totalPlacement = params['placement']
    if build.length == 1
      build[0]['placement'] = totalPlacement
      build[0]['offset']    = @@opts['thickness'] * 2
      return
    end

    build.map.with_index do |closet, i|
      key = closet['floor'] ? 'depth' : 'height'
      # Placements
      if closet['type'] == 'Corner'
        placement = 'Shelves'
      elsif i == 0 # First
        taller = (build[i + 1]['height'] >= closet['height'])
        deeper = (build[i + 1]['depth'] > closet['depth'])
        isNextTaller = taller || deeper
        placement = if totalPlacement == 'Right'
                      isNextTaller ? 'Shelves' : 'Right'
                    else
                      isNextTaller ? 'Left' : 'Center'
                    end
      elsif i == build.count - 1 # Last
        isPrevTaller = (build[i - 1][key] > closet[key])
        placement = if totalPlacement == 'Left'
                      isPrevTaller ? 'Shelves' : 'Left'
                    else
                      isPrevTaller ? 'Right' : 'Center'
                    end
      else
        lastH = build[i - 1][key]
        nextH = build[i + 1][key]
        thisH = closet[key]

        if    lastH <= thisH && (thisH > nextH || build[i + 1]['type'] == 'Corner')
          placement = 'Center'
        elsif lastH <= thisH && thisH <= nextH
          placement = 'Left'
        elsif lastH > thisH && thisH > nextH
          placement = 'Right'
        elsif lastH > thisH && thisH <= nextH
          placement = 'Shelves'
        end

      end

      # Offsets
      offset = if placement == 'Center'
                 @@opts['thickness'] * 2
               elsif placement == 'Shelves'
                 0
               else
                 @@opts['thickness']
               end

      closet['placement'] = placement
      closet['offset']    = offset
    end
  end

  def self.set_attributes(comp, attributes, dictionary='cnc')
    attributes.each do |key, attribute|
      comp.set_attribute(dictionary, key, attribute)
    end
  end

  def self.setClosets(build, params)
    dividedWidth(build, params)
    setHeights(build, params)
    setPlacements(build, params)
  end

  def self.setMixedParams(build)
    if build.length == 1
      build[0][:placement] = 'Center'
      build[0][:offset]    = @@opts['thickness'] * 2
      return
    end

    build.map.with_index do |buildOpts, i|
      # Placements
      if i == 0 # First
        placement = build[i + 1][:height] >= buildOpts[:height] ? 'Left' : 'Center'
      elsif i == build.count - 1 # Last
        placement = build[i - 1][:height] > buildOpts[:height] ? 'Right' : 'Center'
      else
        lastH = build[i - 1][:height]
        nextH = build[i + 1][:height]
        thisH = buildOpts[:height]

        if    lastH <= thisH && thisH > nextH
          placement = 'Center'
        elsif lastH <= thisH && thisH <= nextH
          placement = 'Left'
        elsif lastH > thisH && thisH > nextH
          placement = 'Right'
        elsif lastH > thisH && thisH <= nextH
          placement = 'Shelves'
        end

      end

      # Offsets
      offset = if placement == 'Center'
                 @@opts['thickness'] * 2
               elsif placement == 'Shelves'
                 0
               else
                 @@opts['thickness']
               end

      buildOpts[:placement] = placement
      buildOpts[:offset]    = offset
    end
  end

  def self.displayError(e)
    matches = %r{.*/(.*)\.rb(:.*)}.match(e.backtrace[0])
    message = 'Error: ' + e.message + ' - ' + matches[1] + matches[2]
    p message
    abort
    message
  end
end # module FVCC::Closets
