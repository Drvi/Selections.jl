
module Selections
    using DataFrames
    import Base: &, -, |, !, ~, iterate
    export select, select!,
           rename, rename!,
           cols, not,
           if_matches, if_keys, if_values, if_pairs, if_eltype, colrange,
           rest,
           key_prefix, key_suffix, key_map, key_replace

    include("selection_types.jl")
    include("utils.jl")
    include("resolutions.jl")
    include("chaining.jl")
    include("select.jl")
end
