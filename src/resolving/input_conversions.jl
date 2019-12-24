
function _translate_types(p::Pair{T, Pair{S, P}}) where {
        T,
        S <: Union{AbstractTransformation,Callable},
        P
    }
    selection(first(p)) => transformation(first(last(p))) => renaming(last(last(p)))
end

function _translate_types(p::Pair{T, Pair{S, P}}) where {
        T,
        S,
        P <: Union{AbstractTransformation,Callable}
    }
    selection(first(p)) => renaming(first(last(p))) => transformation(last(last(p)))
end

function _translate_types(p::Pair{T, S}) where {T, S <: AbstractTransformation}
    selection(first(p)) => last(p)
end

function _translate_types(p::Pair{T, S}) where {
        T,
        S<:Union{
            Pair{<:Union{Regex,AbstractString},SubstitutionString},
            AbstractRenaming,
            Symbol,
            AbstractArray{Symbol},
            Tuple{Vararg{Symbol}}
        }
    }
    selection(first(p)) => renaming(last(p))
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
end

function _translate_types(p::Pair{S, Pair{T, SymbolSelection}}) where {
        S,
        T <: Union{AbstractTransformation,Callable}
    }
    ColumnCreation(
        selection(first(p)),
        transformation(first(last(p))),
        last(last(p)).s
end


# Stopping criteria
_translate_types(x::AbstractSelection) = x
_translate_types(p::Pair{T, S}) where {T <: AbstractSelection, S <: AbstractRenaming} = p
_translate_types(p::Pair{S, T}) where {S <: AbstractSelection, T <: AbstractTransformation} = p
function _translate_types(p::Pair{T, Pair{S, P}}) where {
        T<:AbstractSelection,
        S<:AbstractRenaming,
        P<:AbstractTransformation
    }
    p
end
function _translate_types(p::Pair{T, Pair{S, P}}) where {
        T<:AbstractSelection,
        S<:AbstractTransformation,
        P<:AbstractRenaming
    }
    first(p) => last(last(p)) => first(last(p))
end

translate_types(x) = SelectionQuery(_translate_types(x))
