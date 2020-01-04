struct RenamingFunction{S} <: AbstractRenaming where S <: Base.Callable
    s::S
end
(s::RenamingFunction)(x::Symbol) = Symbol(s.s(string(x)))
Base.show(io::IO, r::RenamingFunction) = print(io, "RenamingFunction(", r.s, ")")

struct RenamingSymbols{S} <: AbstractRenaming
    s::S
end
RenamingSymbols(s::AbstractVector{S}) where S<:Union{AbstractChar,AbstractString} = RenamingSymbols(map(Symbol, s))
Base.show(io::IO, r::RenamingSymbols) = print(io, "RenamingSymbols(", r.s, ")")
(r::RenamingSymbols)(x) = r.s

struct RenamingSymbol <: AbstractRenaming
    s::Symbol
end
RenamingSymbol(s::Union{AbstractChar,AbstractString}) = RenamingSymbol(Symbol(s))
Base.show(io::IO, r::RenamingSymbol) = print(io, "RenamingSymbol(:", r.s, ")")
(r::RenamingSymbol)(x) = r.s

add_affixes(xs::Symbol, prefix, suffix) =
    RenamingSymbol(_add_affixes(prefix, xs, suffix))
add_affixes(xs::Union{AbstractVector{Symbol},Tuple{Vararg{Symbol}}}, prefix, suffix) =
    RenamingSymbols(_add_affixes.(prefix, xs, suffix))
add_affixes(f::Base.Callable, prefix, suffix) =
    RenamingFunction(x->_add_affixes(prefix, f(x), suffix))
add_affixes(p::Pair{<:Union{AbstractString,AbstractChar,Regex}, <:Union{AbstractString,AbstractChar,SubstitutionString}}, prefix, suffix) =
    RenamingFunction(x->_add_affixes(prefix, replace(x, first(p) => last(p), suffix)))

_add_affixes(prefix, s, suffix) = string(prefix, s, suffix)
_add_affixes(prefix::Nothing, s, suffix) = string(s, suffix)
_add_affixes(prefix, s, suffix::Nothing) = string(prefix, s)
_add_affixes(prefix::Nothing, s, suffix::Nothing) = s

renaming(r::R) where R <: AbstractRenaming = r
renaming(s::Symbol) = RenamingSymbol(s)
renaming(s::Union{Tuple{Vararg{Symbol}}, AbstractArray{Symbol}}) = RenamingSymbols(s)
renaming(f::Base.Callable) = RenamingFunction(f)
renaming(r::Pair{<:Union{AbstractString,AbstractChar,Regex}, <:Union{AbstractString,AbstractChar,SubstitutionString}}) =
    RenamingFunction(x->replace(x, first(p) => last(p)))

apply_rename(::Nothing, colname) = colname
apply_rename(c::Composition, colname) = apply_rename(c.funcs, colname)
apply_rename(fs, colname) = apply_rename(Base.tail(fs), first(fs)(colname))
apply_rename(::Tuple{}, colname) = colname

# alias(r; prefix=Nothing, suffix=Nothing)
function alias(
    ;
    prefix::Nothing=nothing,
    suffix::Nothing=nothing)
    throw(MethodError(alias, ()))
end

function alias(
    ;
    prefix::Union{Nothing,AbstractChar,AbstractString,Symbol}=nothing,
    suffix::Union{Nothing,AbstractChar,AbstractString,Symbol}=nothing)
    RenamingFunction(x->_add_affixes(prefix, x, suffix))
end

function alias(
    r;
    prefix::Union{Nothing,AbstractChar,AbstractString,Symbol}=nothing,
    suffix::Union{Nothing,AbstractChar,AbstractString,Symbol}=nothing)
    add_affixes(r, prefix, suffix)
end


"""
```
key_prefix(s::Union{AbstractString,Char})
key_suffix(s::Union{AbstractString,Char})
key_map(f::Callable)
key_replace(pat=>r)
```
Modify names of columns selected within a call to `select(tab, s...)`.
Usage:
* `Selection => key_preffix(s)` or `Selection => key_suffix(s)` -- Modify all of the selected column names by concatenating string `s` to them
* `Selection => key_map(f)` -- Modify all of the selected columns names by applying function `f` to them.
* `Selection => key_replace(pat=>r)` -- Modify all of the selected columns names by replacing pattern `pat` with `r`.

See also: [`select`](@ref), [`selection`](@ref), [`transformation`](@ref)
"""
key_prefix, key_suffix, key_map, key_replace, renaming, alias
