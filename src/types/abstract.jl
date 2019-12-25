abstract type AbstractSelection{R,T} end
# (!)(s::Pair{<:AbstractSelection,S}) where S = !first(s) => last(s)
(Base.:~)(s::AbstractSelection) = !s
bool(s::AbstractSelection) = s.b::Bool
keyfunc(s::AbstractSelection{R,T}) where {R,T} = s.r::R
valfunc(s::AbstractSelection{R,T}) where {R,T} = s.t::T
params(s::AbstractSelection) = (s.s,)

abstract type AbstractContextSelection{R,T} <: AbstractSelection{R,T}; end
bool(s::AbstractContextSelection) = true
params(s::AbstractSelection) = (s.s1, s.s2)
(Base.:!)(s::S) where S <: AbstractContextSelection = throw(ArgumentError(lowercase(string(S.name, "() cannot be negated."))))
abstract type AbstractMultiSelection{R,T} <: AbstractSelection{R,T} end
Base.first(s::AbstractMultiSelection) = s.s1
Base.last(s::AbstractMultiSelection) = s.s2

abstract type AbstractMetaSelection end
abstract type AbstractRenaming end
abstract type AbstractTransformation{Bool} end

function translate_types end
function selection end
function renaming end
function transformation end

function cols end
function not end
