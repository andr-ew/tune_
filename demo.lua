include 'nest_/lib/nest/core'
include 'nest_/lib/nest/norns'
include 'nest_/lib/nest/grid'

local tune = include 'tune/lib/tune'
tune.params()

n = nest_ {
    keyboard = _grid.momentary {
        x = { 1, 8 }, y = { 1, 8 },
        action = function(s, v, t, d, add, rem)
            tune.note(add, rem)
        end
    },
    --TODO: octave marker _grid.fill at y = 8
    scale_preset = _grid.number {
        x = { 9, 16 }, y = 1,
    } :param('tune_preset'),
    scale = _grid.number {
        x = function() return { 9, 9 + math.min(8, #tune.intervals) - 1 } end,
        y = 2, wrap = 8,
    } :param('tune_scale'),
    intervals = tune.intervals_ {
        left = 9, top = 4,
    },
    transpose = _grid.number {
        x = { 9, 16 },
        y = 7,
    } :param('tune_transpose'),

    --TODO: _grid.number.redraw bug when min < 1
    octave = _grid.number {
        x = { 9, 16 },
        y = 8
    } :param('tune_octave')
} :connect { g = grid.connect() }

m = midi.connect()
m.event = function(data)
    tune.note_midi(midi.to_msg(data))
end

tune.setup {
    on = function(id, hz, midi, vel)
        engine.start(id, hz)

        if midi then m:note_on(midi, vel or 1, 1) end
    end,
    off = function(id, midi, vel)
        engine.stop(hz)
        
        if midi then m:note_off(midi, vel or 1, 1) end
    end,
    affordance = n.keyboard
}

params:add_separator()
engine.name = 'PolySub'
polysub = include 'we/lib/polysub'
polysub.params()

function init()
    n:init()
    params:bang()
end
