app = require('http').createServer(handler)
io = require('socket.io').listen(app)
uuid = require 'uuid'

app.listen(8000)

handler = (req, res) ->
  # pass

sockets = {}

class Session

  constructor:(@socket, @options) ->

    @uuid = uuid.v4()

    @socket.on 'url', (url) =>
      @url = url
      if @url not of sockets
        sockets[@url] = {}
      sockets[@url][@uuid] = @
    
    @socket.on 'select', (selection) =>
      if @url not of sockets
        return
      for _, session of sockets[@url]
        session.socket.emit 'select', selection

    @socket.on 'note.create', (selection) =>
      if @url not of sockets
        return
      id = uuid.v4()
      for _, session of sockets[@url]
        session.socket.emit 'note.create', selection, id

    @socket.on 'note.lock', (id) =>
      if @url not of sockets
        return
      for _, session of sockets[@url]
        if session.socket != @socket
          session.socket.emit 'note.lock', id

    @socket.on 'note.edit', (text, id) =>
      if @url not of sockets
        return
      for _, session of sockets[@url]
        if session.socket != @socket
          session.socket.emit 'note.edit', text, id

    @socket.on 'disconnect', (msg) =>
      if @url of sockets and @uuid of sockets[@url]
        delete sockets[@url][@uuid]


io.sockets.on 'connection', (socket) ->
  options = {}
  session = new Session socket, options

