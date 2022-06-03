
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

  def self.addFace (addition, push = 0, material = nil)
    group = @@currentEnt.add_group
    face = group.entities.add_face(addition)

    addMaterial(face, material) unless material == nil
    face.pushpull(push) unless push == 0
    group
  end

  def self.addMaterial (face, material_name='Metal Corrugated Shiny')
    filename = "Materials/Metal/#{material_name}.skm"
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

  def self.addToLayer(component, layerName)
    layer = @@model.layers[layerName] || @@model.layers.add(layerName)
    component.layer = layer
  end

  def self.displayError(e)
    matches = /.*\/(.*)\.rb(:.*)/.match(e.backtrace[0])
    message = "Error: " + e.message + ' - ' + matches[1]+matches[2]
    p message
    abort
    message
  end

  def self.postProcessGable(height, depth, thickness)
	
    height = postProcessHeight(height)
    depth  = postProcessDepth(depth)

    return [height, depth, thickness]
  end

  def self.postProcessShelf(width, depth, thickness)
    [width, postProcessDepth(depth), thickness]
  end
  
  def self.postProcessHeight(height)
	(( (height-18) / 32 ).to_i) * 32 + 18
  end
  
  def self.postProcessDepth(depth)
    if depth == 375
      depth  = 376 
    elsif depth == 305
      depth = 300
    end
	
	depth
  end

end # module FVCC::Closets
