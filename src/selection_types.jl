abstract type AbstractSelection end
(-)(s::Pair{<:AbstractSelection,S}) where S = -s.first => s.second
(!)(s::AbstractSelection) = -s
(~)(s::AbstractSelection) = -s
bool(s::AbstractSelection) = s.b
iterate(s::AbstractSelection) = (s, nothing)
iterate(x::AbstractSelection, ::Any) = nothing

abstract type AbstractSymbolSelection <: AbstractSelection end
abstract type AbstractMultiSelection <: AbstractSelection end

abstract type AbstractSelectionRename end

const AMultiOrSingle = Union{AbstractMultiSelection,AbstractSelection,AbstractSymbolSelection}
const ASingle = Union{AbstractSelection,AbstractSymbolSelection}
const RenameTarget = Union{Symbol,Vector{Symbol},AbstractSelectionRename}
(-)(s::Pair{<:AbstractSelection,<:RenameTarget}) = -s.first => s.second

function selection end
function cols end
function not end

struct Complement{F1,F2} <: AbstractSymbolSelection where F1 <: AbstractSelectionRename where F2 <: Function
    f1::F1
    f2::F2
end
(&)(s1::Complement, s2) = error("rest() cannot be explicitly chained by `&`, just supply as another argument to select().")
(&)(s1, s2::Complement) = error("rest() cannot be explicitly chained by `&`, just supply as another argument to select().")
rest() = Complement(key_map(identity), identity)
(-)(x::Complement) = error("rest() cannot be negated.")
bool(s::Complement) = true
getname(s::Complement) = s
getnames(s::Complement) = [s]

struct SymbolSelection{R} <: AbstractSymbolSelection
    s::Symbol
    b::Bool
    r::R
end
SymbolSelection(s::Symbol) = SymbolSelection(s, true, identity)
SymbolSelection(s::Symbol, b::Bool) = SymbolSelection(s, b, identity)
SymbolSelection(s::Vector{Symbol}) = SymbolSelection.(s)
(-)(s::SymbolSelection) = SymbolSelection(s.s, !s.b, s.r)
getname(s::SymbolSelection) = s.s
getnames(s::SymbolSelection) = [getname(s)]
getnames(s::Vector{<:AbstractSymbolSelection}) = getname.(s)

struct IntSelection <: AbstractSelection
    s::Int
    b::Bool
    IntSelection(s, b) = s == 0 ? error("Zero is not a valid column index.") : new(abs(s), b)
end
IntSelection(s::Int) = s == 0 ? error("Zero is not a valid column index.") : IntSelection(abs(s), s > 0)
(-)(s::IntSelection) = IntSelection(s.s, !s.b)


struct BoolSelection <: AbstractSelection
    s::AbstractArray{Bool}
    b::Bool
end
BoolSelection(s::AbstractArray{Bool}) = BoolSelection(s, true)
(-)(s::BoolSelection) = BoolSelection(s.s, !s.b)

struct RangeSelection{T} <: AbstractSelection  where T <: Union{Int,Symbol}
    s1::T
    s2::T
    step::Int
    b::Bool
    function RangeSelection(s1::Int, s2::Int, step::Int, b::Bool)
        @assert sign(s1) == sign(s2) == 1 && ((s2 > s1 && sign(step)) == 1 || (s1 > s2 && sign(step)) == -1 || (s1 == s2 && sign(step) != 0)) "The range used for selection ($(s1):$(step):$(s2)) must be non-empty and non-crossing zero."
        sign(s1) == 1 ? new{Int}(s1, s2, step, b) : new{Int}(abs(s1), abs(s2), abs(step), b)
    end
    RangeSelection(s1::Symbol, s2::Symbol, step::Int, b::Bool) = new{Symbol}(s1, s2, step, b)
end
(-)(s::RangeSelection) = RangeSelection(s.s1, s.s2, s.step, !(s.b))
colrange(s1::Symbol, s2::Symbol; by::Int=1) = RangeSelection(s1, s2, by, true)
colrange(s1::Int, s2::Int; by::Int=1) = RangeSelection(s1, s2, (s1 > s2 ? -1 : 1) * abs(by), true)

function RangeSelection(x::AbstractRange)
    RangeSelection(x[1], x[end], step(x), true)
end
function RangeSelection(x::Union{StepRange{Int,Int},UnitRange{Int}})
    lo,hi = extrema(x)
    range_sign = sign(lo)
    @assert lo != 0 && hi != 0 && length(x) > 0 && range_sign == sign(hi) "The range used for selection ($(x)) must be non-empty and non-crossing zero."
    if (range_sign == 1)
        RangeSelection(x[1], x[end], step(x), true)
    else
        RangeSelection(abs(hi), abs(lo), abs(step(x)), false)
    end
