chai            = require 'chai'
sinon           = require 'sinon'
sinonChai       = require 'sinon-chai'
should          = chai.should()
expect          = chai.expect
assert          = chai.assert
chai.use(sinonChai)

setImmediate    = setImmediate || process.nextTick

Task            = require 'task-registry'
Resource        = require 'resource-file'
fs              = require 'graceful-fs'
path            = require 'path.js'
FileCopyTask    = require '../src'

fs.cwd  = process.cwd
fs.path = path
Resource.setFileSystem fs

describe 'FileCopyTask', ->
  task = Task 'Copy'
  file = Resource './fixture/src.md', cwd:__dirname, dest: 'fixture/dest.md', load:true, read:true

  afterEach ->
    try fs.unlinkSync path.join __dirname, 'fixture/dest.md'

  checkDestFile = (aSrc, aDest = 'fixture/dest.md')->
    aDest = path.resolve __dirname, aDest
    result = fs.existsSync aDest
    expect(result).to.be.true
    result = fs.readFileSync aDest, encoding:'utf8'
    expect(result).to.be.equal aSrc.contents.toString()

  it 'should get file copy task', ->
    expect(task).to.be.instanceOf FileCopyTask
    result = Task 'copy'
    expect(result).to.be.instanceOf FileCopyTask
    result = Task '/Resource/CopyFile'
    expect(result).to.be.instanceOf FileCopyTask

  describe 'executeSync', ->
    it 'should raise error if no path or dest', ->
      expect(task.executeSync.bind(task, {})).to.throw 'missing'

    it 'should copy a file object', ->
      task.executeSync(file)
      checkDestFile file

    it 'should copy a file path', ->
      task.executeSync
        path: path.join __dirname, 'fixture/src.md'
        dest: 'fixture/dest2.md'
        cwd: __dirname
      checkDestFile file, 'fixture/dest2.md'
      fs.unlinkSync path.join __dirname, 'fixture/dest2.md'

    it 'should not copy a file object if dest is exists', ->
      task.executeSync(file)
      checkDestFile file
      expect(task.executeSync.bind(task, file)).to.throw 'EEXIST'

    it 'should copy a file object if dest is exists and overwrite is true', ->
      task.executeSync(file)
      checkDestFile file
      file.overwrite = true
      expect(task.executeSync.bind(task, file)).to.not.throw 'EEXIST'
      delete file.overwrite

    it 'should copy a file object to another directory', ->
      vFile = Resource './fixture/src.md', cwd:__dirname, dest: '.'
      task.executeSync(vFile)
      checkDestFile vFile, './src.md'
      fs.unlinkSync path.join __dirname, 'src.md'

    it 'should copy a inherited file object', ->
      vFile = {}
      vFile.__proto__ = file
      task.executeSync(vFile)
      checkDestFile file
    it 'should copy a inherited file object if dest is exists and overwrite is true', ->
      task.executeSync(file)
      checkDestFile file
      file.overwrite = true
      vFile = {overwrite:false}
      vFile.__proto__ = file
      expect(task.executeSync.bind(task, vFile)).to.throw 'EEXIST'
      delete file.overwrite
    it 'should copy a inherited file object with custom contents', ->
      contents = fs.readFileSync path.join __dirname, './fixture/src2.md'
      vFile = {_contents: contents}
      vFile.__proto__ = file
      task.executeSync(vFile)
      checkDestFile vFile, './fixture/src2.md'

  describe 'execute', ->
    it 'should raise error if no path or dest', (done)->
      task.execute {}, (err)->
        expect(err).to.be.instanceOf TypeError
        done()

    it 'should copy a file object', (done)->
      task.execute file, (err)->
        checkDestFile file unless err
        done(err)

    it 'should copy a file path', (done)->
      task.execute
        path: path.join __dirname, 'fixture/src.md'
        dest: 'fixture/dest2.md'
        cwd: __dirname
      , (err)->
        unless err
          checkDestFile file, 'fixture/dest2.md'
          fs.unlinkSync path.join __dirname, 'fixture/dest2.md'
        done(err)

    it 'should not copy a file object if dest is exists', (done)->
      task.execute file, (err)->
        return done(err) if err
        checkDestFile file
        task.execute file, (err)->
          expect(err).to.be.instanceOf Error
          expect(err.message).to.be.equal 'EEXIST'
          done()

    it 'should copy a file object if dest is exists and overwrite is true', (done)->
      task.execute file, (err)->
        return done(err) if err
        checkDestFile file
        file.overwrite = true
        task.execute file, (err)->
          expect(err).to.not.exist
          delete file.overwrite
          done()

    it 'should copy a file object to another directory', (done)->
      vFile = Resource './fixture/src.md', cwd:__dirname, dest: '.'
      task.execute vFile, (err)->
        unless err
          checkDestFile vFile, './src.md'
          fs.unlinkSync path.join __dirname, 'src.md'
        done(err)

    it 'should copy a inherited file object', (done)->
      vFile = {}
      vFile.__proto__ = file
      task.execute vFile, (err)->
        checkDestFile file unless err
        done(err)

    it 'should copy a inherited file object if dest is exists and overwrite is true', (done)->
      task.execute file, (err)->
        return done(err) if err
        checkDestFile file
        file.overwrite = true
        vFile = overwrite: false
        vFile.__proto__ = file
        task.execute vFile, (err)->
          delete file.overwrite
          expect(err).to.be.exist
          done()

    it 'should copy a inherited file object with custom contents', (done)->
      contents = fs.readFileSync path.join __dirname, './fixture/src2.md'
      vFile = {_contents: contents}
      vFile.__proto__ = file
      task.execute vFile, (err)->
        checkDestFile vFile, './fixture/src2.md' unless err
        done(err)
