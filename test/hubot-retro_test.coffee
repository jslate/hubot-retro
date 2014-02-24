chai = require 'chai'
sinon = require 'sinon'
chai.use require 'sinon-chai'

expect = chai.expect

describe 'retro:', ->
  retro_module = require('../src/retro')

  beforeEach ->
    @robot =
      respond: sinon.spy()
      hear: sinon.spy()
    @msg =
      send: sinon.spy()
      random: sinon.spy()
    @retro_module = retro_module(@robot)

  describe 'record a comment', ->

    # TODO
