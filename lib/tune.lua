local mu = require 'musicutil'
local ji = require 'intonation'

local presets = 8

local states = {}
local function state(pre)
    return states[pre][modenames[states[pre].mode]]
end

local modenames = { 'west', 'just', 'maqam' }
local modes = {
    west = {
        temperment = 'equal',
        tones = 12,
        scales = {},
    },
    just = {
        temperment = 'just'
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
        if vv ~= 12 then table.insert(scl, vv) end
    end
    if scl.name == 'Major Pentatonic' then majp = i end
    if scl.name == 'Minor Pentatonic' then minp = i end
    modes.west.scales[i] = scl
end
-- put major pentatonic & minor pentatonic in front
table.insert(modes.west.scales, 1, table.remove(modes.west.scales, minp))
table.insert(modes.west.scales, 1, table.remove(modes.west.scales, majp))

local function mode(pre)
    return modes[modenames[math.floor(states[pre].mode)]]
end

local scale_names = {}
for k,v in pairs(modes) do
    scale_names[k] = {}
    for i, vv in ipairs(v.scales) do
        scale_names[i] = vv.name
    end
end

local function init_state()
    for i = 1, presets do
        states[i] = {
            mode = 1, --west
            tonic = 3, --D
        }
        for k,_ in pairs(modes) do
            states[i][k] = {
                scale = 1,
                tuning = {},
                toggles = {}
            }
            local tuning = states[i][k].tuning
            local toggles = states[i][k].toggles

            for ii,vv in ipairs(modes[k].scales) do
                tuning[ii] = 1
                toggles[ii] = {}
                for iii, vvv in ipairs(modes[k].scales.iv) do
                    toggles[ii][iii] = 1
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
    return states[pre].tonic
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
for i = 1, 12 do tonic_names[i] = note_names[i] end

local function tuning(pre)
    local scl = state(pre).scale
    return state(pre).tuning[scl]
end

local function intervals(pre)
    local scl = state(pre).scale
    local all = mode(pre).scales[scl]
    local some = {}
    for i,v in ipairs(all) do
        if state(pre).toggles[scl][i] > 0 then 
            table.insert(some, v)
        end
    end
    if #some == 0 then table.insert(some, all[1]) end
    return some
end
local function tonic(pre)
    return tune.tonics[math.min(params:get('tune_tonic_'..pre), #tune.tonics)]
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
    local rowint = tuning() - 1
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

    --TODO just intonnation
    return 2^(tonic(pre)/tune.tones) * 2^oct * 2^(iv[deg]/mode(pre).tones)
end

--TODO
tune.volts = function() end

--TODO
tune.midi = function() end

local function west(rooted)
    return (tune.root % 110 == 0 or (not rooted))
    and tune.temperment=='equal' 
    and tune.tones==12 
end

tune.is_western = west

return function(arg)
    presets = arg.presets or presets
    --TODO: arg.modes

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
                mode_tab = _txt.encoder.option {
                    x = 0, y = top,
                    options = modenames,
                    value = function() return states[i].mode end,
                    action = function(s, v) states[i].mode = v end
                },
                mode = nest_(#modenames):each(function(j)
                    local k = modenames[j]
                    local st = states[i][k]

                    return nest_ {
                        enabled = function() return math.floor(states[i].mode)==j end,

                        toggles = nest_(#modes[k].scales):each(function(iii)
                            local scale = modes[k].scales[iii].iv

                            return nest_(#scale):each(function(ii)
                                local function pos(ax)
                                    local r = kb.pos[
                                       (scale[ii] + tonic(i)) % 12 + 1
                                    ]
                                    return r[ax]
                                end
                                return _grid.toggle {
                                    x = function() return left + pos('x') - 1 end,
                                    y = function() return top + 3 + pos('y') - 1 end,
                                    lvl = { 8, 15 },
                                    value = function() 
                                        return st.toggles[iii][ii]
                                    end,
                                    action = function(s, v)
                                        st.toggles[iii][ii] = v
                                        redraw()
                                    end
                                }
                            end):merge { 
                                enabled = function() 
                                    return iii = st.scale
                                end,
                            }
                        end),
                        --i named this affordance zoink because the z parameter is broken & this causes it to draw in the correct order :)
                        zoink = nest_(12):each(function(ii) 
                            local pos = kb.pos[ii]
                            local lvl = 4

                            return _grid.fill {
                                x = left + pos.x - 1, y = top + 3 + pos.y - 1, lvl = lvl, v = 1,
                            }
                        end),
                        screen = nest_ {
                            preset = nest_ {
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
                            options = _txt.enc.list {
                                n = 2,
                                x = { x[2], 128 }, y = y[2], flow = 'y',
                                sens = 0.5,
                                items = nest_ {
                                    _txt.enc.option {
                                        label = 'tonic',
                                        options = tonic_names,
                                        value = function()
                                            return states[i].tonic
                                        end,
                                        action = function(s, v)
                                            states[i].tonic = v
                                        end
                                    },
                                    _txt.enc.option {
                                        label = 'scale',
                                        options = scale_names[k],
                                        value = function()
                                            return st.scale
                                        end,
                                        action = function(s, v)
                                            st.scale = v
                                        end
                                    },
                                    _txt.enc.option {
                                        label = 'tuning',
                                        options = iv_names,
                                        value = function()
                                            return st.tuning[st.scale]
                                        end,
                                        action = function(s, v)
                                            st.tuning[st.scale] = v
                                        end
                                    }
                                }:each(function(k, v) v.n = 3 end)
                            },
                            toggles = nest_(#modes[k].scales):each(function(iii) 
                                local ivs = modes[k].scales[iii].iv

                                return nest_(12):each(function(ii)
                                    local mul = 10
                                    local p = kb.pos[ii]
                                    local xx = (p.x - 1) * mul + x[2]
                                    local yy = y[4 + p.y]

                                    return _txt.label {
                                        x = xx, y = yy, 
                                        padding = 1.5,
                                        lvl = function()
                                            local iv = (
                                                ii-1-tonic(i)
                                            )%12
                                            local deg = tab.key(ivs, iv)

                                            local is_interval = tab.contains(ivs, iv)
                                            local is_enabled = deg and (st.toggles[iii][ii] == 1)
                                            local is_tonic = iv==0

                                            return is_tonic and 0 or (is_interval and is_enabled) and 15  or 2
                                        end,
                                        fill = function()
                                            local iv = (
                                                ii-1-tonic(i)
                                            )%12
                                            local deg = tab.key(ivs, iv)

                                            local is_interval = tab.contains(ivs, iv)
                                            local is_enabled = deg and (st.toggles[iii][ii] == 1)
                                            local is_tonic = iv==0

                                            return (is_interval and is_enabled and is_tonic) and 10  or 0
                                        end,
                                        v = function()
                                            local iv = (
                                                ii-1-tonic(i)
                                            )%12
                                            return tab.contains(ivs,  iv)
                                            and note_names[ii] or '.'
                                        end
                                    }
                                end):merge { 
                                    enabled = function() 
                                        return iii == state(i).scale
                                    end,
                                }
                            end)
                        }
                    }
                end)
            }
        end):merge(o)
    end
end
