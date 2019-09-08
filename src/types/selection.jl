struct SymbolSelection <: AbstractSelection
    s::Symbol
    b::Bool
    SymbolSelection(s::Symbol, b::Bool) = new(s, b)
end
SymbolSelection(s::Symbol) = SymbolSelection(s, true)
SymbolSelection(s::Vector{Symbol}) = SymbolSelection.(s)
(-)(s::SymbolSelection) = SymbolSelection(s.s, !s.b)

struct IntSelection <: AbstractSelection
    s::Int
    b::Bool
    function IntSelection(s::Int, b::Bool)
        if s == 0
            throw(ArgumentError("Zero is not a valid column index."))
        else
            new(abs(s), b)
        end
    end
end
function IntSelection(s::Int)
    if s == 0
        throw(ArgumentError("Zero is not a valid column index."))
    else
        IntSelection(abs(s), s > 0)
    end
end
(-)(s::IntSelection) = IntSelection(s.s, !s.b)

struct BoolSelection <: AbstractSelection
    s::AbstractArray{Bool}
    b::Bool
end
BoolSelection(s::AbstractArray{Bool}) = BoolSelection(s, true)
(-)(s::BoolSelection) = BoolSelection(s.s, !s.b)

struct RangeSelection{T} <: AbstractSelection where T <: Union{Int,Symbol}
    s1::T
    s2::T
    step::Int
    b::Bool
    function RangeSelection(s1::Int, s2::Int, step::Int, b::Bool)
        if !(sign(s1) == sign(s2) == 1 && ((s2 > s1 && sign(step)) == 1 || (s1 > s2 && sign(step)) == -1 || (s1 == s2 && sign(step) != 0)))
            throw(ArgumentError("The range used for selection ($(s1):$(step):$(s2)) must be non-empty and non-crossing zero."))
        end

        sign(s1) == 1 ? new{Int}(s1, s2, step, b) : new{Int}(abs(s1), abs(s2), abs(step), b)
    end
    RangeSelection(s1::Symbol, s2::Symbol, step::Int, b::Bool) = new{Symbol}(s1, s2, step, b)
end
(-)(s::RangeSelection) = RangeSelection(s.s1, s.s2, s.step, !bool(s))
colrange(s1::Symbol, s2::Symbol; by::Int=1) = RangeSelection(s1, s2, by, true)
colrange(s1::Int, s2::Int; by::Int=1) = RangeSelection(s1, s2, (s1 > s2 ? -1 : 1) * abs(by), true)
Base.show(io::IO, s::RangeSelection) = (!bool(s) && print(io, "-"); print(io, "RangeSelection(", s.s1, ":", s.step == 1 ? "" : "$(s.step):", s.s2, ")"))

function RangeSelection(x::AbstractRange)
    RangeSelection(x[1], x[end], step(x), true)
end
function RangeSelection(x::Union{StepRange{Int,Int},UnitRange{Int}})
    lo,hi = extrema(x)
    range_sign = sign(lo)

    if !(lo != 0 && hi != 0 && length(x) > 0 && range_sign == sign(hi))
        throw(ArgumentError("The range used for selection ($(x)) must be non-empty and non-crossing zero."))
    end

    if (range_sign == 1)
        RangeSelection(x[1], x[end], step(x), true)
    else
        RangeSelection(abs(hi), abs(lo), abs(step(x)), false)
    end
end

struct ArraySelection{S} <: AbstractSelection where T <: Union{Int,Symbol}
    s::Vector{S}
    b::Bool
    ArraySelection(s::AbstractVector{S}, b::Bool) where S <: Union{Int,Symbol} = new{S}(unique(s), b)
    ArraySelection(s::Tuple{Vararg{S}}, b::Bool) where S <: Union{Int,Symbol} = new{S}(collect(unique(s)), b)
end
ArraySelection(s) = ArraySelection(s, true)
(-)(x::ArraySelection) = ArraySelection(x.s, !x.b)


struct KeyPredicateSelection{F} <: AbstractSelection where F <: Callable
    f::F
    b::Bool
end
if_keys(f::Callable) = KeyPredicateSelection(f, true)
if_matches(s::S) where S <: Union{Regex,AbstractString,Char} = if_keys(x -> occursin(s, string(x)))
(-)(x::KeyPredicateSelection) = KeyPredicateSelection(x.f, !x.b)

struct PredicateSelection{F} <: AbstractSelection where F <: Callable
    f::F
    b::Bool
end
if_values(f::Callable) = PredicateSelection(f, true)
if_eltype(t::DataType) = if_values(x -> eltype(x) <: t || eltype(x) <: Union{Missing, t})
(-)(x::PredicateSelection) = PredicateSelection(x.f, !x.b)

struct PairPredicateSelection{F} <: AbstractSelection where F <: Callable
    f::F
    b::Bool
end
if_pairs(f::Callable) = PairPredicateSelection(f, true)
(-)(x::PairPredicateSelection) = PairPredicateSelection(x.f, !x.b)

selection(x::Symbol) = SymbolSelection(x)
selection(x::Int) = IntSelection(x)
selection(x::AbstractVector{Bool}) = BoolSelection(x)
selection(x::StepRange{Int,Int}) = RangeSelection(x)
selection(x::UnitRange{Int}) = RangeSelection(x)
selection(x::AbstractVector{S}) where {S<:Union{Int,Symbol}} = ArraySelection(x)
selection(x::AbstractVector) = isempty(x) ? ArraySelection(Symbol[]) : cols(x...)
selection(x::Tuple{Vararg{S}}) where {S<:Union{Int,Symbol}} = ArraySelection(x)
selection(x::Tuple) = isempty(x) ? ArraySelection(Symbol[]) : cols(x...)
selection(x::Regex) = if_matches(x)
selection(x::DataType) = if_eltype(x)
selection(x::AbstractSelection) = x
selection(x::SelectionQuery) = x
selection(x::SelectionResult) = x


col(x) = selection(x)

cols() = throw(MethodError(cols, ()))
cols(s) = selection(s)
cols(s...) = mapfoldl(selection, OrSelection, [s...])

not() = throw(MethodError(not, ()))
not(x::Pair) = -selection(first(x)) => last(x)
not(s) = -selection(s)
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
