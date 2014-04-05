app = require('http').createServer(handler)
io = require('socket.io').listen(app)
uuid = require 'uuid'

app.listen(8000)

handler = (req, res) ->
  # pass

sockets = {}
histories = {}

class Session

  constructor:(@socket, @options) ->

    @uuid = uuid.v4()

    @socket.on 'url', (url) =>
      @url = url
      if @url not of sockets
        sockets[@url] = {}
        histories[@url] = []
      sockets[@url][@uuid] = @
      @socket.emit 'history', histories[@url]
    
    @socket.on 'select', (selection, color) =>
      if @url not of sockets
        return
      log =
        type: 'select'
        selection: selection
        color: color
      histories[@url].push log

      for _, session of sockets[@url]
        session.socket.emit 'select', selection, color

    @socket.on 'note.create', (selection, color) =>
      if @url not of sockets
        return
      id = uuid.v4()

      log =
        type: 'note.create'
        selection: selection
        color: color
        id: id
      histories[@url].push log

      for _, session of sockets[@url]
        session.socket.emit 'note.create', selection, color, id

    @socket.on 'note.lock', (id) =>
      if @url not of sockets
        return
      for _, session of sockets[@url]
        if session.socket != @socket
          session.socket.emit 'note.lock', id

    @socket.on 'note.edit', (text, id) =>
      if @url not of sockets
        return
      log =
        type: 'note.edit'
        text: text
        id: id
      histories[@url].push log

      for _, session of sockets[@url]
        if session.socket != @socket
          session.socket.emit 'note.edit', text, id

    @socket.on 'disconnect', (msg) =>
      if @url of sockets and @uuid of sockets[@url]
        delete sockets[@url][@uuid]


io.sockets.on 'connection', (socket) ->
  options = {}
  session = new Session socket, options

