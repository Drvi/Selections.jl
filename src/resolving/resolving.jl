# resolve_flat(tab, x::Symbol) = (x in colnames(tab)) ? x => bycol(identity) : throw(KeyError("column `$(x)` is not present in this $(typeof(tab))."))
#
# function resolve_flat(tab, x::Pair{<:Any,<:Callable})
#     column_names = _resolve(tab, selection(first(x)))
#     if length(column_names) > 1
#         column_names => byrow.(last(x), Tuple(column_names))
#     else
#         column_names => transformation(last(x))
#     end
# end
#
# function resolve_flat(tab, x::Pair{<:Any,<:Union{RowwiseTrans,TabwiseTrans}})
#     column_names = _resolve(tab, selection(first(x)))
#     column_names => typeof(last(x))(last(x).f, Tuple(column_names))
# end
#
# function resolve_flat(tab, x::Pair{<:Any,<:ColwiseTrans})
#     _resolve(tab, selection(first(x))) => last(x)
# end

resolve_query(tab, s::SelectionQuery) = _resolve(tab, s.s)

positive_selection(tab, symbols::Tuple{Vararg{Symbol}}, b::Bool) = b ? collect(symbols) : setdiff(colnames(tab), symbols)
positive_selection(tab, symbols::AbstractVector{Symbol}, b::Bool) = b ? symbols : setdiff(colnames(tab), symbols)
positive_selection(tab, symbol::Symbol, b::Bool) = b ? [symbol] : setdiff(colnames(tab), [symbol])
positive_selection(tab, s::AbstractArray{Bool}, b::Bool) = b ? @inbounds(colnames(tab)[s]) : @inbounds(colnames(tab)[.!s])

function _resolve(tab, s::ElementSelection{Symbol})
    if !(s.s in colnames(tab))
        throw(KeyError(s.s))
    else
        SelectionPlan(positive_selection(tab, s.s, bool(s)), s.r, s.t)
    end
end

function _resolve(tab, s::ElementSelection{<:Integer})
    SelectionPlan(positive_selection(tab, colnames(tab)[s.s], bool(s)), s.r, s.t)
end

function _resolve(tab, s::ArraySelection{Bool})
    c = colnames(tab)
    if length(c) != length(s.s)
        throw(BoundsError(c, s.s))
    else
        SelectionPlan(@inbounds(c[bool(s) ? s.s : .!s.s]), s.r, s.t)
    end
end

function _resolve(tab, s::RangeSelection{Symbol})
    s1, s2 = s.s1, s.s2
    c = colnames(tab)

    i = findfirst(x -> x == s1, c)
    i == nothing && throw(KeyError(s1))

    j = findfirst(x -> x == s2, c)
    j == nothing && throw(KeyError(s2))

    idx = i > j ? reverse(j:s.step:i) : i:s.step:j
    SelectionPlan(positive_selection(tab, @inbounds(c[idx]), bool(s)), s.r, s.t)
end

function _resolve(tab, s::RangeSelection{<:Integer})
    s1, s2 = s.s1, s.s2
    c = colnames(tab)
    idx = s1 > s2 ? reverse(s2:abs(s.step):s1) : s1:s.step:s2
    SelectionPlan(positive_selection(tab, c[idx], bool(s)), s.r, s.t)
end

function _resolve(tab, s::ArraySelection{Symbol})
    sd = setdiff(s.s, colnames(tab))
    !(isempty(sd)) && throw(ArgumentError("column$(length(sd) == 1 ? "" : "s") `$(join(sd, "`, `"))` not found."))
    SelectionPlan(positive_selection(tab, s.s, bool(s)), s.r, s.t)
end

function _resolve(tab, s::ArraySelection{<:Integer})
    SelectionPlan(positive_selection(tab, colnames(tab)[s.s], bool(s)), s.r, s.t)
end

function _resolve(tab, s::Union{Tuple,AbstractArray{<:AbstractSelection}})
    if length(s) == 1
        SelectionPlan(_resolve(tab, selection(@inbounds(s[1]))), s.r, s.t)
    else
        SelectionPlan(_resolve(tab, cols(s...)), s.r, s.t)
    end
end

# function _resolve(tab, s::ValuesPredicateSelection)
#     [k for (k, v) in pairs(map(s.f, columntable(tab))) if bool(s) ? v : !v]
# end
# function _resolve(tab, s::KeysPredicateSelection)
#     c = colnames(tab)
#     [k for (k, v) in (c .=> map(s.f, string.(c))) if bool(s) ? v : !v]
# end
function _resolve(tab, s::PairsPredicateSelection)
    SelectionPlan(
        [k for (k, v) in pairs(columntable(tab)) if bool(s) ? s.f(string(k), v) : !s.f(string(k), v)],
        s.r,
        s.t)
end
_resolve(tab, s::AllSelection) = collect(colnames(tab))
_resolve(tab, s::ColumnCreation) = ColumnCreation(_resolve(tab, s.s), s.t, _resolve(s.n))

# These needs to be resolved at later stage
_resolve(tab, s::OtherSelection) = OtherSelection(_resolve(s.s), keyfunc(s), valfunc(s))
_resolve(tab, s::ElseSelection) = ElseSelection(_resolve(s.s), keyfunc(s), valfunc(s))
