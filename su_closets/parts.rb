module Closets

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

  def self.addPartComponent (face, trans, name, partName = name, params = '', handle = [])
    group = addFace(face, @@opts['thickness'])
    if !handle.empty?
        group.entities.add_line handle[0], handle[1]
    end
    comp = group.to_component

    comp.definition.name = name
    comp.definition.set_attribute("cnc_params", "partName", partName)
    comp.definition.set_attribute("cnc_params", "params", params)
    
    comp.move! trans
    comp
  end

  def self.addPart(compName, location, face, partName, params)
    
    compDefinition = Sketchup.active_model.definitions[compName]
    transformation = Geom::Transformation.new(location)
    if (!compDefinition)
      comp = addPartComponent(face, transformation, compName, partName, params)
    else
      comp = @@currentEnt.add_instance compDefinition, transformation
    end
    comp
  end

  def self.addGable (width, height, location = [0, 0, 0], part = {})

    partName = part.fetch('partName', 'Gable')
    params   = part.fetch('params', '')
    compName = "#{partName} @ #{height} x #{width} " + params
    face = [
        Geom::Point3d.new(0, 0, 0),
        Geom::Point3d.new(0, width, 0),
        Geom::Point3d.new(0, width, height),
        Geom::Point3d.new(0, 0, height),
      ]
    addPart(compName, location, face, partName, params)
  end

  def self.addShelves(width, depth, locations, dimension = true)
    locations.each_with_index do |location, i|
      self.addShelf(width, depth, location, i==0)
    end
  end

  def self.addShelf (width, depth, location, dimension = false, part = {})
    part = @@cncParts['shelf'] unless part
    partName = part.fetch('partName', '')
    params   = part.fetch('params', '')
    name = "Shelf @ #{width} x #{depth} " + params

    # create if part doesn't exist or not the same dimensions
    face = [
        Geom::Point3d.new(0, 0, 0),
        Geom::Point3d.new(width, 0, 0),
        Geom::Point3d.new(width, depth, 0),
        Geom::Point3d.new(0, depth, 0),
    ]
    addPart(name, location, face, partName, params)

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
    compName = "#{width} Cleat"
    partName = @@cncParts['cleat']['partName']

    compDefinition = Sketchup.active_model.definitions[compName]
    transformation = Geom::Transformation.new(location)
    if (!compDefinition)
      cleat = [
        Geom::Point3d.new(0, 0, 0),
        Geom::Point3d.new(width, 0, 0),
        Geom::Point3d.new(width, 0, @@opts['cleat']),
        Geom::Point3d.new(0, 0, @@opts['cleat']),
      ]
      comp = addPartComponent(cleat, transformation, compName, partName)
    else
      @@currentEnt.add_instance(compDefinition, transformation)
    end
  end

  def self.addDrawer(width, height, location)
    addDrawerFront(width, height, location)
  end

  def self.addDrawerFront (width, height, location=[0,0,0])
    compName = "#{width} x #{height} Drawer"
    partName = @@cncParts['drawer']['front']['partName']
    params = @@cncParts['drawer']['front']['params']

    overlay = @@opts['thickness']
    location[0] -= overlay/2
    
    compDefinition = Sketchup.active_model.definitions[compName]
    transformation = Geom::Transformation.new(location)
    if (!compDefinition)
      drawingWidth = width + overlay
      drawer = [
        Geom::Point3d.new(0, 0, 0),
        Geom::Point3d.new(drawingWidth, 0, 0),
        Geom::Point3d.new(drawingWidth, 0, height),
        Geom::Point3d.new(0, 0, height),
      ]

      pt1 = Geom::Point3d.new(drawingWidth/2-2, -@@opts['thickness'], height/2)
      pt2 = Geom::Point3d.new(drawingWidth/2+2, -@@opts['thickness'], height/2)

      comp = addPartComponent(drawer, transformation, compName, partName, params, [pt1, pt2])

      cncWidth = width.to_mm.round
      comp.definition.set_attribute("cnc_params", "shelfwidth", cncWidth)
    else
      @@currentEnt.add_instance(compDefinition, transformation)
    end
  end

  def self.addDoor (width, height, location=[0,0,0])
    compName = "#{width} x #{height} Door"

    compDefinition = Sketchup.active_model.definitions[compName]
    transformation = Geom::Transformation.new(location)
    if (!compDefinition)
      door = [
        Geom::Point3d.new(0, 0, 0),
        Geom::Point3d.new(width, 0, 0),
        Geom::Point3d.new(width, 0, height),
        Geom::Point3d.new(0, 0, height),
      ]
      comp = addPartComponent(door, transformation, compName)
    else
      comp = @@currentEnt.add_instance(compDefinition, transformation)
    end
    addToLayer(comp, "Doors")
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
end # module FVCC::Closets
