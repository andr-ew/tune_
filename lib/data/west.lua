-- lua config file for western tuning. 
--
-- anything beginning in "--" is a comment (not read by the script)
-- 'strings' (words) are surrounded by quotes
-- lists are comma (,) separated & surrounded by braces {  }

root = 440 -- A440

temperment = 'equal' -- possible values: 'euqal' or 'just'
tones = 12 -- the number of octave divisions

tonics = { 
    -9, --C
    -8, --C#
    -7, --D
    -6, --D#
    -5, --E
    -4, --F
    -3, --F#
    -2, --G
    -1, --G#
    0,  --A
    1,  --A#
    2,  --B
}

-- in 12-tet, each number is the number of semitones, starting from 0 (the tonic)
scales = {
    { 0, 2, 4, 7, 9, },
    { 0, 3, 5, 7, 10, },
    { 0, 2, 4, 5, 7, 9, 11, },
    { 0, 2, 3, 5, 7, 8, 10, },
    { 0, 2, 3, 5, 7, 8, 11, }
    { 0, 2, 3, 5, 7, 9, 11, },
    { 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, }
}

-- an optional name for each scale (in the same order as scales)
scale_names = {
    'Major Pentatonic',
    'Minor Pentatonic',
    'Major',
    'Natural Minor',
    'Harmonic Minor',
    'Melodic Minor',
    'Chromatic',
}
