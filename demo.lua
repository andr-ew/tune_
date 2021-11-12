include 'nest_/lib/nest/core'
include 'nest_/lib/nest/norns'
include 'nest_/lib/nest/grid'
include 'nest_/lib/nest/txt'

tune, tune_ = include 'tune_/lib/tune' 
tune.setup { presets = 8, scales = include 'tune_/lib/scales' }

params:add_separator('tuning')

local function clear()
    --n.keyboard:clear()
    engine.stopAll()
end

params:add {
    type='option', id='voicing', options={ 'poly', 'mono' },
    action = clear,
}

params:add {
    type='number', name='scale preset', id='scale_preset', min = 1, max = 8,
    default = 1, action = function() redraw() end
}
params:add {
    type='number', name='transpose', id='transpose', min = 0, max = 7,
    default = 0,
}
params:add {
    type='number', name='octave', id='octave', min = -3, max = 4,
    default = 0,
}

n = nest_ {
    voicing = _grid.toggle {
        x = 1, y = 1, lvl = { 4, 15 },
    } :param('voicing'), 
    keyboard = _grid.momentary {
        x = { 1, 8 }, y = { 2, 8 },
        lvl = function(s, x, y)
            return tune.is_tonic(x, y, params:get('scale_preset'), params:get('transpose')) and { 4, 15 } or { 0, 15 }
        end,
        action = function(s, v, t, d, add, rem)
            local k = add or rem
            local id = params:get('voicing') == 2  and 0 or k.x + (k.y * 16)

            local trans, oct, pre = params:get('transpose'), params:get('octave'), params:get('scale_preset')

            local hz = 440 * tune.hz(pre, k.x, k.y, trans, oct)
            local midi = tune.midi(pre, k.x, k.y, trans, oct)

            if add then
                engine.start(id, hz)
                if midi then m:note_on(midi, vel or 1, 1) end
            elseif rem then
                engine.stop(id) 
                if midi then m:note_off(midi, vel or 1, 1) end
            end
        end
    },
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
        lvl = function(s, x) 
            local iv = tune.get_intervals(params:get('scale_preset'))
            local x = tune.wrap(x, 0, params:get('scale_preset'))
            return (
                (iv[x] == 7 or iv[x] == 0)
            ) and { 4, 15 } or { 0, 15 }
        end
    } :param('transpose'),
    octave = _grid.number {
        x = { 9, 16 },
        y = 8
    } :param('octave')
} :connect { g = grid.connect(), screen = screen, key = key, enc = enc }


params:add_separator()
engine.name = 'PolySub'
polysub = include 'we/lib/polysub'
polysub.params()

function init()
    n:init()
    params:bang()
end
