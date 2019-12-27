module Selections

import Base: !, ~, -
using Base.Broadcast: broadcasted, materialize, materialize!
using Tables: columns, columntable, materializer, rowtable, schema

export select #, select_colnames, select_renames, rename, subset, transform
export col, cols, not #, if_keys, if_values, if_pairs, if_eltype, if_matches, colrange
export alias #, key_map, key_prefix, key_replace, key_suffix
export all_cols, other_cols, else_cols
export bycol, bycol!, byrow, byrow!, bytab, bytab!


include("utils.jl")
include("types/function_composition.jl")

include("types/abstract.jl")
include("types/context_selection.jl")
include("types/renaming.jl")
include("types/intermediate_containers.jl")
include("types/selection.jl")
include("types/transformation.jl")
include("types/chaining.jl")

include("resolving/input_conversions.jl")
include("resolving/chaining.jl")
include("resolving/resolving.jl")
include("resolving/select.jl")

end # module
