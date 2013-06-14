less = require 'less'
fs = require 'fs'
vm = require 'vm'
path = require 'path'


module.exports = (grunt) ->
  'use strict'

  getClosureFileMap = (main = null) ->
    depsFile = 'client/deps.js' # todo config
    depsTree = {}
    fileMap = {}
    vm.runInNewContext fs.readFileSync(depsFile),
      goog: addDependency: (file, klasses, dependencies) ->
        klasses = [klasses] unless Array.isArray klasses
        for klass in klasses
          depsTree[klass] = dependencies
          fileMap[klass] = file.substr 12 # force hack

    used = {}

    findDeps = (name) ->
      used[name] = fileMap[name] if fileMap[name]
      deps = depsTree[name]
      if deps and deps.length
        findDeps dep for dep in deps

    if main
      findDeps main
    else
      used = fileMap


    used



  grunt.registerMultiTask 'lesssprites', 'Compiles less with sprites to css', () ->
    done = @async()
    # console.log 'xxxaasduasoiduasiduasdioa'


    options = this.options()
    grunt.verbose.writeflags options, 'Options'

    # todo nacitat z konfigu
    map = getClosureFileMap 'app.start'

    # done()

    # return
    # console.log 'xxx'
    # console.log map
    lessPaths = {}
    for name, file of map
      # console.log file
      data = fs.readFileSync(file).toString().split "\n"

      #TODO esprima
      for line, lineNr in data
        if m = line.match /\@LESS\s?(.*)/
          p =  path.dirname(file) + '/' + m[1] + '.less'
          p = path.normalize p
          try
            fs.statSync p
            lessPaths[p] = yes
          catch err
            # vyrobim error o neexistujicim souboru
            o =
              file: file
              type: "ReferenceError"
              message: "File #{p} doesn't exists"
              line: lineNr + 1
              toString: () ->
                "#{@type} #{@file}:#{@line}\n#{@message}"

            grunt.log.error o
            grunt.fail.warn 'Error compiling LESS.'


    console.log '>>>>'
    lesses = (lessFile for lessFile of lessPaths)
    console.log lesses


    grunt.util.async.forEachSeries lesses, (file, next) ->
      source = file

      fs.readFile source, (err, buffer) ->
        # console.log err if err
        return next err if err
        # console.log buffer
        data = buffer.toString()
        parser = new(less.Parser)
          filename: source
          # paths: path.dirname file
        # console.log 'parse'
        parser.parse data, (err, tree) ->
          if err
            lessError err if err
            return next err

          css = tree.toCSS()

          fs.writeFileSync 'client/app.css', css
          console.log css
          next()

    , (err) ->
      grunt.log.ok('asdsdasdasdfiles fixed bsda');
      done err

  formatLessError = (e) ->
    pos = '[' + 'L' + e.line + ':' + ('C' + e.column) + ']'
    return e.filename + ': ' + pos + ' ' + e.message

  lessError = (e) ->
    # console.log e
    if less.formatError
      message = less.formatError e
    else
      message = formatLessError e
    o =
      toString: () ->
        message
      err: e

    grunt.log.error o
    grunt.fail.warn 'Error compiling LESS.'


    # # return
    # parser = new(less.Parser)
    #   # filename: file
    #   paths: path.dirname file
    #
    # console.log 'sdasdasdasd'
    # console.log @files
    # console.log 'sd-as0-d9as0-d9as0-d9as-d0'
    # throw new Error 'x'
    # var count = 0

# this.files.forEach(function (f) {
#   try {
# var file = grunt.file.read(f.dest);
#   file = coffee2closure.fix(file);
#   grunt.file.write(f.dest, file);
#   count++;
# }
# catch(e) {
# grunt.log.writeln('File ' + f.dest + ' failed.');

