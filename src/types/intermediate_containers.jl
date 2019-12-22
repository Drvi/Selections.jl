const QueryKeys = AbstractSelection
const TermKeys = Union{Symbol,OtherSelection,ElseSelection}
const Renaming = AbstractRenaming
const Trans = AbstractTransformation
const MaybeRenaming = Union{Nothing,AbstractRenaming}
const MaybeTrans = Union{Nothing,AbstractTransformation}
const MaybeComp = Union{Nothing,Composition}

struct SelectionQuery{S<:QueryKeys, R<:MaybeRenaming, T<:MaybeTrans} <: AbstractMetaSelection
    s::S
    r::R
    t::T
end
SelectionQuery(s::SelectionQuery) = s
SelectionQuery(s::S) where {S<:QueryKeys} = SelectionQuery(s, nothing, nothing)

SelectionQuery(s::S, r::R) where {S<:QueryKeys, R<:MaybeRenaming} =
    SelectionQuery(x, r, nothing)
SelectionQuery(p::Pair{S,R}) where {S<:QueryKeys, R<:MaybeRenaming} =
    SelectionQuery(first(p), last(p), nothing)

SelectionQuery(s::S, t::T) where {S<:QueryKeys, T<:MaybeTrans} =
    SelectionQuery(x, nothing, t)
SelectionQuery(p::Pair{S,T}) where {S<:QueryKeys, T<:MaybeTrans} =
    SelectionQuery(first(p), nothing, last(p))

SelectionQuery(s::S, t::T, r::R) where {S<:QueryKeys, R<:Renaming, T<:Trans} =
    SelectionQuery(s, r, t)
SelectionQuery(p::Pair{S,Pair{R,T}}) where {S<:QueryKeys, R<:MaybeRenaming, T<:MaybeTrans} =
    SelectionQuery(first(p), first(last(p)), last(last(p)))
SelectionQuery(p::Pair{S,Pair{T,R}}) where {S<:QueryKeys, R<:MaybeRenaming, T<:MaybeTrans} =
    SelectionQuery(first(p), last(last(p)), first(last(p)))

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

struct SelectionResult{S} <: AbstractVector{S}
    s::Vector{S}
    SelectionResult(s::AbstractVector{S}) where {S<:SelectionTerm} = new{S}(collect(s))
end
Base.size(s::SelectionResult) = size(s.s)
Base.getindex(s::SelectionResult, i) = getindex(s.s, i)
Base.iterate(x::SelectionResult) = iterate(x.s)
Base.iterate(x::SelectionResult, state) = iterate(x.s, state)
function Base.show(io::IO, mime::MIME{Symbol("text/plain")}, s::SelectionResult)
    print(io, length(s.s), "-element SelectionResult\n")
    foreach(x->println(io, " ", x), s.s)
end

function SelectionResult(xs::Vector{S}, r::RenamingSymbols, t::MaybeTrans) where {
        S <: Union{Symbol,OtherSelection,ElseSelection}
    }
    if length(xs) == length(r.s)
        SelectionResult([
            SelectionTerm(x, Composition(RenamingSymbol(s)), Composition(t))
            for (x, s)
            in zip(xs, r.s)
        ])
    else
        @warn("Renaming array had different length ($(length(r.s))) than target selections ($(length(xs))), renaming skipped.")
        SelectionResult([SelectionTerm(x, nothing, Composition(t)) for x in xs])
    end
end

function SelectionResult(xs::Vector{S}, r::MaybeRenaming, t::MaybeTrans) where {
        S <: Union{Symbol,OtherSelection,ElseSelection}
    }
    SelectionResult([SelectionTerm(x, Composition(r), Composition(t)) for x in xs])
end
function SelectionResult(xs::Vector{S}, r::Union{Composition, MaybeRenaming}, t::Union{Composition, MaybeTrans}) where {
        S <: Union{Symbol,OtherSelection,ElseSelection}
    }
    SelectionResult([SelectionTerm(x, Composition(r), Composition(t)) for x in xs])
end

function SelectionResult(x::S, r::MaybeRenaming, t::MaybeTrans) where {
        S <: Union{Symbol,OtherSelection,ElseSelection}
    }
    SelectionResult([SelectionTerm(x, Composition(r), Composition(t))])
end

function SelectionResult(
        xs::AbstractVector{S},
        rs::AbstractVector{<:MaybeComp},
        ts::AbstractVector{<:MaybeComp}) where {
        S <: Union{Symbol,OtherSelection,ElseSelection}
    }
    SelectionResult([SelectionTerm(x, r, t) for (x, r, t) in zip(xs, rs, ts)])
end

function SelectionResult(xs::SelectionResult, rn::MaybeRenaming, tn::MaybeTrans)
    SelectionResult([SelectionTerm(x, extend(r, rn), extend(t, tn)) for (x, r, t) in xs])
end

colnames(x::SelectionResult) = map(colname, x)
keyfuncs(x::SelectionResult) = map(keyfunc, x)
valfuncs(x::SelectionResult) = map(valfunc, x)


Base.show(io::IO, s::SelectionQuery) = (print(io, "SelectionQuery("); _print_srt(io, s); print(io, ")"))
Base.show(io::IO, s::SelectionTerm) = (print(io, "SelectionTerm("); _print_srt(io, s); print(io, ")"))
function _print_srt(io::IO, s)
    print(io, s.s isa Symbol ? ":" : "", s.s)
    isnothing(s.r) || print(io, " => ", s.r)
    isnothing(s.t) || print(io, " => ", s.t)
end
