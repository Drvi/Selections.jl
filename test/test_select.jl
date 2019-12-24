
function test_renaming_queries(section, queries, tab)
    @testset "$section" begin
        for (sel, res) in queries
            @test s.select(tab, sel...) == _select_rename(tab, res)
        end
    end
end

function test_queries(section, queries, tab)
    @testset "$section" begin
        for (sel, res) in queries
            @test s.select(tab, sel...) == _select_subset(tab, res)
        end
    end
end

function test_queries_and_errors(section, queries, errors, tab)
    @testset "$section" begin
        @testset "queries" begin
            for (sel, res) in queries
                @test s.select(tab, sel...) == _select_subset(tab, res)
            end
        end
        @testset "errors" begin
            for (sel, res) in errors
                @test_throws res s.select(tab, eval(sel)...)
            end
        end
    end
end

# https://github.com/JuliaLang/julia/issues/25612
function test_renaming_queries_warn(section, queries, tab)
    @testset "$section" begin
        for (query, msg) in queries
            (sel, res) = query
            @test_logs (:warn, msg) (@test s.select(tab, sel...) == _select_rename(tab, res))
        end
    end
end

function test_transforms(section, tab)
    base = Tables.columntable(tab).a
    @testset "$section" begin
        @test all((_pull(select(tab, :a => bycol.(x->x + 1)), :a) .- base) .== 1)
        @test all((_pull(select(tab, :a => byrow.((r,c)->r[c] + 1)), :a) .- base) .== 1)
        @test all((_pull(select(tab, :a => bycol(x->x .+ 1)), :a) .- base) .== 1)
        @test all((_pull(select(tab, :a => byrow((r,c)->getindex.(r, c) .+ 1)), :a) .- base) .== 1)
        @test all((_pull(select(tab, :a => bytab((t,c)->t[c] .+ 1)), :a) .- base) .== 1)
        @test all((_pull(select(deepcopy(tab), :a => bycol!.(x->x + 1)), :a) .- base) .== 1)
        @test all((_pull(select(deepcopy(tab), :a => byrow!.((r,_)->r.a + 1)), :a) .- base) .== 1)
        @test all((_pull(select(deepcopy(tab), :a => bycol!(x->x .+ 1)), :a) .- base) .== 1)
        @test all((_pull(select(deepcopy(tab), :a => byrow!((r,c)->getindex.(r, c) .+ 1)), :a) .- base) .== 1)
        @test all((_pull(select(deepcopy(tab), :a => bytab!((t,_)->t.a .+ 1)), :a) .- base) .== 1)
    end
end

function test_transforms(section, first_trans, tab)
    base = Tables.columntable(tab).a
    @testset "$section" begin
        @test all((_pull(select(deepcopy(tab), (:a, :b) => first_trans, :a => bycol.(x->x + 1)), :a) .- base) .== 2)
        @test all((_pull(select(deepcopy(tab), (:a, :b) => first_trans, :a => byrow.((r,c)->r[c] + 1)), :a) .- base) .== 2)
        @test all((_pull(select(deepcopy(tab), (:a, :b) => first_trans, :a => bycol(x->x .+ 1)), :a) .- base) .== 2)
        @test all((_pull(select(deepcopy(tab), (:a, :b) => first_trans, :a => byrow((r,c)->getindex.(r, c) .+ 1)), :a) .- base) .== 2)
        @test all((_pull(select(deepcopy(tab), (:a, :b) => first_trans, :a => bytab((t,c)->t[c] .+ 1)), :a) .- base) .== 2)
        @test all((_pull(select(deepcopy(tab), (:a, :b) => first_trans, :a => bycol!.(x->x + 1)), :a) .- base) .== 2)
        @test all((_pull(select(deepcopy(tab), (:a, :b) => first_trans, :a => byrow!.((r,_)->r.a + 1)), :a) .- base) .== 2)
        @test all((_pull(select(deepcopy(tab), (:a, :b) => first_trans, :a => bycol!(x->x .+ 1)), :a) .- base) .== 2)
        @test all((_pull(select(deepcopy(tab), (:a, :b) => first_trans, :a => byrow!((r,c)->getindex.(r, c) .+ 1)), :a) .- base) .== 2)
        @test all((_pull(select(deepcopy(tab), (:a, :b) => first_trans, :a => bytab!((t,_)->t.a .+ 1)), :a) .- base) .== 2)
    end
