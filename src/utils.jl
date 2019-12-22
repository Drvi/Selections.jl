@inline colnames(table)::Vector{Symbol} = collect(propertynames(columns(table)))
@inline getcol(table, x) = getproperty(columns(table), x)


function subset_cols(table, cols::Tuple{Vararg{Symbol}})
    nt = columntable(table)
    newcols = NamedTuple{cols}(nt)
    materializer(table)(newcols)
end
function subset_cols(table::NamedTuple, cols::Tuple{Vararg{Symbol}})
    NamedTuple{cols}(table)
end
subset_cols(table, cols::Symbol...) = subset_cols(table, cols)

subset_cols(table, cols::Tuple{Vararg{Symbol,0}}) = table

ensure_tuple(x) = tuple(x)
ensure_tuple(x::Tuple) = x
ensure_tuple(x::AbstractArray) = Tuple(x)
