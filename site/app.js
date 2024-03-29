// Generated by CoffeeScript 1.6.3
(function() {
  var Session, app, handler, histories, io, sockets, uuid;

  app = require('http').createServer(handler);

  io = require('socket.io').listen(app);

  uuid = require('uuid');

  app.listen(8000);

  handler = function(req, res) {};

  sockets = {};

  histories = {};

  Session = (function() {
    function Session(socket, options) {
      var _this = this;
      this.socket = socket;
      this.options = options;
      this.uuid = uuid.v4();
      this.socket.on('url', function(url) {
        _this.url = url;
        if (!(_this.url in sockets)) {
          sockets[_this.url] = {};
          histories[_this.url] = [];
        }
        sockets[_this.url][_this.uuid] = _this;
        return _this.socket.emit('history', histories[_this.url]);
      });
      this.socket.on('select', function(selection, color) {
        var log, session, _, _ref, _results;
        if (!(_this.url in sockets)) {
          return;
        }
        log = {
          type: 'select',
          selection: selection,
          color: color
        };
        histories[_this.url].push(log);
        _ref = sockets[_this.url];
        _results = [];
        for (_ in _ref) {
          session = _ref[_];
          _results.push(session.socket.emit('select', selection, color));
        }
        return _results;
      });
      this.socket.on('note.create', function(selection, color) {
        var id, log, session, _, _ref, _results;
        if (!(_this.url in sockets)) {
          return;
        }
        id = uuid.v4();
        log = {
          type: 'note.create',
          selection: selection,
          color: color,
          id: id
        };
        histories[_this.url].push(log);
        _ref = sockets[_this.url];
        _results = [];
        for (_ in _ref) {
          session = _ref[_];
          _results.push(session.socket.emit('note.create', selection, color, id));
        }
        return _results;
      });
      this.socket.on('note.lock', function(id) {
        var session, _, _ref, _results;
        if (!(_this.url in sockets)) {
          return;
        }
        _ref = sockets[_this.url];
        _results = [];
        for (_ in _ref) {
          session = _ref[_];
          if (session.socket !== _this.socket) {
            _results.push(session.socket.emit('note.lock', id));
          } else {
            _results.push(void 0);
          }
        }
        return _results;
      });
      this.socket.on('note.edit', function(text, id) {
        var log, session, _, _ref, _results;
        if (!(_this.url in sockets)) {
          return;
        }
        log = {
          type: 'note.edit',
          text: text,
          id: id
        };
        histories[_this.url].push(log);
        _ref = sockets[_this.url];
        _results = [];
        for (_ in _ref) {
          session = _ref[_];
          if (session.socket !== _this.socket) {
            _results.push(session.socket.emit('note.edit', text, id));
          } else {
            _results.push(void 0);
          }
        }
        return _results;
      });
      this.socket.on('disconnect', function(msg) {
        if (_this.url in sockets && _this.uuid in sockets[_this.url]) {
          return delete sockets[_this.url][_this.uuid];
        }
      });
    }

    return Session;

  })();

  io.sockets.on('connection', function(socket) {
    var options, session;
    options = {};
    return session = new Session(socket, options);
  });

}).call(this);
