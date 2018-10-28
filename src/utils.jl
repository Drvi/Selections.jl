
namedpair(s) = [i.s => i.r for i in s]

asarray(x::Tuple) = x
asarray(x::AbstractArray) = x
asarray(x::PositiveSelectionArray) = x.s
asarray(x::AbstractSelection) = [x]

getfieldvec(s::Complement, name::Symbol) = [s]
getfieldvec(s, name::Symbol) = [getfield(s, name)]
function getfieldvec(s::AbstractArray, name::Symbol)
      getfield.(s, name)
end

function unfold(A)
    V = Union{Complement,SymbolSelection}[]
    for x in A
        if x === A
            push!(V, x)
        else
            append!(V, unfold(x))
        end
    end
    V
end

resolve_query(df, itr) = unique(unfold(resolve(df, mapfoldl(selection, OrMultiSelection, itr))))

function reduce_renames(sr)
    s = unique(first.(sr))
    [i => foldl(∘, reverse(getfieldvec(filter(x -> x.first == i, sr), :second))) for i in s]
end