end

function test_newcols(section, tab)
    base = Tables.columntable(tab).a
    @testset "$section" begin
        @test all((_pull(select(tab, t = :a => bycol.(x->x + 1)), :t) .- base) .== 1)
        @test all((_pull(select(tab, t = :a => byrow.((r,c)->r.a + 1)), :t) .- base) .== 1)
        @test all((_pull(select(tab, t = :a => bycol(x->x .+ 1)), :t) .- base) .== 1)
        @test all((_pull(select(tab, t = :a => byrow((r,c)->getindex.(r, :a) .+ 1)), :t) .- base) .== 1)
        @test all((_pull(select(tab, t = :a => bytab((t,c)->t.a .+ 1)), :t) .- base) .== 1)
        @test all((_pull(select(deepcopy(tab), a = :a => bycol!.(x->x + 1)), :a) .- base) .== 1)
        @test all((_pull(select(deepcopy(tab), a = :a => byrow!.((r,_)->r.a + 1)), :a) .- base) .== 1)
        @test all((_pull(select(deepcopy(tab), a = :a => bycol!(x->x .+ 1)), :a) .- base) .== 1)
        @test all((_pull(select(deepcopy(tab), a = :a => byrow!((r,c)->getindex.(r, :a) .+ 1)), :a) .- base) .== 1)
        @test all((_pull(select(deepcopy(tab), a = :a => bytab!((t,_)->t.a .+ 1)), :a) .- base) .== 1)
        @test_throws KeyError select(deepcopy(tab), t = :a => bycol!.(x->x + 1))
        @test_throws KeyError select(deepcopy(tab), t = :a => byrow!.((r,_)->r.a + 1))
        @test_throws KeyError select(deepcopy(tab), t = :a => bycol!(x->x .+ 1))
        @test_throws KeyError select(deepcopy(tab), t = :a => byrow!((r,c)->getindex.(r, :a) .+ 1))
        @test_throws KeyError select(deepcopy(tab), t = :a => bytab!((t,_)->t.a .+ 1))
    end
end


symbol_queries = [
    (:a,) => [:a],
    (!cols(:b),) => [:a, :c1],
    (not(:c1),) => [:a, :b],
    (not(:a, :b, :c1),) => [],
    (:b, :a) => [:b, :a],
    ((:b, :a)) => [:b, :a],
    (!cols(:b, :c1),) => [:a],
    (not(:b, :c1),) => [:a],
    (!(cols(:b) | cols(:c1)),) => [:a],
    (not(cols(:b) & cols(:c1)),) => [:a, :b, :c1],
    (not(not(:a)),) => [:a]
]

symbol_errors = [
    :(:A,) => KeyError,
    :(cols(:A),) => KeyError,
    :((:a, :A)) => KeyError,
    :(!cols(:A),) => KeyError
]

int_queries = [
    (1,) => [:a],
    (!cols(:b),) => [:a, :c1],
    (not(3),) => [:a, :b],
    (2, 1) => [:b, :a],
    ((2, 1)) => [:b, :a],
    (!cols(2, 3),) => [:a],
    (not(2, 3),) => [:a],
    (!(cols(2) | cols(3)),) => [:a],
    (not(cols(2) & cols(3)),) => [:a, :b, :c1]
]

int_errors = [
    :((4,)) => BoundsError,
    :((0,)) => ArgumentError,
    :((4, 1)) => BoundsError,
    :(!cols(4),) => BoundsError
]

mixed_queries = [
    (1, :b) => [:a , :b],
    ((2, :a)) => [:b , :a],
    ([2, :a],) => [:b, :a],
    (!cols(2, :c1),) => [:a],
    (~cols(2, :c1),) => [:a],
    (cols(:b, 1),) => [:b, :a],
    ([2, 1],) => [:b, :a]
]

