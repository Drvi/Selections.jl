# add r and t field to all abstract selections
struct SymbolSelection{R,T} <: AbstractSelection{R,T}
    s::Symbol
    b::Bool
    r::R
    t::T
    SymbolSelection(s::Symbol, b::Bool=true, r::R=nothing, t::T=nothing) = new{R,T}(s, b, r, t)
end

struct IntSelection{R,T} <: AbstractSelection{R,T}
    s::Int
    b::Bool
    r::R
    t::T
    function IntSelection(s::Int, b::Bool=true, r::R=nothing, t::T=nothing) where {R,T}
        if s <= 0
            throw(ArgumentError("Non-positive integers are not valid column indices."))
        else
            new{R,T}(s, b, r, t)
        end
    end
end

struct BoolSelection{R,T} <: AbstractSelection{R,T}
    s::AbstractArray{Bool}
    b::Bool
    r::R
    t::T
    function BoolSelection(s::AbstractArray{Bool}, b::Bool=true, r::R=nothing, t::T=nothing) where {R,T}
        new{R,T}(s, b, r, t)
    end
end

# TODO: negative integers are not allowed
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
function RangeSelection(x::AbstractRange)
    RangeSelection(x.start, x.stop, step(x), true, nothing, nothing)
end
params(s::RangeSelection) = (s.start, s.stop, s.step)
cols_range(start::S, stop::S; step::S=one(S)) where {S<:Integer} = RangeSelection(start, stop, step)
cols_range(start::Symbol, stop::Symbol; step::S=1) where {S<:Integer} = RangeSelection(start, stop, step)
Base.show(io::IO, s::RangeSelection) = (!bool(s) && print(io, "-"); print(io, "RangeSelection(", s.start, ":", s.step == 1 ? "" : "$(s.step):", s.stop, ")"))

struct ArraySelection{S,R,T} <: AbstractSelection{R,T} where T <: Union{Int,Symbol}
    s::Vector{S}
    b::Bool
    r::R
    t::T
    function ArraySelection(s::AbstractVector{S}, b::Bool=true, r::R=nothing, t::T=nothing) where {S<:Union{Int,Symbol},R,T}
        new{S,R,T}(unique(s), b, r, t)
    end
end
ArraySelection(s::Tuple{Vararg{S}}, b::Bool=true, r::R=nothing, t::T=nothing) where {S<:Union{Int,Symbol},R,T} =
    ArraySelection(collect(unique(s)), b, r, t)

struct PairsPredicateSelection{F,R,T}} <: AbstractSelection where F <: Callable
    f::F
    b::Bool
    r::R
    t::T
    PairsPredicateSelection(f::F, b::Bool=true, r::R=nothing, t::T=nothing) where {F<:Callable,R,T} =
        new{F,R,T}(f, b, r, t)
end
params(s::PairsPredicateSelection) = (s.f,)

selection(x::Symbol, b::Bool=true) = SymbolSelection(x, b)
selection(x::Int, b::Bool=true) = IntSelection(x, b)
selection(x::AbstractVector{Bool}, b::Bool=true) = BoolSelection(x, b)
selection(x::StepRange{Int,Int}, b::Bool=true) = RangeSelection(x, b)
selection(x::UnitRange{Int}, b::Bool=true) = RangeSelection(x, b)
selection(x::AbstractVector{S}, b::Bool=true) where {S<:Union{Int,Symbol}} = ArraySelection(x, b)
selection(x::AbstractVector, b::Bool=true) = isempty(x) ? ArraySelection(Symbol[], b) : cols(x...)
selection(x::Tuple{Vararg{S}}, b::Bool=true) where {S<:Union{Int,Symbol}} = ArraySelection(x, b)
selection(x::Tuple, b::Bool=true) = isempty(x) ? ArraySelection(Symbol[], b) : cols(x...)
selection(x::Union{Regex,AbstractString,Char}, b::Bool=true) = PairsPredicateSelection((k,v) -> occursin(x, string(k)), b)
selection(x::DataType, b::Bool=true) = PairsPredicateSelection((k,v) -> eltype(v) <: x || eltype(v) <: Union{Missing, t}, b)
selection(x::Callable, b::Bool=true) = PairsPredicateSelection(x, b)
selection(x::AbstractSelection, b::Bool=true) = x
selection(x::SelectionQuery, b::Bool=true) = x
selection(x::SelectionPlan, b::Bool=true) = x

# not(s...; alias, trans)
cols() = all_cols()
cols(s) = selection(s, true)
cols(s...) = mapfoldl(cols, OrSelection, [s...])

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
