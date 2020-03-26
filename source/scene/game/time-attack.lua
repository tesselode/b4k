local Game = require 'scene.game'

local TimeAttack = Game:extend()

TimeAttack.gameRulesSystem = require 'scene.game.system.game-rules.time-attack'

return TimeAttack