mixed_errors = [
    :(:c1, 4) => BoundsError,
    :(0, :a) => ArgumentError,
    :(1, :D) => KeyError
]

int_range_queries = [
    (1:1,) => [:a],
    (!cols(2:2),) => [:a, :c1],
    (1:2,) => [:a, :b],
    (1:2:3,) => [:a, :c1],
    (!cols(1:2:3),) => [:b]
]

int_range_errors = [
    :(0:3,) => ArgumentError,
    :(4:4,) => BoundsError,
    :(-4:-4) => BoundsError,
    :(-3:-3,) => BoundsError,
]

symbol_range_queries = [
    (colrange(:a, :a),) => [:a], (!colrange(:b, :b),) => [:a, :c1],
    (colrange(:c1, :b),) => [:c1, :b], (colrange(:a, :b),) => [:a, :b],
    (colrange(:c1, :a, by=2),) => [:c1, :a],
    (colrange(1, 1),) => [:a], (!colrange(2, 2),) => [:a, :c1],
    (colrange(3, 2),) => [:c1, :b], (colrange(1, 2),) => [:a, :b],
    (colrange(3, 1, by=2),) => [:c1, :a]
]

symbol_range_errors = [
    :(colrange(:a, :d),) => KeyError,
    :(colrange(:d, :d),) => KeyError,
    :(!colrange(:d, :d),) => KeyError,
    :(colrange(1, 4),) => BoundsError,
    :(colrange(0, 0),) => ArgumentError,
    :(!colrange(4, 0),) => ArgumentError
]

bool_queries = [
    ([true, true, true],) => [:a, :b, :c1], (:b, [false, false, false], :a) => [:b, :a],
    ([false, true, false],) => [:b],  (!cols([true, false, true]),) => [:b],
    (.![false, true, false],) => [:a, :c1]
]

bool_errors = [
    :([true],) => BoundsError,
    :([false, false, false, false],) => BoundsError
]

regex_queries = [
    (if_matches(r"."),) => [:a, :b, :c1], (if_matches(r"a"),) => [:a],
    (!if_matches(r"b"),) => [:a, :c1], (!if_matches(r"c"),) => [:a, :b],
    (if_matches("c"),) => [:c1], (!if_matches('b'),) => [:a, :c1],
    (if_keys(x->length(x) == 2),) => [:c1], (~if_keys(x->length(x) == 1),) => [:c1]
]

predicate_queries = [
    (if_values(x -> !any(ismissing.(x))),) => [:a, :b, :c1],
    (!if_values(x -> !any(ismissing.(x))),) => [],
    (!if_values(x -> !any(ismissing.(x))),) => [],
    (if_eltype(Char),) => [:b],
    (~if_eltype(Int),) => [:b, :c1],
    (if_pairs((k,v) -> k == "a" || eltype(v) == Char),) => [:a, :b],
    (!if_pairs((k,v) -> k == "a" || eltype(v) == Char),) => [:c1]
]

combined_queries = [
    (if_eltype(Int) | if_matches(r"b"),) => [:a, :b],
    (!if_eltype(Int) | if_matches(r"b"),) => [:b, :c1],
    (!if_eltype(Int) & if_matches(r"b"),) => [:b],
    (cols(:c1, (not(:a) & if_matches(r"b"))) | cols(:a),) => [:c1, :b, :a],
    (not(:c1) & not(:b),) => [:a],
    (cols(:c1) | cols(:a),) => [:c1, :a]
]

context_queries = [
    (:b, all_cols()) => [:b, :a, :c1],
    (:c1, :a, all_cols(), :b) => [:c1, :a, :b],
    (all_cols(),) => [:a, :b, :c1],
    (:b, other_cols()) => [:b, :a, :c1],
    (:c1, :a, other_cols(), :b) => [:c1, :a, :b],
    (:b, else_cols()) => [:b, :a, :c1],
    (:c1, :a, else_cols(), :b) => [:c1, :a, :b]
]

