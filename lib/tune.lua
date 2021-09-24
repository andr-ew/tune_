local tune = {}

tune.intervals = { 1, 2, 3, 4 }
tune.tones = 12

tune.params = function()
    params:add {
        type='number', name='scale', id='tune_scale', min = 1, max = 8,
        default = 1,
    }

    return tune
end

--norns.state.data
--norns.state.script
--norns.state.path
--norns.state.lib
tune.setup = function(arg)
    --TODO: copy lib/data/scales to norns.state.data if absent, load from norns.state.data
    local f = loadfile(norns.state.lib..'data/scales.lua')
    debug.setupvalue(f, 1, tune) 
    print 'loading scales config'
    local all_good, err = pcall(f)
    
    if not all_good then
        redraw = function()
            screen.move(64, 32)
            screen.text_center('scales.lua error :(')
            screen.move(64, 32+10)
            screen.text_center('check maiden REPL')
            screen.update()
        end
        redraw()
        print('---------------- SCALES.LUA ERROR -----------------------')
        print(err)
        f = loadfile(norns.state.lib..'data/scales.lua')
        f()
    end

    return tune
end

tune.hz = function(deg, oct, pre)
    local iv = {}
    local oct = oct + deg//(#iv+1)
    local deg = (deg - 1)%#iv + 1

    return tune.root * 2^oct * 2^(iv[deg]/tune.tones)
end

tune.midi = function() end

tune.volts = function() end

tune.intervals_ = function() end

return tune
