#TODO(optimization): Esp for AndSelection, if we know from first(s) that that column cant be selected,
# skip evaluating it in last(s).
# e.g. `select(tab, cols([false, false, false]) & if_values(x->median(x) > 0)))`
# We can skip all median calls.


_resolve_leaf(tab, s) = SelectionPlan(_resolve(tab, s), keyfunc(s), valfunc(t))
_resolve_leaf(tab, s::ColumnCreation) = _resolve(tab, s)

function _resolve(tab, s::OrSelection)
    res = union_results(tab, _resolve_leaf(tab, first(s)), _resolve_leaf(tab, last(s)))
    if bool(s)
        res
    else
        r = expand(keyfunc(res), keyfunc(s))
        t = expand(valfunc(res), valfunc(s))
        SelectionPlan(positive_selection(tab, colnames(res), bool(s)), r, t)
    end
end

function _resolve(tab, s::AndSelection)
    res = intersect_results(tab, _resolve_leaf(tab, first(s)), _resolve_leaf(tab, last(s)))
    if bool(s)
        res
    else
        r = expand(keyfunc(res), keyfunc(s))
        t = expand(valfunc(res), valfunc(s))
        SelectionPlan(positive_selection(tab, colnames(res), bool(s)), r, t)
    end
end

function _resolve(tab, s::SubSelection)
    res = sub_results(tab, _resolve_leaf(tab, first(s)), _resolve_leaf(tab, last(s)))
    if bool(s)
        res
    else
        r = expand(keyfunc(res), keyfunc(s))
        t = expand(valfunc(res), valfunc(s))
        SelectionPlan(positive_selection(tab, colnames(res), bool(s)), r, t)
    end
end

# Union ############################################################################################

function _union_results_inner!(tab, x, y, out)
    length(x) == 0 && return y
    length(y) == 0 && return x
    yset = Set(colnames(y)) # TODO: fix Any
    # yterms = (;(colnames(y) .=> keyfuncs(y) .=> valfuncs(y))...)  # other_cols() cannot be a nt key
    yterms = Dict(colnames(y) .=> keyfuncs(y) .=> valfuncs(y))
    for xterm in x
        xname = colname(xterm)
        if xname in yset
            funs = yterms[xname]
            push!(
                out,
                SelectionTerm(
                    xname,
                    extend(keyfunc(xterm), first(funs)),
                    extend(valfunc(xterm), last(funs))
                )
            )
            delete!(yset, xname)
        else
            push!(out, xterm)
        end
    end
    for yterm in filter(term -> colname(term) in yset, y)
        push!(out, yterm)
    end
    SelectionPlan(map(identity, out))
end

function union_results(tab, x::SelectionPlan{<:SelectionTerm{ElseSelection}}, y::SelectionPlan)
    SelectionPlan(
        vcat(
            SelectionPlan(
                setdiff(colnames(tab), colnames(y)),
                keyfunc(x[1]),
                valfunc(x[1])
            ),
            y
        )
    )
end

function union_results(tab, x::SelectionPlan, y::SelectionPlan{<:SelectionTerm{ElseSelection}})
    SelectionPlan(
        vcat(
            x,
            SelectionPlan(
                setdiff(colnames(tab), colnames(x)),
                keyfunc(y[1]),
                valfunc(y[1])
            )
        )
    )
end

function union_results(
        tab,
        x,
        y
    )
    out = []  # TODO: fix Any
    _union_results_inner!(tab, x, y, out)
end

function union_results(tab, x::ColumnCreation, y)
end

function union_results(tab, x, y::ColumnCreation)
end

# Intersection #####################################################################################

function intersect_results(tab, x::SelectionPlan, y::SelectionPlan)
    length(x) == 0 && return x
    length(y) == 0 && return y

    out = SelectionTerm{Symbol}[]
    yset = Set(colnames(y))
    yterms = (;(colnames(y) .=> keyfuncs(y) .=> valfuncs(y))...)
    for xterm in x
        xname = colname(xterm)
        if xname in yset
            funs = yterms[xname]
            push!(
                out,
                SelectionTerm(
                    xname,
                    extend(keyfunc(xterm), first(funs)),
                    extend(valfunc(xterm), last(funs))
                )
            )
        end
    end
    SelectionPlan(out)
end

function intersect_results(tab, x::SelectionPlan{<:SelectionTerm{T}}, y::SelectionPlan) where {
        T<:Union{ElseSelection,OtherSelection}
    }
    ArgumentError("Cannot intersect with `$(T)`.")
end

function intersect_results(tab, x::SelectionPlan, y::SelectionPlan{<:SelectionTerm{T}}) where {
        T<:Union{ElseSelection,OtherSelection}
    }
    ArgumentError("Cannot intersect with `$(T)`.")
end

function intersect_results(tab, x::S, y::S) where {
        T<:Union{ElseSelection,OtherSelection},
        S<:SelectionPlan{<:SelectionTerm{T}}
    }
    throw(ArgumentError("Cannot resolve two `$(T)`s."))
end

# Setdiff ##########################################################################################

function sub_results(tab, x::SelectionPlan, y::SelectionPlan)
    yset = Set(colnames(y))
    SelectionPlan(filter(term->!(colname(term) in yset), x))
end

function sub_results(tab, x::SelectionPlan{<:SelectionTerm{T}}, y::SelectionPlan) where {
        T<:Union{ElseSelection,OtherSelection}
    }
    ArgumentError("Cannot subtract `$(T)`.")
end

function sub_results(tab, x::SelectionPlan, y::SelectionPlan{<:SelectionTerm{T}}) where {
        T<:Union{ElseSelection,OtherSelection}
    }
    ArgumentError("Cannot subtract `$(T)`.")
end

function sub_results(tab, x::S, y::S) where {
        T<:Union{ElseSelection,OtherSelection},
        S<:SelectionPlan{<:SelectionTerm{T}}
    }
    throw(ArgumentError("Cannot resolve two `$(T)`s."))
end
