using DataFrames
using Test
using InteractiveUtils
using Selections
const s = Selections

@testset "Selections" begin
include("test_selections.jl")
include("test_resolutions.jl")
include("test_select.jl")
end
