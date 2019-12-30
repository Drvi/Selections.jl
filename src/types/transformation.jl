# When the previous transformation didnt modify the table inplace
# then applying f to rows would ignore the previous transformation.
# One solution is to create a deepcopy of the table, apply the
# previsous transformation inplace on that copy and finally apply f
# to its rows. Copying the whole table is wasteful, so ByRow and
# ByRow! structs can store the columns needed.
for T in (:ByRow, :ByRow!)
    F = Symbol(lowercase(String(T)))
    @eval begin
        struct $(T){Bool,S} <: AbstractTransformation{Bool} where S
            f::S
            cols::Tuple{Vararg{Symbol}}
        end
        $(F)(x::Base.Callable) = $(T){false, typeof(x)}(x, Tuple{Vararg{Symbol,0}}())
        $(F)(x::Base.Callable, cols) = $(T){false, typeof(x)}(x, cols)
        $(F)(x::Pair{Tuple{Vararg{Symbol}},Base.Callable}) = $(T){false, typeof(x)}(last(x), first(x))
        $(F)(x::Pair{Symbol,Base.Callable}) = $(T){false, typeof(x)}(last(x), (first(x),))

        @inline function Broadcast.broadcasted(::typeof($(F)), x::Base.Callable)
            $(T){true, typeof(x)}(x, Tuple{Vararg{Symbol,0}}())
        end
        @inline function Broadcast.broadcasted(::typeof($(F)), x::Base.Callable, cols)
            $(T){true, typeof(x)}(x, cols)
        end
        @inline function Broadcast.broadcasted(::typeof($(F)), x::Pair{Tuple{Vararg{Symbol}},Base.Callable})
            $(T){true, typeof(x)}(last(x), first(x))
        end
        @inline function Broadcast.broadcasted(::typeof($(F)), x::Pair{Symbol,Base.Callable})
            $(T){true, typeof(x)}(last(x), (first(x),))
        end
        @inline (t::$(T){true})(x, colname) = broadcasted(t.f, x, colname)
        @inline (t::$(T){false})(x, colname) = t.f(x, colname)
        Base.show(io::IO, f::$(T){false}) = print(io, $(F), "(", f.f, ")")
        Base.show(io::IO, f::$(T){true}) = print(io, $(F), ".(", f.f, ")")
    end
end

for T in (:ByTab, :ByTab!)
    F = Symbol(lowercase(String(T)))
    @eval begin
        struct $(T){Bool,S} <: AbstractTransformation{Bool} where S
            f::S
            cols::Tuple{Vararg{Symbol}}
        end
        $(F)(x::Base.Callable) = $(T){false, typeof(x)}(x, Tuple{Vararg{Symbol,0}}())
        $(F)(x::Base.Callable, cols) = $(T){false, typeof(x)}(x, cols)
        $(F)(x::Pair{Tuple{Vararg{Symbol}},Base.Callable}) = $(T){false, typeof(x)}(last(x), first(x))
        $(F)(x::Pair{Symbol,Base.Callable}) = $(T){false, typeof(x)}(last(x), (first(x),))

        @inline (t::$(T){false})(x, colname) = t.f(x, colname)
        Base.show(io::IO, f::$(T){false}) = print(io, $(F), "(", f.f, ")")
    end
end

for T in (:ByCol, :ByCol!)
    F = Symbol(lowercase(String(T)))
    @eval begin
        struct $(T){Bool,S} <: AbstractTransformation{Bool} where S
            f::S
        end
        $(F)(x::Base.Callable) = $(T){false, typeof(x)}(x)
        @inline function Broadcast.broadcasted(::typeof($(F)), x::Base.Callable)
            $(T){true, typeof(x)}(x)
        end
        @inline (t::$(T){true})(x) = broadcasted(t.f, x)
        @inline (t::$(T){false})(x) = t.f(x)
        Base.show(io::IO, f::$(T){false}) = print(io, $(F), "(", f.f, ")")
        Base.show(io::IO, f::$(T){true}) = print(io, $(F), ".(", f.f, ")")
    end
end

struct ColumnCreation{S,T,N}
    s::S
    t::T
    n::N
    function ColumnCreation(s::S, t::T, n::N) where {
            S<:Union{Symbol,<:AbstractVector{Symbol},ElementSelection},
            T<:AbstractTransformation,
            N<:Union{RenamingSymbol,RenamingFunction,Symbol}
        }
        new{S,T,N}(s,t,n)
    end
end
function Base.show(io::IO, x::ColumnCreation)
    print(io, "ColumnCreation(", repr(x.s), ", ", x.t, ", ", repr(x.n), ")")
end