end

struct NamePredicateSelection{F} <: AbstractSelection where F <: Function
    f::F
    b::Bool
end
if_keys(f::Function) = NamePredicateSelection(f, true)
if_matches(s::S) where S <: Union{Regex,AbstractString,Char} = if_keys(x -> occursin(s, string(x)))
(-)(x::NamePredicateSelection) = NamePredicateSelection(x.f, !x.b)

struct PredicateSelection{F} <: AbstractSelection where F <: Function
    f::F
    b::Bool
end
if_values(f::Function) = PredicateSelection(f, true)
if_eltype(t::DataType) = if_values(x -> eltype(x) <: t || eltype(x) <: Union{Missing, t})
(-)(x::PredicateSelection) = PredicateSelection(x.f, !x.b)

struct PairPredicateSelection{F} <: AbstractSelection where F <: Function
    f::F
    b::Bool
end
if_pairs(f::Function) = PairPredicateSelection(f, true)
(-)(x::PairPredicateSelection) = PairPredicateSelection(x.f, !x.b)

struct PositiveSelectionArray{S} <: AbstractVector{S}
    s::Vector{S}
end
Base.size(s::PositiveSelectionArray) = size(s.s)
Base.getindex(s::PositiveSelectionArray, i) = getindex(s.s, i)
bool(s::PositiveSelectionArray) = true
getnames(s::PositiveSelectionArray) = getname(s.s)
iterate(x::PositiveSelectionArray) = iterate(x.s)
iterate(x::PositiveSelectionArray, state::Any) = iterate(x.s, state)

struct OrMultiSelection{S,T} <: AbstractMultiSelection
    s1::S
    s2::T
    b::Bool
end
OrMultiSelection(s1, s2) = OrMultiSelection(s1, s2, true)
(-)(s::OrMultiSelection) = OrMultiSelection(s.s1, s.s2, !s.b)
(|)(s1::S, s2::T) where S <: AbstractSelection where T <: AbstractSelection = OrMultiSelection(s1, s2)
(|)(s1::Vector{S}, s2::T) where S <: AbstractSelection where T <: AbstractSelection = OrMultiSelection(s1, s2)
(|)(s1::S, s2::Vector{T}) where S <: AbstractSelection where T <: AbstractSelection = OrMultiSelection(s1, s2)
(|)(s1::Vector{S}, s2::Vector{T}) where S <: AbstractSelection where T <: AbstractSelection = OrMultiSelection(s1, s2)
# This is type piracy
(|)(s1, s2::Pair{S,<:RenameTarget}) where S = OrMultiSelection(selection(s1), s2)
(|)(s1::Pair{S,<:RenameTarget}, s2) where S = OrMultiSelection(s1, selection(s2))
(|)(s1::Pair{S,<:RenameTarget}, s2::Pair{T,<:RenameTarget}) where S where T = OrMultiSelection(selection(s1), selection(s2))
(|)(s1::S, s2::Pair{<:AbstractSelection,<:RenameTarget}) where S <: AbstractSelection  = OrMultiSelection(s1, s2)
(|)(s1::Pair{<:AbstractSelection,<:RenameTarget}, s2::S) where S <: AbstractSelection = OrMultiSelection(s1, s2)
(|)(s1::Pair{S,<:RenameTarget}, s2::Pair{T,<:RenameTarget}) where S <:AbstractSelection where T <:AbstractSelection = OrMultiSelection(s1, s2)

struct AndMultiSelection{S,T} <: AbstractMultiSelection
    s1::S
    s2::T
    b::Bool
end
AndMultiSelection(s1, s2) = AndMultiSelection(s1, s2, true)
(-)(s::AndMultiSelection) = AndMultiSelection(s.s1, s.s2, !s.b)
(&)(s1::S, s2::T) where S <: AbstractSelection where T <: AbstractSelection = AndMultiSelection(s1, s2)
(&)(s1::Vector{S}, s2::T) where S <: AbstractSelection where T <: AbstractSelection = AndMultiSelection(s1, s2)
(&)(s1::S, s2::Vector{T}) where S <: AbstractSelection where T <: AbstractSelection = AndMultiSelection(s1, s2)
(&)(s1::Vector{S}, s2::Vector{T}) where S <: AbstractSelection where T <: AbstractSelection = AndMultiSelection(s1, s2)

