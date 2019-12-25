function _translate_types(p::Pair{S, Pair{R, T}}) where {
        S,
        R<:Union{
            Pair{<:Union{AbstractString,AbstractChar,Regex},<:Union{AbstractString,AbstractChar,SubstitutionString}},
            AbstractRenaming,
            Symbol,
            AbstractArray{Symbol},
            Tuple{Vararg{Symbol}}
        },
        T <: Union{AbstractTransformation,Base.Callable}
    }
    selection(first(p), true, renaming(last(last(p))), transformation(first(last(p))))
end

function _translate_types(p::Pair{Pair{S, R}, T}) where {
        S,
        R<:Union{
            Pair{<:Union{AbstractString,AbstractChar,Regex},<:Union{AbstractString,AbstractChar,SubstitutionString}},
            AbstractRenaming,
            Symbol,
            AbstractArray{Symbol},
            Tuple{Vararg{Symbol}}
        },
        T <: Union{AbstractTransformation,Base.Callable}
    }
    selection(first(first(p)), true, renaming(first(last(p))), transformation(last(last(p))))
end

function _translate_types(p::Pair{S,T}) where {S, T <: AbstractTransformation}
    selection(first(p), true, nothing, last(p))
end

function _translate_types(p::Pair{S,T}) where {S, T <: Base.Callable}
    throw(ArgumentError(string("`Pair{<:Any,<:Base.Callable}` is ambiguous. ",
    "Use `alias()` to mark the function as a renaming or one of the `transformation` ",
    "functions to mark it a s transformation.")))
end

function _translate_types(p::Pair{S,R}) where {
        S,
        R<:Union{
            Pair{<:Union{AbstractString,AbstractChar,Regex},<:Union{AbstractString,AbstractChar,SubstitutionString}},
            AbstractRenaming,
            Symbol,
            AbstractArray{Symbol},
            Tuple{Vararg{Symbol}}
        }
    }
    selection(first(p), true, renaming(last(p)), nothing)
end

_translate_types(x) = selection(x)

# Creating columns
function _translate_types(p::Pair{S, Pair{T, Symbol}}) where {
        S,
        T <: Union{AbstractTransformation,Callable}
    }
    ColumnCreation(
        selection(first(p)),
        transformation(first(last(p))),
        last(last(p))
    )
end

function _translate_types(p::Pair{S, Pair{T, SymbolSelection}}) where {
        S,
        T <: Union{AbstractTransformation,Callable}
    }
    ColumnCreation(
        selection(first(p)),
        transformation(last(first(p))),
        last(last(p)).s
    )
end

function _translate_types(p::Pair{Pair{S, T}, Symbol}) where {
        S,
        T <: Union{AbstractTransformation,Base.Callable}
    }
    ColumnCreation(
        selection(first(first(p))),
        transformation(first(last(p))),
        last(p)
    )
end

function _translate_types(p::Pair{Pair{S, T}, SymbolSelection}) where {
        S,
        T <: Union{AbstractTransformation,Base.Callable}
    }
    ColumnCreation(
        selection(first(first(p))),
        transformation(first(last(p))),
        last(p).s
    )
end


# Stopping criteria
_translate_types(x::AbstractSelection) = x
_translate_types(p::Pair{S, R}) where {S <: AbstractSelection, R <: AbstractRenaming} = extend_selection(first(p), last(p), nothing)
_translate_types(p::Pair{S, T}) where {S <: AbstractSelection, T <: AbstractTransformation} = extend_selection(first(p), nothing, last(p))
function _translate_types(p::Pair{S, Pair{R, T}}) where {
        S<:AbstractSelection,
        R<:AbstractRenaming,
        T<:AbstractTransformation
    }
    extend_selection(first(p), first(last(p)), last(last(p)))
end
function _translate_types(p::Pair{S, Pair{T, R}}) where {
        S<:AbstractSelection,
        R<:AbstractRenamin
        T<:AbstractTransformation
    }
    extend_selection(first(p), last(last(p)), first(last(p)))
end
function _translate_types(p::Pair{Pair{S, R}, T}) where {
        S<:AbstractSelection,
        R<:AbstractRenaming,
        T<:AbstractTransformation
    }
    extend_selection(first(first(p)), last(first(p)), last(p))
end
function _translate_types(p::Pair{Pair{S, T}, R}) where {
        S<:AbstractSelection,
        R<:AbstractRenaming,
        T<:AbstractTransformation
    }
    extend_selection(first(first(p)), last(p), last(fisrt(p)))
end

translate_types(x) = SelectionQuery(_translate_types(x))
