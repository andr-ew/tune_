local tune = {
    scales = {},
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

local iv_names = {
    [0] = 'octaves',
    "min 2nds", "maj 2nds",
    "min 3rds", "maj 3rds", "4ths",
    "tritones", "5ths", "min 6ths",
    "maj 6ths", "min 7ths", "maj 7ths",
    "octaves"
}
local note_names = {
    'a  ', 'a#', 'b  ', 'c  ', 'c#', 'd  ', 'd#', 'e  ', 'f  ', 'f#', 'g  ', 'g#'
}

tune.params = function()
    for i = 1, tune.presets do
        p { type='number', id='tune_tonic_'..i, min = 1, max = 8, default = 1, }
        p { type='number', id='tune_scales_'..i, min = 1, max = 16, default = 1, }
        p { type='number', id='tune_row_interval_'..i, min = 1, max = 15, default = 1 }

        for ii = 1,16 do
            p { 
                type='binary', behavior='toggle', id='tune_scales_'..i..'_enable_'..ii,
                default = 1,
            }
        end
    end
    --TODO: fileselect param for config ?

    return tune
end

local function scales(pre)
    local all = tune.scales[math.min(params:get('tune_scales_'..pre), #tune.scales)]
    local some = {}
    for i,v in ipairs(all) do
        if params:get('tune_scales_'..pre..'_enable_'..i) > 0 then 
            table.insert(some, v)
        end
    end
    if #some == 0 then table.insert(some, all[1]) end
    return some
end
local function tonic(pre)
    return tune.tonics[math.min(params:get('tune_tonic_'..pre), #tune.tonics)]
end

tune.get_scales = scales

tune.wrap = function(deg, oct, pre)
    local iv = scales(pre)

    oct = oct + (deg-1)//#iv + 1
    deg = (deg - 1)%#iv + 1

    return deg, oct
end

--TODO: start row wrapping in the middle of the grid vertically somehow
tune.degoct = function(row, column, pre, trans, toct)
    local iv = scales(pre)
    local rowint = params:get('tune_row_interval_'..pre) - 1
    if rowint == 0 then rowint = #iv end

    local deg = (trans or 0) + row + ((column-1) * (rowint))
    local oct = (toct or 0) - 5
    deg, oct = tune.wrap(deg, oct, pre)
    
    return deg, oct
end

tune.is_tonic = function(row, column, pre)
    return tune.degoct(row, column, pre) == 1
end

tune.hz = function(row, column, trans, toct, pre)
    local iv = scales(pre)
    local deg, oct = tune.degoct(row, column, pre, trans, toct)

    --TODO just intonnation
    return tune.root * 2^(tonic(pre)/tune.tones) * 2^oct * 2^(iv[deg]/tune.tones)
end

--TODO
tune.midi = function() end

--TODO
tune.volts = function() end

local function west(rooted)
    return (tune.root % 110 == 0 or (not rooted))
    and tune.temperment=='equal' 
    and tune.tones==12 
end

tune.is_western = west

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
    
    local x, y = {}, {}
    do
        local gap = 6
        local top, mul = 6, 10

        x = { 128/3 - gap/2, 128/3 + gap/2 }
        for i = 1, 6 do
            y[i] = (i-1) * mul + top
        end
    end

    return 
    tune,
    function(o)
        local left, top = o.left or 1, o.top or 1
        local width = o.width or 16

        local count = {
            preset = tune.presets,
            tonic = math.min(width, #tune.tonics),
            scales = math.min(width, #tune.scales),
            row_interval = function(i)
                local iv = scales(i)
                return math.min(width, #iv)
            end
        }

        return nest_(tune.presets):each(function(i) 
            return nest_ {
                tonic = _grid.number {
                    x = { left, left + count.tonic - 1 }, y = top,
                    lvl = { 4, 15 },
                    value = function() return params:get('tune_tonic_'..i) end,
                    action = function(s, v) 
                        params:set('tune_tonic_'..i, v) 
                        redraw()
                    end
                },
                scales = _grid.number {
                    x = { left, left + count.scales - 1 }, y = top + 1,
                    lvl = { 4, 15 },
                    value = function() return params:get('tune_scales_'..i) end,
                    action = function(s, v) 
                        params:set('tune_scales_'..i, v) 
                        redraw()
                    end
                },
                row_interval = _grid.number {
                    x = function() 
                        return { left, left + count.row_interval(i) - 1 }
                    end,
                    y = top + 2,
                    lvl = function(s, x)
                        local iv = scales(i)
                        return ((x==1) or (
                            west() and (iv[x] == 7)
                        )) and { 4, 15 }
                        or { 1, 15 }
                    end,
                    value = function() return params:get('tune_row_interval_'..i) end,
                    action = function(s, v) 
                        params:set('tune_row_interval_'..i, v) 
                        redraw()
                    end
                },
                toggles = nest_(#tune.scales):each(function(iii)
                    return nest_(#tune.scales[iii]):each(function(ii)
                        local function pos(ax)
                            local r = { x = (ii-1) % 8 + 1, y = (ii-1) // 8 + 1 }
                            if west(true) then
                                r = kb.pos[
                                    (
                                        tune.scales[iii][ii]
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
                                return params:get('tune_scales_'..i..'_enable_'..ii) 
                            end,
                            action = function(s, v)
                                params:set('tune_scales_'..i..'_enable_'..ii, v)
                                redraw()
                            end
                        }
                    end):merge { 
                        enabled = function() 
                            return iii == params:get('tune_scales_'..i) 
                        end,
                    }
                end),
                --i named this affordance zoink because the z parameter is broken & this causes it to draw in the correct order :)
                zoink = nest_(12):each(function(ii) 
                    local pos = kb.pos[ii]
                    local lvl = (west()) and 4 or 0

                    return _grid.fill {
                        x = left + pos.x - 1, y = top + 3 + pos.y - 1, lvl = lvl, v = 1,
                    }
                end):merge {
                    enabled = function() return west() end,
                    z = -1
                },
                screen = nest_ {
                    preset = nest_ {
                        _txt.label {
                            x = x[1], y = y[1], align = 'right', lvl = 4,
                            value = 'preset',
                        },
                        _txt.enc.option {
                            input = false,
                            x = x[2], y = y[1], lvl = { 2, 15 },
                            margin = 7, --lvl = { 0, 15 }
                            options = function()
                                local ops = {}
                                for ii = 1,count.preset do
                                    ops[ii] = ii
                                end
                                return ops
                            end,
                            value = i
                        }
                    },
                    tonic = nest_ {
                        _txt.label {
                            x = x[1], y = y[2], align = 'right', lvl = 4,
                            value = 'tonic',
                        },
                        _txt.enc.option {
                            input = false,
                            x = x[2], y = y[2], lvl = { 2, 15 },
                            margin = 6,
                            --TODO: non-west
                            options = function()
                                local ops = {}
                                for ii = 1,count.tonic do
                                    ops[ii] = note_names[tune.tonics[ii]+1]
                                end
                                return ops
                            end,
                            value = function()
                                return params:get('tune_tonic_'..i)
                            end
                        }
                    },
                    scales = nest_ {
                        _txt.label {
                            x = x[1], y = y[3], align = 'right', lvl = 4,
                            value = 'scale',
                        },
                        _txt.label {
                            input = false,
                            x = x[2], y = y[3],
                            value = function()
                                local idx = params:get('tune_scales_'..i)
                                return tune.scales[idx].name or idx
                            end
                        }
                    },
                    tuning = nest_ {
                        _txt.label {
                            x = x[1], y = y[4], align = 'right', lvl = 4,
                            value = 'tuning'
                        },
                        _txt.label {
                            input = false,
                            x = x[2], y = y[4],
                            value = function()
                                local idx = tune.scales[params:get('tune_scales_'..i)][params:get('tune_row_interval_'..i)]
                                return iv_names[idx] or idx
                            end
                        }
                    },
                    toggles = nest_(#tune.scales):each(function(iii) 
                        local ivs = tune.scales[iii]
                        return nest_(12):each(function(ii)
                            local mul = 12
                            local p = kb.pos[ii]
                            local xx = (p.x - 1) * mul + x[2]
                            local yy = y[4 + p.y]

                            return _txt.label {
                                x = xx, y = yy, 
                                lvl = function()
                                    local iv = (
                                        ii-1-tune.tonics[params:get('tune_tonic_'..i)]
                                    )%12
                                    local deg = tab.key(ivs, iv)

                                    local is_interval = tab.contains(ivs, iv)
                                    local is_enabled = deg and (params:get('tune_scales_'..i..'_enable_'..deg) == 1)

                                    return (is_interval and is_enabled) and 15  or 2
                                end,
                                v = function()
                                    local iv = (
                                        ii-1-tune.tonics[params:get('tune_tonic_'..i)]
                                    )%12
                                    return tab.contains(ivs,  iv)
                                    and note_names[ii] or '.'
                                end
                            }
                        end):merge { 
                            enabled = function() 
                                return iii == params:get('tune_scales_'..i) 
                            end,
                        }
                    end):merge {
                        label = _txt.label {
                            x = x[1], y = y[6], v = 'toggles', align = 'right', lvl = 4
                        }
                    }
                }
            }
        end):merge(o)
    end
end
