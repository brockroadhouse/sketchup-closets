
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

  def self.startOperation (name, newGroup = true)
    @@model = Sketchup.active_model
    @@model.start_operation(name, true)
    @@selection = Sketchup.active_model.selection
    addGroup if (newGroup == true)
  end

  def self.endOperation
    @@model.commit_operation
  end

  def self.addGroup
    @currentGroup = @@model.active_entities.add_group
    @@currentEnt = @currentGroup.entities
  end

  def self.addFace (addition, push = 0, material = nil)
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
    group = addFace(face, @@thickness)
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
    return @@selection.single_object? && @@selection.first.is_a?(Sketchup::Edge)
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

  def self.moveToSelection(depth, height)
    return unless @@move == true && selectionIsEdge

    location = @@selection[0].start.position
    pt = Geom::Point3d.new(location[0], location[1]-depth, location[2]-height)

    moveTo(pt)

    diff  = @@selection[0].end.position[1] - @@selection[0].start.position[1]

    rotateTo(location, diff>0) unless (diff == 0)
  end

  def self.addTitle(name, pt)
    nameGroup = @@currentEnt.add_group

    # 3D Text
    nameGroup.entities.add_3d_text(name, TextAlignRight, 'Tahoma', false, false, 9, tolerance = 0.0, 0, true, 3)

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
    compName = "#{width}\" x #{height}\" Gable"
    compDefinition = Sketchup.active_model.definitions[compName]
    transformation = Geom::Transformation.new(location)
    if (!compDefinition)
      gable = [
        Geom::Point3d.new(0, 0, 0),
        Geom::Point3d.new(0, width, 0),
        Geom::Point3d.new(0, width, height),
        Geom::Point3d.new(0, 0, height),
      ]
      group = addFace(gable, @@thickness)
      comp = group.to_component
      comp.definition.name = compName

      comp.move! transformation
    else
      @@currentEnt.add_instance compDefinition, transformation
    end
  end

  def self.addShelf (width, depth, location, dimension = false)
    compName = "#{width}\" x #{depth}\" Shelf"

    compDefinition = Sketchup.active_model.definitions[compName]
    transformation = Geom::Transformation.new(location)
    if (!compDefinition)
      comp = addComponent(width, depth, @@thickness, compName)
      comp.move! transformation
    else
      comp = @@currentEnt.add_instance(compDefinition, transformation)
    end

    # Add dimension line
    if (dimension == true)
      xStart  = location[0]
      xEnd    = location[0]+width
      y       = location[1]
      z       = location[2]

      addDimension([xStart, y, z], [xEnd, y, z], [0,0,-5])
    end
  end

  def self.addCleat (width, location)
    compName = "#{width}\" Cleat"

    compDefinition = Sketchup.active_model.definitions[compName]
    transformation = Geom::Transformation.new(location)
    if (!compDefinition)
      cleat = [
        Geom::Point3d.new(0, 0, 0),
        Geom::Point3d.new(width, 0, 0),
        Geom::Point3d.new(width, 0, @@cleat),
        Geom::Point3d.new(0, 0, @@cleat),
      ]
      compName = "#{width}\" Cleat"
      group = addFace(cleat, @@thickness)
      comp = group.to_component
      comp.definition.name = compName

      comp.move! transformation
    else
      @@currentEnt.add_instance(compDefinition, transformation)
    end
  end

  def self.addDrawer (width, height, location=[0,0,0])
    compName = "#{width}\" Drawer"

    compDefinition = Sketchup.active_model.definitions[compName]
    transformation = Geom::Transformation.new(location)
    if (!compDefinition)
      drawer = [
        Geom::Point3d.new(0, 0, 0),
        Geom::Point3d.new(width, 0, 0),
        Geom::Point3d.new(width, 0, height),
        Geom::Point3d.new(0, 0, height),
      ]
      group = addFace(drawer, @@thickness)

      pt1 = Geom::Point3d.new(width/2-2, -@@thickness, height/2)
      pt2 = Geom::Point3d.new(width/2+2, -@@thickness, height/2)
      group.entities.add_line pt1, pt2
      comp = group.to_component
      comp.definition.name = compName

      comp.move! transformation
    else
      @@currentEnt.add_instance(compDefinition, transformation)
    end
  end

  def self.addRod (width, location)
    # location[x,y,z] are the coords of the bottom corner of shelf
    compName = "#{width}\" Closet Rod"

    compDefinition = Sketchup.active_model.definitions[compName]
    transformation = Geom::Transformation.new([location[0]+0, location[1]+2, location[2]-(1.5+@@thickness)])
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

  def self.setMixedParams(build)
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
        offset = @@thickness * 2
      elsif (placement == "Shelves")
        offset = 0
      else
        offset = @@thickness
      end

      buildOpts[:placement] = placement
      buildOpts[:offset]    = offset
    end
  end

end # module FVCC::Closets
