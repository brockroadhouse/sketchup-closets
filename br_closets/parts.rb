# frozen_string_literal: true

require_relative 'part.rb'

module FVCC::Closets

  def self.add_title(name, pt)
    name_group = @@currentEnt.add_group

    # 3D Text
    name_group.entities.add_3d_text(name, TextAlignRight, 'Tahoma', false,
                                    false, 6, 0, 0, true, 3)

    # Move text to pt
    t = Geom::Transformation.new pt
    name_group = name_group.move!(t)

    # Rotate correctly
    point = pt
    vector = Geom::Vector3d.new(1, 0, 0)
    angle = 90.degrees # Return 45 degrees in radians.
    new_transform = Geom::Transformation.rotation(point, vector, angle)
    name_group.transform!(new_transform)
  end

  def self.add_part_component(face, trans, name, part = name, params = '', handle = [])
    push_distance = @@opts['thickness']
    # push_distance = name.include? 'rod' ? width : @@opts['thickness']
    group = addFace(face, push_distance)
    group.entities.add_line handle[0], handle[1] unless handle.empty?
    comp = group.to_component

    comp.definition.name = name
    comp.definition.set_attribute('cnc_params', 'partName', part)
    comp.definition.set_attribute('cnc_params', 'params', params)

    comp.move! trans
    comp
  end

  def self.add_part(comp_name, location, face, part_name = comp_name, params = '')
    definition = Sketchup.active_model.definitions[comp_name]
    trans = Geom::Transformation.new(location)
    comp = if !definition
             add_part_component(face, trans, comp_name, part_name, params)
           else
             @@currentEnt.add_instance definition, trans
           end
    comp
  end

  def self.addGable(width, height, location = [0, 0, 0], part = {})
    part_name = part == nil ? 'Gable' : part.fetch('partName', 'Gable')
    params = part == nil ? '' : part.fetch('params', '')
    comp_name = "#{part_name} @ #{height} x #{width} " + params
    face = make_yz_face(width, height)
    add_part(comp_name, location, face, part_name, params)
  end

  def self.addShelves(width, depth, locations, _dimension = true)
    locations.each_with_index do |location, i|
      addShelf(width, depth, location, i == 0)
    end
  end

  def self.addShelf(width, depth, location, dimension = false, part = {})
    part = @@cncParts['shelf'] if part.empty?
    shelf = Shelf.new(width, depth, @@opts['thickness'], location, part)
    shelf.add_dimension if dimension
    
    return
    partName = part.fetch('partName', '')
    params   = part.fetch('params', '')
    name = "Shelf @ #{width} x #{depth} " + params

    # create if part doesn't exist or not the same dimensions
    face = make_xy_face(width, depth)
    add_part(name, location, face, partName, params)
  end

  def self.addCleat(width, location)
    compName = "#{width} Cleat"
    partName = @@cncParts['cleat']['partName']

    cleat = [
      Geom::Point3d.new(0, 0, 0),
      Geom::Point3d.new(width, 0, 0),
      Geom::Point3d.new(width, 0, @@opts['cleat']),
      Geom::Point3d.new(0, 0, @@opts['cleat'])
    ]
    add_part(compName, location, cleat, partName)
  end

  def self.addDrawer(width, height, location)
    add_drawer_front(width, height, location)
    add_drawer_bottom(width, location)
	  location[1] += 340.mm
    add_drawer_back(width, location)
  end

  def self.add_drawer_front(width, height, location = [0, 0, 0])
    front = Drawer.new(width, height, location)
	return 
    compName  = "#{width} x #{height} Drawer"
    part      = @@cncParts['drawer']['front']
    partName  = part['partName']
    params    = part['params']

    overlay = part['overlay'].to_l
    location[0] -= overlay / 2

    compDefinition = Sketchup.active_model.definitions[compName]
    transformation = Geom::Transformation.new(location)
    if !compDefinition
      drawingWidth = width + overlay
      drawer = [
        Geom::Point3d.new(0, 0, 0),
        Geom::Point3d.new(drawingWidth, 0, 0),
        Geom::Point3d.new(drawingWidth, 0, height),
        Geom::Point3d.new(0, 0, height)
      ]

      pt1 = Geom::Point3d.new(drawingWidth / 2 - 2, -@@opts['thickness'], height / 2)
      pt2 = Geom::Point3d.new(drawingWidth / 2 + 2, -@@opts['thickness'], height / 2)

      comp = add_part_component(drawer, transformation, compName, partName, params, [pt1, pt2])

      set_drawer_width_params(comp.definition, part, width)
    else
      @@currentEnt.add_instance(compDefinition, transformation)
    end
  end

  def self.add_drawer_bottom(width, location)
    name = "#{width} Drawer Bottom"
    part_name = @@cncParts['drawer']['bottom']['partName']
    params = @@cncParts['drawer']['bottom']['params']

    face = make_xy_face(width, 340.mm)
    location[1] += @@opts['thickness']
    comp = add_part(name, location, face, part_name, params)
    
    part = @@cncParts['drawer']['bottom']
    set_drawer_width_params(comp.definition, part, width)
  end

  def self.add_drawer_back(width, location)
    name = "#{width} Drawer Back"
    part = @@cncParts['drawer']['back']['large']
    part_name = part['partName']
	
    face = make_xz_face(width, part['height'].to_l)
    comp = add_part(name, location, face, part_name)

    set_drawer_width_params(comp.definition, part, width)
  end

  def self.set_drawer_width_params(comp_def, part, width)
    shelf_width = width.to_mm.round

    width_mod = if part.has_key? 'overlay'
                  shelf_width + part['overlay'].to_i
                elsif part.has_key? 'inset'
                  shelf_width - part['inset'].to_i
                else
                  shelf_width
                end

    comp_def.set_attribute('cnc_params', 'width', width_mod.round)
  end

  def self.addDoor(width, height, location = [0, 0, 0])
    compName = "#{width} x #{height} Door"
    door = [
      Geom::Point3d.new(0, 0, 0),
      Geom::Point3d.new(width, 0, 0),
      Geom::Point3d.new(width, 0, height),
      Geom::Point3d.new(0, 0, height)
    ]
    comp = add_part(compName, location, door)
    addToLayer(comp, 'Doors')
  end

  def self.addRod(width, location)
    # location[x,y,z] are the coords of the bottom corner of shelf
    comp_name = "#{width} Closet Rod"
    new_location = [
      location[0] + 0,
      location[1] + 2,
      location[2] - (3 + @@opts['thickness'])
    ]
    
    rod_face = make_xz_face(width, 1.5.inch)
    rod = add_part(comp_name, new_location, rod_face)
    addMaterial(rod)
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

  def self.make_xy_face(_x, _y)
    [
      Geom::Point3d.new(0, 0, 0),
      Geom::Point3d.new(_x, 0, 0),
      Geom::Point3d.new(_x, _y, 0),
      Geom::Point3d.new(0, _y, 0)
    ]
  end

  def self.make_xz_face(_x, _z)
    [
      Geom::Point3d.new(0, 0, 0),
      Geom::Point3d.new(_x, 0, 0),
      Geom::Point3d.new(_x, 0, _z),
      Geom::Point3d.new(0, 0, _z)
    ]
  end

  def self.make_yz_face(_y, _z)
    [
      Geom::Point3d.new(0, 0, 0),
      Geom::Point3d.new(0, _y, 0),
      Geom::Point3d.new(0, _y, _z),
      Geom::Point3d.new(0, 0, _z)
    ]
  end
end # module FVCC::Closets
