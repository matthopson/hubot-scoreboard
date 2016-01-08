chai = require 'chai'
sinon = require 'sinon'
chai.use require 'sinon-chai'

expect = chai.expect

describe 'scoreboard', ->
  beforeEach ->
    @robot =
      respond: sinon.spy()

    require('../src/scoreboard')(@robot)
