# frozen_string_literal: true

require 'sketchup.rb'
require 'su_closets/helpers.rb'
require 'su_closets/export.rb'
require 'su_closets/dialog.rb'
require 'su_closets/settings.rb'
require 'su_closets/prompts.rb'
require 'pp'

module Closets
  def self.testfunction
    startOperation('Test Function')

    setSelection
    p @@selection.is_surface?
    @@selection.each do |entity|
      p entity
      entity.vertices.each do |v|
        p v.position
      end
    end

    addShelf(24.inch, 5, [0, 0, 0])
    compGrp = @currentGroup.to_component.definition
    @@model.place_component(compGrp)
    return
    cleat = [
      Geom::Point3d.new(0.273659, 0, 5.20606),
      Geom::Point3d.new(0.271968, 0, 5.21491),
      Geom::Point3d.new(0.269339, 0, 5.22868),
      Geom::Point3d.new(0.271473, 0, 5.2516),
      Geom::Point3d.new(0.279894, 0, 5.27304),
      Geom::Point3d.new(0.293938, 0, 5.29129),
      Geom::Point3d.new(0.3125, 0, 5.30492),
      Geom::Point3d.new(0.214958, 0, 5.5),
      Geom::Point3d.new(0, 0, 5.5),
      Geom::Point3d.new(0, 0, 0),
      Geom::Point3d.new(0.625, 0, 0),
      Geom::Point3d.new(0.625, 0, 4.5),
      Geom::Point3d.new(0.583861, 0, 4.5+(1/16)),
      Geom::Point3d.new(0.595299, 0, 4.62925),
      Geom::Point3d.new(0.616627, 0, 4.66147),
      Geom::Point3d.new(0.625, 0, 4.68928),
      Geom::Point3d.new(0.627763, 0, 4.69846),
      Geom::Point3d.new(0.627763, 0, 4.73709),
      Geom::Point3d.new(0.625, 0, 4.74627),
      Geom::Point3d.new(0.616627, 0, 4.77408),
      Geom::Point3d.new(0.595299, 0, 4.8063),
      Geom::Point3d.new(0.565592, 0, 4.83099),
      Geom::Point3d.new(0.284093, 0, 5.18553)
      ]
      group = addFace(cleat, 50)
      p group
    endOperation
  end

  def self.buildCabinet(params)
    @@move = false
    depth = params['depth'].to_l
    height = params['height'].to_l
    doors = params['doors'].to_i
    drawers = params['drawers'].to_i
    thickness = params['thickness'].to_l
    width = params['width'].to_l - (thickness*2)

    addGable(depth, height, [0, 0, 0], params)
    addShelf(width, 5, [thickness, depth - 5, height])
    addShelf(width, 5, [thickness, 0, height])
    addShelf(width, depth, [thickness, 0, thickness])

    reveal = 1.mm
    drawerWidth = width + ((thickness - reveal) * 2)
    drawerHeightTotal = 0
    drawers.times do |n|
      locZ = (n + 1) * 6
      drawerHeightTotal += 6
      addDrawer(drawerWidth, 6, [reveal, 0, height - locZ])
    end

    doorWidth = (width + ((thickness - reveal) * 2)) / doors
    doors.times do |n|
      loc = reveal + (n * doorWidth)
      addDoor(doorWidth, height - drawerHeightTotal, [loc, 0, 0], (HANDLE_TOP_RIGHT+n))
    end
    addGable(depth, height, [(0 + width + thickness), 0, 0], params)

    @@move = true
    moveToSelection(depth, height)
  end

  def self.buildBlindCabinet(params)
    @@move = false
    depth = params['depth'].to_l
    height = params['height'].to_l
    doors = params['doors'].to_i
    drawers = params['drawers'].to_i
    thickness = params['thickness'].to_l
    width = params['width'].to_l - (thickness*2)

    addGable(depth, height, [0, 0, 0], params)

    addDoor(depth, height, [0, 0, 0])

    addShelf(width, 5, [thickness, depth - 5, height])
    addShelf(width, 5, [thickness, 0, height])
    addShelf(width, depth, [thickness, 0, thickness])

    drawerHeightTotal = 0
    drawers.times do |n|
      locZ = (n + 1) * 6
      drawerHeightTotal += 6
      locX = depth
      addDrawer(width, 6, [locX, 0, height - locZ])
    end

    doorWidth = width / doors
    doors.times do |n|
      loc = thickness + (n * doorWidth)
      addDoor(doorWidth, height - drawerHeightTotal, [loc, 0, 0])
    end
    addGable(depth, height, [(0 + width + thickness), 0, 0], params)

    @@move = true
    moveToSelection(depth, height)
  end

  def self.buildWalls(name, width, depthL, depthR, returnL, returnR, closetHeight, wallHeight)
    offset = 4.inch
    depthDiff = depthR > 0 ? depthL - depthR : depthL - 1.mm

    leftWall = [
      Geom::Point3d.new(returnL, 0, 0),
      Geom::Point3d.new(returnL, -offset, 0),
      Geom::Point3d.new(-offset, -offset, 0)
    ]
    leftWall.unshift(Geom::Point3d.new(0, 0, 0)) unless returnL == 0

    rightWall = [
      Geom::Point3d.new(width, depthDiff, 0),
      Geom::Point3d.new(width + offset, depthDiff - offset, 0),
      Geom::Point3d.new(width - returnR, depthDiff - offset, 0)
    ]
    unless returnR == 0
      rightWall.unshift(Geom::Point3d.new(width - returnR, depthDiff, 0))
    end

    closet = [
      Geom::Point3d.new(0, depthL, 0),
      Geom::Point3d.new(width, depthL, 0),
      Geom::Point3d.new(width, depthDiff, 0),
      Geom::Point3d.new(width + offset, depthDiff - offset, 0),
      Geom::Point3d.new(width + offset, depthL + offset, 0),
      Geom::Point3d.new(-offset, depthL + offset, 0),
      Geom::Point3d.new(-offset, -offset, 0)
    ]
    closet.unshift(Geom::Point3d.new(0, 0, 0)) unless depthL == 0

    closetHeightLine1 = [
      Geom::Point3d.new(0, 0, closetHeight),
      Geom::Point3d.new(0, depthL, closetHeight)
    ]
    closetHeightLine2 = [
      Geom::Point3d.new(0, depthL, closetHeight),
      Geom::Point3d.new(width, depthL, closetHeight)
    ]
    closetHeightLine3 = [
      Geom::Point3d.new(width, depthL, closetHeight),
      Geom::Point3d.new(width, depthDiff, closetHeight)
    ]
    @@currentEnt.add_line(closetHeightLine1[0], closetHeightLine1[1])
    @@currentEnt.add_line(closetHeightLine2[0], closetHeightLine2[1])
    @@currentEnt.add_line(closetHeightLine3[0], closetHeightLine3[1])

    leftReturn = addFace(leftWall) if depthL > 0 && returnL > 0
    rightReturn = addFace(rightWall) if depthR > 0 && returnR > 0
    closetFace = addFace(closet, -wallHeight)

    # Add dimension lines
    addDimension(closet[0], closet[1], [0, 0, wallHeight + 5]) if depthL > 0
    addDimension(closet[1], closet[2], [0, 0, wallHeight + 5])
    addDimension(closet[2], closet[3], [0, 0, wallHeight + 5]) if depthR > 0

    # Add title
    unless name == ''
      addTitle(name, Geom::Point3d.new(width / 2 - name.length * 2, depthL, wallHeight - 8.inch))
    end
  end

  def self.buildShelfStack(closet, floor)
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
    if floor && (height > @@floorHeight)
      addShelf(width, depth, [posX, posY, height])
      height = @@floorHeight
    end

    drawerHeight = @@opts['thickness'] / 2
    drawerZ = floor ? @@opts['cleat'] : 0
    drawers.times do |n|
      if n == 0
        addShelf(width, depth, [posX, posY, posZ + @@opts['thickness'] + drawerZ])
      end

      profile = closet['drawerHeight'][n].to_f.inch
      addDrawer(width + @@opts['thickness'], profile, [posX - @@opts['thickness'] / 2, posY, posZ + drawerHeight + drawerZ])
      drawerHeight += profile
    end

    if floor
      spacing = (height - @@opts['cleat'] - @@opts['thickness'] - drawerHeight + (@@opts['thickness'] / 2)) / (shelves - 1)
    else
      spacing = (height - @@opts['thickness'] - drawerHeight + (@@opts['thickness'] / 2)) / (shelves - 1)
    end

    # Create shelves
    shelfHeight = height

    shelves.times do |n|
      addShelf(width, depth, [posX, posY, posZ + shelfHeight], n == 0)
      shelfHeight -= spacing
    end

    if closet['doors']
      doorWidth = (width + @@opts['thickness']) / 2
      doorHeight = gableH - drawerHeight - drawerZ - (@@opts['thickness'] / 2)
      firstDoorX = posX - @@opts['thickness'] / 2
      addDoor(doorWidth, doorHeight, [firstDoorX, posY, posZ + drawerHeight + drawerZ])
      addDoor(doorWidth, doorHeight, [firstDoorX + doorWidth, posY, posZ + drawerHeight + drawerZ])
    end

    return if width == 0

    if floor
      # addCleat(width, [posX, posY + depth, posZ + topHeight - @@opts['thickness'] - @@opts['cleat']])
      # addCleat(width, [posX, posY + depth - 1, posZ])
      # addCleat(width, [posX, posY + 2, posZ])
    else
      addCleat(width, [posX, posY + depth, posZ + @@opts['thickness']])
    end
  end

  def self.buildFloorLHShelves(closet)
    width   = closet['width']
    depth   = closet['depth']
    height  = closet['height']

    posX = closet['location'][0]
    posY = closet['location'][1]

    topHeight = height
    if height > @@floorHeight
      addShelf(width, depth, [posX, posY, height])
      height = @@floorHeight
    end

    spacing = @@floorSpacing
    addShelf(width, depth, [posX, posY, height], true)
    addShelf(width, depth, [posX, posY, height - spacing])
    addShelf(width, depth, [posX, posY, height - spacing * 2])
    addShelf(width, depth, [posX, posY, @@opts['cleat'] + @@opts['thickness']])

    backPosY = depth + posY
    addCleat(width, [posX, backPosY, topHeight - @@opts['thickness'] - @@opts['cleat']])
    addCleat(width, [posX, backPosY - 1, 0])
    addCleat(width, [posX, posY + 2, 0])

    addRod(width, [posX, posY + 2, height - spacing * 2])
  end

  def self.buildLHShelves(closet)
    width   = closet['width']
    depth   = closet['depth']
    height  = closet['height']

    posX = closet['location'][0]
    posY = closet['location'][1]
    posZ = closet['location'][2]

    # Shelves
    bottom = @@opts['cleat'] + @@opts['thickness']
    mid = (height + bottom) / 2
    addShelf(width, depth, [posX, posY, posZ + height], true)
    addShelf(width, depth, [posX, posY, posZ + mid])
    addShelf(width, depth, [posX, posY, posZ + bottom])

    addCleat(width, [posX, posY + depth, posZ])

    addRod(width, [posX, posY, posZ + bottom])
  end

  def self.buildFloorDHShelves(closet)
    width   = closet['width']
    depth   = closet['depth']
    height  = closet['height']

    posX = closet['location'][0]
    posY = closet['location'][1]
    posZ = closet['location'][2]

    topHeight = height
    if height > @@floorHeight
      addShelf(width, depth, [posX, posY, height])
      height = @@floorHeight
    end

    backPosY = depth + posY
    addShelf(width, depth, [posX, posY, height], true)
    addShelf(width, 196.mm, [posX, (backPosY - 196.mm), (height / 2)])
    addShelf(width, depth, [posX, posY, @@opts['cleat'] + @@opts['thickness']])

    addCleat(width, [posX, backPosY, topHeight - @@opts['thickness'] - @@opts['cleat']])
    addCleat(width, [posX, backPosY, (height / 2) - @@opts['thickness'] - @@opts['cleat']])
    addCleat(width, [posX, backPosY - 1, 0])
    addCleat(width, [posX, posY + 2, 0])

    addRod(width, [posX, posY + 2, height])
    addRod(width, [posX, posY + 2, (height / 2) + 2])
  end

  def self.buildDHShelves(closet)
    width   = closet['width']
    depth   = closet['depth']
    height  = closet['height']

    posX = closet['location'][0]
    posY = closet['location'][1]
    posZ = closet['location'][2]

    # Shelves
    bottom = @@opts['cleat'] + @@opts['thickness']
    shelfLocations = [
      [posX, posY, posZ + height],
      [posX, posY, posZ + bottom]
    ]
    addShelves(width, depth, shelfLocations)

    addCleat(width, [posX, posY + depth, posZ])

    addRod(width, [posX, posY, posZ + height])
    addRod(width, [posX, posY, posZ + bottom])
  end

  def self.buildFloorVHShelves(closet)
    width   = closet['width']
    depth   = closet['depth']
    height  = closet['height']

    posX = closet['location'][0]
    posY = closet['location'][1]
    posZ = closet['location'][2]

    shelves = closet['shelves']
    reverse = closet['reverse']

    topHeight = height
    if height > @@floorHeight
      addShelf(width, depth, [posX, posY, height])
      height = @@floorHeight
    end

    bottomShelf = @@opts['cleat'] + @@opts['thickness']
    addShelf(width, depth, [posX, posY, height], true)

    spacing = @@floorSpacing
    if reverse
      addRod(width, [posX, posY + 2, height])
      shelfHeight = bottomShelf
    else
      addRod(width, [posX, posY + 2, height - spacing * (shelves - 1)])
      spacing = -spacing
      shelfHeight = height
    end

    (shelves - 1).times do
      shelfHeight += spacing
      addShelf(width, depth, [posX, posY, shelfHeight])
    end

    addShelf(width, depth, [posX, posY, bottomShelf])

    backPosY = depth + posY
    addCleat(width, [posX, backPosY, topHeight - @@opts['thickness'] - @@opts['cleat']])
    addCleat(width, [posX, backPosY - 1, 0])
    addCleat(width, [posX, posY + 2, 0])
  end

  def self.buildVHShelves(closet)
    width   = closet['width']
    depth   = closet['depth']
    height  = closet['height']

    posX = closet['location'][0]
    posY = closet['location'][1]
    posZ = closet['location'][2]

    shelves = closet['shelves']

    # Shelves
    addShelf(width, depth, [posX, posY, posZ + height], true)
    bottom = @@opts['cleat'] + @@opts['thickness']
    addShelf(width, depth, [posX, posY, posZ + bottom]) if shelves > 1

    if shelves > 2
      spacing = (height - bottom) / (shelves - 1)
      shelfHeight = posZ + height - spacing
      (shelves - 2).times do
        addShelf(width, depth, [posX, posY, shelfHeight])
        shelfHeight -= spacing
      end
    end

    addCleat(width, [posX, posY + depth, posZ])

    rodZ = shelves > 1 ? posZ + bottom : posZ + height
    addRod(width, [posX, posY, rodZ])
  end

  def self.buildCornerShelves(closet)
    width   = closet['width']
    depth   = closet['depth']
    height  = closet['height']

    posX = closet['location'][0]
    posY = closet['location'][1]
    posZ = closet['location'][2]

    shelves = closet['shelves']

    # Shelves
    addShelf(width, depth, [posX, posY, posZ + height], true)
  end

  def self.buildFloorCornerShelves(closet)
    width   = closet['width']
    depth   = closet['depth']
    height  = closet['height']

    posX = closet['location'][0]
    posY = closet['location'][1]
    posZ = closet['location'][2]

    shelves = closet['shelves']

    # Shelves
    addShelf(width, depth, [posX, posY, posZ + height], true)
    addShelf(width, depth, [posX, posY, @@opts['cleat'] + @@opts['thickness']])
    addCleat(width, [posX, posY + 2, 0])
  end

  # From Dialog
  def self.verifyParams(closets, _params)
    errors = []
    closets.each_with_index do |closet, i|
      type = closet['type']

      noZeroes = %w[width depth height shelves]
      noZeroes.each do |attr|
        if closet[attr] == 0.to_s
          errors << attr.capitalize! + " cannot be zero for #{type} section."
        end
      end

      if type == 'Corner' && !([0, (closets.length - 1)].include? i)

        errors << 'Corner shelf must be on an end.'
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
    posX = params['gapLeft'].to_l
    hang = false

    # addCleat(params['width'].to_l-1.5, [@@opts['thickness'], 2-@@opts['thickness'], 0])
    closets.each do |closet|
      floor = closet['floor']
      hang = true unless floor
      width = closet['width']
      depth = closet['depth']
      height = closet['height']
      placement = closet['placement']

      closet['location'] = [posX, buildDepth - depth, buildHeight - height]

      if closet['type'] != 'Corner' && (%w[Left Center].include? placement)
        gable = addGable(depth, height, closet['location'], closet)
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
      when 'Shelves'
        buildShelfStack(closet, floor)
      end
      closet['location'][0] += width

      if closet['type'] != 'Corner' && (%w[Right Center].include? placement)
        addGable(depth, height, closet['location'], closet)
        closet['location'][0] += @@opts['thickness']
      end

      posX = closet['location'][0]
    end
    addWallRail(posX, [0, buildDepth - 5.mm, buildHeight - 3.inch]) if hang

    @@move = true
    moveToSelection(buildDepth, buildHeight)
    endOperation

    true
  end
end # module FVCC::Closets
