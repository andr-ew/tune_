-- lua config file with some just intonnation tunings. 
--
-- anything beginning in "--" is a comment (not read by the script)
-- 'strings' (words) are surrounded by quotes
-- lists are comma (,) separated & surrounded by braces {  }

root = 220

temperment = 'just' --possible values: 'euqal' or 'just'

scales = {
    { 1/1, 9/8, 6/5, 5/4, 4/3, 3/2, 5/3, 15/8 },
    { 1/1, 9/8, 81/64, 4/3, 3/2, 27/16, 243/128 },
    { 1/1, 16/15, 9/8, 6/5, 5/4, 4/3, 45/32, 3/2, 8/5, 5/3, 16/9, 15/8, },
    { 1/1, 16/15, 9/8, 6/5, 5/4, 4/3, 45/32, 3/2, 8/5, 5/3, 9/5, 15/8, },
    { 1/1, 16/15, 9/8, 6/5, 5/4, 4/3, 45/32, 3/2, 8/5, 5/3, 9/5, 15/8 },
    { 1/1, 16/15, 8/7, 32/27, 16/13, 4/3, 16/11, 32/21, 8/5, 32/19, 16/9, 32/17, }
}

-- an optional name for each scale (in the same order as scales)
scale_names = {
    'ptolematic major',
    'pythagorean major',
    '12-tone normal',
    '12-tone ptolemaic',
    '12-tone overtone',
    '12-tone undertone',
}
