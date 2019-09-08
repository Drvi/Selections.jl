struct RenamingFunction{S} <: AbstractRenaming where S <: Callable
    s::S
end
(s::RenamingFunction)(x::Symbol) = Symbol(s.s(string(x)))
key_prefix(s::Union{AbstractString,Char}) = RenamingFunction(x -> string(s, x))
key_suffix(s::Union{AbstractString,Char}) = RenamingFunction(x -> string(x, s))
key_map(f::Callable) = RenamingFunction(f)
key_replace(p::Pair) = RenamingFunction(x -> replace(x, first(p) => last(p)))
Base.show(io::IO, r::RenamingFunction) = print(io, "RenamingFunction(", r.s, ")")

struct RenamingSymbols{S} <: AbstractRenaming
    s::S
end
Base.show(io::IO, r::RenamingSymbols) = print(io, "RenamingSymbols(", r.s, ")")
(r::RenamingSymbols)(x) = r.s

struct RenamingSymbol <: AbstractRenaming
    s::Symbol
end
Base.show(io::IO, r::RenamingSymbol) = print(io, "RenamingSymbol(:", r.s, ")")
(r::RenamingSymbol)(x) = r.s

apply_rename(::Nothing, colname) = colname
apply_rename(c::Composition, colname) = apply_rename(c.funcs, colname)
apply_rename(fs, colname) = apply_rename(Base.tail(fs), first(fs)(colname))
apply_rename(::Tuple{}, colname) = colname

renaming(r::R) where R <: AbstractRenaming = r
renaming(r::Pair{<:Union{AbstractString,Regex}, SubstitutionString}) = key_replace(r)
renaming(s::Symbol) = RenamingSymbol(s)
renaming(s::Union{Tuple{Vararg{Symbol}}, AbstractArray{Symbol}}) = RenamingSymbols(s)
renaming(c::Callable) = key_map(c)


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
key_prefix, key_suffix, key_map, key_replace, renaming
