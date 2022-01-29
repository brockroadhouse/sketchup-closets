# frozen_string_literal: true

require 'json'

module Closets
    @currentDialog = nil
  ## Cabinet Dialog ##
  def self.createCabinetDialog
    htmlFile = File.join(__dir__, 'html', 'cabinet.html')

    options = {
      dialog_title: 'Create Cabinet',
      preferences_key: 'com.fvcc.closets',
      style: UI::HtmlDialog::STYLE_DIALOG
    }
    dialog = UI::HtmlDialog.new(options)
    dialog.set_file(htmlFile)
    dialog.set_size(520, 875)
    dialog.center
    @currentDialog = dialog
  end

  def self.showCabinetDialog
    @currentDialog = (@cabinet_dialog ||= createCabinetDialog)
    @cabinet_dialog.add_action_callback('ready') do |_action_context|
      updateCabinetDialog
      nil
    end
    @cabinet_dialog.add_action_callback('buildCabinet') do |_action_context, _params|
      success = buildCab(_params)
      @cabinet_dialog.execute_script("success(#{success})")
      nil
    end
    @cabinet_dialog.add_action_callback('buildBlind') do |_action_context, _params|
      success = buildBlind(_params)
      @cabinet_dialog.execute_script("success(#{success})")
      nil
    end
    @cabinet_dialog.add_action_callback('unbuildCabinet') do |_action_context|
      Sketchup.undo
      nil
    end
    @cabinet_dialog.add_action_callback('cancel') do |_action_context, _value|
      @cabinet_dialog.close
      nil
    end
    @cabinet_dialog.visible? ? @cabinet_dialog.bring_to_front : @cabinet_dialog.show
  end

  def self.updateCabinetDialog
    cabinet_hash = {
      type: '',
      width: defaultWidth.to_l,
      depth: 24,
      height: selectionHeight == 0 ? 32.inch : selectionHeight.to_l,
      thickness: @@opts['thickness'],
      drawers: 0,
      shelves: 0,
      doors: 0
    }

    cabinetJson = JSON.pretty_generate(cabinet_hash)
    @cabinet_dialog.execute_script("updateCabinet(#{cabinetJson})")
  end

  def self.buildCab(params)
    startOperation('Build Cabinet', true)
    begin
      buildCabinet(params)
    rescue StandardError => e
      puts 'error: ' + e.message
      abort
      return false
    end
    endOperation
    true
  end

  def self.buildBlind(params)
    startOperation('Build Blind Cabinet', true)
    begin
      buildBlindCabinet(params)
    rescue StandardError => e
      puts 'error: ' + e.message
      abort
      return false
    end
    endOperation
    true
  end

  ## Room Dialog ##
  def self.createRoomDialog
    htmlFile = File.join(__dir__, 'html', 'room.html')

    options = {
      dialog_title: 'Create Walls',
      preferences_key: 'com.fvcc.closets',
      style: UI::HtmlDialog::STYLE_DIALOG
    }
    dialog = UI::HtmlDialog.new(options)
    dialog.set_file(htmlFile)
    dialog.set_size(520, 875)
    dialog.center
    @currentDialog = dialog
  end

  def self.showRoomDialog
    @@nameCount += 1
    @currentDialog = (@room_dialog ||= createRoomDialog)
    @room_dialog.add_action_callback('ready') do |_action_context|
      updateRoomDialog
      nil
    end
    @room_dialog.add_action_callback('buildRoom') do |_action_context, room|
      @room_dialog.close if buildRoom(room)
      nil
    end
    @room_dialog.add_action_callback('cancel') do |_action_context, _value|
      @room_dialog.close
      nil
    end
    @room_dialog.visible? ? @room_dialog.bring_to_front : @room_dialog.show
  end

  def self.updateRoomDialog
    closetHash = {
      name: 'Closet ' + @@nameCount.to_s,
      width: 50,
      total: true,
      height: 84,
      depthLeft: 24,
      trimL: false,
      depthRight: 24,
      trimR: false,
      returnL: 6,
      trimReturnL: false,
      returnR: 6,
      trimReturnR: false,
      wallHeight: 96
    }

    closetJson = JSON.pretty_generate(closetHash)
    @room_dialog.execute_script("updateCloset(#{closetJson})")
  end

  def self.buildRoom(closet)
    startOperation('Build Walls', true, closet['name'])
    begin
      buildWalls(
        closet['name'],
        closet['total'] ? closet['width'].to_l - 0.5.inch : closet['width'].to_l,
        closet['trimL'] ? closet['depthLeft'].to_l - 0.5.inch : closet['depthLeft'].to_l,
        closet['trimR'] ? closet['depthRight'].to_l - 0.5.inch : closet['depthRight'].to_l,
        closet['trimReturnL'] ? closet['returnL'].to_l - 0.5.inch : closet['returnL'].to_l,
        closet['trimReturnR'] ? closet['returnR'].to_l - 0.5.inch : closet['returnR'].to_l,
        closet['height'].to_l,
        closet['wallHeight'].to_l
      )
    rescue StandardError => e
      puts 'error: ' + e.message
      abort
      return false
    end
    endOperation
  end

  ## Build Dialog ##
  def self.create_dialog
    htmlFile = File.join(__dir__, 'html', 'dialog.html')

    options = {
      dialog_title: 'Build Closet',
      preferences_key: 'com.fvcc.closets',
      style: UI::HtmlDialog::STYLE_DIALOG
    }
    dialog = UI::HtmlDialog.new(options)
    dialog.set_file(htmlFile)
    dialog.set_size(800, 800)
    dialog.set_on_closed { onClose }
    dialog.center
    dialog
  end

  def self.onClose
    @dialog = nil
  end

  def self.show_dialog
    @currentDialog = (@dialog ||= create_dialog)
    unless @dialog.visible?
      @dialog.add_action_callback('build') do |_action_context, closet, params|
        errors = verifyParams(closet, params)
        if errors.empty?
          begin
            success = build(closet, params)
          rescue StandardError => e
            message = displayError(e)
            dialogError([errors])
            success = false
          end
        else
          dialogError(errors)
          success = false
        end
        @dialog.execute_script("success(#{success})")
        nil
      end
      @dialog.add_action_callback('unbuild') do |_action_context, _closet, _params|
        Sketchup.undo
        nil
      end
      @dialog.add_action_callback('cancel') do |_action_context, _value|
        @dialog.close
      end
    end
    @dialog.add_action_callback('ready') do |_action_context|
      update_dialog
      nil
    end
    @dialog.visible? ? @dialog.bring_to_front : @dialog.show
  end

  def self.update_dialog
    setSelection

    closets = [
      {
        type: '',
        width: '',
        depth: '',
        drawers: '',
        shelves: '',
        height: '',
        reverse: false,
        doors: false,
        drawerHeight: [10],
        floor: false
      }
    ]
    closetParams = {
      width: defaultWidth.to_l,
      gapLeft: 0,
      gapRight: 0,
      height: selectionHeight == 0 ? 84.inch : selectionHeight.to_l,
      placement: 'Center'
    }
    types = {
      'LH' => { sections: 'three', floorSections: 'three', depth: 12, height: 24, shelves: 0 },
      'DH' => { sections: 'three', floorSections: 'three', depth: 12, height: 48, shelves: 0 },
      'VH' => { sections: 'five', floorSections: 'five', depth: 12, height: 12, shelves: 2 },
      'Shelves' => { sections: 'seven', floorSections: 'six', depth: '14 3/4', height: 76, shelves: 5 },
      'Corner' => { sections: 'three', floorSections: 'three', depth: 12 }
    }
    placements = [
      { value: 'Left', text: 'L' },
      { value: 'Center', text: 'C' },
      { value: 'Right', text: 'R' }
    ]

    closetsJson       = JSON.generate(closets)
    closetParamsJson  = JSON.generate(closetParams)
    typesJson         = JSON.generate(types)
    placementsJson    = JSON.generate(placements)
    @dialog.execute_script("updateCloset(#{closetsJson}, #{closetParamsJson}, #{typesJson}, #{placementsJson})")
  end

  def self.update_width(_selection)
    return unless selectionIsEdge && @currentDialog
    updateHash = {
      width: defaultWidth.to_l,
      height: selectionHeight
    }

    updateJson = JSON.generate(updateHash)
    @currentDialog.execute_script("updateParams(#{updateJson})")
  end

  def self.dialogError(message)
    return if message.empty?

    jsonError = JSON.generate(message)
    @dialog.execute_script("updateError(#{jsonError})")
  end

  def self.on_selection_change(selection)
    update_width(selection)
  end

  ## Selection Observers ##
  PLUGIN ||= self
  class SelectionChangeObserver < Sketchup::SelectionObserver
    def onSelectionBulkChange(selection)
      PLUGIN.on_selection_change(selection)
    end
  end

  class AppObserver < Sketchup::AppObserver
    def onNewModel(model)
      observe_model(model)
    end

    def onOpenModel(model)
      observe_model(model)
    end

    def expectsStartupModelNotifications
      true
    end

    private

    def observe_model(model)
      model.selection.add_observer(SelectionChangeObserver.new)
    end
  end

  Sketchup.add_observer(AppObserver.new) unless file_loaded?(__FILE__)
end
