require "sketchup.rb"
require "su_closets/prompts.rb"
require "su_closets/helpers.rb"
require "su_closets/export.rb"
require "su_closets/dialog.rb"

module Closets

  @@thickness = 0.75.inch
  @@defaultW  = 610.mm
  @@cleat     = 5.inch
  @@move      = true
  @@drawer    = 10.inch
  @@hangDepth = 12.inch
  @@lhHeight  = 24.inch
  @@dhHeight  = 48.inch

  @@nameCount = 1

  @@currentEnt
  @@selection
  @currentGroup
  @@model

  def self.buildWalls (name, width, depthL, depthR, closetHeight, wallHeight)
    offset = 4.inch
    depthDiff = depthR > 0 ? depthL-depthR : depthL-1.mm
    wallReturn = 6

    leftWall = [
      Geom::Point3d.new(0, 0, 0),
      Geom::Point3d.new(wallReturn, 0, 0),
      Geom::Point3d.new(wallReturn, -offset, 0),
      Geom::Point3d.new(-offset, -offset, 0),
    ]

    rightWall = [
      Geom::Point3d.new(width-wallReturn, depthDiff, 0),
      Geom::Point3d.new(width, depthDiff, 0),
      Geom::Point3d.new(width+offset, depthDiff-offset, 0),
      Geom::Point3d.new(width-wallReturn, depthDiff-offset, 0),
    ]

    closet = [
      Geom::Point3d.new(0, depthL, 0),
      Geom::Point3d.new(width, depthL, 0),
      Geom::Point3d.new(width, depthDiff, 0),
      Geom::Point3d.new(width+offset, depthDiff-offset, 0),
      Geom::Point3d.new(width+offset, depthL+offset, 0),
      Geom::Point3d.new(-offset, depthL+offset, 0),
      Geom::Point3d.new(-offset, -offset, 0),
    ]
    closet.unshift(Geom::Point3d.new(0, 0, 0)) unless depthL == 0

    closetHeightLine1 = [
      Geom::Point3d.new(0, 0, closetHeight),
      Geom::Point3d.new(0, depthL, closetHeight),
    ]
    closetHeightLine2 = [
      Geom::Point3d.new(0, depthL, closetHeight),
      Geom::Point3d.new(width, depthL, closetHeight),
    ]
    closetHeightLine3 = [
      Geom::Point3d.new(width, depthL, closetHeight),
      Geom::Point3d.new(width, depthDiff, closetHeight),
    ]
    @@currentEnt.add_line(closetHeightLine1[0], closetHeightLine1[1])
    @@currentEnt.add_line(closetHeightLine2[0], closetHeightLine2[1])
    @@currentEnt.add_line(closetHeightLine3[0], closetHeightLine3[1])

    leftFace = addFace(leftWall) if depthL > 0
    rightFace = addFace(rightWall) if depthR > 0
    closetFace = addFace(closet, -wallHeight)

    # Add dimension lines
    addDimension(closet[0], closet[1], [0, 0, 4])
    addDimension(closet[1], closet[2], [0, 0, closetHeight+2])
    addDimension(closet[2], closet[3], [0, 0, 4]) if depthR > 0

    # Add title
    addTitle(name, Geom::Point3d.new(width/2-name.length*2, depthL, wallHeight-8.inch)) unless name == ""

  end

  def self.buildShelfStack (type, width, depth, height, shelves, drawers, sections, floor, placement, location = [0,0,0])
    if (floor)
      spacing = (height-@@cleat-@@thickness-drawers*@@drawer)/(shelves - 1)
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
      drawerZ = floor ? @@cleat : 0
      drawers.times do |n|
        addShelf(width, depth, [posX, posY, posZ+@@thickness+drawerZ]) if n==0
        addDrawer(width+@@thickness, @@drawer, [posX-@@thickness/2, posY, posZ+drawerHeight+drawerZ])
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
      addShelf(shelfWidth, depth, [pos, 0, height], true)
      addRod(shelfWidth, [pos, 0, height])
      addCleat(shelfWidth, [pos, depth, 0])
      pos += shelfWidth
      addGable(depth, height, [pos, 0, 0])
    end

    moveToSelection(depth, height)
  end

  def self.buildFloorLH (type, width, depth, height, placement, location = [0,0,0])
    posX = location[0]
    posY = location[1]
    posZ = location[2]
    unless (["Right", "Shelves"].include? placement)
      addGable(depth, height, location)
      posX += @@thickness
    end

    shelfSpacing = 250.mm
    addShelf(width, depth, [posX, 0, height], true)
    addShelf(width, depth, [posX, 0, height-shelfSpacing])
    addShelf(width, depth, [posX, 0, height-shelfSpacing*2])
    addShelf(width, depth, [posX, 0, @@cleat+@@thickness])

    addCleat(width, [posX, depth, height-@@thickness-@@cleat])
    addCleat(width, [posX, depth-1, 0])
    addCleat(width, [posX, 2, 0])

    addRod(width, [posX, 2, height-shelfSpacing*2])

    addGable(depth, height, [width+posX, posY, posZ]) unless (["Left", "Shelves"].include? placement)
  end

  def self.buildLH (type, width, depth, placement, location = [0,0,0])
    if (placement == "Center")
      numGables = 0
    elsif (placement == "Shelves")
      numGables = 2
    else
      numGables = 1
    end

    if (type == "Total")
      sections = ((width-@@thickness)/(32 + @@thickness)).ceil
      width = (width - (sections+1-numGables)*@@thickness)/sections
    else
      sections = 1
    end
    height = @@lhHeight

    posX = location[0]
    posY = location[1]
    posZ = location[2]
    # Gables
    unless (["Right", "Shelves"].include? placement)
      addGable(depth, height, [posX, posY, posZ])
      posX += @@thickness
    end

    sections.times do |i|
      # Shelves
      bottom = @@cleat + @@thickness
      mid = (height+bottom)/2
      addShelf(width, depth, [posX, posY, posZ+height], true)
      addShelf(width, depth, [posX, posY, posZ+mid])
      addShelf(width, depth, [posX, posY, posZ+bottom])

      addCleat(width, [posX, posY+depth, posZ])

      addRod(width, [posX, posY, posZ+bottom])

      addGable(depth, height, [width+posX, posY, posZ]) unless (((i+1) == sections) && (["Left", "Shelves"].include? placement))
      posX += width + @@thickness
    end

    moveToSelection(depth, height)
  end

  def self.buildFloorDH (type, width, depth, height, placement, location = [0,0,0])
    posX = location[0]
    posY = location[1]
    posZ = location[2]
    unless (["Right", "Shelves"].include? placement)
      addGable(depth, height, location)
      posX += @@thickness
    end

    addShelf(width, depth, [posX, 0, height], true)
    addShelf(width, 196.mm, [posX, (depth-196.mm), (height/2)])
    addShelf(width, depth, [posX, 0, @@cleat+@@thickness])

    addCleat(width, [posX, depth, height-@@thickness-@@cleat])
    addCleat(width, [posX, depth, (height/2)-@@thickness-@@cleat])
    addCleat(width, [posX, depth-1, 0])
    addCleat(width, [posX, 2, 0])

    addRod(width, [posX, 2, height])
    addRod(width, [posX, 2, (height/2)+2])

    addGable(depth, height, [width+posX, posY, posZ]) unless (["Left", "Shelves"].include? placement)
  end

  def self.buildDH (type, width, depth, placement, location = [0,0,0])
    if (placement == "Center")
      numGables = 0
    elsif (placement == "Shelves")
      numGables = 2
    else
      numGables = 1
    end

    if (type == "Total")
      sections = ((width-@@thickness)/(32 + @@thickness)).ceil
      width = (width - (sections+1-numGables)*@@thickness)/sections
    else
      sections = 1
    end
    height = @@dhHeight

    posX = location[0]
    posY = location[1]
    posZ = location[2]
    # Gables
    unless (["Right", "Shelves"].include? placement)
      addGable(depth, height, [posX, posY, posZ])
      posX += @@thickness
    end

    sections.times do |i|
      # Shelves
      bottom = @@cleat + @@thickness
      addShelf(width, depth, [posX, posY, posZ+height], true)
      addShelf(width, depth, [posX, posY, posZ+bottom])

      addCleat(width, [posX, posY+depth, posZ])

      addRod(width, [posX, posY, posZ+height])
      addRod(width, [posX, posY, posZ+bottom])

      addGable(depth, height, [width+posX, posY, posZ]) unless (((i+1) == sections) && (["Left", "Shelves"].include? placement))
      posX += width + @@thickness
    end
    moveToSelection(depth, height)
  end

  def self.buildMixed(width, types, shelves, drawers, height, depth, stackWidth, floor)
    @@move        = false
    build         = Array.new
    buildHeight   = 0
    buildDepth    = floor ? depth : @@hangDepth
    totalStack    = 0
    hangSections  = 0
    height        = floor ? selectionHeight : height
    types.each do |type|
      unless (type == "-")
        case type
        when "LH"
          typeHeight = floor ? height : @@lhHeight
          hangSections += 1
        when "DH"
          typeHeight = floor ? height : @@dhHeight
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
        if (floor)
          buildFloorLH(widthType, hangWidth, y, height, placement, [pos, 0,  0])
        else
          buildLH(widthType, hangWidth, y, placement, [pos, 0,  buildHeight-z])
        end
        offset = hangWidth
      when "DH"
        y = buildDepth
        z = @@dhHeight
        placement = buildOpts[:placement]
        if (floor)
          buildFloorDH(widthType, hangWidth, y, height, placement, [pos, 0,  0])
        else
          buildDH(widthType, hangWidth, y, placement, [pos, 0,  buildHeight-z])
        end
        offset = hangWidth
      when "Shelves"
        y = depth
        z = height
        placement = buildOpts[:placement]
        buildShelfStack(widthType, stackWidth, depth, height, shelves, drawers, 1, floor, placement, [pos, buildDepth-depth,  buildHeight-z])
        offset = stackWidth
      end

      pos += offset + buildOpts[:offset]
    end

    @@move = true
    moveToSelection(buildDepth, buildHeight)
  end

end # module FVCC::Closets
