
selection(x::Symbol) = SymbolSelection(x,)
selection(x::Int) = IntSelection(x)
selection(x::AbstractArray{Bool}) = BoolSelection(x)
selection(x::StepRange{Int,Int}) = RangeSelection(x)
selection(x::UnitRange{Int}) = RangeSelection(x)
selection(x::S) where S <: AbstractSelection = x
selection(x::Vector{S}) where S <: AbstractSymbolSelection = x

selection(x::Regex) = if_matches(x)

selection(x::Pair{S,<:RenameTarget}) where S = selection(x.first) => x.second
selection(x::Pair{<:AbstractSelection,S}) where S = x.first => x.second
selection(x::Pair{Symbol,Symbol}) = SymbolSelection(x.first, true, ToSymbol(x.second))
selection(x::Pair{SymbolSelection,Symbol}) = apply_rename(x.first, x.second)
selection(x::Pair{<:AbstractSymbolSelection,<:AbstractSelectionRename}) = bool(x.first) ? apply_rename(x.first, x.second) : x.first => x.second
selection(x::Pair{<:AbstractSelection,<:RenameTarget}) = x.first => x.second
function selection(x::Pair{Vector{:S},Vector{:S}}) where S <: Symbol
    if length(x.first) == length(x.second)
        SymbolSelection.(x.first, (true,), ToSymbol.(x.second))
    else
        @warn("Renaming array had different length ($(length(x.second))) than target selections ($(length(x.first))), renaming skipped.")
        SymbolSelection.(x.first)
    end
end

selection(x::AbstractArray) = isempty(x) ? Vector{SymbolSelection}() : selection.(x)
selection(x::Tuple) = map(selection, x)

cols(s) = selection(s)
cols(s...) = mapfoldl(selection, OrMultiSelection, [s...])

not(x::Pair{S,<:RenameTarget}) where S = -selection(x.first) => x.second
not(x::Pair{<:AbstractSelection,S}) where S = -x.first => x.second
not(x::Pair{Symbol,Symbol}) = SymbolSelection(x.first, false, x.second)
not(x::Pair{SymbolSelection,Symbol}) = apply_rename(-x.first, ToSymbol(x.second))
not(x::Pair{<:AbstractSymbolSelection,<:RenameTarget}) where S = bool(x.first) ? apply_rename(-x.first, x.second) : -x.first => x.second
not(x::Pair{<:AbstractSelection,<:RenameTarget}) = -x.first => x.second
function not(x::Pair{Vector{:S},Vector{:S}}) where S <: Symbol
    if length(x.first) == length(x.second)
        SymbolSelection.(x.first, (false,), ToSymbol.(x.second))
    else
        @warn("Renaming array had different length ($(length(x.second))) than target selections ($(length(x.first))), renaming skipped.")
        SymbolSelection.(x.first, (false,))
    end
end

not(s::Tuple) = map(-, selection.(s))
not(s::AbstractArray{Bool}) = -selection(s)

not(s) = -selection(s)
not(s...) = mapfoldl(not, AndMultiSelection, [s...])

_positiveselection(df, symbols::Vector{Symbol}, b::Bool) = selection(b ? symbols : setdiff(names(df), symbols))
_positiveselection(df, symbol::Symbol, b::Bool) = selection.(b ? [symbol] : setdiff(names(df), [symbol]))
_positiveselection(df, s::AbstractArray{Bool}, b::Bool) = selection.(b ? names(df)[s] : names(df)[.!s])
_positiveselection(df, f::Function, b::Bool) = selection.(filter((b ? identity : !)(f), names(df)))
function _positiveselection(df, s::SymbolSelection, b::Bool)
    if b
        [s]
    elseif s.r == identity || (typeof(s.r) == ToSymbol && s.r.s == s.s)
        selection.(setdiff(names(df), [s.s]))
    elseif typeof(s.r) == ToSymbol && s.r.s != s.s
        out = setdiff(names(df), [s.s])
        if length(out) == 1
            [SymbolSelection(s.r.s)]
        else
            @warn("Renaming to a sigle new name is not supported for multiple selections ($(length(out))), renaming skipped.")
            selection.(out)
        end
    else
        out = setdiff(names(df), [s.s])
        SymbolSelection.(out, (true,), (s.r,))
    end
end
positiveselection(df, x, b) = PositiveSelectionArray(_positiveselection(df, x, b))


function resolve(df, p::Pair{T,S}) where T where S
     apply_rename(resolve(df, p.first), p.second)
end

function resolve(df, s::SymbolSelection)
    if !(s.s in names(df))
        throw(KeyError("column `$(s.s)` is not present in this $(typeof(df))."))
    else
        positiveselection(df, s, bool(s))
    end
end

function resolve(df, s::IntSelection)
    if length(names(df)) < s.s
        throw(BoundsError("index $(s.s) is out of bounds for this $(typeof(df)) with $(length(names(df))) columns."))
    else
        positiveselection(df, names(df)[s.s], bool(s))
    end
end

function resolve(df, s::BoolSelection)
    if length(names(df)) != length(s.s)
        throw(BoundsError("$(typeof(s.s)) is length $(length(s.s)), but the $(typeof(df)) has $(length(names(df))) columns."))
    else
        positiveselection(df, s.s, s.b)
    end
end

function resolve(df, s::RangeSelection{<:Symbol})
    s1, s2 = s.s1, s.s2
    i = findfirst(x -> x == s1, names(df))
    i == nothing && throw(KeyError("column `$(s1)` is not present in this $(typeof(df))."))

    j = findfirst(x -> x == s2, names(df))
    j == nothing && throw(KeyError("column `$(s2)` is not present in this $(typeof(df))."))

    idx = i > j ? reverse(j:s.step:i) : i:s.step:j
    positiveselection(df, names(df)[idx], bool(s))
end

function resolve(df, s::RangeSelection{<:Int})
    s1, s2 = s.s1, s.s2
    !(s1 >= 1 & s2 <= length(names(df))) && throw(BoundsError())
    idx = s1 > s2 ? reverse(s2:abs(s.step):s1) : s1:s.step:s2
    positiveselection(df, names(df)[idx], bool(s))
end

resolve(df, s::PositiveSelectionArray) = bool(s) ? s : PositiveSelectionArray(setdiff(names(df), s.s))
resolve(df, s::AbstractArray) = length(s) == 1 ? resolve(df, selection(s[1])) : resolve.((df,), selection(s))
resolve(df, s::Tuple) = length(s) == 1 ? resolve(df, selection(s[1])) : resolve.((df,), selection(s))
resolve(df, s::Complement) = s
resolve(df, s::PredicateSelection) = positiveselection(df, x -> s.f(df[!, x]), bool(s))
resolve(df, s::NamePredicateSelection) = positiveselection(df, x -> s.f(string(x)), bool(s))
resolve(df, s::PairPredicateSelection) = positiveselection(df, x -> s.f(string(x), df[!, x]), bool(s))

function resolve_complement(c::Complement, complement_names::Vector{Symbol})
    complement_names .=> (c.f1,)
end


"""
cols(s...)
not(s...)

Wrappers that turn its inputs into `Selection`s and reduces them into a single chained `Selection`.
`cols()` reduces all conditions with an `|` boolean function, `not()` with `&` and also negates its inputs.

`cols(s...)` is rougly `mapfoldl(selection, OrMultiSelection, [s...])`
`not(s...)` is rougly `mapfoldl((-)∘selection, AndMultiSelection, [s...])`
"""
cols, not
