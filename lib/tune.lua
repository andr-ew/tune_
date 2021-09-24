local tune = {}

tune.intervals = { 1, 2, 3, 4 }
tune.tones = 12

tune.params = function()
    params:add {
        type='number', name='scale', id='tune_scale'..id, min = 1, max = 8,
        default = 1,
    }

    return tune
end

tune.setup = function(arg)

    return tune
end

tune.hz = function(deg, oct, pre)
    local iv = {}
    local oct = oct + deg//(#iv+1)
    local deg = (deg - 1)%#iv + 1

    return tune.root * 2^oct * 2^(iv[deg]/tune.tones)

    --TODO: calculate volt, return volt

    if add then tune.on(id, hz)
    elseif rem then tune.off(id) end
    
    return hz
end

tune.midi = function() end

tune.volts = function() end

tune.intervals_ = function() end

return tune
