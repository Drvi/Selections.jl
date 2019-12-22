# Basically taken from Flux. TODO: just use Tuple?
struct Composition{T<:Tuple}
  funcs::T
  Composition(xs...) = new{typeof(xs)}(xs)
end
Composition(x::Nothing) = nothing
Composition(c::Composition) = c
Base.getindex(x::Composition) = getindex(x.funcs)
Base.getindex(c::Composition, i::AbstractArray) = Composition(c.funcs[i]...)
Base.length(x::Composition) = length(x.funcs)
Base.first(x::Composition) = first(x.funcs)
Base.last(x::Composition) = last(x.funcs)
Base.tail(x::Composition) = Base.tail(x.funcs)
Base.iterate(x::Composition) = iterate(x.funcs)
Base.lastindex(x::Composition) = lastindex(x.funcs)

extend(c::Composition, el) = Composition(c.funcs..., el)
extend(el, c::Composition) = Composition(el, c.funcs...)
extend(a::Nothing, b::Nothing) = nothing
extend(c1::Composition, c2::Composition) = Composition(c1.funcs..., c2.funcs...)
extend(c::Composition, el::Nothing) = c
extend(el::Nothing, c::Composition) = c
extend(f, el::Nothing) = Composition(f)
extend(el::Nothing, f) = Composition(f)
extend(f1, f2) = Composition(f1, f2)

function Base.show(io::IO, c::Composition)
    print(io, "Composition(")
    join(io, c.funcs, ", ")
    print(io, ")")
end
