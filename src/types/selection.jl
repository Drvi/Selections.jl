# add r and t field to all abstract selections
struct ElementSelection{S,R,T} <: AbstractSelection{R,T} where {S<:Union{Symbol,Integer}}
    s::S
    b::Bool
    r::R
    t::T
    ElementSelection(s::Symbol, b::Bool=true, r::R=nothing, t::T=nothing) where {R,T} = new{Symbol,R,T}(s, b, r, t)
    function ElementSelection(s::S, b::Bool=true, r::R=nothing, t::T=nothing) where {S,R,T}
        if s <= 0
            throw(ArgumentError("Non-positive integers are not valid column indices."))
        else
            new{S,R,T}(s, b, r, t)
        end
    end
end

struct ArraySelection{S,R,T} <: AbstractSelection{R,T} where S<:Union{Int,Symbol,Bool}
    s::AbstractVector{S}
    b::Bool
    r::R
    t::T
    function ArraySelection(s::AbstractVector{S}, b::Bool=true, r::R=nothing, t::T=nothing) where {S<:Union{Int,Symbol},R,T}
        new{S,R,T}(unique(s), b, r, t)
    end
    function ArraySelection(s::AbstractVector{S}, b::Bool=true, r::R=nothing, t::T=nothing) where {S<:Bool,R,T}
        new{S,R,T}(s, b, r, t)
    end
end
ArraySelection(s::Tuple{Vararg{S}}, b::Bool=true, r::R=nothing, t::T=nothing) where {S<:Union{Int,Symbol},R,T} =
    ArraySelection(collect(unique(s)), b, r, t)

struct RangeSelection{S,R,T} <: AbstractSelection{R,T} where S <: Union{Int,Symbol}
    start::S
    stop::S
    step::Int
    b::Bool
    r::R
    t::T
    function RangeSelection(start::S, stop::S, step::S=one(S), b::Bool=true, r::R=nothing, t::T=nothing) where {S<:Integer,R,T}
        if start <= 0 && stop <= 0
            throw(ArgumentError("Non-positive integers are not valid column indices."))
        end
        new{S,R,T}(start, stop, step, b, r, t)
    end
    function RangeSelection(start::Symbol, stop::Symbol, step::S=1, b::Bool=true, r::R=nothing, t::T=nothing) where {S<:Integer,R,T}
        new{S,R,T}(start, stop, step, b, r, t)
    end
end
function RangeSelection(x::AbstractRange, b::Bool=true, r::R=nothing, t::T=nothing) where {R,T}
    RangeSelection(x.start, x.stop, step(x), b, r, t)
end
Base.first(s::RangeSelection) = s.start
Base.last(s::RangeSelection) = s.stop
Base.step(s::RangeSelection) = s.step
params(s::RangeSelection) = (s.start, s.stop, s.step)

struct PairsPredicateSelection{F,R,T} <: AbstractSelection{R,T} where F <: Base.Callable
    f::F
    b::Bool
    r::R
    t::T
    PairsPredicateSelection(f::F, b::Bool=true, r::R=nothing, t::T=nothing) where {F<:Base.Callable,R,T} =
        new{F,R,T}(f, b, r, t)
end
params(s::PairsPredicateSelection) = (s.f,)

for S in (:ElementSelection, :ArraySelection, :PairsPredicateSelection)
    @eval (Base.:!)(s::$(S)) = $(S)(params(s)..., !bool(s), keyfunc(s), valfunc(s))
    @eval Base.show(io::IO, s::$(S)) = print(io, bool(s) ? "" : "!", Symbol($S), "(", repr.(params(s))..., ")")
    @eval function extend_selection(s::$(S), r=nothing, t=nothing)
        $(S)(params(s)..., bool(s), extend(keyfunc(s), r), extend(valfunc(s), t))
    end
end
(Base.:!)(s::RangeSelection) = RangeSelection(params(s)..., !bool(s), keyfunc(s), valfunc(s))
function Base.show(io::IO, s::RangeSelection)
    print(io,
        bool(s) ? "" : "!",
        RangeSelection,
        "(",
        repr(first(s)),
        step(s) == 1 ? "" : ":$(step(s))",
        ":",
        repr(last(s)),
        ")"
    )
end


selection(x::Union{Int,Symbol}, b=true, r=nothing,t=nothing) =
    ElementSelection(x, b, r, t)
