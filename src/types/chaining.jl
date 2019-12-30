for (op, MS) in ((:|, :OrSelection), (:&, :AndSelection), (:-, :SubSelection))
    @eval begin
        struct $(MS){U,V,R,T} <: AbstractMultiSelection{R,T}
            s1::U
            s2::V
            b::Bool
            r::R
            t::T
            function $(MS)(s1, s2, b::Bool=true, r::R=nothing, t::T=nothing) where {R,T}
                s1 = translate_types(s1)
                s2 = translate_types(s2)
                new{typeof(s1),typeof(s2),R,T}(s1, s2, b, r, t)
            end
            function $(MS)(s1::S, s2::S, b::Bool=true, r::R=nothing, t::T=nothing) where {S<:AbstractContextSelection,R,T}
                throw(ArgumentError("Cannot chain two `$(S)`s"))
            end
        end
        (Base.:!)(s::$(MS)) = $(MS)(params(s)..., !bool(s), keyfunc(s), valfunc(s))
        function extend_selection(s::$(MS), r=nothing, t=nothing)
            $(MS)(params(s)..., bool(s), extend(keyfunc(s), r), extend(valfunc(s), t))
        end
    end
    let _T = Union{AbstractSelection, Pair{<:AbstractSelection,<:Any}},
        _S = AbstractContextSelection
        # Since operators like & and | have high precendence, we need to make sure
        # the inputs got converted
        @eval ($(op))(s1, s2::S) where S<:$(_T) = $(MS)(s1, s2)
        @eval ($(op))(s1::S, s2) where S<:$(_T) = $(MS)(s1, s2)
        @eval ($(op))(s1::S, s2::T) where {S<:$(_T), T<:$(_T)} = $(MS)(s1, s2)
        # Inverting a selection that contains all the columns results to an empty selection
        @eval (Base.:!)(s::$(MS){S,<:Any}) where {S<:$(_S)} =
            throw(ArgumentError(string("Cannot invert ", $(MS) , " containing a ", S)))
        @eval (Base.:!)(s::$(MS){<:Any,S}) where {S<:$(_S)} =
            throw(ArgumentError(string("Cannot invert ", $(MS) , " containing a ", S)))
        @eval (Base.:!)(s::$(MS){S,T}) where {S<:$(_S), T<:$(_S)} =
            throw(ArgumentError(string("Cannot invert ", $(MS) , " containing a ", S)))
    end
end

for (MS, verb) in [(:AndSelection, "intersect"), (:SubSelection, "setdiff")]
    @eval begin
        $(MS)(s1::T, s2::S, ::Bool) where {T<:AbstractSelection, S<:OtherSelection} =
            throw(ArgumentError(string("Cannot  ", verb, " with an `other_cols()`")))
        $(MS)(s1::S, s2::T, ::Bool) where {T<:AbstractSelection, S<:OtherSelection} =
            throw(ArgumentError(string("Cannot  ", verb, " with an `other_cols()`")))

        $(MS)(s1::T, s2::S, ::Bool) where {T<:AbstractSelection, S<:ElseSelection} =
            throw(ArgumentError(string("Cannot  ", verb, " with an `else_cols()`")))
        $(MS)(s1::S, s2::T, ::Bool) where {T<:AbstractSelection, S<:ElseSelection} =
            throw(ArgumentError(string("Cannot  ", verb, " with an `else_cols()`")))

        $(MS)(s1::T, s2::S, ::Bool) where {T<:AbstractSelection, S<:ColumnCreation} =
            throw(ArgumentError(string("Cannot  ", verb, " when creating new columns")))
        $(MS)(s1::S, s2::T, ::Bool) where {T<:AbstractSelection, S<:ColumnCreation} =
            throw(ArgumentError(string("Cannot  ", verb, " when creating new columns")))

        $(MS)(s1::T, s2::S, ::Bool) where {T<:AbstractSelection, S<:ColumnCreations} =
            throw(ArgumentError(string("Cannot  ", verb, " when creating new columns")))
        $(MS)(s1::S, s2::T, ::Bool) where {T<:AbstractSelection, S<:ColumnCreations} =
            throw(ArgumentError(string("Cannot  ", verb, " when creating new columns")))
    end
end

function _print_node(io, s, mark, prefix, islast)
    println(io, prefix, "$(mark)── " , s)
end

function _print_node(io, s::AbstractMultiSelection, mark, prefix, islast)
    println(io, prefix, "$(mark)── ", typeof(s).name.name)
    prefix *= islast ? "    " : "│    "
    _print_node(io, first(s), '├', prefix, false)
    _print_node(io, last(s), '└', prefix, true)
end

function Base.show(io::IO, s::AbstractMultiSelection)
    println(io, typeof(s).name.name)
    _print_node(io, first(s), '├', "", false)
    _print_node(io, last(s), '└', "", true)
end
