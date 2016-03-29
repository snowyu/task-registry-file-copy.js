fs              = require 'graceful-fs'
path            = require 'path.js'
mkdir           = require 'mkdirp'
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

  defineProperties @,
    path:
      type: 'String'
    dest:
      type: 'String'
    overwrite:
      type: 'Boolean'
    ignoreEmptyFile:
      type: 'Boolean'

  _copyFile: (aFile, contents, aOptions)->
    aOptions = aFile unless aOptions
    vDest = aFile.dest
    vDest = path.resolve aFile.cwd, vDest if aFile.cwd
    vFileBaseName = path.basename aFile.path

    if isFunction(aFile.isDirectory) and aFile.isDirectory()
      contents = aFile.summary
      mkdir.sync path.join vDest, vFileBaseName
      if aFile.$cfgPath
        vFileBaseName = path.join vFileBaseName, path.basename(aFile.$cfgPath)
      else
        @logger.info 'No folder Config file to copy:', aFile if @logger
        return #unless contents
    try stat = fs.statSync vDest
    if stat
      if stat.isDirectory()
        vDest = path.join vDest, vFileBaseName
        stat = fs.existsSync vDest
      if stat and !aOptions.overwrite
        throw new Error 'EEXIST'
    unless aOptions.ignoreEmptyFile and (!contents or contents.length <= 0)
      fs.writeFileSync vDest, contents
    else
      @logger.info 'ignore copy empty file:', vDest if @logger
    return

  _executeSync: (aFile)->
    if aFile.path? and aFile.dest?
      if isFunction(aFile.getContentSync)
        if !aFile.hasOwnProperty('_contents') && aFile.parent && !aFile.parent.isDirectory()
          # the inherited file resource object use the parent's contents
          # if parent is a file(not folder) and no contents on itself.
          vFile = aFile.parent
        else
          vFile = aFile
        contents = vFile.getContentSync(text:false)
        @_copyFile vFile, contents, aFile
      else
        contents = fs.readFileSync aFile.path
        @_copyFile aFile, contents

    else
      throw new TypeError MISSING_OPTIONS
    return

  _copyFilecallback = (aFile, done)->
    (err, contents)->
      return done err if err
      vDest = aFile.dest
      vDest = path.resolve aFile.cwd, vDest if aFile.cwd
      vFileBaseName = path.basename aFile.path

      if isFunction(aFile.isDirectory) and aFile.isDirectory()
        contents = aFile.summary
        mkdir.sync path.join vDest, vFileBaseName
        if aFile.$cfgPath
          vFileBaseName = path.join vFileBaseName, path.basename(aFile.$cfgPath)
        else
          @logger.info 'No folder Config file to copy:', aFile if @logger
          done()
          return #unless contents
      fs.stat vDest, (err, stat)->
        unless err
          if stat.isDirectory()
            vDest = path.join vDest, vFileBaseName
            stat = fs.existsSync vDest
          if stat and !aFile.overwrite
            return done new Error 'EEXIST'
        unless aFile.ignoreEmptyFile and (!contents or contents.length <= 0)
          fs.writeFile vDest, contents, (err)->done(err)
        else
          @logger.info 'ignore copy empty file:', vDest if @logger
          done()
      return

  _execute: (aFile, done)->
    if aFile.path? and aFile.dest?
      if isFunction(aFile.getContent)
        if !aFile.hasOwnProperty('_contents') && aFile.parent && !aFile.parent.isDirectory()
          vFile = aFile.parent
        else
          vFile = aFile
        vFile.getContent text:false, _copyFilecallback(aFile, done)
      else
        fs.readFile aFile.path, _copyFilecallback(aFile, done)
    else
      done new TypeError MISSING_OPTIONS
