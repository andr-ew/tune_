include 'nest_/lib/nest/core'
include 'nest_/lib/nest/norns'
include 'nest_/lib/nest/grid'

tune, tune_ = include 'tune/lib/tune' { presets = 8, config = 'tune/lib/data/scales.lua' }

params:add_separator('tuning')
tune.params()

params:add {
    type='number', name='scale preset', id='scale_preset', min = 1, max = 8,
    default = 1,
}
params:add {
    type='number', name='transpose', id='transpose', min = 0, max = 7,
    default = 1,
}
params:add {
    type='number', name='octave', id='octave', min = -1, max = 6,
    default = 0
}

n = nest_ {
    keyboard = _grid.momentary {
        x = { 1, 8 }, y = { 1, 8 },
        action = function(s, v, t, d, add, rem)
            local k = add or rem
            local id = k.y * k.x
            local deg = k.x + params:get('transpose')
            local oct = k.y-3 + params:get('octave')
            local pre = params:get('scale_preset')

            local hz = tune.hz(deg, oct, pre)
            local midi = tune.midi(deg, oct, pre)

            if add then
                engine.start(id, hz)
                if midi then m:note_on(midi, vel or 1, 1) end
            elseif rem then
                engine.stop(id) 
                if midi then m:note_off(midi, vel or 1, 1) end
            end
        end
    },
    --TODO: octave marker _grid.fill at y = 8
    scale_preset = _grid.number {
        x = { 9, 16 }, y = 1,
    } :param('scale_preset'),
    tune = tune_ {
        left = 9, top = 2,
    } :each(function(i, v) 
        v.enabled = function() return i == params:get('scale_preset') end
    end),
    transpose = _grid.number {
        x = { 9, 16 },
        y = 7,
    } :param('transpose'),

    --TODO: _grid.number.redraw bug when min < 1
    octave = _grid.number {
        x = { 9, 16 },
        y = 8
    } :param('octave')
} :connect { g = grid.connect() }

--TODO: screen interface - print scale in western notes if west

m = midi.connect()
m.event = function(data)
end

params:add_separator()
engine.name = 'PolySub'
polysub = include 'we/lib/polysub'
polysub.params()

function init()
    n:init()
    params:bang()
end
