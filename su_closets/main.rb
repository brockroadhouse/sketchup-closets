require "sketchup.rb"
require "su_closets/prompts.rb"
require "su_closets/helpers.rb"
require "su_closets/export.rb"

module Closets

  @@thickness = 0.75.inch
  @@defaultW  = 610.mm
  @@offset    = 4.inch
  @@cleat     = 5.inch
  @@move      = true
  @@drawer    = 10.inch
  @@hangDepth = 12.inch
  @@lhHeight  = 24.inch
  @@dhHeight  = 48.inch

  @@nameCount = 0

  @@currentEnt
  @@selection
  @currentGroup
  @@model

  def self.buildWalls (name, width, depth, left, right, closetHeight, wallHeight)

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
    addTitle(name, Geom::Point3d.new(width/2-name.length*3, depth, 85)) unless name == ""

  end

  def self.buildShelfStack (type, width, depth, height, shelves, drawers, sections, floor, placement, location = [0,0,0])
    if (floor)
      spacing = (height-@@cleat-@@thickness)/(shelves - 1)
    else
      spacing = (height-@@thickness-drawers*@@drawer)/(shelves - 1)
    end

    # Add gable when in center
    numGables = sections
    numGables += 1 if (placement == "Center")

    width = (width - numGables * @@thickness) / sections if (type == "Total")

    posX = location[0]
    posY = location[1]
    posZ = location[2]
    ### Gable Creation ###
    # Left gable
    unless (placement == "Right")
      addGable(depth, height, [posX, posY, posZ])
      posX += @@thickness
    end

    sections.times do |i|
      # Create shelves
      shelfHeight = height

      shelves.times do |n|
        addShelf(width, depth, [posX, posY, posZ+shelfHeight], n==0)
        shelfHeight -= spacing
      end

      drawerHeight = @@thickness/2
      drawers.times do |n|
        addShelf(width, depth, [posX, posY, posZ+@@thickness]) if n==0
        addDrawer(width+@@thickness, @@drawer, [posX-@@thickness/2, posY, posZ+drawerHeight])
        drawerHeight += @@drawer
      end

      if (floor)
        addCleat(width, [posX, posY+depth, posZ+height-@@thickness-@@cleat])
        addCleat(width, [posX, posY+depth-1, posZ])
        addCleat(width, [posX, posY+2, posZ])
      else
        addCleat(width, [posX, posY+depth, posZ+@@thickness])
      end
      posX += width

      # Right gable
      addGable(depth, height, [posX, posY, posZ]) unless (i == (sections - 1) && placement == "Left")
      posX += @@thickness
      moveToSelection(depth, height)
    end
  end

  def self.buildSimpleLH (width)
    sections = ((width-@@thickness)/(32 + @@thickness)).ceil
    shelfWidth = (width - (sections+1)*@@thickness)/sections

    pos = 0
    depth = @@hangDepth
    height = 10
    # Left gable
    addGable(12, height)

    sections.times do |i|
      pos += @@thickness
      addShelf(shelfWidth, depth, [pos, 0, height])
      addRod(shelfWidth, [pos, 0, height])
      addCleat(shelfWidth, [pos, depth, 0])
      pos += shelfWidth
      addGable(depth, height, [pos, 0, 0])
    end

    moveToSelection(depth, height)
  end

  def self.buildLH (type, width, depth, placement, location = [0,0,0])
    if (placement == "Center")
      numGables = 2
    elsif (placement == "Shelves")
      numGables = 0
    else
      numGables = 1
    end

    width = (width - numGables * @@thickness) if (type == "Total")
    height = @@lhHeight

    posX = location[0]
    posY = location[1]
    posZ = location[2]
    # Gables
    unless (["Right", "Shelves"].include? placement)
      addGable(depth, height, [posX, posY, posZ])
      posX += @@thickness
    end

    # Shelves
    bottom = @@cleat + @@thickness
    mid = (height+bottom)/2
    addShelf(width, depth, [posX, posY, posZ+height], true)
    addShelf(width, depth, [posX, posY, posZ+mid])
    addShelf(width, depth, [posX, posY, posZ+bottom])

    addCleat(width, [posX, posY+depth, posZ])

    addRod(width, [posX, posY, posZ+bottom])

    addGable(depth, height, [width+posX, posY, posZ]) unless ["Left", "Shelves"].include? placement

    moveToSelection(depth, height)
  end

  def self.buildDH (type, width, depth, placement, location = [0,0,0])

    numGables = (placement == "Center") ? 2 : 1
    width = (width - numGables * @@thickness) if (type == "Total")
    height = @@dhHeight

    posX = location[0]
    posY = location[1]
    posZ = location[2]
    # Gables
    unless (["Right", "Shelves"].include? placement)
      addGable(depth, height, [posX, posY, posZ])
      posX += @@thickness
    end

    # Shelves
    bottom = @@cleat + @@thickness
    addShelf(width, depth, [posX, posY, posZ+height], true)
    addShelf(width, depth, [posX, posY, posZ+bottom])

    addCleat(width, [posX, posY+depth, posZ])

    addRod(width, [posX, posY, posZ+height])
    addRod(width, [posX, posY, posZ+bottom])

    addGable(depth, height, [width+posX, posY, posZ]) unless ["Left", "Shelves"].include? placement

    moveToSelection(depth, height)
  end

  def self.buildMixed(width, types, shelves, drawers, height, depth, stackWidth)
    @@move        = false
    build         = Array.new
    buildHeight   = 0
    buildDepth    = @@hangDepth
    totalStack    = 0
    hangSections  = 0
    types.each do |type|
      unless (type == "N/A")
        case type
        when "LH"
          typeHeight = @@lhHeight
          hangSections += 1
        when "DH"
          typeHeight = @@dhHeight
          hangSections += 1
        when "Shelves"
          typeHeight = height
          totalStack += stackWidth
        end
        build << {:type => type, :height => typeHeight}
        buildHeight = typeHeight if (typeHeight > buildHeight)
      end
    end
    sections = build.count

    setMixedParams(build)

    built = 0
    pos = 0
    widthType = "Shelf"
    hangWidth = (width - totalStack - (sections+1) * @@thickness) / hangSections
    build.each do |buildOpts|
      built += 1

      case buildOpts[:type]
      when "LH"
        y = buildDepth
        z = @@lhHeight
        placement = buildOpts[:placement]
        lh = buildLH(widthType, hangWidth, y, placement, [pos, 0,  buildHeight-z])
        offset = hangWidth
      when "DH"
        y = buildDepth
        z = @@dhHeight
        placement = buildOpts[:placement]
        dh = buildDH(widthType, hangWidth, y, placement, [pos, 0,  buildHeight-z])
        offset = hangWidth
      when "Shelves"
        y = depth
        z = height
        placement = buildOpts[:placement]
        buildShelfStack(widthType, stackWidth, depth, height, shelves, drawers, 1, false, placement, [pos, buildDepth-depth,  buildHeight-z])
        offset = stackWidth
      end

      pos += offset + buildOpts[:offset]
    end

    @@move = true
    moveToSelection(buildDepth, buildHeight)
  end

end # module FVCC::Closets
