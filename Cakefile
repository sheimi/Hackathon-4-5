{exec} = require 'child_process'
{fork} = require 'child_process'
 
task 'clean', 'Clean the build env', ->
  clean()
 
task 'compile', 'Compiles coffee in src/ to js in bin/', ->
  compile()

task 'copyStatic', 'Copy static files', ->
  copyStatic()
 
task 'cc', 'Compile client coffee script', ->
  compileClient()
 
task 'run', 'Run app', ->
  clean -> compileClient -> compile -> copyStatic -> run()

execute = (cmds, callback) ->
  if not (cmds instanceof Array)
    cmds = [cmds]
  if cmds.length is 0
    callback?()
    return
  cmd = cmds.shift()
  exec cmd, (err, stdout, stderr) ->
    throw err if err
    console.log cmd + " executed"
    execute cmds, callback

clean = (callback) ->
  execute 'rm -rf site', callback

compileClient = (callback) ->
  cmds = [
    "coffee -o src-client/webnote -c src-client/coffee"
    "lessc --compress src-client/less/webnote.less > src-client/webnote/css/webnote.css"
  ]
  execute cmds, callback

compile = (callback) ->
  execute 'coffee -o site/ -c src/', callback

copyStatic = (callback) ->
  cmds = [
    "ln -s #{__dirname}/node_modules site/node_modules"
  ]
  execute cmds, callback

run = (callback) ->
  fork 'site/app.js'
