require "sketchup.rb"
require "su_closets/helpers.rb"
require "su_closets/export.rb"
require "su_closets/dialog.rb"
require 'su_closets/settings.rb'
require "su_closets/prompts.rb"

module Closets

  def self.buildWalls (name, width, depthL, depthR, returnL, returnR, closetHeight, wallHeight)
    offset = 4.inch
    depthDiff = depthR > 0 ? depthL-depthR : depthL-1.mm

    leftWall = [
      Geom::Point3d.new(returnL, 0, 0),
      Geom::Point3d.new(returnL, -offset, 0),
      Geom::Point3d.new(-offset, -offset, 0),
    ]
    leftWall.unshift(Geom::Point3d.new(0, 0, 0)) unless returnL == 0

    rightWall = [
      Geom::Point3d.new(width, depthDiff, 0),
      Geom::Point3d.new(width+offset, depthDiff-offset, 0),
      Geom::Point3d.new(width-returnR, depthDiff-offset, 0),
    ]
    rightWall.unshift(Geom::Point3d.new(width-returnR, depthDiff, 0)) unless returnR == 0

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

    leftReturn = addFace(leftWall) if (depthL > 0 && returnL > 0)
    rightReturn = addFace(rightWall) if (depthR > 0 && returnR > 0)
    closetFace = addFace(closet, -wallHeight)

    # Add dimension lines
    addDimension(closet[0], closet[1], [0, 0, wallHeight+5]) if depthL > 0
    addDimension(closet[1], closet[2], [0, 0, wallHeight+5])
    addDimension(closet[2], closet[3], [0, 0, wallHeight+5]) if depthR > 0

    # Add title
    addTitle(name, Geom::Point3d.new(width/2-name.length*2, depthL, wallHeight-8.inch)) unless name == ""

  end

  def self.buildShelfStack (closet, floor)

    width   = closet['width']
    depth   = closet['depth']
    height  = closet['height']
    gableH  = closet['height']
    drawers = closet['drawers']
    shelves = closet['shelves']

    posX = closet['location'][0]
    posY = closet['location'][1]
    posZ = closet['location'][2]

    ### Gable Creation ###
    topHeight = height
    if (floor && (height > @@floorHeight))
      addShelf(width, depth, [posX, posY, height])
      height = @@floorHeight
    end

    drawerHeight = @@opts['thickness']/2
    drawerZ = floor ? @@opts['cleat'] : 0
    drawers.times do |n|
      addShelf(width, depth, [posX, posY, posZ+@@opts['thickness']+drawerZ]) if n==0

      profile = closet['drawerHeight'][n].to_f.inch
      addDrawer(width+@@opts['thickness'], profile, [posX-@@opts['thickness']/2, posY, posZ+drawerHeight+drawerZ])
      drawerHeight += profile
    end

    if (floor)
      spacing = (height-@@opts['cleat']-@@opts['thickness']-drawerHeight+(@@opts['thickness']/2))/(shelves - 1)
    else
      spacing = (height-@@opts['thickness']-drawerHeight+(@@opts['thickness']/2))/(shelves - 1)
    end

    # Create shelves
    shelfHeight = height

    shelves.times do |n|
      addShelf(width, depth, [posX, posY, posZ+shelfHeight], n==0)
      shelfHeight -= spacing
    end

    if (closet['doors'])
      doorWidth = (width+@@opts['thickness'])/2
      doorHeight = gableH-drawerHeight-drawerZ-(@@opts['thickness']/2)
      firstDoorX = posX-@@opts['thickness']/2
      addDoor(doorWidth, doorHeight, [firstDoorX, posY, posZ+drawerHeight+drawerZ])
      addDoor(doorWidth, doorHeight, [firstDoorX+doorWidth, posY, posZ+drawerHeight+drawerZ])
    end

    return if width == 0
    if (floor)
      addCleat(width, [posX, posY+depth, posZ+topHeight-@@opts['thickness']-@@opts['cleat']])
      addCleat(width, [posX, posY+depth-1, posZ])
      addCleat(width, [posX, posY+2, posZ])
    else
      addCleat(width, [posX, posY+depth, posZ+@@opts['thickness']])
    end
  end

  def self.buildFloorLHShelves (closet)

    width   = closet['width']
    depth   = closet['depth']
    height  = closet['height']

    posX = closet['location'][0]
    posY = closet['location'][1]

    topHeight = height
    if (height > @@floorHeight)
      addShelf(width, depth, [posX, posY, height])
      height = @@floorHeight
    end

    spacing = @@floorSpacing
    addShelf(width, depth, [posX, posY, height], true)
    addShelf(width, depth, [posX, posY, height-spacing])
    addShelf(width, depth, [posX, posY, height-spacing*2])
    addShelf(width, depth, [posX, posY, @@opts['cleat']+@@opts['thickness']])

    backPosY = depth + posY
    addCleat(width, [posX, backPosY, topHeight-@@opts['thickness']-@@opts['cleat']])
    addCleat(width, [posX, backPosY-1, 0])
    addCleat(width, [posX, posY+2, 0])

    addRod(width, [posX, posY+2, height-spacing*2])

  end

  def self.buildLHShelves (closet)
    width   = closet['width']
    depth   = closet['depth']
    height  = closet['height']

    posX = closet['location'][0]
    posY = closet['location'][1]
    posZ = closet['location'][2]

    # Shelves
    bottom = @@opts['cleat'] + @@opts['thickness']
    mid = (height+bottom)/2
    addShelf(width, depth, [posX, posY, posZ+height], true)
    addShelf(width, depth, [posX, posY, posZ+mid])
    addShelf(width, depth, [posX, posY, posZ+bottom])

    addCleat(width, [posX, posY+depth, posZ])

    addRod(width, [posX, posY, posZ+bottom])
  end

  def self.buildFloorDHShelves (closet)
    width   = closet['width']
    depth   = closet['depth']
    height  = closet['height']

    posX = closet['location'][0]
    posY = closet['location'][1]
    posZ = closet['location'][2]

    topHeight = height
    if (height > @@floorHeight)
      addShelf(width, depth, [posX, posY, height])
      height = @@floorHeight
    end

    backPosY = depth + posY
    addShelf(width, depth, [posX, posY, height], true)
    addShelf(width, 196.mm, [posX, (backPosY-196.mm), (height/2)])
    addShelf(width, depth, [posX, posY, @@opts['cleat']+@@opts['thickness']])

    addCleat(width, [posX, backPosY, topHeight-@@opts['thickness']-@@opts['cleat']])
    addCleat(width, [posX, backPosY, (height/2)-@@opts['thickness']-@@opts['cleat']])
    addCleat(width, [posX, backPosY-1, 0])
    addCleat(width, [posX, posY+2, 0])

    addRod(width, [posX, posY+2, height])
    addRod(width, [posX, posY+2, (height/2)+2])
  end

  def self.buildDHShelves (closet)
    width   = closet['width']
    depth   = closet['depth']
    height  = closet['height']

    posX = closet['location'][0]
    posY = closet['location'][1]
    posZ = closet['location'][2]

    # Shelves
    bottom = @@opts['cleat'] + @@opts['thickness']
    shelfLocations = [
      [posX, posY, posZ+height],
      [posX, posY, posZ+bottom]
    ]
    addShelves(width, depth, shelfLocations)

    addCleat(width, [posX, posY+depth, posZ])

    addRod(width, [posX, posY, posZ+height])
    addRod(width, [posX, posY, posZ+bottom])
  end

  def self.buildFloorVHShelves (closet)
    width   = closet['width']
    depth   = closet['depth']
    height  = closet['height']

    posX = closet['location'][0]
    posY = closet['location'][1]
    posZ = closet['location'][2]

    shelves = closet['shelves']
    reverse = closet['reverse']

    topHeight = height
    if (height > @@floorHeight)
      addShelf(width, depth, [posX, posY, height])
      height = @@floorHeight
    end

    bottomShelf = @@opts['cleat']+@@opts['thickness']
    addShelf(width, depth, [posX, posY, height], true)

    spacing = @@floorSpacing
    if (reverse)
      addRod(width, [posX, posY+2, height])
      shelfHeight = bottomShelf
    else
      addRod(width, [posX, posY+2, height - spacing*(shelves - 1)])
      spacing = -spacing
      shelfHeight = height
    end

    (shelves-1).times do
      shelfHeight += spacing
      addShelf(width, depth, [posX, posY, shelfHeight])
    end

    addShelf(width, depth, [posX, posY, bottomShelf])

    backPosY = depth + posY
    addCleat(width, [posX, backPosY, topHeight-@@opts['thickness']-@@opts['cleat']])
    addCleat(width, [posX, backPosY-1, 0])
    addCleat(width, [posX, posY+2, 0])

  end

  def self.buildVHShelves (closet)
    width   = closet['width']
    depth   = closet['depth']
    height  = closet['height']

    posX = closet['location'][0]
    posY = closet['location'][1]
    posZ = closet['location'][2]

    shelves = closet['shelves']

    # Shelves
    addShelf(width, depth, [posX, posY, posZ+height], true)
    bottom = @@opts['cleat'] + @@opts['thickness']
    addShelf(width, depth, [posX, posY, posZ+bottom]) if (shelves > 1)

    if (shelves > 2)
      spacing = (height - bottom)/(shelves - 1)
      shelfHeight = posZ + height - spacing
      (shelves-2).times do
        addShelf(width, depth, [posX, posY, shelfHeight])
        shelfHeight -= spacing
      end
    end

    addCleat(width, [posX, posY+depth, posZ])

    rodZ = shelves > 1 ? posZ+bottom : posZ+height
    addRod(width, [posX, posY, rodZ])
  end

  def self.buildCornerShelves (closet)
    width   = closet['width']
    depth   = closet['depth']
    height  = closet['height']

    posX = closet['location'][0]
    posY = closet['location'][1]
    posZ = closet['location'][2]

    shelves = closet['shelves']

    # Shelves
    addShelf(width, depth, [posX, posY, posZ+height], true)

  end

  def self.buildFloorCornerShelves (closet)
    width   = closet['width']
    depth   = closet['depth']
    height  = closet['height']

    posX = closet['location'][0]
    posY = closet['location'][1]
    posZ = closet['location'][2]

    shelves = closet['shelves']

    # Shelves
    addShelf(width, depth, [posX, posY, posZ+height], true)
    addShelf(width, depth, [posX, posY, @@opts['cleat']+@@opts['thickness']])
    addCleat(width, [posX, posY+2, 0])

  end

  # From Dialog
  def self.verifyParams(closets, params)
    errors = []
    closets.each_with_index do |closet, i|
      type = closet['type']

      noZeroes = ['width','depth','height','shelves']
      noZeroes.each do |attr|
        errors << attr.capitalize! + " cannot be zero for #{type} section."    if closet[attr] == 0.to_s
      end

      if (type == 'Corner' && !([0, (closets.length-1)].include? i))

        errors << "Corner shelf must be on an end."
      end
    end
    errors
  end

  def self.build(closets, params)
    startOperation('Build Closet')
    @@move = false

    setClosets(closets, params)
    buildHeight = params['buildHeight']
    buildDepth = params['buildDepth']
    posX = 0

    closets.each do |closet|
      floor = closet['floor']
      width = closet['width']
      depth = closet['depth']
      height = closet['height']
      placement = closet['placement']

      closet['location'] = [posX, buildDepth-depth, buildHeight-height]

      if (closet['type'] != 'Corner' && (["Left", "Center"].include? placement))
        addGable(depth, height, closet['location'])
        closet['location'][0] += @@opts['thickness']
      end

      case closet['type']
      when 'LH'
        floor ? buildFloorLHShelves(closet) : buildLHShelves(closet)
      when 'DH'
        floor ? buildFloorDHShelves(closet) : buildDHShelves(closet)
      when 'VH'
        floor ? buildFloorVHShelves(closet) : buildVHShelves(closet)
      when 'Corner'
        floor ? buildFloorCornerShelves(closet) : buildCornerShelves(closet)
      when "Shelves"
        buildShelfStack(closet, floor)
      end
      closet['location'][0] += width

      if (closet['type'] != 'Corner' && (["Right", "Center"].include? placement))
        addGable(depth, height, closet['location'])
        closet['location'][0] += @@opts['thickness']
      end
      addWallRail(width, [0, buildDepth-5.mm, buildHeight-3.inch]) unless floor

      posX = closet['location'][0]
    end


    @@move = true
    moveToSelection(buildDepth, buildHeight)
    endOperation

    true
  end

end # module FVCC::Closets