struct ColumnCreations{S,T,N}
    s::S
    t::T
    n::N
    function ColumnCreations(s::S,t::T,n::N) where {
            S<:Union{AbstractVector{Symbol},Tuple{Vararg{Symbol}},AbstractSelection},
            T<:AbstractTransformation,
            N<:Union{RenamingFunction,RenamingSymbols}
        }
        new{S,T,N}(s,t,n)
    end
end



const RowwiseTrans{T} = Union{ByRow{T}, ByRow!{T}} where T
const ColwiseTrans{T} = Union{ByCol{T}, ByCol!{T}} where T
const TabwiseTrans{T} = Union{ByTab{T}, ByTab!{T}} where T
const InplaceTrans{T} = Union{ByCol!{T}, ByRow!{T}, ByTab!{T}} where T
const OnCopyTrans{T} = Union{ByCol{T}, ByRow{T}, ByTab{T}} where T

####################################################################################################
# Nested ###########################################################################################
####################################################################################################

apply_trans_nested(::Nothing, colname, tab) = columntable(tab)[colname]

function apply_trans_nested(c::Composition, colname, tab)
    apply_trans_nested(c.funcs, colname, tab, columntable(tab)[colname], nothing)
end

function apply_trans_nested(fs::Tuple, colname, tab, x, f)
    apply_trans_nested(
        Base.tail(fs),
        colname,
        tab,
        _apply_trans_nested(first(fs), f, x, tab, colname),
        first(fs))
end

apply_trans_nested(::Tuple{}, colname, tab, x, f) = x

apply_trans_nested(::Tuple{}, colname, tab, x, f::OnCopyTrans{true}) = materialize(x)

function apply_trans_nested(::Tuple{}, colname, tab, x, f::InplaceTrans{true})
    materialize!(columntable(tab)[colname], x)
end

function apply_trans_nested(::Tuple{}, colname, tab, x, f::InplaceTrans{false})
    copyto!(columntable(tab)[colname], x)
end


# RowwiseTrans #####################################################################################

function _apply_trans_nested(f::RowwiseTrans, prev_f::OnCopyTrans{true}, x, tab, colname)
    if isempty(f.cols)
        _df = deepcopy(tab)
    else
        _df = deepcopy(subset_cols(tab, f.cols))
    end
    materialize!(columntable(_df)[colname], x)
    f(rowtable(_df), colname)
end

function _apply_trans_nested(
        f::RowwiseTrans,
        prev_f::AbstractTransformation{false},
        x,
        tab,
        colname)
    if isempty(f.cols)
        _df = deepcopy(tab)
    else
        _df = deepcopy(subset_cols(tab, f.cols))
    end
    copyto!(columntable(_df)[colname], x)
    f(rowtable(_df), colname)
end

function _apply_trans_nested(f::RowwiseTrans, prev_f::InplaceTrans{true}, x, tab, colname)
    materialize!(columntable(tab)[colname], x)
    f(rowtable(tab), colname)
end

_apply_trans_nested(f::RowwiseTrans, prev_f::Nothing, x, tab, colname) = f(rowtable(tab), colname)

_apply_trans_nested(f::T, prev_f::T, x, tab, colname) where T<:RowwiseTrans{true} = f(rowtable(tab), colname)


# ColwiseTrans #####################################################################################

function _apply_trans_nested(
        f::ColwiseTrans,
        prev_f::Union{AbstractTransformation{false}, Nothing},
        x,
        tab,
        colname)
    f(x)
end

function _apply_trans_nested(f::ColwiseTrans, prev_f::InplaceTrans{true}, x, tab, colname)
    f(materialize!(columntable(tab)[colname], x))
end

function _apply_trans_nested(f::ColwiseTrans, prev_f::OnCopyTrans{true}, x, tab, colname)
    f(materialize(x))
end

_apply_trans_nested(f::T, prev_f::T, x, tab, colname) where T<:ColwiseTrans{true} = f(x)


# TabwiseTrans #####################################################################################

_apply_trans_nested(f::TabwiseTrans, prev_f::Nothing, x, tab, colname) = f(columntable(tab), colname)

function _apply_trans_nested(f::TabwiseTrans, prev_f::AbstractTransformation{false}, x, tab, colname)
    if isempty(f.cols)
        _df = columntable(deepcopy(tab))
    else
        _df = subset_cols(columntable(deepcopy(tab)), f.cols)
    end
    copyto!(_df[colname], x)
    f(_df, colname)
end

function _apply_trans_nested(f::TabwiseTrans, prev_f::InplaceTrans{true}, x, tab, colname)
    _df = columntable(tab)
    materialize!(_df[colname], x)
    f(_df, colname)
end

function _apply_trans_nested(f::TabwiseTrans, prev_f::OnCopyTrans{true}, x, tab, colname)
    if isempty(f.cols)
        _df = columntable(deepcopy(tab))
    else
        _df = subset_cols(columntable(deepcopy(tab)), f.cols)
    end
    materialize!(_df[colname], x)
    f(_df, colname)
