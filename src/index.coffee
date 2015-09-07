fs              = require 'graceful-fs'
path            = require 'path.js'
isString        = require 'util-ex/lib/is/type/string'
isObject        = require 'util-ex/lib/is/type/object'
isFunction      = require 'util-ex/lib/is/type/function'
Task            = require 'task-registry'
ResourceTask    = require 'task-registry-resource'
register        = Task.register
aliases         = Task.aliases
defineProperties= Task.defineProperties

# copy a file to dest dir.
MISSING_OPTIONS = 'missing path or dest'

module.exports  = class CopyFileTask
  register CopyFileTask, ResourceTask #the real name: '/Resource/CopyFile'
  aliases CopyFileTask, 'Copy', 'copy', 'FileCopy'

  _executeSync: (aFile)->
    if aFile.path? and aFile.dest?
      if isFunction(aFile.getContentSync)
        contents = aFile.getContentSync(text:false)
      else
        contents = fs.readFileSync aFile.path
      vDest = aFile.dest
      vDest = path.resolve aFile.cwd, vDest if aFile.cwd
      try stat = fs.statSync vDest
      if stat
        if stat.isDirectory()
          vDest = path.join vDest, path.basename(aFile.path)
          stat = fs.existsSync vDest
        if stat and !aFile.overwrite
          throw new Error 'EEXIST'
      fs.writeFileSync vDest, contents
    else
      throw new TypeError MISSING_OPTIONS
    return

  _copyFilecallback = (aFile, done)->
    (err, contents)->
      return done err if err
      vDest = aFile.dest
      vDest = path.resolve aFile.cwd, vDest if aFile.cwd
      fs.stat vDest, (err, stat)->
        unless err
          if stat.isDirectory()
            vDest = path.join vDest, path.basename(aFile.path)
            stat = fs.existsSync vDest
          if stat and !aFile.overwrite
            return done new Error 'EEXIST'
        fs.writeFile vDest, contents, (err)->done(err)
      return

  _execute: (aFile, done)->
    if aFile.path? and aFile.dest?
      if isFunction(aFile.getContent)
        aFile.getContent text:false, _copyFilecallback(aFile, done)
      else
        fs.readFile aFile.path, _copyFilecallback(aFile, done)
    else
      done new TypeError MISSING_OPTIONS
