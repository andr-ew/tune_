-- lua config file for (teeny bit of) arabic maqam scales.
-- if you want to transpose more: https://maqamworld.com/en/maqam
-- contributions welcome :)
--
-- anything beginning in "--" is a comment (not read by the script)
-- 'strings' (words) are surrounded by quotes
-- lists are comma (,) separated & surrounded by braces {  }

root = 440

temperment = 'equal' -- possible values: 'euqal' or 'just'
tones = 24

tonics = { 
    -9,
}

-- note names in 24-tet for reference
-- c, c#, d, d#, e,  f,  f#,  g,  g#,  a,  a#,  b,  bh#, chf
-- 0, 2,  4, 6,  8,  10, 12,  14, 16,  18, 20,  22, 23,  24

scales = {
    { 4, 7, 10, 14, 18, 20, 24, },
    { 4, 7, 10, 14, 18, 21, 24, },
    { 4, 7, 10, 14, 16, 23, 24, },
    { 4, 6, 12, 14, 18, 20, 24, },
    { 4, 6, 12, 14, 18, 21, 24, }
}

-- an optional name for each scale (in the same order as scales)
scale_names = {
    'Bayati (Jins Nahawand)',
    'Bayati (Jins Rast)',
    'Bayati Shuri',
    'Hijaz (Jins Nahawand)',
    'Hijaz (Jins Rast)',
}
