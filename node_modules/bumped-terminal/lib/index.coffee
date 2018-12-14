'use strict'

spawn    = require 'execspawn'
stripEof = require 'strip-eof'
omit     = require 'lodash.omit'

keywords =
  '$newVersion':
    regex: /\$newVersion/g
    replace: '_version'

  '$oldVersion':
    regex: /\$oldVersion/g
    replace: '_oldVersion'

replaceAll = (str, bumped, key) ->
  str.replace keywords[key].regex, bumped[keywords[key].replace]

###*
 * Execute a terminal command
###
module.exports = (bumped, plugin, cb) ->
  command = plugin.opts.command
  return cb new TypeError('command for bumped-terminal is required.') unless command

  command = replaceAll command, bumped, key for key of keywords
  opts = omit(plugin.opts, 'command')
  log = (type, data) -> plugin.logger[type] stripEof data.toString()

  error = false
  errorMessage = null

  cmd = spawn command, plugin.options

  cmd.stdout.on 'data', (data) -> log 'success', data

  cmd.stderr.on 'data', (data) -> log 'error', data

  cmd.on 'error', (err) ->
    error = true
    errorMessage = err.message or err

  cmd.on 'exit', (code) ->
    return cb() unless error or code
    errorMessage ?= "Process exited with code #{code}"
    log 'error', errorMessage
    cb true