end


####################################################################################################
# Flat #############################################################################################
####################################################################################################
# TODO: inplace byrow and bytab

function apply_trans_flat(f::ByRow, selected_colnames, newcolname, nt)
    _selected_colnames = ensure_tuple(length(f.cols) > 1 ? f.cols : selected_colnames)
    materialize(f(rowtable(NamedTuple{_selected_colnames}(nt)), newcolname))
end

function apply_trans_flat(f::ByRow!{false}, selected_colnames, newcolname, nt)
    !(newcolname in colnames(nt)) && throw(KeyError(newcolname))
    _selected_colnames = ensure_tuple(length(f.cols) > 1 ? f.cols : selected_colnames)
    copyto!(nt[newcolname], f(rowtable(NamedTuple{_selected_colnames}(nt)), newcolname))
end

function apply_trans_flat(f::ByRow!{true}, selected_colnames, newcolname, nt)
    !(newcolname in colnames(nt)) && throw(KeyError(newcolname))
    _selected_colnames = ensure_tuple(length(f.cols) > 1 ? f.cols : selected_colnames)
    materialize!(nt[newcolname], f(rowtable(NamedTuple{_selected_colnames}(nt)), newcolname))
end

function apply_trans_flat(f::ByTab{false}, selected_colnames, newcolname, nt)
    _selected_colnames = ensure_tuple(length(f.cols) > 1 ? f.cols : selected_colnames)
    materialize(f(NamedTuple{_selected_colnames}(nt), newcolname))
end

function apply_trans_flat(f::ByTab!{false}, selected_colnames, newcolname, nt)
    !(newcolname in colnames(nt)) && throw(KeyError(newcolname))
    _selected_colnames = ensure_tuple(length(f.cols) > 1 ? f.cols : selected_colnames)
    copyto!(nt[newcolname], f(NamedTuple{_selected_colnames}(nt), newcolname))
end

function apply_trans_flat(f::ByCol, selected_colnames, newcolname, nt)
    if length(selected_colnames) > 1
        throw(error("Multiple columns as an input for $(typeof(f)) is not implemented."))
    else
        materialize(f(nt[@inbounds(selected_colnames[1])]))
    end
end

function apply_trans_flat(f::ByCol!{true}, selected_colnames, newcolname, nt)
    if !(newcolname in colnames(nt))
        throw(KeyError(newcolname))
    elseif length(selected_colnames) > 1
        throw(error("Multiple columns as an input for $(typeof(f)) is not implemented."))
    else
        x = nt[selected_colnames[1]]
        materialize!(x, f(x))
    end
end

function apply_trans_flat(f::ByCol!{false}, selected_colnames, newcolname, nt)
    if !(newcolname in colnames(nt))
        throw(KeyError(newcolname))
    elseif length(selected_colnames) > 1
        throw(error("Multiple columns as an input for $(typeof(f)) is not implemented."))
    else
        x = nt[selected_colnames[1]]
        copyto!(x, f(x))
    end
end

transformation(f::Base.Callable) = bycol(f)
transformation(t::AbstractTransformation) = t

"""
```
bycol(f::Callable)           # ~ f(column)
bycol!(f::Callable)          # ~ f(column)
byrow(f::Callable[, cols])   # ~ f(rowtable, name::Symbol))
byrow!(f::Callable[, cols])  # ~ f(rowtable, name::Symbol))
bytab(f::Callable[, cols])   # ~ f(coltable, name::Symbol))
bytab!(f::Callable[, cols])  # ~ f(coltable, name::Symbol))

bycol.(f::Callable)           # ~ f(element)
bycol!.(f::Callable)          # ~ f(element)
byrow.(f::Callable[, cols])   # ~ f(row, name::Symbol))
byrow!.(f::Callable[, cols])  # ~ f(row, name::Symbol))
```

Wrappers around transformations `f` to be applied to selected columns in `select(tab, args...; kwargs...)`.
`cols` are the source columns to make available inside the function.

As their name suggest, functions wrapped in `bycol[!.]` are applied to individual selected columns,
`byrow[!.]` to rows and `bytab[!]` to a whole table (a `NamedTuple` of columns).
`byrow[!.]` and `bytab[!]` will supply the name of the currently selected column as the second argument to `f`

Functions ending with `!` apply the transformation inplace. This requires the columns to exist
(i.e. you won't be able to create a new column in `kwargs...` this way) and to have the same input and output eltype.

Broadcasting of these wrappers is a signal to interpret the wrapped function `f` as an elementwise function.
You you chain multiple broadcasted transformation together and if they are of same type (e.g. they are all `bycol.`)
then the multiple wrapped function would be fused together.

See also: [`select`](@ref), [`selection`](@ref), [`renaming`](@ref)
"""
bycol, bycol!, byrow, byrow!, bytab, bytab!, transformation
