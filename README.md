# Selections

This package is a working API proposal for selecting columns from Tables.
Specifically, it implements a function `select(df, s...)` that lets you select, rename and reorder columns from `df`, a `DataFrame`. `select()`s cannot create new columns and it also cannot select one column multiple times.

All other arguments to `select()` besides the first one will be interpreted as `Selection`s;
those can be:
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

* `Selection => r::Symbol`  or `Selection => r::Vector{Symbol}`-- If `Selection` returns column or columns, rename them to `r`.
* `Selection => key_preffix(s)` or `Selection => key_suffix(s)` -- Modify all of the selected column names by concatenating string `s` to them
* `Selection => key_map(f::Function)` -- Modify all of the selected columns names by applying function `f` to them.
* `Selection => key_replace(pat=>r)` -- Modify all of the selected columns names by replacing pattern `pat` with `r`.

## Examples

```julia
using Selections, DataFrames, Dates
df = DataFrame(x1 = randn(100), x2 = randn(100), c = today() + Week.(1:100),
               y = rand(0:1, 100), t = rand(1:100, 100), z = rand([Missing, "t"], 100));

# You can select columns by their names
select(df, :y, if_matches(r"\d$"))
100×3 DataFrame
│ Row │ y     │ x1        │ x2        │
│     │ Int64 │ Float64   │ Float64   │
├─────┼───────┼───────────┼───────────┤
│ 1   │ 0     │ 0.886387  │ 0.686522  │
│ 2   │ 1     │ 1.06553   │ -0.16702  │
│ 3   │ 0     │ -0.465344 │ -1.40936  │
⋮
```
The query above translates to "select a column named `:y`" *or* "all the columns whose names
end with a digit". Other equivalent ways of writing this query would be:

```julia
select(df, cols(:y, if_matches(r"\d$")))
select(df, cols(:y) | if_matches(r"\d$"))
select(df, cols(:y), if_matches(r"\d$"))
```
because `cols()` resolves `Selection`s with an `|`. Note that you cannot call `:y | :t` directly
as defining such method would be type piracy, so in order to combine `Selection`s you need to wrap them in `cols()`
first.

Combining all conditions with an `|` might not be always convenient. E.g.:
```julia
# This should be pretty standard
select(df, 1, 2)
100×2 DataFrame
│ Row │ x1        │ x2        │
│     │ Float64   │ Float64   │
├─────┼───────────┼───────────┤
│ 1   │ 0.886387  │ 0.686522  │
│ 2   │ 1.06553   │ -0.16702  │
⋮
# On the other hand, when we want deselect multiple columns...
select(df, -1, -2)
100×6 DataFrame
│ Row │ x2        │ c          │ y     │ t     │ z       │ x1        │
│     │ Float64   │ Date       │ Int64 │ Int64 │ Any     │ Float64   │
├─────┼───────────┼────────────┼───────┼───────┼─────────┼───────────┤
│ 1   │ 0.686522  │ 2018-11-04 │ 0     │ 1     │ t       │ 0.886387  │
│ 2   │ -0.16702  │ 2018-11-11 │ 1     │ 5     │ Missing │ 1.06553   │
│ 3   │ -1.40936  │ 2018-11-18 │ 0     │ 85    │ t       │ -0.465344 │
⋮
```
Yikes! What happened? Well the first condition says "select all columns whose index is not 1" and the first
five columns actually do this, but then we added: ... *or* "select all columns whose index is not 2" -- and since no column can have two distinct indices, the `|` will also include `:x1` because it indeed satisfies the second condition.

Ok, so how do we actually deselect the first two columns? Here are a couple of options:
```julia
select(df, not(1, 2))
select(df, -colrange(1, 2))
select(df, -cols(1) & -cols(2))
```
The `not()` wrapper is like `cols()` but it *negates* all its inputs and it resolves them with `&`. The new query then says "select all columns whose index is not 1" *and* "select all columns whose index is not 2", which is what we wanted.


```julia
# Or by their positions -- use negation to deselect columns
select(df, -2)
100×5 DataFrame
│ Row │ x1        │ c          │ y     │ t     │ z       │
│     │ Float64   │ Date       │ Int64 │ Int64 │ Any     │
├─────┼───────────┼────────────┼───────┼───────┼─────────┤
│ 1   │ 0.886387  │ 2018-11-04 │ 0     │ 1     │ t       │
│ 2   │ 1.06553   │ 2018-11-11 │ 1     │ 5     │ Missing │
│ 3   │ -0.465344 │ 2018-11-18 │ 0     │ 85    │ t       │
⋮
# Or by their positions
select(df, if_matches(r"\d$") & not(2))
100×1 DataFrame
│ Row │ x1        │
│     │ Float64   │
├─────┼───────────┤
│ 1   │ 0.886387  │
│ 2   │ 1.06553   │
│ 3   │ -0.465344 │
⋮
```

You can also rename columns by creating a pair from `Selection` to `Renaming` object.
Since each renaming instruction is paired to a Selection source, you can apply multiple renamings
if there is an overlap between the selections, e.g.:
```julia
select(df, if_eltype(Number) => key_suffx("_num"), :t => key_prefix("idx_"))
100×4 DataFrame
│ Row │ x1_num    │ x2_num    │ y_num │ idx_t_num │
│     │ Float64   │ Float64   │ Int64 │ Int64     │
├─────┼───────────┼───────────┼───────┼───────────┤
│ 1   │ 0.886387  │ 0.686522  │ 0     │ 1         │
│ 2   │ 1.06553   │ -0.16702  │ 1     │ 5         │
│ 3   │ -0.465344 │ -1.40936  │ 0     │ 85        │
⋮
```

## Implementation
In order to support `select()` for different table types than `DataFrame`s, you need to
specify following methods:
```julia
names(df)::Vector{Symbol}             # Column names
getindex(df, x::Symbol)               # Index into df by symbols (returns a column)
getindex(df, x::Vector{Symbol})       # Index into df by symbols (returns a df)
rename!(df, x::Pair{Symbol=>Symbol})  # Inplace column renaming
delete!(df, x::Vector{Symbol})        # Inplace column deletion (for select!() only)
```

## TODO:
* `rename(df, s...)` -- function that always selects all columns in their original order, but can change column names
* `order(df, s...)` -- function that always selects all columns with their original names, but can change their order
* Functionality that changes column values will be implemented in a different package

## Acknowledgement

This work was heavily inspired by the R [tidyselect](https://github.com/tidyverse/tidyselect) package.
