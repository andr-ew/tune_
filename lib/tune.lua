local presets = 8
local modenames = {}

local states = {}
local function state(pre)
    return states[pre][modenames[states[pre].mode]]
end

local modes = {}
local function mode(pre)
    return modes[modenames[math.floor(states[pre].mode)]]
end

local scale_names = {}

local function init_state()
    for i = 1, presets do
        states[i] = {
            mode = 1, --west
            tonic = 1, --C
        }
        for k,_ in pairs(modes) do
            states[i][k] = {
                scale = 1,
                tuning = {},
                toggles = {}
            }
            for ii,vv in ipairs(modes[k].scales) do
                states[i][k].tuning[ii] = 1
                states[i][k].toggles[ii] = {}
                for iii, vvv in ipairs(modes[k].scales[ii].iv) do
                    states[i][k].toggles[ii][iii] = 1
                end
            end
        end
    end
end

local tonics = {}
for i = 1, 12 do
    local n = i - 9 - 1 -- start from C below middle A
    tonics[i] = n
end
local function tonic(pre)
    return tonics[states[pre].tonic]
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
                kb.pos[i+0.5] = { x=x, y=y }
            end
        end
    end
end

local iv_names = {
    'octaves',
    "min 2nds", "maj 2nds",
    "min 3rds", "maj 3rds", "4ths",
    "tritones", "5ths", "min 6ths",
    "maj 6ths", "min 7ths", "maj 7ths",
}

-- a ^ for half flat/sharp
local note_names = {
    [1] = 'A', [1.5] = 'A^#', 
    [2] = 'A#', [2.5] = 'B^b', 
    [3] = 'B', [3.5] = 'B^#', 
    [4] = 'C', [4.5] = 'C^#', 
    [5] = 'C#', [5.5] = 'D^b', 
    [6] = 'D', [6.5] = 'D^#', 
    [7] = 'D#', [7.5] = 'E^b',
    [8] = 'E',  [8.5] = 'E^#', 
    [9] = 'F', [9.5] = 'F^#', 
    [10] = 'F#', [10.5] = 'G^b', 
    [11] = 'G', [11.5] = 'G^#', 
    [12] = 'G#', [12.5] = 'A^b',
}
local tonic_names = {}
for i = 4, 15 do table.insert(tonic_names, note_names[(i-1)%12+1]) end

local function tuning(pre)
    local scl = state(pre).scale
    return state(pre).tuning[scl]
end

local function intervals(pre)
    local scl = state(pre).scale
    local all = mode(pre).scales[scl].iv

    local some = {}
    for i,v in ipairs(all) do
        if state(pre).toggles[scl][i] > 0 then 
            table.insert(some, v)
        end
    end
    if #some == 0 then table.insert(some, all[1]) end
    return some
end

local tune = {}

tune.get_intervals = intervals

tune.wrap = function(deg, oct, pre)
    local iv = intervals(pre)

    oct = oct + (deg-1)//#iv + 1
    deg = (deg - 1)%#iv + 1

    return deg, oct
end

--TODO: start row wrapping in the middle of the grid vertically somehow
tune.degoct = function(row, column, pre, trans, toct)
    local iv = intervals(pre)
    local rowint = tuning(pre) - 1
    if rowint == 0 then rowint = #iv end

    local deg = (trans or 0) + row + ((column-1) * (rowint))
    local oct = (toct or 0) - 5
    deg, oct = tune.wrap(deg, oct, pre)
    
    return deg, oct
end

tune.is_tonic = function(row, column, pre, trans)
    return tune.degoct(row, column, pre, trans) == 1
end

--number to be multiplied by center freq in hz
tune.hz = function(row, column, trans, toct, pre)
    local iv = intervals(pre)
    local deg, oct = tune.degoct(row, column, pre, trans, toct)

    return (
        2^(tonic(pre)/(mode(pre).tones or 12)) * 2^oct 
        * ((mode(pre).temperment == 'just') 
            and (iv[deg])
            or (2^(iv[deg]/mode(pre).tones))
        )
    )
