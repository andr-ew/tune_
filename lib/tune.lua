local mu = require 'musicutil'
local ji = require 'intonation'

local presets = 8
local modenames = { 'west', 'just', 'maqam' }

local states = {}
local function state(pre)
    return states[pre][modenames[states[pre].mode]]
end

local modes = {
    west = {
        temperment = 'equal',
        tones = 12,
        scales = {},
    },
    just = {
        temperment = 'just',
        scales = {
            -- more scales here ? minor scales ?
            { name='ptolematic major', iv={1/1, 9/8, 6/5, 5/4, 4/3, 3/2, 5/3, 15/8 }},
            { name='pythagorean major', iv={1/1, 9/8, 81/64, 4/3, 3/2, 27/16, 243/128 }},
            { name= '12-tone normal', iv=ji.normal() }, 
            { name= '12-tone ptolemy', iv=ji.ptolemy() }, 
            { name= '12-tone overtone', iv=ji.overtone() }, 
            { name= '12-tone undertone', iv=ji.undertone() }, 
            { name= '12-tone lamonte', iv=ji.lamonte() }, 
        },
    },
    maqam = {
        temperment = 'equal',
        tones = 12,

        -- could defnintely use some more maqamat !
        scales = {
            --1st jins      2nd jins
            { name = 'Bayati (Jins Nahawand)', iv = { 2, 3.5, 5, 7, 9, 10, 12, }},
            { name = 'Bayati (Jins Rast)', iv = { 2, 3.5, 5, 7, 9, 10.5, 12, }},
            { name = 'Bayati Shuri', iv = { 2, 3.5, 5, 7, 8, 11.5, 12, }},
            { name = 'Hijaz (Jins Nahawand)', iv = { 2, 3, 6, 7,   9, 10, 12, }},
            { name = 'Hijaz (Jins Rast)', iv = { 2, 3, 6, 7,   9, 10.5, 12, }},
        }
    }
}
local majp, minp
for i,v in ipairs(mu.SCALES) do
    local scl = { name=v.name, iv = {} }
    for ii,vv in ipairs(v.intervals) do
        if vv ~= 12 then table.insert(scl.iv, vv) end
    end
    if scl.name == 'Major Pentatonic' then majp = i end
    if scl.name == 'Minor Pentatonic' then minp = i end
    modes.west.scales[i] = scl
end
-- put major pentatonic & minor pentatonic in front
table.insert(modes.west.scales, 1, table.remove(modes.west.scales, minp))
table.insert(modes.west.scales, 1, table.remove(modes.west.scales, majp+1))

local function mode(pre)
    return modes[modenames[math.floor(states[pre].mode)]]
end

local scale_names = {}
for k,v in pairs(modes) do
    scale_names[k] = {}
    for i, vv in ipairs(v.scales) do
        scale_names[k][i] = vv.name
    end
end

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
                    --print('huh', i, ii, iii)
                    states[i][k].toggles[ii][iii] = 1
                    --print('err', states[i][k].toggles[ii][iii])
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
    print('iv', iv[deg] + tonic(pre))

    --TODO just intonnation
    return 2^(tonic(pre)/mode(pre).tones) * 2^oct * 2^(iv[deg]/mode(pre).tones)
end

--TODO
tune.volts = function() end

--TODO
tune.midi = function() end

