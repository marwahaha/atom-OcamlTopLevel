OcamltopView = require './ocamltop-view'
url = require 'url'

module.exports =
  ocamltopView: null

  getCursors : (editor) ->
    cursors = editor.getCursors()
    posArray = []
    for cursor in cursors
      bufferPosition = cursor.getBufferPosition()
      posArray.push [
        bufferPosition.row
        bufferPosition.column
      ]
    posArray

  setCursors : (editor, posArray) ->
  # console.log "setCursors: #{posArray}"
    for bufferPosition, i in posArray
      if i is 0
        editor.setCursorBufferPosition bufferPosition
        continue
      editor.addCursorAtBufferPosition bufferPosition
    return

  activate: (state) ->
    atom.workspaceView.command "ocamltop:toplevel", => @toplevel()

  getUserHome: ->
    process.env.HOME or process.env.HOMEPATH or process.env.USERPROFILE

  toplevel: ->

    { spawn } = require 'child_process'
    {EventEmitter} = require 'events'
    fs = require 'fs'
    #emitter = require 'emitter'
    #emitter.setMaxListeners 100
    #ls = spawn '/Users/ByTeK/.atom/packages/ocamltop/node_modules/Ocaml_Interpreteur.sh'
    #ls.stdout.on 'data', ( data ) -> console.log "Output: #{ data }"
    #ls.stderr.on 'data', ( data ) -> console.error "Error: #{ data }"
    #ls.on 'close', -> console.log "'ls' has finished executing."

    home = @getUserHome()
    editor = atom.workspace.getActivePaneItem()

    #editor.onDidDestroy(()->console.log "test")

    file = editor?.buffer.file
    filePath = file?.path
    #directoryPath = atom.project.getPath()
    f = file.getPath()
    file_name = "#{ file.getBaseName() }"#.replace /.ml/, ""

    uri = "#{ home }/.atom/packages/ocamltop/temp/#{ file_name }"

    foo = -> fs.readFileSync filePath, 'utf8'
    string = foo().toString()
    # tempStream = fs.createWriteStream(uri,\
    #    {flags: 'w'});
    #console.log "#{ uri }"

    ocaml = spawn "#{ home }/.atom/packages/ocamltop/node_modules/Ocaml_Interpreteur.sh",["#{ f }","#{ uri }"]
    ocaml.once 'close', -> console.log "'ocaml' has finished executing."
    ocaml.exit

    clean = ->
      rm = spawn 'rm',["-f","#{ uri }"]
      rm.once 'close', -> console.log "'rm' has finished executing."
      rm.exit
    editor.onDidDestroy(clean)

    userPanel = atom.workspace.getActivePane()
    previewPane = atom.workspace.paneForUri(uri)
    if previewPane
      previewPane.activateItemForUri(uri) 
      userPanel.activate()
      return

    userPanelHandle = ->
        userPanel.activate()
    atom.workspace.onDidOpen(userPanelHandle)


    atom.workspace.open(uri, split: 'right', searchAllPanes: true, activatePane: true).done
    #newPane = atom.workspace.getActivePane()
    #interpreterPane.activateItemForUri(uri)
    #activePane.activate()

  deactivate: ->

    @ocamltopView.destroy()

  serialize: ->
    ocamltopViewState: @ocamltopView.serialize()
