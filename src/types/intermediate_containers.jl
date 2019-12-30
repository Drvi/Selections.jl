const QueryKeys = AbstractSelection
const TermKeys = Union{Symbol,OtherSelection,ElseSelection}
const Renaming = AbstractRenaming
const Trans = AbstractTransformation
const MaybeRenaming = Union{Nothing,AbstractRenaming}
const MaybeTrans = Union{Nothing,AbstractTransformation}
const MaybeComp = Union{Nothing,Composition}

struct SelectionTerm{S<:TermKeys, R<:MaybeComp, T<:MaybeComp} <: AbstractMetaSelection
    s::S
    r::R
    t::T
end
colname(s::SelectionTerm) = s.s
keyfunc(s::SelectionTerm) = s.r
valfunc(s::SelectionTerm) = s.t
Base.iterate(s::SelectionTerm) = (colname(s), (keyfunc(s), valfunc(s)))
Base.iterate(s::SelectionTerm, state) = (first(state), Base.tail(state))
Base.iterate(s::SelectionTerm, ::Type{Tuple}) = nothing
function Base.show(io::IO, s::SelectionTerm)
    print(io,
        "SelectionTerm(",
        repr(colname(s)),
        isnothing(keyfunc(s)) ? "" : " => $(keyfunc(s))",
        isnothing(valfunc(s)) ? "" : " => $(valfunc(s))",
        ")"
    )
end

struct SelectionPlan{S} <: AbstractVector{S}
    s::Vector{S}
    SelectionPlan(s::AbstractVector{S}) where {S<:SelectionTerm} = new{S}(collect(s))
end
Base.size(s::SelectionPlan) = size(s.s)
Base.getindex(s::SelectionPlan, i) = getindex(s.s, i)
Base.iterate(x::SelectionPlan) = iterate(x.s)
Base.iterate(x::SelectionPlan, state) = iterate(x.s, state)
function Base.show(io::IO, mime::MIME{Symbol("text/plain")}, s::SelectionPlan)
    println(io, length(s.s), "-element SelectionPlan")
    foreach(x->println(io, " ", x), s.s)
end

function SelectionPlan(xs::Vector{S}, r::RenamingSymbols, t::MaybeTrans) where {
        S <: Union{Symbol,OtherSelection,ElseSelection}
    }
    if length(xs) == length(r.s)
        SelectionPlan([
            SelectionTerm(x, Composition(RenamingSymbol(s)), Composition(t))
            for (x, s)
            in zip(xs, r.s)
        ])
    else
        @warn("Renaming array had different length ($(length(r.s))) than target selections ($(length(xs))), renaming skipped.")
        SelectionPlan([SelectionTerm(x, nothing, Composition(t)) for x in xs])
    end
end

function SelectionPlan(xs::Vector{S}, r::MaybeRenaming, t::MaybeTrans) where {
        S <: Union{Symbol,OtherSelection,ElseSelection}
    }
    SelectionPlan([SelectionTerm(x, Composition(r), Composition(t)) for x in xs])
end
function SelectionPlan(xs::Vector{S}, r::Union{Composition, MaybeRenaming}, t::Union{Composition, MaybeTrans}) where {
        S <: Union{Symbol,OtherSelection,ElseSelection}
    }
    SelectionPlan([SelectionTerm(x, Composition(r), Composition(t)) for x in xs])
end

function SelectionPlan(x::S, r::MaybeRenaming, t::MaybeTrans) where {
        S <: Union{Symbol,OtherSelection,ElseSelection}
    }
    SelectionPlan([SelectionTerm(x, Composition(r), Composition(t))])
end

function SelectionPlan(
        xs::AbstractVector{S},
        rs::AbstractVector{<:MaybeComp},
        ts::AbstractVector{<:MaybeComp}) where {
        S <: Union{Symbol,OtherSelection,ElseSelection}
    }
    SelectionPlan([SelectionTerm(x, r, t) for (x, r, t) in zip(xs, rs, ts)])
end

function SelectionPlan(xs::SelectionPlan, rn::MaybeRenaming, tn::MaybeTrans)
    SelectionPlan([SelectionTerm(x, extend(r, rn), extend(t, tn)) for (x, r, t) in xs])
end

colnames(x::SelectionPlan) = map(colname, x)
keyfuncs(x::SelectionPlan) = map(keyfunc, x)
valfuncs(x::SelectionPlan) = map(valfunc, x)
