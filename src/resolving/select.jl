newcolfunc(x) = length(x) == 1 ? @inbounds(x[1]) : rowtable(x)
newcolfunc(x::AbstractArray) = x

process_other!(table, plans::SelectionResult{<:SelectionTerm{Symbol}}) = plans

function process_other!(tab, plans)
    isempty(plans) && (return plans)
    colset = Set(Symbol[])
    other_idxs = Int[]
    other_keyfunc, other_valfunc = nothing, nothing
    for (i, term) in enumerate(plans)
        if colname(term) isa OtherSelection
            push!(other_idxs, i)
            other_keyfunc = extend(other_keyfunc, keyfunc(term))
            other_valfunc = extend(other_valfunc, valfunc(term))
        else
            push!(colset, colname(term))
        end
    end
    other_colnames = isempty(colset) ? colnames(tab) : setdiff(colnames(tab), colset)
    if !isempty(other_colnames)
        if length(other_idxs) > 1
            deleteat!(plans.s, @inbounds(other_idxs[2:end]))
        end
        splice!(
            plans.s,
            @inbounds(other_idxs[1]),
            SelectionTerm.(other_colnames, Ref(other_keyfunc), Ref(other_valfunc))
        )
    else
        deleteat!(plans.s, other_idxs)
    end
end

function rename_colnames(column_names, renamings)
    out::Vector{Symbol} = apply_rename.(renamings, column_names)
    seen = Set()
    to_report = Dict()

    for (renamed, renaming) in zip(out, renamings)
        isnothing(renaming) && (push!(seen, renamed))
    end

    for (i, (column_name, renamed, renaming)) in enumerate(zip(column_names, out, renamings))
        isnothing(renaming) && continue
        new_renamed = renamed
        index = 0

        while new_renamed in seen
            index += 1
            new_renamed = Symbol(string(renamed, index))
        end

        if index > 0
            to_report[column_name] = renamed => new_renamed
            renamed = new_renamed
        end

        push!(seen, renamed)
        out[i] = renamed
    end

    !isempty(to_report) && @warn "Following columns' renaming was modified to preserve uniqueness" to_report
    Tuple(out)
end

function transform_columns(tab, column_names, transforms)
    Tuple(apply_trans_nested(f, c, tab) for (c, f) in zip(column_names, transforms))
end

function select(tab, args...; kwargs...)
    has_args = !isempty(args)
    has_kwargs = !isempty(kwargs)

    if has_args
        # Selection queries -> triplets of selection, renamings and transforms that are generic,
        # can be applied to any Table. Multiple `args` are chained with an `|`.
        # The translate_types function also tries to guess the correct meaning of inputs,
        # i.e. that `:a => :A` is a `selection(:a) => renaming(:A)`.
        queries = mapfoldl(translate_types, OrSelection, ensure_tuple(args))
        # Selection results -> triplets of column names, renamings and transforms that are fitted
        # to this particular table, the generic selections are replaces with actual column names.
        # If multiple selections were overlapping, their renamings and transformations were combined.
        plans = resolve_nested(tab, queries)::SelectionResult
        # the other_cols() are resolved if present
        process_other!(tab, plans)
        # Prepare renamings -- produces unique output names to be applied later
        outnames = rename_colnames(colnames(plans), keyfuncs(plans))
        # Apply transformations to tables columns
        outcols = transform_columns(tab, colnames(plans), valfuncs(plans))
        # At this point, results are in a form of a NamedTuple
        nt = NamedTuple{outnames}(outcols)
    else
        nt = columntable(tab)
    end
    if has_kwargs
        for (new_column_name, _args) in pairs(kwargs)
            # Produce source_columns => transformation pairs.
            plan = resolve_flat(nt, _args)
            # Create the new column
            new_column = apply_trans_flat(last(plan), first(plan), new_column_name, nt)
            # Add the result to our table (NamedTuple), so the next column definition can use them
            nt = merge(nt, (; new_column_name => newcolfunc(new_column)))
        end
    end
    materializer(tab)(nt) # Return a Table of the same "kind" as the input.
end

function rename(tab, args...) end
function transform(tab, args...; kwargs...) end
function select_colnames(tab, args...) end
function select_renames(tab, args...) end

# outnames = Tuple{Vararg{Symbol,length(plans)}}(apply_rename(f, x) for (f, x) in zip(keyfuncs(plans), colnames(plans)))
# outcols = Tuple(apply_trans_nested(f, x, tab) for (f, x) in zip(valfuncs(plans), colnames(plans)))