selection(x::AbstractVector{Bool}, b=true, r=nothing,t=nothing) =
    ArraySelection(x, b, r, t)
selection(x::AbstractVector{S}, b=true, r=nothing,t=nothing) where {S<:Union{Int,Symbol}} =
    ArraySelection(x, b, r, t)
selection(x::Tuple{Vararg{S}}, b=true, r=nothing,t=nothing) where {S<:Union{Int,Symbol}} =
    ArraySelection(x, b, r, t)
selection(x::AbstractVector, b=true, r=nothing,t=nothing) =
    isempty(x) ? ArraySelection(Symbol[], b, r, t) : cols(x...)
selection(x::Tuple, b=true, r=nothing,t=nothing) =
    isempty(x) ? ArraySelection(Symbol[], b, r, t) : cols(x...)
selection(x::StepRange{Int,Int}, b=true, r=nothing,t=nothing) =
    RangeSelection(x, b, r, t)
selection(x::UnitRange{Int}, b=true, r=nothing,t=nothing) =
    RangeSelection(x, b, r, t)
selection(x::Union{Regex,AbstractString,Char}, b=true, r=nothing,t=nothing) =
    PairsPredicateSelection((k,v) -> occursin(x, string(k)), b, r, t)
selection(x::DataType, b=true, r=nothing,t=nothing) =
    PairsPredicateSelection((k,v) -> eltype(v) <: x || eltype(v) <: Union{Missing, t}, b, r, t)
selection(x::Base.Callable, b=true, r=nothing,t=nothing) =
    PairsPredicateSelection(x, b, r, t)
selection(x::AbstractSelection, b=true, r=nothing, t=nothing) = x
selection(x::AbstractMetaSelection, b=true, r=nothing, t=nothing) = x

# cols(s...; alias, trans)
cols() = all_cols()
cols(s) = selection(s, true)
cols(s...) = mapfoldl(cols, OrSelection, [s...])

cols_range(start::S, stop::S; step::S=one(S)) where {S<:Integer} = RangeSelection(start, stop, step)
cols_range(start::Symbol, stop::Symbol; step::S=1) where {S<:Integer} = RangeSelection(start, stop, step)

# not(s...; alias, trans)
not() = throw(MethodError(not, ()))
not(s) = selection(s, false)
not(p::Pair) = not(first(p)) => last(p)
not(s...) = mapfoldl(not, AndSelection, [s...])


"""
```
if_keys(f::Callable)
if_matches(s::Union{AbstractString,Regex})
if_values(f::Callable)
if_eltype(t::DataType)
if_pairs(f::Callable)
colrange(s1, s2 [; step::Int=1])
```
Select columns based on their values and/or names within a call to `select(tab, args...)`.
Usage:
* `if_values(f)` -- Select all columns where `f(column) == true`
* `if_keys(f)` -- Select all columns where `f(colname) == true`
* `if_pairs(f)` -- Select all columns where `f(colname, column) == true`
* `if_eltype(T)` -- Select all columns where `eltype(column) <: T || eltype(column) <: Union{T,Missing}`
* `if_matches(s)` -- Select all columns where `occursin(s, keys(tab)) == true`
* `colrange(s1, s2)` -- Select all columns between `s1` and `s2`. `s1` and `s2` can be both `Symbols` or `Int`s.

See also: [`select`](@ref), [`cols`](@ref), [`other_cols`](@ref), [`renaming`](@ref), [`transformation`](@ref)
"""
if_matches, if_keys, if_values, if_pairs, if_eltype, selection


"""
```
cols(args...)
not(args...)
col(s)
```

Wrappers that turn its inputs into `selection`s and reduce them into a single chained `selection`.
`cols()` reduces all conditions with an `|` boolean operator, `not()` with `&` and also negates its inputs.
`col()` simply converts its single input into a `selection`.

Useful for wrapping `Symbol`s, `Int`s, ranges and boolean vectors so that they can be interpreted as `selections`
and combined with `|`, `&` or `-`.

I.e. `select(tab , :a | :b)` is not defined and it would be considered type piracy, to define it.
Instead, you can use `select(tab, col(:a) | col(:b))` or `select(tab, cols(:a, :b))`.

`cols(args...)` is rougly `mapfoldl(selection, OrSelection, [args...])`

`not(args...)` is rougly `mapfoldl((-)∘selection, AndSelection, [args...])`

See also: [`select`](@ref), [`selection`](@ref)
"""
cols, not, col
