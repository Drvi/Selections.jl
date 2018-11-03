
function merge_complements(df, selections, c_idx, c)
    complement_pairs = resolve_complement(c, setdiff(names(df), getnames(selections)))
    vcat(namedpair(selections[1:(c_idx-1)]), complement_pairs, namedpair(selections[c_idx:end]))
end

function postprocess(df, selections::AbstractVector)
    c_idx = findfirst(x -> isa(x, Complement) | isa(x, Pair{Complement,<:Any}), selections)
    c_idx == nothing && return namedpair(selections)
    c = selections[c_idx]
    merge_complements(df, convert(Vector{SymbolSelection}, filter(x->isa(x, SymbolSelection), selections)), c_idx, c)
end

postprocess(df, s::SymbolSelection) = [s.s => s.r]
postprocess(df, selections::Complement) = resolve_complement(selections, names(df))

select(df) = error("Cannot call `select(df)` without any additional arguments for selection.")
select!(df) = error("Cannot call `select!(df)` without any additional arguments for selection.")

function select(df, s...)
    selections = resolve_query(df, [s...])
    selection_pairs = reduce_renames(postprocess(df, selections))
    out = df[[k for (k,f) in selection_pairs]]
    rename!(out, [k => f(k) for (k,f) in selection_pairs])
    out
end

function select!(df, s...)
    selections = resolve_query(df, [s...])
    selection_pairs = reduce_renames(postprocess(df, selections))
    delete!(df, setdiff(names(df), first.(selection_pairs)))
    rename!(out, [k => f(k) for (k,f) in selection_pairs])
    df
end

function rename!(df, s...)
    selections = resolve_query(df, [s...])
    selection_pairs = reduce_renames(postprocess(df, selections))
    rename!(df, [k => f(k) for (k,f) in selection_pairs])
    df
end

function rename(df, s...)
    rename!(copy(df), s)
end

"""
```
select(df, s...) -> df
select!(df, s...) -> df
rename(df, s...) -> df
rename!(df, s...) -> df
```

Select, rename and reorder columns from `df`, a `DataFrame`.

`select` can subset, reorder and rename columns.
`rename` selects all columns in their original order, but can change column names.

All other arguments besides the first one will be interpreted as `Selection`s, those can be:
* of type `Symbol` -- Select a column by name
* of type `Int` -- Positive integer selects a column by its position
* of type `AbstractRange` -- Positive integer ranges select multiple columns by their position
* of type `AbstractArray{Bool}` -- Boolean vector where each element signifies whether the corresponding column should be selected
* `colrange(s1, s2 [; step::Int=1])` -- Select all columns between `s1` and `s2`
* `if_values(predicate::Function)` -- Select all columns where `predicate(column) == true`
  * `if_eltype(t::DataType)` -- Select all columns where `eltype(column) <: t || eltype(column) <: Union{t,Missing}`
* `if_keys(predicate::Function)` -- Select all columns where `predicate(colname) == true`
  * `if_matches(s::Union{AbstractString,Regex})` -- Select all columns where `occursin(s, keys(df)) == true`
* `if_pairs(predicate::Function)` -- Select all columns where `predicate(colname, column) == true`
* `rest()` -- Select all the columns that were not selected by other selections.

You can use the `cols(s...)` function to explicitly convert all of its inputs into
`Selection`s when chaining (see below) multiple `Selection`s together or in case of
negating them. All `Selection`s can be negated by adding a `-`, `!` or `~` in front of them.
Negated `Selection` will select the complement of the columns a non-negated
`Selection` would've chosen.

Furthermore, you can chain different `Selection`s with boolean operators `|` and `&`.
The default chaining operator is `|` as it's consistent with `select(df, :a, :b)` returning
the columns `:a` and `:b` (it returned all columns whose name were `:a` *or* `:b`).
E.g. if you want all the columns whose names contains the string "abc" *and* are not
`Int` vectors, you could call:

    `select(df, if_matches("abc") & -if_eltype(Int))`

`Selection`s can be further put into a `Pair` to modify the name of the selected column
or columns:

* `Selection => r::Symbol` or `Selection => r::Vector{Symbol}`-- If `Selection` returns column or columns, rename them to `r`.
* `Selection => key_preffix(s)` or `Selection => key_suffix(s)` -- Modify all of the selected column names by concatenating string `s` to them
* `Selection => key_map(f::Function)` -- Modify all of the selected columns names by applying function `f` to them.
* `Selection => key_replace(pat=>r)` -- Modify all of the selected columns names by replacing pattern `pat` with `r`.

See also: [`if_keys`](@ref), [`if_values`](@ref), [`key_map`](@ref), [`rest`](@ref)
"""
select, select!, rename, rename!
