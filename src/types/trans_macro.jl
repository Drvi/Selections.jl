macro trans(ex)
    (false, trans_helper(ex)...)
end

macro trans!(ex)
    (true, trans_helper(ex)...)
    # inplace. broadcast, args to supply, cols to keep
end

function trans_helper(ex::Expr)
    dotted = false
    if ex.head == :macrocall
        if ex.args[1] == Symbol("@__dot__")
            dotted = true
        end
        ex = ex.args[3]
    end
    if ex.head == Symbol("->")
        arg_names = get_args(ex.args[1])
        println(arg_names, typeof(arg_names))
        code = ex.args[2]
    end
    return dotted, tuple(arg_names), find_used_cols(arg_names, code, Set{Symbol}())
end

function trans_helper(ex::Symbol)
    return false, (), Set{Symbol}()
end

function find_used_cols(container, ex::Expr, cols)
    if ex.head == :block
        find_used_cols(container, ex.args[2], cols)
    elseif ex.head == :call
        for arg in ex.args[2:end]
            find_used_cols(container, arg, cols)
        end
    elseif ex.head == Symbol(".") || ex.head == Symbol(:ref)
        if ex.args[1] in container
            push!(cols, ex.args[2].value)
        end
    end
    return cols
end
find_used_cols(container, ex, cols) = nothing

get_args(x::Symbol) = (x,)
get_args(x::AbstractArray) = Tuple(x)
ger_args(x) = tuple(x)
get_args(x::Expr) = get_args(x.args)

# @trans(row->row.x+row[:y]+1)
# @trans(@. (row, name)->row.x+row[:y]+1)
# @trans(identity)
# @trans!(row->row.x+row[:y]+1)
# @trans!(@. (row, name)->row.x+row[:y]+1)
# @trans!(identity)
