for (op, MS) in ((:|, :OrSelection), (:&, :AndSelection), (:-, :SubSelection))
    @eval begin
        struct $(MS){U,V} <: AbstractMultiSelection
            s1::U
            s2::V
            b::Bool
            function $(MS)(s1, s2, b::Bool)
                s1 = translate_types(s1)
                s2 = translate_types(s2)
                new{typeof(s1), typeof(s2)}(s1, s2, b)
            end
            function $(MS)(s1::T, s2::T, b::Bool) where T<:AbstractContextSelection
                throw(ArgumentError("Cannot chain two `s1`s"))
            end
        end
        $(MS)(s1, s2) = $(MS)(s1, s2, true)
        (!)(s::$(MS)) = $(MS)(s.s1, s.s2, !bool(s))
    end
    let _T = Union{AbstractSelection, SelectionQuery, Pair{<:AbstractSelection,<:Any}},
        _S = SelectionQuery{<:AbstractContextSelection}
        # Since operators like & and | have high precendence, we need to make sure
        # the inputs got selectioned / combined
        @eval ($(op))(s1, s2::S) where S<:$(_T) = $(MS)(s1, s2)
        @eval ($(op))(s1::S, s2) where S<:$(_T) = $(MS)(s1, s2)
        @eval ($(op))(s1::S, s2::T) where {S<:$(_T), T<:$(_T)} = $(MS)(s1, s2)
        # Negating a selection that contains all the columns results to an empty selection
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