context_errors = [:(cols(:a) & all_cols()) => MethodError]

renaming_queries = [
    (all_cols() => key_map(uppercase),) => [:a => :A, :b => :B, :c1 => :C1],
    (:a => :X,) => [:a => :X],
    ((cols(:a) | cols(:b)) => key_map(uppercase),) => [:a => :A, :b => :B],
    (1:2 => [:X, :Y],) => [:a => :X, :b => :Y],
    (1:2 => key_map(uppercase),) => [:a => :A, :b => :B],
    (1 => key_prefix("A"), :b => key_suffix("B"),) => [:a => :Aa, :b => :bB],
    (:c1 => key_suffix("C"), not(:b) => key_suffix("D"),) => [:c1 => :c1CD, :a => :aD]
]

# TODO: Make the warnings opt-in, error by default
renaming_queries_warn = [
    (query = (:a => [:X, :Y],) => [:a => :a],
     msg = "Renaming array had different length (2) than target selections (1), renaming skipped."),
    (query = (1:3 => [:X, :Y],) => [:a => :a, :b => :b, :c1 => :c1],
     msg = "Renaming array had different length (2) than target selections (3), renaming skipped."),
    (query = (1:2 => [:X],) => [:a => :a, :b => :b],
     msg = "Renaming array had different length (1) than target selections (2), renaming skipped."),
    (query = (1:2 => :X,) => [:a => :X, :b => :X1],
     msg = "Following columns' renaming was modified to preserve uniqueness"),
    (query = (:a => :b, :b, :c1 => :b) => [:a => :b1, :b => :b, :c1 => :b2],
     msg = "Following columns' renaming was modified to preserve uniqueness")
]


@testset "select" begin
    for (tab, pkg) in [(df, :DataFrames), (jdb, :JuliaDB), (tt, :TypedTables)]
        @testset "$(pkg)" begin
            @time test_queries_and_errors("Symbol", symbol_queries, symbol_errors, tab)
            @time test_queries_and_errors("Int", int_queries, int_errors, tab)
            @time test_queries_and_errors("Int+Symbol", mixed_queries, mixed_errors, tab)
            @time test_queries_and_errors("IntRange", int_range_queries, int_range_errors, tab)
            @time test_queries_and_errors("SymbolRange", symbol_range_queries, symbol_range_errors, tab)
            @time test_queries_and_errors("Bool", bool_queries, bool_errors, tab)
            @time test_queries("Matches", regex_queries, tab)
            @time test_queries("Predicate", predicate_queries, tab)
            @time test_queries("Chaining", combined_queries, tab)
            @time test_queries_and_errors("Complement", context_queries, context_errors, tab)
            @time test_renaming_queries("Renaming", renaming_queries, tab)
            @time test_renaming_queries_warn("Renaming Warning", renaming_queries_warn, tab)
            @time test_transforms("transform", tab)
            @time test_transforms("transform bycol", bycol(x -> x .+ 1), tab)
            @time test_transforms("transform bycol!", bycol!(x -> x .+ 1), tab)
            @time test_transforms("transform bycol.", bycol.(x -> x + 1), tab)
            @time test_transforms("transform bycol!.", bycol!.(x -> x + 1), tab)
            @time test_transforms("transform byrow", byrow((x, c) -> getindex.(x, c) .+ 1), tab)
            @time test_transforms("transform byrow!", byrow!((x, c) -> getindex.(x, c) .+ 1), tab)
            @time test_transforms("transform byrow.", byrow.((x, c) -> x[c] + 1), tab)
            @time test_transforms("transform byrow!.", byrow!.((x, c) -> x[c] + 1), tab)
            @time test_transforms("transform bytab", bytab((x, c) -> x[c] .+ 1), tab)
            @time test_transforms("transform bytab!", bytab!((x, c) -> x[c] .+ 1), tab)
            @time test_newcols("add new column", tab)
        end
    end
end
