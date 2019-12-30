function translate_types(p::Pair{S, Pair{R, T}}) where {
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
    selection(first(p), b=true, r=renaming(last(last(p))), t=transformation(first(last(p))))
end

function translate_types(p::Pair{Pair{S, R}, T}) where {
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
    selection(first(first(p)), b=true, r=renaming(first(last(p))), t=transformation(last(last(p))))
end

function translate_types(p::Pair{S,T}) where {S, T <: AbstractTransformation}
    selection(first(p), b=true, r=nothing, t=last(p))
end

function translate_types(p::Pair{S,T}) where {S, T <: Base.Callable}
    throw(ArgumentError(string("`Pair{<:Any,<:Base.Callable}` is ambiguous. ",
    "Use `alias()` to mark the function as a renaming or one of the `transformation` ",
    "functions to mark it as a transformation.")))
end

function translate_types(p::Pair{S,R}) where {
        S,
        R<:Union{
            Pair{<:Union{AbstractString,AbstractChar,Regex},<:Union{AbstractString,AbstractChar,SubstitutionString}},
            AbstractRenaming,
            Symbol,
            AbstractArray{Symbol},
            Tuple{Vararg{Symbol}}
        }
    }
    selection(first(p), b=true, r=renaming(last(p)), t=nothing)
end

translate_types(x) = selection(x)

# Creating columns
function translate_types(p::Pair{S, Pair{T, Symbol}}) where {
        S,
        T <: Union{AbstractTransformation,Base.Callable}
    }
    ColumnCreation(
        selection(first(p)),
        transformation(first(last(p))),
        last(last(p))
    )
end

function translate_types(p::Pair{S, Pair{T, ElementSelection{Symbol}}}) where {
        S,
        T <: Union{AbstractTransformation,Base.Callable}
    }
    ColumnCreation(
        selection(first(p)),
        transformation(last(first(p))),
        last(last(p)).s
    )
end

function translate_types(p::Pair{Pair{S, T}, Symbol}) where {
        S,
        T <: Union{AbstractTransformation,Base.Callable}
    }
    ColumnCreation(
        selection(first(first(p))),
        transformation(first(last(p))),
        last(p)
    )
end

function translate_types(p::Pair{Pair{S, T}, ElementSelection{Symbol}}) where {
        S,
        T <: Union{AbstractTransformation,Base.Callable}
    }
    ColumnCreation(
        selection(first(first(p))),
        transformation(first(last(p))),
        last(p).s
    )
end

# TODO: check lenghts of symbol arrays
function translate_types(p::AbstractVector{<:Pair{Pair{S, T}, AbstractRenaming}}) where {
        S,
        T <: Union{AbstractTransformation,Base.Callable}
    }
    ColumnCreations(
        selection(first(first(p))),
        transformation(last(first(p))),
        last(p)
    )
end

function translate_types(p::AbstractVector{<:Pair{S, <:Pair{T, AbstractRenaming}}}) where {
        S,
        T <: Union{AbstractTransformation,Base.Callable}
    }
    ColumnCreations(
        selection(first(p)),
        transformation(first(last(p))),
        last(last(p))
    )
end

# Stopping criteria
translate_types(x::ColumnCreation) = x
translate_types(x::AbstractSelection) = x
translate_types(p::Pair{S, R}) where {S <: AbstractSelection, R <: AbstractRenaming} = extend_selection(first(p), last(p), nothing)
translate_types(p::Pair{S, T}) where {S <: AbstractSelection, T <: AbstractTransformation} = extend_selection(first(p), nothing, last(p))
function translate_types(p::Pair{S, Pair{R, T}}) where {
        S<:AbstractSelection,
        R<:AbstractRenaming,
        T<:AbstractTransformation
    }
    extend_selection(first(p), first(last(p)), last(last(p)))
end
function translate_types(p::Pair{S, Pair{T, R}}) where {
        S<:AbstractSelection,
        R<:AbstractRenaming,
        T<:AbstractTransformation
    }
    extend_selection(first(p), last(last(p)), first(last(p)))
end
function translate_types(p::Pair{Pair{S, R}, T}) where {
        S<:AbstractSelection,
        R<:AbstractRenaming,
        T<:AbstractTransformation
    }
    extend_selection(first(first(p)), last(first(p)), last(p))
end
function translate_types(p::Pair{Pair{S, T}, R}) where {
        S<:AbstractSelection,
        R<:AbstractRenaming,
        T<:AbstractTransformation
    }
    extend_selection(first(first(p)), last(p), last(fisrt(p)))
end

struct SelectionQuery
    s
end

selection_query(s) = SelectionQuery(mapfoldl(translate_types, OrSelection, [s...]))

function _print_node(io, s, mark, prefix, islast)
    println(io, prefix, "$(mark)── " , s)
end

function _print_node(io, s::AbstractMultiSelection, mark, prefix, islast)
    println(io, prefix, "$(mark)── ", typeof(s).name.name)
    prefix *= islast ? "    " : "│    "
    _print_node(io, s.s1, '├', prefix, false)
    _print_node(io, s.s2, '└', prefix, true)
end

function Base.show(io::IO, s::SelectionQuery)
    println(io, "SelectionQuery:")
    print(io, s)
end
