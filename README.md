# Selections.jl

This package is a working API proposal for a unified `SELECT` operations on columnar [Tables](https://github.com/JuliaData/Tables.jl).

The main function is `select(tab, args...; kwargs...)` which allows you to apply complex transformations to your table. Use `args...` to apply layered transformations to your current columns and `kwargs...` to create new columns.  

## Install

The package is not yet registered. To install it, use:
```
] add https://github.com/Drvi/Selections.jl
```

## Usage

The key goal of the package is to be able to refer to columns not by just their names or positions, but also by their properties (like their `eltype` or fraction of values missing) and use this increased expressivity to ease data munging activities.

### Simple things are simple

```julia
# selects the :a column (select always returns a table)
select(tab, :a)
# selects the first and the :g column. If they coincide, only one column is returned
select(tab, 1, :g)  
# select all the columns except those between :f and :h
select(tab, -colrange(:f, :h))
# create new column :timestamp from :year, :month and :day columns
select(tab, timestamp = (:year, :month, :day) => byrow.((row, _) -> Date(row...)))
```

### Complex things are possible

The `args...` can be used to chain commands to modify to the current columns of a table, these commands are of form:

<p align="center">
    <code><strong>
        selection => renaming => transformation
    </code></strong>
</p>

[`selection`s](https://github.com/Drvi/Selections.jl#selections) are expressions that identify which columns to work with. [`renaming`s](https://github.com/Drvi/Selections.jl#renamings) are functions applied to the corresponding column names and [`transformation`s](https://github.com/Drvi/Selections.jl#transformations) are functions applied to the corresponding column values.

You can also provide multiple such commands and combine them together with `|`, `&` or `-`. This will apply the renaming and transforming operations on the union, intersection or set difference of the columns selected. To make sure to avoid type piracy, you can wrap your selection statements in `cols`.

Using `kwargs...` you can create new columns as a function of of all other columns present in the table (including those you've just defined using a any previous key word arguments). These expressions have the following form:

<p align="center">
    <code><strong>
        column_name = selection => transformation
    </code></strong>
</p>

You can also provide multiple such expressions, and all the columns that were created will be available to the expressions that are evaluated after them.

That being said, let's have a look at a more complex example:

```julia
using DataFrames: DataFrame
using Statistics
using Selections

df = DataFrame(a = 1.0:4.0, b = 'a':'d', A = 10:13)
# 4×3 DataFrame
# │ Row │ a       │ b    │ A     │
# │     │ Float64 │ Char │ Int64 │
# ├─────┼─────────┼──────┼───────┤
# │ 1   │ 1.0     │ 'a'  │ 10    │
# │ 2   │ 2.0     │ 'b'  │ 11    │
# │ 3   │ 3.0     │ 'c'  │ 12    │
# │ 4   │ 4.0     │ 'd'  │ 13    │

select(df,
    # Select the column :a and mark the other columns with a "prefix_" and increment their values
    col(:a) | (else_cols() => key_prefix("prefix_") => bycol.(x->x + 1)),
    # Select the column :b and mark the other columns with a "_suffix" and double their values
    col(:b) | (else_cols() => key_suffix("_suffix") => bycol.(x->2x))
)
# 4×3 DataFrame
# │ Row │ a_suffix │ prefix_b │ prefix_A_suffix │
# │     │ Float64  │ Char     │ Int64           │
# ├─────┼──────────┼──────────┼─────────────────┤
# │ 1   │ 2.0      │ 'b'      │ 22              │
# │ 2   │ 4.0      │ 'c'      │ 24              │
# │ 3   │ 6.0      │ 'd'      │ 26              │
# │ 4   │ 8.0      │ 'e'      │ 28              │

scale(x) = (m = mean(x); (x .- m) ./ std(x, mean=m))

select(df,
    # To generalize, we might want to add "prefix_" to all non Float64 columns, not just :a.
    # While we're at it, we can standardize the float columns.
    (cols(Float64) => bycol(scale)) | (else_cols() => key_prefix("prefix_") => bycol.(x->x + 1)),
    # To generalize, we might want to add "_suffix" to all non Numeric columns, not just :b.
    # While we're at it, we can also add a suffix to the non Numeric columns.
    (not(Number) => key_suffix("_id")) | (else_cols() => key_suffix("_suffix") => bycol.(x->2x))
)
# 4×3 DataFrame
# │ Row │ a_suffix  │ prefix_b_id │ prefix_A_suffix │
# │     │ Float64   │ Char        │ Int64           │
# ├─────┼───────────┼─────────────┼─────────────────┤
# │ 1   │ -2.32379  │ 'b'         │ 22              │
# │ 2   │ -0.774597 │ 'c'         │ 24              │
# │ 3   │ 0.774597  │ 'd'         │ 26              │
# │ 4   │ 2.32379   │ 'e'         │ 28              │
```

## How it works

What follows is a short reference of the exported functions.

### Selections

| Example in `select(tab, ...)`                           | Selects
|---------------------------------------------------------|---------------------
| `1`                                                     | the first column
| `:a`                                                    | the column `:a`
| `cols(:a, :b)`  # or  `cols(:a) \| cols(:b)`            | the columns `:a` and `:b`
| `not(:a, :b)`  # or  `!cols(:a) & !cols(:b)`            | the columns other than `:a` and `:b`
| `1:2:3`                                                 | the first and third columns
| `colrange(:d, :a, 2)`                                   | every other column between `:d` and `:a`
| `[true, false, true]`                                   | the first and third columns
| `if_values(v -> mean(ismissing.(v)) > 0.5)`             | columns having more than 50 % missing values
| `if_eltype(Real)`  # or just `Real`                     | all columns with eltype `T <: Union{Real,Missing}`
| `if_keys(k -> length(k) > 5)`                           | columns with names longer than 5 letters
| `if_matches(r"\d")`  # or just `r"\d"`                  | column whose name contains a digit
| `if_pairs((k,v) -> occursin("id", k) && minimum(v) > 0)` | columns whose names contains "id" and that also have a positive minimum values

All these selections can be inverted with a `!` or a `not()` function so that they match the complement of the columns they would match otherwise. There are also special selections like `all_cols()`, `other_cols()` (the columns that were not selected in any other part of the selection query) and `else_cols()` (the columns that the previous selection query didn't capture).

The thing to remember about chaining selections is that they behave according to as boolean operators applied to sets:
`cols(:a) | cols(:b)` give you both `:a` and `:b`, but `cols(:a) | !cols(:b)` or `cols(:a) | not(:b)` will return all the columns as one of the conditions must be true for each of them.

### Renamings

| Example in `select(tab, ...)`    | Meaning
|----------------------------------|----------------------
| `s => :A`                        | Rename column to `:A`
| `s => [:A, :C]`                  | Rename columns to `:A`, `:B` (ignore if `s` doesn't match 2 columns)
| `s => key_replace(r"a" => s"b")` | Replace the letter "a" with "b" in column names of `s`
| `s => key_map(uppercase)`        | Map names of `s` to upper case
| `s => key_prefix("pre_")`        | Add prefix "pre_" to column names of `s`
| `s => key_suffix("_dt")`         | Add suffix "_dt" to column names of `s`

If renaming results in non-unique names, a integer suffix will be added to modified column names that will ensure uniqueness and a warning describing these changes will be issued. If you supply an array of new column names that is of different length than the corresponding selection, the renaming will be skipped and a warning will be issued.

### Transformations

| Example in `select(tab, ...)`                              | Meaning
|------------------------------------------------------------|----------------------
| `s => bycol(x -> x .- mean(x))`                                 | Center every selected column
| `s => bycol!(x -> x .- mean(x)) `                               | ^ inplace (if the resulting type permits)
| `s => bycol.(x -> x + 1)`                                       | Add 1 to every element of selected columns
| `s => bycol!.(x -> x + 1)`                                      | ^ inplace (if the resulting type permits)
| `s => byrow((rowtable, name) -> f(rowtable, name)`              | Apply `f` to a vector of namedtuples (the `rowtable`), with `name` being the name of the current column
| `s => byrow!((rowtable, name) -> f(rowtable, name))`            | ^ inplace (if the resulting type permits)
| `s => byrow.((row, name) -> row[name] - row.a`                  | Subtract `:a` from each selected column
| `s => byrow!.((row, name) -> row[name] - row.a`                 | ^ inplace (if the resulting type permits)
| `s => bytab((coltable, name) -> coltable.a .+ coltable[name])`  | Add the column `:a` to the current column
| `s => bytab!((coltable, name) -> coltable.a .+ coltable[name])` | ^ inplace (if the resulting type permits)

Broadcasting plays nicely with your ability to chain multiple selections together (you can e.g. `if_matches(r"a") | if_eltype(Number)` to select all the columns that contain the letter "a" or are numeric) in a sense that when you chain multiple broadcasted transformations like `(a: => bycol.(x->x+1)) | (all_cols() => bycol.(x -> 2x))` then in the case of column `:a`, the transformations will be fused as if there was only one transformation `x -> (x + 1) * 2`.

## Implementation
Here is the source code of `select`:

```julia
function select(tab, args...; kwargs...)
    has_args = !isempty(args)
    has_kwargs = !isempty(kwargs)

    if has_args
        # Selection queries -> triplets of selections, renamings and transforms that are generic,
        # can be applied to any Table. Multiple `args` are chained with an `|`.
        # The translate_types function also tries to guess the correct meaning of inputs,
        # i.e. that `:a => :A` is a `selection(:a) => renaming(:A)`.
        queries = mapfoldl(translate_types, OrSelection, ensure_tuple(args))
        # Selection results -> triplets of column names, renamings and transforms that are fitted
        # to this particular table, the generic selections are replaced with actual column names.
        # If multiple selections were overlapping, their renamings and transformations were combined.
        plans = resolve_nested(tab, queries)::SelectionPlan
        # the other_cols() are resolved if present
        process_other!(tab, plans)
        # Prepare renamings -- produces unique output names to be applied later
        outnames = rename_colnames(colnames(plans), keyfuncs(plans))
        # Apply transformations to tables columns
        outcols = transform_columns(tab, colnames(plans), valfuncs(plans))
        # At this point, results are in a form of a NamedTuple
        nt = NamedTuple{outnames}(outcols)
    else
        nt = columntable(tab)
    end
    if has_kwargs
        for (new_column_name, _args) in pairs(kwargs)
            # Produce source_columns => transformation pairs.
            plan = resolve_flat(nt, _args)
            # Create the new column
            new_column = apply_trans_flat(last(plan), first(plan), new_column_name, nt)
            # Add the result to our table (NamedTuple), so the next column definition can use them
            nt = merge(nt, (; new_column_name => newcolfunc(new_column)))
        end
    end
    materializer(tab)(nt) # Return a Table of the same "kind" as the input.
end
```

As you can see, `renamings` and `transformations` are applied after the `selections` are resolved, so you don't have to worry about renamings messing up your subsequent selections.

## TODOs and ideas:
* `select_colnames(tab, args...)` -- function that returns the names of columns matching selections in `args...`
* `select_renames(tab, args...)` -- function that returns the symbol pairs of columns matching selections and renamings in `args...`
* `rename(tab, args...)` -- function that always selects all columns in their original order, but can change column names
* `transform(tab, args..., kwargs...)` -- function that always selects columns in their original order, but can change column values and add new columns
* add macro version of all transformations that will guess which source columns to use and that would allow some special behaviour for closures based on their arguments name (`row -> f` vs `(row, name) -> f`). Maybe even support things similar to [data.tables special symbols](https://rdrr.io/cran/data.table/man/special-symbols.html).
* column name hints in keyerrors (what DataFrames.jl already does)
* Allow `all_cols()`, `other_cols()` and `else_cols()` to accept `args...` to make them more flexible.
* proper docs

## Disclaimer

This package started as and still is an experiment, a search for a flexible and powerful API for *SELECT*-like operations. At this point, the API still may evolve and change in a breaking manner.

## Acknowledgement

This work was heavily inspired by the R [tidyselect](https://github.com/tidyverse/tidyselect), [dplyr](https://github.com/tidyverse/dplyr) and [data.table](https://github.com/Rdatatable/data.table) packages as well as by the design of [DataFrames.jl](https://github.com/JuliaData/DataFrames.jl) and [JuliaDB.jl](https://github.com/JuliaComputing/JuliaDB.jl).
