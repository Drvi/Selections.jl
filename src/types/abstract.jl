abstract type AbstractSelection end
(-)(s::Pair{<:AbstractSelection,S}) where S = -first(s) => last(s)
(!)(s::AbstractSelection) = -s
(~)(s::AbstractSelection) = -s
bool(s::AbstractSelection) = s.b
function Base.show(io::IO, s::AbstractSelection)
    !bool(s) && print(io, "-")
    print(io, typeof(s).name.name)
    :f in fieldnames(typeof(s)) ?
        print(io, "(", s.f, ")") :
        print(io, "(", s.s isa Symbol ? ":" : "", s.s, ")")
end

abstract type AbstractContextSelection <: AbstractSelection end
abstract type AbstractMultiSelection <: AbstractSelection end
Base.first(s::AbstractMultiSelection) = s.s1
Base.last(s::AbstractMultiSelection) = s.s2

abstract type AbstractMetaSelection end
abstract type AbstractRenaming end
# abstract type AbstractPermuteCols end
abstract type AbstractTransformation{Bool} end

function translate_types end
function selection end
function renaming end
function transformation end

function cols end
function not end
