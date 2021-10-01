local tune = {
    intervals = {},
    tonics = {},
    presets = 8,
}

local p = function(a)
    params:add(a)
    params:hide(a.id)
end

local kb = {}
kb.grid = {
      { 05, 07, 00, 10, 12, 02, },
    { 04, 06, 08, 09, 11, 01, 03, }
}
kb.pos = {}
for i = 1,12 do
    for y = 1,2 do
        for x,v in ipairs(kb.grid[y]) do
            if i == v then
                kb.pos[i] = { x=x, y=y }
            end
        end
    end
end

tune.params = function()
    for i = 1, tune.presets do
        p { type='number', id='tune_tonic_'..i, min = 1, max = 8, default = 1, }
        p { type='number', id='tune_intervals_'..i, min = 1, max = 16, default = 1, }
        p { type='number', id='tune_row_interval_'..i, min = 0, max = 15, default = 1 }

        for ii = 1,16 do
            p { 
                type='binary', behavior='toggle', id='tune_intervals_'..i..'_enable_'..ii,
                default = 1,
            }
        end
    end
    --TODO: fileselect param for config ?

    return tune
end

local function intervals(pre)
    local all = tune.intervals[math.min(params:get('tune_intervals_'..pre), #tune.intervals)]
    local some = {}
    for i,v in ipairs(all) do
        if params:get('tune_intervals_'..pre..'_enable_'..i) > 0 then 
            table.insert(some, v)
        end
    end
    return some
end
local function tonic(pre)
    return tune.tonics[math.min(params:get('tune_tonic_'..pre), #tune.tonics)]
end

tune.degoct = function(row, column, pre, trans, toct)
    local iv = intervals(pre)
    local rowint = params:get('tune_row_interval_'..pre)
    if rowint == 1 then rowint = #iv end

    local deg = (trans or 0) + row + ((column-1) * (rowint))
    local oct = (toct or 0) - 5 + (deg-1)//#iv + 1
    deg = (deg - 1)%#iv + 1
    
    return deg, oct
end

tune.is_tonic = function(row, column, pre)
    return tune.degoct(row, column, pre) == 1
end

tune.hz = function(row, column, trans, toct, pre)
    local iv = intervals(pre)
    local deg, oct = tune.degoct(row, column, pre, trans, toct)
    print(deg, oct)

    --TODO just intonnation
    return tune.root * 2^(tonic(pre)/tune.tones) * 2^oct * 2^(iv[deg]/tune.tones)
end

tune.midi = function() end

tune.volts = function() end

local function west(rooted)
    return (tune.root % 110 == 0 or (not rooted))
    and tune.temperment=='equal' 
    and tune.tones==12 
end

return function(arg)
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
            screen.text_center('config file error :(')
            screen.move(64, 32+10)
            screen.text_center('check maiden REPL')
            screen.update()
        end
        redraw()
        print('---------------- CONFIG FILE ERROR -----------------------')
        print('FILE PATH: '..arg.config) --TODO: use loaded path
        print('ERROR MESSAGE: ')
        print(err)
        f = loadfile(norns.state.lib..'data/scales.lua')
        f()
    end

    return 
    tune,
    function(o)
        local left, top = o.left or 1, o.top or 1
        local width = o.width or 16

        return nest_(tune.presets):each(function(i) 
            return nest_ {
                tonic = _grid.number {
                    x = { left, left + math.min(width, #tune.tonics) - 1 }, y = top,
                    lvl = { 4, 15 },
                    value = function() return params:get('tune_tonic_'..i) end,
                    action = function(s, v) params:set('tune_tonic_'..i, v) end
                },
                intervals = _grid.number {
                    x = { left, left + math.min(width, #tune.intervals) - 1 }, y = top + 1,
                    lvl = { 4, 15 },
                    value = function() return params:get('tune_intervals_'..i) end,
                    action = function(s, v) params:set('tune_intervals_'..i, v) end
                },
                row_interval = _grid.number {
                    x = function() 
                        local iv = intervals(i)
                        return { left, left + math.min(width, #iv) - 1 }
                    end,
                    y = top + 2,
                    lvl = function(s, x)
                        local iv = intervals(i)
                        return ((x==1) or (
                            west() and (iv[x] == 7 or iv[x] == 5)
                        )) and { 4, 15 }
                        or { 1, 15 }
                    end,
                    value = function() return params:get('tune_row_interval_'..i) end,
                    action = function(s, v) params:set('tune_row_interval_'..i, v) end
                },
                toggles = nest_(#tune.intervals):each(function(iii)
                    return nest_(#tune.intervals[iii]):each(function(ii)
                        local function pos(ax)
                            local r = { x = (ii-1) % 8 + 1, y = (ii-1) // 8 + 1 }
                            if west(true) then
                                r = kb.pos[
                                    (
                                        tune.intervals[iii][ii]
                                        + tune.tonics[params:get('tune_tonic_'..i)]
                                    ) % 12 + 1
                                ]
                            end
                            return r[ax]
                        end
                        return _grid.toggle {
                            x = function() return left + pos('x') - 1 end,
                            y = function() return top + 3 + pos('y') - 1 end,
                            lvl = { 8, 15 },
                            value = function() 
                                return params:get('tune_intervals_'..i..'_enable_'..ii) 
                            end,
                            action = function(s, v)
                                params:set('tune_intervals_'..i..'_enable_'..ii, v)
                            end
                        }
                    end):merge { 
                        enabled = function() return iii == params:get('tune_intervals_'..i) end
                    }
                end),
                --TODO: piano bg (lvl=4) if western
            }
        end):merge(o)
    end
end
