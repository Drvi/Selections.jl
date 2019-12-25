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
    end
    let _T = Union{AbstractSelection, SelectionQuery, Pair{<:AbstractSelection,<:Any}},
        _S = SelectionQuery{<:AbstractContextSelection}
        # Since operators like & and | have high precendence, we need to make sure
        # the inputs got converted
        @eval ($(op))(s1, s2::S) where S<:$(_T) = $(MS)(s1, s2)
        @eval ($(op))(s1::S, s2) where S<:$(_T) = $(MS)(s1, s2)
        @eval ($(op))(s1::S, s2::T) where {S<:$(_T), T<:$(_T)} = $(MS)(s1, s2)
        # Inverting a selection that contains all the columns results to an empty selection
        @eval (!)(s::$(MS){S,<:Any}) where {S<:$(_S)} =
            throw(ArgumentError(string("Cannot invert ", $(MS) , " containing a ", S)))
        @eval (!)(s::$(MS){<:Any,S}) where {S<:$(_S)} =
            throw(ArgumentError(string("Cannot invert ", $(MS) , " containing a ", S)))
        @eval (!)(s::$(MS){S,T}) where {S<:$(_S), T<:$(_S)} =
            throw(ArgumentError(string("Cannot invert ", $(MS) , " containing a ", S)))
    end
end

for (MS, verb) in [(:AndSelection, "intersect"), (:SubSelection, "setdiff")]
    @eval begin
        @eval $(MS)(s1::T, s2::S, ::Bool) where {T<:AbstractSelection, S<:OtherSelection} =
            throw(ArgumentError(string("Cannot  ", verb, " with an `other_cols()`"))
        @eval $(MS)(s1::S, s2::T, ::Bool) where {T<:AbstractSelection, S<:OtherSelection} =
            throw(ArgumentError(string("Cannot  ", verb, " with an `other_cols()`"))

        @eval $(MS)(s1::T, s2::S, ::Bool) where {T<:AbstractSelection, S<:ElseSelection} =
            throw(ArgumentError(string("Cannot  ", verb, " with an `else_cols()`"))
        @eval $(MS)(s1::S, s2::T, ::Bool) where {T<:AbstractSelection, S<:ElseSelection} =
            throw(ArgumentError(string("Cannot  ", verb, " with an `else_cols()`"))

        @eval $(MS)(s1::T, s2::S, ::Bool) where {T<:AbstractSelection, S<:ColumnCreation} =
            throw(ArgumentError(string("Cannot  ", verb, " when creating new columns"))
        @eval $(MS)(s1::S, s2::T, ::Bool) where {T<:AbstractSelection, S<:ColumnCreation} =
            throw(ArgumentError(string("Cannot  ", verb, " when creating new columns"))
    end
end
