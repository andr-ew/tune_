include 'nest_/lib/nest/core'
include 'nest_/lib/nest/norns'
include 'nest_/lib/nest/grid'

include 'tune/lib/tune'



engine.name = 'PolySub'
polysub = include 'we/lib/polysub'
polysub.params()
