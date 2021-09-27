local tune = {
    intervals = {},
    tonics = {},
    presets = 8,
}

local p = function(a)
    local id = a.id
    params:add(a)
    params:hide(a)
end

tune.params = function()

    return tune
end

tune.setup = function(arg)
    tune.presets = arg.presets or tune.presets
    
    --TODO: if absent, copy arg.config to norns.state.data, else load from norns.state.data
    local f = loadfile('/home/we/dust/code/'..arg.config)
    debug.setupvalue(f, 1, tune) 
    print 'loading scales config'
    local all_good, err = pcall(f)
    
    if not all_good then
        redraw = function()
            screen.clear()
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

local left = function(s) return s.parent and s.parent.p_.left or 1 end
local top = function(s) return s.parent and s.parent.p_.top or 1 end

tune.midi = function() end

tune.volts = function() end

local tune_ = nest_(tune.presets):each(function(i) 
    return nest_ {
        left=left, top=top,

        tonic = _grid.number {
            top = function(s) return top(s) end, left = function(s) return left(s) end,
            x = function(s) return { s.p_.left, s.p_.left + math.min(8, #tune.tonics) - 1 } end,
            y = function(s) return s.p_.top end, 
            wrap = 8, lvl = { 4, 15 }
        },
        scale = _grid.number {
            top = function(s) 
                return top(s) + 1 
            end, left = function(s) return left(s) end,
            x = function(s) return { s.p_.left, s.p_.left + math.min(8, #tune.intervals) - 1 } end,
            y = function(s)
                return s.p_.top 
            end, 
            wrap = 8, lvl = { 4, 15 }
        },
        intervals = nest_ {
            top = function(s) return top(s) + 3 end, left = function(s) return left(s) end,
        },
    }
end):merge { left=1, top=1 }

return tune, tune_
