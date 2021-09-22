local tune = {}

tune.intervals = { 1, 2, 3, 4 }

tune.params = function(id)
    id = id and ('_'..id) or ''

    params:add_separator('tuning'..id)
    params:add {
        type='number', name='scale preset', id='tune_scale_preset'..id, min = 1, max = 8,
        default = 1,
    }
    params:add {
        type='number', name='scale', id='tune_scale'..id, min = 1, max = 8,
        default = 1,
    }
    params:add {
        type='number', name='transpose', id='tune_transpose'..id, min = 1, max = 8,
        default = 1,
    }
    params:add {
        type='number', name='octave', id='tune_octave'..id, min = -1, max = 6,
        default = 0
    }
end

tune.setup = function(arg)
end

tune.note_grid = function(add, rem)
end

tune.note_midi = function(msg)
end

tune.intervals_ = function() end

return tune
