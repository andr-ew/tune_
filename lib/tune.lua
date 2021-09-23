local tune = {}

tune.id = ''

tune.on = function(id, hz, midi, volt)
tune.off = function(id, midi)
tune.change = function(id, hz, midi, volt)
tune.affordance = nil

tune.intervals = { 1, 2, 3, 4 }

local function pgeg(par)
    return params:get('tune_'..par..tune.id)
end

tune.params = function(id)
    id = id and ('_'..id) or ''
    tune.id = id

    params:add_separator('tuning'..id)
    params:add {
        type='number', name='preset', id='tune_preset'..id, min = 1, max = 8,
        default = 1,
    }
    params:add {
        type='number', name='scale', id='tune_scale'..id, min = 1, max = 8,
        default = 1,
    }

    --TODO: change callback
    params:add {
        type='number', name='transpose', id='tune_transpose'..id, min = 0, max = 7,
        default = 1,
    }
    params:add {
        type='number', name='octave', id='tune_octave'..id, min = -1, max = 6,
        default = 0
    }

    return tune
end

tune.setup = function(arg)

    return tune
end

tune.note_lookup = function()
end

tune.note = function(add, rem)
    local k = add or rem
    local id = k.y * k.x
    local iv = tune.intervals[pget 'scale']
    local oct = k.y-3 + k.x//(#iv+1) + pget 'octave'
    local deg = (k.x - 1 + pget 'transpose')%#iv + 1
    local hz = tune.root * 2^oct * 2^(iv[deg]/12)

    --TODO: calculate volt, return volt

    if add then tune.on(id, hz)
    elseif rem then tune.off(id) end
    
    return hz
end

tune.note_midi = function(msg)
end

tune.intervals_ = function() end

return tune