# This is type piracy
(&)(s1, s2::Pair{S,<:RenameTarget}) where S = AndMultiSelection(selection(s1), s2)
(&)(s1::Pair{S,<:RenameTarget}, s2) where S = AndMultiSelection(s1, selection(s2))
(&)(s1::Pair{S,<:RenameTarget}, s2::Pair{T,<:RenameTarget}) where S where T = AndMultiSelection(selection(s1), selection(s2))
(&)(s1::S, s2::Pair{<:AbstractSelection,<:RenameTarget}) where S <: AbstractSelection  = AndMultiSelection(s1, s2)
(&)(s1::Pair{<:AbstractSelection,<:RenameTarget}, s2::S) where S <: AbstractSelection = AndMultiSelection(s1, s2)
(&)(s1::Pair{S,<:RenameTarget}, s2::Pair{T,<:RenameTarget}) where S <:AbstractSelection where T <:AbstractSelection = AndMultiSelection(s1, s2)

struct SelectionRename{S} <: AbstractSelectionRename where S <:Function
    s::S
end
(s::SelectionRename)(x::Symbol) = Symbol(s.s(string(x)))
key_prefix(s::Union{AbstractString,Char}) = SelectionRename(x -> s * x)
key_suffix(s::Union{AbstractString,Char}) = SelectionRename(x -> x * s)
key_map(f::Function) = SelectionRename(f)
key_replace(p::Pair) = SelectionRename(x -> replace(x, p.first => p.second))

struct ToSymbol{S}
    s::S
end
(ts::ToSymbol)(x) = ts.s

apply_rename(s::SymbolSelection, r::Symbol) = SymbolSelection(s.s, s.b, ToSymbol(r))
apply_rename(s::SymbolSelection, r::AbstractSelectionRename) = SymbolSelection(s.s, s.b, s.r ∘ r)
function apply_rename(s::AbstractArray, r::AbstractSelectionRename)
     apply_rename.(s, (r,))
 end
function apply_rename(s::AbstractArray, r::Symbol)
    if length(s) == 1
        [apply_rename(s[1], r)]
    else
        @warn("Renaming to a sigle new name is not supported for multiple selections ($(length(s))), renaming skipped.")
        s
    end
end

function apply_rename(s::AbstractArray, r::Vector{Symbol})
    if length(s) == length(r)
        apply_rename.(s, r)
    else
        @warn("Renaming array had different length ($(length(r))) than target selections ($(length(s))), renaming skipped.")
        s
    end
end
apply_rename(s::Complement, r::AbstractSelectionRename) = Complement(r, s.f2)

"""
```
rest()
```

Select all the columns that were not selected by other selections within a call to `select(df, s...)`.

See also: [`select`](@ref)
"""
rest

"""
```
colrange(s1, s2 [; step::Int=1])
```
Select all columns between `s1` and `s2`. `s1` and `s2` can be both `Symbols` or `Int`s.

See also: [`select`](@ref), [`if_keys`](@ref), [`key_map`](@ref)
"""
colrange

"""
```
if_keys(f::Function)
if_matches(s::Union{AbstractString,Regex})
if_values(f::Function)
if_eltype(t::DataType)
if_pairs(f::Function)
```
Select columns based on their values and/or names within a call to `select(df, s...)`.
Usage:
* `if_values(f)` -- Select all columns where `f(column) == true`
* `if_keys(f)` -- Select all columns where `f(colname) == true`
* `if_pairs(f)` -- Select all columns where `f(colname, column) == true`
* `if_eltype(t)` -- Select all columns where `eltype(column) <: t || eltype(column) <: Union{t,Missing}`
* `if_matches(s)` -- Select all columns where `occursin(s, keys(df)) == true`

See also: [`select`](@ref), [`colrange`](@ref), [`key_map`](@ref)
"""
if_matches, if_keys, if_values, if_pairs, if_eltype

"""
```
key_prefix(s::Union{AbstractString,Char})
key_suffix(s::Union{AbstractString,Char})
key_map(f::Function)
key_replace(pat=>r)
```
Modify names of columns selected within a call to `select(df, s...)`.
Usage:
* `Selection => key_preffix(s)` or `Selection => key_suffix(s)` -- Modify all of the selected column names by concatenating string `s` to them
* `Selection => key_map(f)` -- Modify all of the selected columns names by applying function `f` to them.
* `Selection => key_replace(pat=>r)` -- Modify all of the selected columns names by replacing pattern `pat` with `r`.

See also: [`select`](@ref), [`if_keys`](@ref), [`colrange`](@ref)
"""
key_prefix, key_suffix, key_map, key_replace
