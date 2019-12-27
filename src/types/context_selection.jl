_select_all(k,v) = true

for (T, f) in ((:OtherSelection, :other_cols), (:ElseSelection, :else_cols), (:AllSelection, :all_cols))
    @eval begin
        struct $(T){S,R,T} <: AbstractContextSelection{R,T}
            s::S
            r::R
            t::T
            $(T)(s::S, r::R=nothing, t::T=nothing) where {S,R,T} = new{S,R,T}(s,r,t)
        end
        $(f)() = $(T)(_select_all)
        function extend_selection(s::$(T), r=nothing, t=nothing)
            $(T)(params(s)..., bool(s), extend(keyfunc(s), r), extend(valfunc(s), t))
        end
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