end

--TODO
tune.volts = function() end

--TODO
tune.midi = function() end

tune.setup = function(arg)
    presets = arg.presets or presets
    modes = arg.scales

    modenames = { 'west', 'just' }
    for k,_ in pairs(modes) do 
        if not tab.contains(modenames, k) then table.insert(modenames, k) end
    end
    for k,v in pairs(modes) do
        scale_names[k] = {}
        for i, vv in ipairs(v.scales) do
            scale_names[k][i] = vv.name
        end
    end

    init_state()

    return tune
end

tune.read = function(path)
end

tune.write = function(path)
end

local tune_ = function(o)
    local left, top = o.left or 1, o.top or 1
    local width = o.width or 16
    
    --TODO: arg.tonic (whether to add the tonic option)
    
    local x, y
    do
        local top, bottom = 10, 64-6
        local left, right = 4, 128-4
        local mul = { x = (right - left) / 2, y = (bottom - top) / 2 }
        x = { left, left + mul.x*5/4, [1.5] = 24  }
        y = { top, bottom - mul.y*1/2, [1.5] = 20 }
    end

    return nest_(presets):each(function(i) 
        return nest_ {
            grid = nest_ {
                toggles = nest_(24):each(function(ii2)
                    local ii = ii2/2 + 0.5
                    return nest_ {
                        mutes = _grid.toggle {
                            x = function() return left + kb.pos[ii].x - 1 end,
                            y = function() return top + kb.pos[ii].y - 1 end,
                            lvl = { 8, 15 },
                            enabled = function()
                                local ji = mode(i).temperment == 'just'
                                local scl = state(i).scale
                                local ivs = mode(i).scales[scl].iv
                                local map = ji and mode(i).scales[scl].map
                                local iv = (ii-1-tonic(i))%12
                                local deg = ji and tab.key(map, iv) or tab.key(ivs, iv)

                                local is_interval = tab.contains(ivs, iv)
                                if ji then is_interval = tab.contains(map, iv) end

                                return is_interval
                            end,
                            value = function() 
                                local ji = mode(i).temperment == 'just'
                                local scl = state(i).scale
                                local ivs = mode(i).scales[scl].iv
                                local map = ji and mode(i).scales[scl].map
                                local iv = (ii-1-tonic(i))%12
                                local deg = ji and tab.key(map, iv) or tab.key(ivs, iv)

                                return deg and state(i).toggles[scl][deg] or 0
                            end,
                            action = function(s, v)
                                local ji = mode(i).temperment == 'just'
                                local scl = state(i).scale
                                local ivs = mode(i).scales[scl].iv
                                local map = ji and mode(i).scales[scl].map
                                local iv = (ii-1-tonic(i))%12
                                local deg = ji and tab.key(map, iv) or tab.key(ivs, iv)

                                if deg then state(i).toggles[scl][deg] = v end
                                redraw()
                            end
                        },
                    }
                end),
                tonic = nest_(12):each(function(ii)
                    return _grid.toggle {
                        x = function() return left + kb.pos[ii].x - 1 end,
                        y = function() return top + 3 + kb.pos[ii].y - 1 end,
                        lvl = { 0, 15 },
                        value = function()
                            return states[i].tonic == (ii - 4)%12+1 and 1 or 0
                        end,
                        action = function(s, v)
                            states[i].tonic = (ii - 4)%12+1
                            redraw()
                        end
                    }
                end),
                --i named this affordance zoink because the z parameter is broken & this causes it to draw in the correct order :)
                zoink = nest_(12):each(function(ii) 
                    local pos = kb.pos[ii]
                    local lvl = 4

                    return nest_ {
                        _grid.fill {
                            x = left + pos.x - 1, y = top + pos.y - 1, lvl = lvl, v = 1,
                        },
                        _grid.fill {
                            x = left + pos.x - 1, y = top + 3 + pos.y - 1, lvl = lvl, v = 1,
                        }
                    }
                end)
            },
            screen = nest_ {
                toggles = nest_(24):each(function(ii2)
                    local ii = ii2/2 + 0.5
                    local mul = 10
                    local p = kb.pos[ii]
                    local xx = 4 + (p.x - 1) * 20
                    local yy = y[1.5] + (p.y - 1) * 10

                    return _txt.label {
                        x = xx, y = yy, 
                        padding = 1.5,
                        lvl = function()
                            local ji = mode(i).temperment == 'just'
                            local scl = state(i).scale
                            local ivs = mode(i).scales[scl].iv
                            local map = ji and mode(i).scales[scl].map
                            local iv = (ii-1-tonic(i))%12
                            local deg = ji and tab.key(map, iv) or tab.key(ivs, iv)

                            local is_interval = tab.contains(ivs, iv)
                            if ji then is_interval = tab.contains(map, iv) end
                            local is_enabled = deg and (state(i).toggles[scl][deg] == 1)
                            local is_tonic = iv==0

                            return is_tonic and 0 or (is_interval and is_enabled) and 15  or 2
                        end,
                        fill = function()
                            local ji = mode(i).temperment == 'just'
                            local scl = state(i).scale
                            local ivs = mode(i).scales[scl].iv
                            local map = ji and mode(i).scales[scl].map
                            local iv = (ii-1-tonic(i))%12
                            local deg = ji and tab.key(map, iv) or tab.key(ivs, iv)

                            local is_interval = ji and tab.contains(map, iv) or tab.contains(ivs, iv)
                            local is_enabled = deg and (state(i).toggles[scl][deg] == 1)
                            local is_tonic = iv==0

                            return (is_interval and is_enabled and is_tonic) and 10  or 0
                        end,
                        v = function()
                            local ji = mode(i).temperment == 'just'
                            local scl = state(i).scale
                            local ivs = mode(i).scales[scl].iv
                            local map = ji and mode(i).scales[scl].map
                            local str = ji and mode(i).scales[scl].string
                            local iv = (ii-1-tonic(i))%12
                            local deg = ji and tab.key(map, iv)

                            return ji and (
                                tab.contains(map, iv) and str[deg] or '.'
                            ) or (
                                tab.contains(ivs, iv)
                                and note_names[(iv+tonic(i))%12+1] or '.'
                            )
                        end
                    }
                end)
            },
            mode = _txt.enc.option {
                x = x[1], y = y[2], n = 2, line_wrap = 2,
                options = modenames,
                value = function() return states[i].mode end,
                action = function(s, v) 
                    states[i].mode = v 
                    grid_redraw()
                end
            }, 
            scale = _txt.enc.number {
                x = x[1], y = y[1], n = 1, wrap = true,
                min = 1, step = 1, inc = 1, max = function() 
                    return #scale_names[modenames[states[i].mode]] 
                end,
                formatter = function(s, v)
                    return scale_names[modenames[states[i].mode]][v]
                end,
                value = function()
                    return state(i).scale
                end,
                action = function(s, v)
                    state(i).scale = v
                    grid_redraw()
                end,
            },
            tuning = _txt.enc.number {
                x = x[2], y = y[2], n = 3, flow = 'y',
                min = 1, max = 12, step = 1, inc = 1,
                value = function()
                    return state(i).tuning[state(i).scale]
                end,
                action = function(s, v)
                    state(i).tuning[state(i).scale] = v
                    grid_redraw()
                end,
                formatter = function(s, v)
                    local ji = mode(i).temperment == 'just'
                    local deg

                    if ji then
                        local scl = state(i).scale
                        local map = mode(i).scales[scl].map
                        local ivs = mode(i).scales[scl].iv
                        local iv = intervals(i)
                        deg = map[tab.key(ivs, iv[(v-1)%#iv+1])]
                    else
                        local iv = intervals(i)
                        deg = iv[(v-1)%#iv+1]
                    end

                    return iv_names[deg+1]
                end
            }
        }
    end):merge(o)
end

return tune, tune_
