
function resolve_or(df, s1::Vector{S}, s2::Vector{T}) where S <: AbstractSelection where T <: AbstractSelection
    b1 = all(bool.(s1))
    b2 = all(bool.(s2))

    if b1 == b2
        if b1
            return union(s1, s2)
        else
            return selection.(setdiff(names(df), getnames(s1), getnames(s2)))
        end
    else
        if b1
            return vcat(s1, selection.(setdiff(names(df), getnames(s1), getnames(s2))))
        else
            return vcat(selection.(setdiff(names(df), getnames(s1), getnames(s2))), s2)
        end
    end
end

resolve_or(df, s1, s2) = resolve_or(df, asarray(s1), asarray(s2))
resolve_or(df, s1, s2::Complement) = vcat(asarray(s1), s2)
resolve_or(df, s1::Complement, s2) = vcat(s1, asarray(s2))


function resolve_and(df, s1::Vector{S}, s2::Vector{T}) where S <: AbstractSelection where T <: AbstractSelection
    b1 = all(bool.(s1))
    b2 = all(bool.(s2))
    vec_s1 = getnames(s1)
    vec_s2 = getnames(s2)

    if b1 == b2
        if b1
            return intersect(s1, s2)
        else
            return selection.(setdiff(names(df), intersect(vec_s1, vec_s2)))
        end
    else
        if b1
            return filter(x -> !(getnames(x) in vec_s2), s1)
        else
            return filter(x -> !(getnames(x) in vec_s1), s2)
        end
    end
end

resolve_and(df, s1, s2) = resolve_and(df, asarray(s1), asarray(s2))
resolve_and(df, s1, s2::Complement) = vcat(asarray(s1), s2)
resolve_and(df, s1::Complement, s2) = vcat(s1, asarray(s2))

function resolve(df, s::OrMultiSelection)
    out = resolve_or(
      df,
      resolve(df, selection(s.s1)),
      resolve(df, selection(s.s2))
    )
    PositiveSelectionArray(bool(s) ? out : selection.(setdiff(names(df), getnames(out))))
end

function resolve(df, s::AndMultiSelection)
    out = resolve_and(
      df,
      resolve(df, selection(s.s1)),
      resolve(df, selection(s.s2))
    )
    PositiveSelectionArray(bool(s) ? out : selection.(setdiff(names(df), getnames(out))))
end
