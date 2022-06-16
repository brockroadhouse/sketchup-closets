# frozen_string_literal: true

module FVCC::Closets

  class Part

    def initialize(width, depth, height, location, part)
      @width = width
      @depth = depth
      @height = height
      @location = location
      @face = make_face
      
      @part_name = part.fetch('partName', '')
      @params   = part.fetch('params', '')
      @name = set_name
      add_part
    end

    def add_part
      definition = Sketchup.active_model.definitions[@name]
      trans = Geom::Transformation.new(@location)
      @comp = if !definition
              add_part_component(trans)
            else
              FVCC::Closets.current_entities.add_instance definition, trans
            end
    end

    def add_part_component(trans)
      set_definition

      @comp.move! trans
    end

    def set_definition
      group = FVCC::Closets.addFace(@face, thickness)
      @comp = group.to_component
      @comp.definition.name = @name
      @comp.definition.set_attribute('cnc_params', 'partName', @part_name)
      @comp.definition.set_attribute('cnc_params', 'params', @params)
    end

    def make_xy_face(_x, _y)
      [
        Geom::Point3d.new(0, 0, 0),
        Geom::Point3d.new(_x, 0, 0),
        Geom::Point3d.new(_x, _y, 0),
        Geom::Point3d.new(0, _y, 0)
      ]
    end
  
    def make_xz_face(_x, _z)
      [
        Geom::Point3d.new(0, 0, 0),
        Geom::Point3d.new(_x, 0, 0),
        Geom::Point3d.new(_x, 0, _z),
        Geom::Point3d.new(0, 0, _z)
      ]
    end
  
    def make_yz_face(_y, _z)
      [
        Geom::Point3d.new(0, 0, 0),
        Geom::Point3d.new(0, _y, 0),
        Geom::Point3d.new(0, _y, _z),
        Geom::Point3d.new(0, 0, _z)
      ]
    end
	
    def thickness
      FVCC::Closets.thickness
    end
  end

  class Shelf < Part
    def make_face
      make_xy_face(@width, @depth)
    end

    def set_name
      "Shelf @ #{@width} x #{@depth} " + @params
    end

    def add_dimension

      add_width_dimension
      add_depth_dimension
      # Depth
    end

    def add_width_dimension
      pt1 = [@location[0], @location[1], @location[2]]
      pt2 = [@location[0] + @width, @location[1], @location[2]]
      FVCC::Closets.addDimension(pt1, pt2, [0, 0, -5])
    end

    def add_depth_dimension
      pt1 = [@location[0], @location[1], @location[2]]
      pt2 = [@location[0], @location[1] + @depth, @location[2]]
      FVCC::Closets.addDimension(pt1, pt2, [@width / 2, 0, 0])
    end
  end

  class Drawer < Part
    # @part
    # @overlay
	
    def initialize(width, height, location)
      set_part
      set_overlay
      set_location(location)

      width_modified = width + @overlay

      super(width_modified, height, thickness, @location, @part)
      @comp.definition.set_attribute('cnc_params', 'width', @width.round)
      
      add_handle
    end
    
    def set_part
      @part = FVCC::Closets.cnc_parts['drawer']['front']
    end
    
    def set_overlay
      @overlay = @part['overlay'].to_l
    end
    
    def set_location(location)
      @location = location
      @location[0] -= @overlay / 2
    end	
    
    def set_name
      "#{@width} x #{@height} Drawer"
    end
    
    def make_face
      make_xz_face(@width, @depth)
    end
    
    def add_handle
      pt1 = Geom::Point3d.new(@width / 2 - 2, -thickness, @depth / 2)
      pt2 = Geom::Point3d.new(@width / 2 + 2, -thickness, @depth / 2)
      
      @comp.definition.entities.add_line(pt1, pt2)
    end
  end
end