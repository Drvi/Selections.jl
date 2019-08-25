using DataFrames
using Test
using InteractiveUtils
using Selections
const s = Selections

const df = DataFrame(a = 1:4, b = 'a':'d', c1 = [[float(i)] for i in 1:4])

@testset "Selections" begin
    include("test_selections.jl")
    include("test_resolutions.jl")
    include("test_select.jl")
    include("test_rename.jl")
end
