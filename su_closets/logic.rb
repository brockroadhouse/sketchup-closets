module Closets

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
    buildDepth  = 0
    total       = closets.length - 1

    closets.each_with_index do |closet, i|
      floor = closet['floor']
      case closet['type']
      when "LH"
        closet['shelves'] = closet['shelves'].empty? ? 2 : closet['shelves'].to_i
        depth  = closet['depth'].empty? ? (floor ? @@floorDepth : @@hangDepth) : closet['depth']
        height = floor ? floorHeight : (closet['height'].empty? ? @@lhHeight : closet['height'])
      when "DH"
        depth  = closet['depth'].empty? ? (floor ? @@floorDepth : @@hangDepth) : closet['depth']
        height = floor ? floorHeight : @@dhHeight
      when "Corner"
        closet['shelves'] = floor ? 2 : 1
        if (i == 0)
          closet['side'] = 'right'
        elsif  (i == total)
          closet['side'] = 'left'
        end
        depth  = closet['depth'].empty? ? (floor ? @@floorDepth : @@hangDepth) : closet['depth']
        height = floor ? floorHeight : (closet['height'].empty? ? @@lhHeight : closet['height']) - 1
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

  def self.setPlacements(sections, params)
    overall_placement = params['placement']
    if (sections.length == 1)
      sections[0]['placement'] = overall_placement
      sections[0]['offset']    = @@opts['thickness'] * 2
      return
    end

    sections.map.with_index do |closet, i|
      key = closet['floor'] ? 'depth' : 'height'
      floor = closet['floor']

      # Placements
      if (closet['type']=='Corner')
        placement = "Shelves"
      elsif (i == 0) # First
        is_trans = is_section_transitional(closet, sections[i + 1])
        if (overall_placement == "Right")
          placement = is_trans ? "Right" : "Shelves"
        else
          placement = is_trans ? "Center" : "Left"
        end
      elsif (i == sections.count-1) # Last
        is_trans = is_section_transitional(closet, sections[i - 1])
        if (overall_placement == "Left")
          placement = is_trans ? "Left" : "Shelves"
        else
          placement = is_trans ? "Center" : "Right"
        end
      else
        placement = set_section_placement(sections, i)
      end

      # Offsets
      offset = if placement == "Center"
                  @@opts['thickness'] * 2
                elsif placement == "Shelves"
                  0
                else
                  @@opts['thickness']
                end

      closet['placement'] = placement
      closet['offset']    = offset
    end
  end

  def self.is_section_transitional(section, other_section)
    # nextF = other_section['floor']

    # taller = (other_section['height'] >= section['height'])
    # deeper = (other_section['depth'] >= section['depth'])
    # return ((taller && !section['floor']) || (nextF && deeper))

    type = section['type']
    other_type = other_section['type']
    if type == 'Shelves' && !(section['floor'] && !other_section['floor'])
      true
    elsif section['floor'] && !other_section['floor']
      true
    elsif type == 'DH'
      ['LH', 'Corner'].include? other_type
    elsif type == 'LH'
      other_type == 'Corner'
    else
      false
    end
  end

  def self.set_section_placement(sections, i)
    prev_type = sections[i-1]['type']
    curr_type = sections[i]['type']
    next_type = sections[i+1]['type']

    trans_left = is_section_transitional(sections[i], sections[i-1])
    trans_right = is_section_transitional(sections[i], sections[i+1])

    if (curr_type == next_type) || (trans_left && !trans_right)
      placement = "Left"
    elsif (trans_left && trans_right)
      placement = "Center"
    elsif (!trans_left && trans_right)
      placement = "Right"
    else
      placement = "Shelves"
    end


    # closet = sections[i]
    # key     = closet['floor'] ? 'depth' : 'height'
    # floor   = closet['floor']

    # lastH = sections[i-1][key]
    # nextH = sections[i+1][key]
    # thisH = closet[key]
    # nextF = sections[i+1]['floor']

    # if    (lastH <= thisH && (thisH > nextH || sections[i+1]['type'] == 'Corner' || (floor && !nextF )))
    #   placement = "Center"
    # elsif (lastH <= thisH && thisH <= nextH)
    #   placement = "Left"
    # elsif ((lastH > thisH && thisH > nextH) || (floor && !nextF))
    #   placement = "Right"
    # elsif (lastH > thisH && thisH <= nextH)
    #   placement = "Shelves"
    # end


    
    placement
  end

  def self.setClosets(build, params)

    dividedWidth(build, params)
    setHeights(build, params)
    setPlacements(build, params)
    setCNCParams(build, params)

  end

  def self.setCNCParams(sections, params)
    sections.map.with_index do |closet, i|

      next if closet['type'] == 'Corner'
      
      placement = closet['placement']
      if (["Left", "Center"].include? placement)
        closet['leftGable'] = self.getGableType(sections, i, closet, 'left')
      end

      if (["Right", "Center"].include? placement)
        closet['rightGable'] = self.getGableType(sections, i, closet, 'right')
      end

    end
  end

  def self.getGableType(sections, i, current, side)
    loc       = current['floor'] ? 'FM' : 'WH' # Floor or Wall Hung
    type      = current['type']                # DH, LH, Shelves etc.
    finished  = current['finished']

    base = @@cncParts[type][loc]
    return unless base
    
    first = (side == 'left' && i.zero?)
    last  = (side == 'right' && i == sections.length-1)
    if first || last 
      # Left gable of first section or right gable of last section
      if finished
        part = base[side]['finished']
      else
        part = base['center']
      end
    else
      other = side == 'left' ? sections[i - 1] : sections[i + 1]
      otherType = other['type']
      if (otherType == type)
        part = base['center']
      else
        trans = 'to' + otherType # toDH/toLH
        part = setPartParams(base.fetch(side).fetch(trans, nil), other)
      end

    end
    part = setPartParams(part, current)
    part
  end

  def self.setPartParams(part, section)
    return part unless part && part.fetch('params', false)
    
	  part = part.dup
    params = part['params']

    replaceable = {
      'shelves' => 'int',
      'height' => 'height',
      'depth' => 'depth'
    }
    replaceable.each do |key, type|
      if section.has_key? key
        if type == 'height'
          value = postProcessHeight(section[key].to_mm.round)
        elsif type == 'depth'
          value = postProcessDepth(section[key].to_mm.round)
        elsif section[key].is_a? Length
          value = section[key].to_mm.round
        else
          value = section[key] 
        end
        part['params'] = part['params'].sub("{#{key.upcase}}", value.to_s)
      end  
    end

	part
  end
end