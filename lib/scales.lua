local mu = require 'musicutil'
local ji = require 'intonation'
local map12 = {}; for i = 1,12 do map12[i] = i-1 end

local scales = {
    west = {
        temperment = 'equal',
        tones = 12,
        scales = {},
    },
    just = {
        temperment = 'just',
        scales = {
            -- more scales here ? minor scales ?
            { name='pythagorean major', 
                iv={ 1/1, 9/8, 81/64, 4/3, 3/2, 27/16, 243/128 },
                map = { 0, 2, 4, 5, 7, 9, 11, },
                string={ '1:1', '9:8', '81:64', '4:3', '3:2', '27:16', '243:128' }
            },
            { 
                name= '12-tone normal', iv=ji.normal(), map=map12, 
                string={ '1:1', '16:15', '9:8', '6:5', '5:4', '4:3', '45:32', '3:2', '8:5', 
                '5:3', '16:9', '15:8', },
            }, 
            { 
                name= '12-tone ptolemy', iv=ji.ptolemy(), map=map12,
                string={ '1:1', '16:15', '9:8', '6:5', '5:4', '4:3', '45:32', '3:2', '8:5', 
                '5:3', '9:5', '15:8', }
            }, 
            { 
                name= '12-tone overtone', iv=ji.overtone(), map=map12,
                string={ '1:1', '16:15', '9:8', '6:5', '5:4', '4:3', '45:32', '3:2', '8:5', 
                '5:3', '9:5', '15:8' }
            }, 
            { 
                name= '12-tone undertone', iv=ji.undertone(), map=map12,
                string={ '1:1', '16:15', '8:7', '32:27', '16:13', '4:3', '16:11', '32:21', 
                '8:5', '32:19', '16:9', '32:17', }
            },
        },
    },
    maqam = {
        temperment = 'equal',
        tones = 12,

        -- could defnintely use some more maqamat !
        scales = {
            --1st jins      2nd jins
            { name = 'Bayati (Jins Nahawand)', iv = { 0, 1.5, 3, 5, 7, 8, 10, }},
            { name = 'Bayati (Jins Rast)', iv = { 0, 1.5, 3, 5, 7, 8.5, 10, }},
            { name = 'Bayati Shuri', iv = { 0, 1.5, 3, 5, 6, 9.5, 10, }},
            { name = 'Hijaz (Jins Nahawand)', iv = { 0, 1, 4, 5, 7, 8, 10, }},
            { name = 'Hijaz (Jins Rast)', iv = { 0, 1, 4, 5, 7, 8.5, 10, }},
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
    scales.west.scales[i] = scl
end
-- put major pentatonic & minor pentatonic in front
table.insert(scales.west.scales, 1, table.remove(scales.west.scales, minp))
table.insert(scales.west.scales, 1, table.remove(scales.west.scales, majp+1))

return scales
