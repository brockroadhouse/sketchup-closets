
module Closets

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
        unit_length = 1.mm
      when 3
        ## model is using metric units - centimetres
        unit_length = 1.cm
      when 4
        ## model is using metric units - metres
        unit_length =  1.m
      end #end case

    else
      UI.messagebox " Can't determine model units - please set in Window/ModelInfo"
    end # if
  end

  def self.setUnits(unit, precision = 0, lengthFormat = 0)
    model = Sketchup.active_model
    manager = model.options
    if provider = manager["UnitsOptions"]
      provider["LengthUnit"]      = unit
      provider["LengthPrecision"] = precision
      provider["LengthFormat"]    = lengthFormat
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
    if(selectionIsEdge)
      defaultWidth = (@@selection[0].length)
      i = 1
      while @@selection[i].is_a?(Sketchup::Edge) do
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

  def self.startOperation (name, newGroup = true, groupName = "")
    @@model = Sketchup.active_model
    @@model.start_operation(name, true)
    self.setSelection
    addGroup(groupName) if (newGroup == true)
  end

  def self.abort
    @@model.abort_operation
  end

  def self.endOperation
    @@model.commit_operation
  end

  def self.addGroup(name = "")
    @currentGroup = @@model.active_entities.add_group
    @currentGroup.name = name
    @@currentEnt = @currentGroup.entities
  end

  def self.addFace (addition, push = 0, material = nil, test = 0)
    group = @@currentEnt.add_group
    face = group.entities.add_face(addition)

    addMaterial(face, material) unless material == nil
    face.pushpull(push) unless push == 0
    group
  end

  def self.addComponent (x, y, z, name, dimension = false)
    face = [
      Geom::Point3d.new(0, 0, 0),
      Geom::Point3d.new(x, 0, 0),
      Geom::Point3d.new(x, y, 0),
      Geom::Point3d.new(0, y, 0),
    ]
    group = addFace(face, @@opts['thickness'])
    comp = group.to_component
    comp.definition.name = name
    comp
  end

  def self.addMaterial (face, addit)
    filename = 'Materials/Metal/Metal Corrugated Shiny.skm'
    path = Sketchup.find_support_file(filename)
    materials = Sketchup.active_model.materials
    if path
      material = materials.load(path)
      face.material = material
    end
  end

  def self.addDimension (pt1, pt2, vector)
    @@currentEnt.add_dimension_linear(pt1, pt2, vector)
  end

  def self.selectionIsEdge
    return defined?(@@selection) ? @@selection.first.is_a?(Sketchup::Edge) : false
  end

  def self.selectionHeight
    height = 0
    if(selectionIsEdge)
      height = @@selection[0].start.position[2]
    end
    return height
  end

  def self.moveTo (pt)
    t = Geom::Transformation.new pt
    @currentGroup = @currentGroup.move! t
  end

  def self.rotateTo (location, left)
    pt = Geom::Point3d.new location
    vector = left ? Geom::Vector3d.new(0, 0, 1) : Geom::Vector3d.new(0, 0, -1)
    angle = 90.degrees
    t = Geom::Transformation.rotation(pt, vector, angle)
    @currentGroup = @currentGroup.transform! t
  end

  def self.moveToSelection(depth, height, floor = false)
    return unless @@move == true && selectionIsEdge

    location = @@selection[0].start.position
    moveHeight = floor ? 0 : location[2]-height
    pt = Geom::Point3d.new(location[0], location[1]-depth, moveHeight)

    moveTo(pt)

    diff  = @@selection[0].end.position[1] - @@selection[0].start.position[1]
    rotateTo(location, diff>0) unless (diff.abs < 1)
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

  def self.addGable (width, height, location = [0, 0, 0])
    compName = "#{width} x #{height} x #{@@opts['thickness']}\" Gable"
    compDefinition = Sketchup.active_model.definitions[compName]
    transformation = Geom::Transformation.new(location)
    if (!compDefinition)
      gable = [
        Geom::Point3d.new(0, 0, 0),
        Geom::Point3d.new(0, width, 0),
        Geom::Point3d.new(0, width, height),
        Geom::Point3d.new(0, 0, height),
      ]
      group = addFace(gable, @@opts['thickness'])
      comp = group.to_component
      comp.definition.name = compName

      comp.move! transformation
    else
      @@currentEnt.add_instance compDefinition, transformation
    end
  end

  def self.addShelves(width, depth, locations, dimension = true)
    locations.each_with_index do |location, i|
      self.addShelf(width, depth, location, i==0)
    end
  end

  def self.addShelf (width, depth, location, dimension = false)
    compName = "#{width} x #{depth} x #{@@opts['thickness']}\" Shelf"
    compDefinition = Sketchup.active_model.definitions[compName]
    transformation = Geom::Transformation.new(location)
    if (!compDefinition)
      comp = addComponent(width, depth, @@opts['thickness'], compName)
      comp.move! transformation
    else
      comp = @@currentEnt.add_instance(compDefinition, transformation)
    end

    # Add dimension line
    if (dimension == true)
      x       = location[0]
      xEnd    = location[0]+width
      y       = location[1]
      yEnd    = location[1]+depth
      z       = location[2]

      # Width
      addDimension([x, y, z], [xEnd, y, z], [0,0,-5])

      # Depth
      addDimension([x, y, z], [x, yEnd, z], [width/2,0,0])
    end
  end

  def self.addCleat (width, location)
    compName = "#{width} x #{@@opts['cleat']}\" x #{@@opts['thickness']}\" Cleat"

    compDefinition = Sketchup.active_model.definitions[compName]
    transformation = Geom::Transformation.new(location)
    if (!compDefinition)
      cleat = [
        Geom::Point3d.new(0, 0, 0),
        Geom::Point3d.new(width, 0, 0),
        Geom::Point3d.new(width, 0, @@opts['cleat']),
        Geom::Point3d.new(0, 0, @@opts['cleat']),
      ]
      group = addFace(cleat, @@opts['thickness'])
      comp = group.to_component
      comp.definition.name = compName

      comp.move! transformation
    else
      @@currentEnt.add_instance(compDefinition, transformation)
    end
  end

  def self.addDrawer (width, height, location=[0,0,0])
    compName = "#{width} x #{height} x #{@@opts['thickness']}\" Drawer"

    compDefinition = Sketchup.active_model.definitions[compName]
    transformation = Geom::Transformation.new(location)
    if (!compDefinition)
      drawer = [
        Geom::Point3d.new(0, 0, 0),
        Geom::Point3d.new(width, 0, 0),
        Geom::Point3d.new(width, 0, height),
        Geom::Point3d.new(0, 0, height),
      ]
      group = addFace(drawer, @@opts['thickness'])

      pt1 = Geom::Point3d.new(width/2-2, -@@opts['thickness'], height/2)
      pt2 = Geom::Point3d.new(width/2+2, -@@opts['thickness'], height/2)
      group.entities.add_line pt1, pt2
      comp = group.to_component
      comp.definition.name = compName

      comp.move! transformation
    else
      @@currentEnt.add_instance(compDefinition, transformation)
    end
  end

  def self.addDoor (width, height, location=[0,0,0])
    compName = "#{width} x #{height} x #{@@opts['thickness']}\" Door"

    compDefinition = Sketchup.active_model.definitions[compName]
    transformation = Geom::Transformation.new(location)
    if (!compDefinition)
      door = [
        Geom::Point3d.new(0, 0, 0),
        Geom::Point3d.new(width, 0, 0),
        Geom::Point3d.new(width, 0, height),
        Geom::Point3d.new(0, 0, height),
      ]
      group = addFace(door, @@opts['thickness'])

      comp = group.to_component
      comp.definition.name = compName

      comp.move! transformation
    else
      comp = @@currentEnt.add_instance(compDefinition, transformation)
    end
    addToLayer(comp, "Doors")
  end

  def self.addToLayer(component, layerName)
    layer = @@model.layers[layerName] || @@model.layers.add(layerName)
    component.layer = layer
  end

  def self.addRod (width, location)
    # location[x,y,z] are the coords of the bottom corner of shelf
    compName = "#{width} Closet Rod"

    compDefinition = Sketchup.active_model.definitions[compName]
    transformation = Geom::Transformation.new([location[0]+0, location[1]+2, location[2]-(1.5+@@opts['thickness'])])
    if (!compDefinition)
      rod = [
        Geom::Point3d.new(0, 0, 0),
        Geom::Point3d.new(0, 0, -1.5),
        Geom::Point3d.new(0, 1, -1.5),
      ]
      group = addFace(rod, width, true)
      comp = group.to_component
      comp.definition.name = compName

      comp.move! transformation
    else
      @@currentEnt.add_instance(compDefinition, transformation)
    end
  end

  def self.addWallRail (width, location)
    compName = "#{width} Wall Rail"

    compDefinition = Sketchup.active_model.definitions[compName]
    transformation = Geom::Transformation.new(location)
    if (!compDefinition)
      rail = [
        Geom::Point3d.new(0, 0, 0),
        Geom::Point3d.new(width, 0, 0),
        Geom::Point3d.new(width, 0, 1.25.inch),
        Geom::Point3d.new(0, 0, 1.25.inch),
      ]
      group = addFace(rail, -1)
      comp = group.to_component
      comp.definition.name = compName

      comp.move! transformation
    else
      @@currentEnt.add_instance(compDefinition, transformation)
    end
  end

  def self.splitWidth(width, place)
    if (placement == "Center")
      numGables = 0
    elsif (placement == "Shelves")
      numGables = 2
    else
      numGables = 1
    end

    sections = ((width-@@opts['thickness'])/(32 + @@opts['thickness'])).ceil
    width = (width - (sections+1-numGables)*@@opts['thickness'])/sections
    return {:sections => sections, :width => width}
  end

  def self.dividedWidth(closets, params)
    gaps = params['gapLeft'].to_l + params['gapRight'].to_l
    buildWidth = dividedWidth = params['width'].to_l - gaps
    
    dividedWidth -= @@opts['thickness'] if params['placement']=='Center'

    sections = 0
    closets.each do |closet|
      sections += 1 if (closet['width'].empty?)
      dividedWidth -= (closet['width'].to_l + @@opts['thickness'])
      dividedWidth += @@opts['thickness'] if closet['type'] == 'Corner'
    end

    params['sectionWidth'] = dividedWidth/sections
    params['buildWidth'] = buildWidth

  end

  def self.setHeights(closets, params)

    floorHeight = params['height'].empty? ? @@floorHeight : params['height'].to_l
    buildHeight = 0
    buildDepth = 0

    closets.each do |closet|
      floor = closet['floor']
      case closet['type']
      when "LH"
        depth  = closet['depth'].empty? ? (floor ? @@floorDepth : @@hangDepth) : closet['depth']
        height = floor ? floorHeight : @@lhHeight
      when "DH"
        depth  = closet['depth'].empty? ? (floor ? @@floorDepth : @@hangDepth) : closet['depth']
        height = floor ? floorHeight : @@dhHeight
      when "VH"
        closet['shelves'] = closet['shelves'].empty? ? 2 : closet['shelves'].to_i
        depth  = closet['depth'].empty? ? (floor ? @@floorDepth : @@hangDepth) : closet['depth']
        height = floor ? floorHeight : (closet['height'].empty? ? @@lhHeight : closet['height'])
      when "Corner"
        closet['shelves'] = floor ? 2 : 1
        depth  = closet['depth'].empty? ? (floor ? @@floorDepth : @@hangDepth) : closet['depth']
        height = floor ? floorHeight : (closet['height'].empty? ? @@lhHeight : closet['height'])
      when "Shelves"
        closet['shelves'] = closet['shelves'].empty? ? 5 : closet['shelves'].to_i
        closet['drawers'] = closet['drawers'].nil? ? 0 : closet['drawers'].to_i
        depth  = closet['depth'].empty? ? @@floorDepth : closet['depth']
        height = floor ? floorHeight : (closet['height'].empty? ? 76.inch : closet['height'])
      end
      closet['width']   = closet['width'].empty? ? params['sectionWidth'].to_l : closet['width'].to_l
      closet['depth']   = depth.to_l
      closet['height']  = height.to_l
      buildHeight = closet['height'] if (closet['height'] > buildHeight)
      buildDepth = closet['depth'] if (closet['depth'] > buildDepth)
    end
    params['buildHeight'] = buildHeight.to_l
    params['buildDepth'] = buildDepth.to_l
  end

  def self.setPlacements(build, params)
    totalPlacement = params['placement']
    if (build.length == 1)
      build[0]['placement'] = totalPlacement
      build[0]['offset']    = @@opts['thickness'] * 2
      return
    end



    build.map.with_index do |closet, i|
      key = closet['floor'] ? 'depth' : 'height'
      floor = closet['floor']

      # Placements
      if (closet['type']=='Corner')
        placement = "Shelves"
      elsif (i == 0) # First
        nextF = build[i+1]['floor']

        taller = (build[i+1]['height'] >= closet['height'])
        deeper = (build[i+1]['depth'] >= closet['depth'])
        isNextTaller = ((taller && !floor) || (deeper && nextF)) 
        if (totalPlacement=="Right")
          placement = isNextTaller ? "Shelves" : "Right"
        else
          placement = isNextTaller ? "Left" : "Center"
        end
      elsif (i == build.count-1) # Last
        lastF = build[i-1]['floor']
        isPrevTaller = (build[i-1][key] > closet[key])
        if (totalPlacement=="Left")
          placement = isPrevTaller ? "Shelves" : "Left"
        else
          placement = isPrevTaller ? "Right" : "Center"
        end
      else
        lastH = build[i-1][key]
        nextH = build[i+1][key]
        thisH = closet[key]
        lastF = build[i-1]['floor']
        nextF = build[i+1]['floor']

        if    (lastH <= thisH && (thisH > nextH || build[i+1]['type'] == 'Corner' || (floor && !nextF )))
          placement = "Center"
        elsif (lastH <= thisH && thisH <= nextH)
          placement = "Left"
        elsif ((lastH > thisH && thisH > nextH) || (floor && !nextF))
          placement = "Right"
        elsif (lastH > thisH && thisH <= nextH)
          placement = "Shelves"
        end

      end

      # Offsets
      if (placement == "Center")
        offset = @@opts['thickness'] * 2
      elsif (placement == "Shelves")
        offset = 0
      else
        offset = @@opts['thickness']
      end

      closet['placement'] = placement
      closet['offset']    = offset
    end
  end

  def self.setClosets(build, params)

    dividedWidth(build, params)
    setHeights(build, params)
    setPlacements(build, params)

  end

  def self.setMixedParams(build)
    if (build.length == 1)
      build[0][:placement] = "Center"
      build[0][:offset]    = @@opts['thickness'] * 2
      return
    end

    build.map.with_index do |buildOpts, i|
      # Placements
      if (i == 0) # First
        placement = (build[i+1][:height] >= buildOpts[:height]) ? "Left" : "Center"
      elsif (i == build.count-1) # Last
        placement = (build[i-1][:height] > buildOpts[:height]) ? "Right" : "Center"
      else
        lastH = build[i-1][:height]
        nextH = build[i+1][:height]
        thisH = buildOpts[:height]

        if    (lastH <= thisH && thisH > nextH)
          placement = "Center"
        elsif (lastH <= thisH && thisH <= nextH)
          placement = "Left"
        elsif (lastH > thisH && thisH > nextH)
          placement = "Right"
        elsif (lastH > thisH && thisH <= nextH)
          placement = "Shelves"
        end

      end

      # Offsets
      if (placement == "Center")
        offset = @@opts['thickness'] * 2
      elsif (placement == "Shelves")
        offset = 0
      else
        offset = @@opts['thickness']
      end

      buildOpts[:placement] = placement
      buildOpts[:offset]    = offset
    end
  end

  def self.displayError(e)
    matches = /.*\/(.*)\.rb(:.*)/.match(e.backtrace[0])
    message = "Error: " + e.message + ' - ' + matches[1]+matches[2]
    p message
    abort
    message
  end

end # module FVCC::Closets
