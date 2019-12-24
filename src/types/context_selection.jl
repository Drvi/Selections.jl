for (T, f) in ((:OtherSelection, :other_cols), (:ElseSelection, :else_cols), (:AllSelection, :all_cols))
    @eval begin
        struct $(T){F} <: AbstractContextSelection{F} where F <: Callable;
            s::F 
        end
        $(f)() = $(T)()
        (-)(x::$(T)) = throw(ArgumentError(string($(f), "() cannot be negated.")))
        bool(s::$(T)) = true
        Base.show(io::IO, s::$(T)) = print(io, $(f), "()")
    end
end

"""
```
other_cols()
all_cols()
else_cols()
```

`all_cols()` -- select all columns
`other_cols()` select the columns that were not selected in any other part of the selection query
`else_cols()` -- select the columns that the previous selection query didn't capture

See also: [`select`](@ref), [`selections`](@ref),
"""
all_cols, other_cols, else_cols