return function(arg)
    presets = arg.presets or presets
    --TODO: arg.modes (whether to have modes or fixed as west)

    --TODO: load state (from path arg.data)
    init_state()

    --TODO: arg.tonic (whether to add the tonic option)
    
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

        return nest_(presets):each(function(i) 
            return nest_ {
                grid = nest_ {
                    toggles = nest_(12):each(function(ii)
                        return nest_ {
                            mutes = _grid.toggle {
                                x = function() return left + kb.pos[ii].x - 1 end,
                                y = function() return top + kb.pos[ii].y - 1 end,
                                lvl = { 8, 15 },
                                enabled = function()
                                    local ivs = mode(i).scales[state(i).scale].iv
                                    local iv = (ii-1-tonic(i))%12
                                    return tab.contains(ivs,  iv)
                                end,
                                value = function() 
                                    local scl = state(i).scale
                                    local ivs = mode(i).scales[scl].iv
                                    local iv = (ii-1-tonic(i))%12
                                    local deg = tab.key(ivs, iv)
                                    return deg and state(i).toggles[scl][deg] or 0
                                end,
                                action = function(s, v)
                                    local scl = state(i).scale
                                    local ivs = mode(i).scales[scl].iv
                                    local iv = (ii-1-tonic(i))%12
                                    local deg = tab.key(ivs, iv)
                                    if deg then state(i).toggles[scl][deg] = v end
                                    redraw()
                                end
                            },
                            tonic = _grid.toggle {
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
                    toggles = nest_(12):each(function(ii)
                        local mul = 10
                        local p = kb.pos[ii]
                        local xx = (p.x - 1) * mul + x[2]
                        local yy = y[4 + p.y]

                        return _txt.label {
                            x = xx, y = yy, 
                            padding = 1.5,
                            lvl = function()
                                local scl = state(i).scale
                                local ivs = mode(i).scales[scl].iv
                                local iv = (ii-1-tonic(i))%12
                                local deg = tab.key(ivs, iv)

                                local is_interval = tab.contains(ivs, iv)
                                local is_enabled = deg and (state(i).toggles[scl][deg] == 1)
                                local is_tonic = iv==0

                                return is_tonic and 0 or (is_interval and is_enabled) and 15  or 2
                            end,
                            fill = function()
                                local scl = state(i).scale
                                local ivs = mode(i).scales[scl].iv
                                local iv = (ii-1-tonic(i))%12
                                local deg = tab.key(ivs, iv)

                                local is_interval = tab.contains(ivs, iv)
                                local is_enabled = deg and (state(i).toggles[scl][deg] == 1)
                                local is_tonic = iv==0

                                return (is_interval and is_enabled and is_tonic) and 10  or 0
                            end,
                            v = function()
                                local scl = state(i).scale
                                local ivs = mode(i).scales[scl].iv
                                local iv = (ii-1-tonic(i))%12
                                return tab.contains(ivs,  iv)
                                and note_names[ii] or '.'
                            end
                        }
                    end)
                },
                options = _txt.enc.list {
                    n = 2,
                    x = { x[2], 128 }, y = y[2], flow = 'y',
                    sens = 0.5,
                    items = nest_ {
                        _txt.enc.option {
                            label = 'mode',
                            options = modenames,
                            value = function() return states[i].mode end,
                            action = function(s, v) states[i].mode = v end
                        },
                        -- _txt.enc.option {
                        --     label = 'tonic',
                        --     options = tonic_names,
                        --     value = function()
                        --         return states[i].tonic
                        --     end,
                        --     action = function(s, v)
                        --         states[i].tonic = v
                        --         grid_redraw()
                        --     end
                        -- },
                        _txt.enc.option {
                            label = 'scale',
                            options = function() return scale_names[modenames[states[i].mode]] end,
                            value = function()
                                return state(i).scale
                            end,
                            action = function(s, v)
                                state(i).scale = v
                                grid_redraw()
                            end
                        },
                        _txt.enc.number {
                            label = 'tuning',
                            min = 1, max = 12, step = 1, inc = 1,
                            value = function()
                                return state(i).tuning[state(i).scale]
                            end,
                            action = function(s, v)
                                state(i).tuning[state(i).scale] = v
                                grid_redraw()
                            end,
                            formatter = function(s, v)
                                local iv = intervals(i)
                                return iv_names[iv[(v-1)%#iv+1]+1]
                            end
                        }
                    }:each(function(k, v) v.n = 3 end)
                },
            }
        end):merge(o)
    end
end
