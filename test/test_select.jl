
function test_renaming_queries(section, queries)
    @testset "$section" begin
        for (sel, res) in queries
            eval(:(@test s.select(df, $sel...) == DataFrames.rename(df[:, $(first.(res))], $(res...))))
        end
    end
end

function test_queries(section, queries)
    @testset "$section" begin
        for (sel, res) in queries
            eval(:(@test s.select(df, $sel...) == df[:, $res]))
        end
    end
end

function test_queries_and_errors(section, queries, errors)
    @testset "$section" begin
        @testset "queries" begin
            for (sel, res) in queries
                eval(:(@test s.select(df, $sel...) == df[:, $res]))
            end
        end
        @testset "errors" begin
            for (sel, res) in errors
                eval(:(@test_throws $res s.select(df, $sel...)))
            end
        end
    end
end

function test_renaming_queries_bang(section, queries)
    @testset "$section" begin
        for (sel, res) in queries
            eval(:(@test s.select!(copy(df), $sel...) == DataFrames.rename(df[:, $(first.(res))], $(res...))))
        end
    end
end

function test_queries_bang(section, queries)
    @testset "$section" begin
        for (sel, res) in queries
            eval(:(@test s.select!(copy(df), $sel...) == df[:, $res]))
        end
    end
end

function test_queries_and_errors_bang(section, queries, errors)
    @testset "$section" begin
        @testset "queries" begin
            for (sel, res) in queries
                eval(:(@test s.select!(copy(df), $sel...) == df[:, $res]))
            end
        end
        @testset "errors" begin
            for (sel, res) in errors
                eval(:(@test_throws $res s.select!(copy(df), $sel...)))
            end
        end
    end
end

# https://github.com/JuliaLang/julia/issues/25612
function test_renaming_queries_warn(section, queries)
    @testset "$section" begin
        for (query, msg) in queries
            (sel, res) = query
            eval(:(@test_logs (:warn, $msg) s.select(df, $sel...)))
        end
    end
end

function test_renaming_queries_warn_bang(section, queries)
    @testset "$section" begin
        for (query, msg) in queries
            (sel, res) = query
            cp_df = copy(df)
            eval(:(@test_logs (:warn, $msg) s.select!($cp_df, $sel...)))
            eval(:(@test $cp_df == df[:, $(first.(res))]))
        end
    end
end

symbol_queries = [:(:a,) => [:a], :(-cols(:b),) => [:a, :c1], :(not(:c1),) => [:a, :b], :(not(:a, :b, :c1),) => [],
                  :(:b, :a) => [:b, :a], :((:b, :a)) => [:b, :a], :(-cols(:b, :c1),) => [:a],  :(not(:b, :c1),) => [:a],
                  :(-(cols(:b) | cols(:c1)),) => [:a],  :(not(cols(:b) & cols(:c1)),) => [:a, :b, :c1], :(not(not(:a)),) => [:a]]

symbol_errors = [:(:A,) => KeyError, :(cols(:A),) => KeyError, :((:a, :A)) => KeyError, :(-cols(:A),) => KeyError]

int_queries = [:(1,) => [:a], :(-cols(:b),) => [:a, :c1], :(not(3),) => [:a, :b], :((-3,)) => [:a, :b],
               :(2, 1) => [:b, :a], :((2, 1)) => [:b, :a], :(-cols(2, 3),) => [:a],  :(not(2, 3),) => [:a],
               :(-(cols(2) | cols(3)),) => [:a],  :(not(cols(2) & cols(3)),) => [:a, :b, :c1]]

int_errors = [:((4,)) => BoundsError, :((0,)) => ArgumentError, :((4, 1)) => BoundsError, :((0, -2)) => ArgumentError, :(-cols(4),) => BoundsError]

mixed_queries = [:(1, :b) => [:a , :b], :((2, :a)) => [:b , :a], :([2, :a],) => [:b, :a], :(-cols(2, :c1),) => [:a],
                 :(!cols(2, :c1),) => [:a], :(~cols(2, :c1),) => [:a], :(cols(:b, 1),) => [:b, :a]]
mixed_errors = [:(:c1, 4) => BoundsError, :(0, :a) => ArgumentError, :(1, :D) => KeyError]

int_range_queries = [:(1:1,) => [:a], :(!cols(2:2),) => [:a, :c1], :(-3:-3,) => [:a, :b],
                     :(1:2,) => [:a, :b], (1:2:3,) => [:a, :c1],
                      (-3:2:-1,) => [:b]]

int_range_errors = [:(0:3,) => ArgumentError, :(4:4,) => BoundsError, :(-4:-4) => BoundsError]

symbol_range_queries = [:(colrange(:a, :a),) => [:a], :(!colrange(:b, :b),) => [:a, :c1],
                        :(colrange(:c1, :b),) => [:c1, :b], :(colrange(:a, :b),) => [:a, :b],
                        :(colrange(:c1, :a, by=2),) => [:c1, :a],
                        :(colrange(1, 1),) => [:a], :(!colrange(2, 2),) => [:a, :c1],
                        :(colrange(3, 2),) => [:c1, :b], :(colrange(1, 2),) => [:a, :b],
                        :(colrange(3, 1, by=2),) => [:c1, :a]]

symbol_range_errors = [:(colrange(:a, :d),) => KeyError,
                       :(colrange(:d, :d),) => KeyError,
                       :(-colrange(:d, :d),) => KeyError,
                       :(colrange(1, 4),) => BoundsError,
                       :(colrange(0, 0),) => ArgumentError,
                       :(-colrange(4, 0),) => ArgumentError]

bool_queries = [:([true, true, true],) => [:a, :b, :c1], :(:b, [false, false, false], :a) => [:b, :a],
                :([false, true, false],) => [:b],  :(!cols([true, false, true]),) => [:b],
                :(.![false, true, false],) => [:a, :c1]]
bool_errors = [:([true],) => BoundsError, :([false, false, false, false],) => BoundsError]

regex_queries = [:(if_matches(r"."),) => [:a, :b, :c1], :(if_matches(r"a"),) => [:a],
                 :(-if_matches(r"b"),) => [:a, :c1], :(!if_matches(r"c"),) => [:a, :b],
                 :(if_matches("c"),) => [:c1], :(-if_matches('b'),) => [:a, :c1],
                 :(if_keys(x->length(x) == 2),) => [:c1], :(~if_keys(x->length(x) == 1),) => [:c1]]

predicate_queries = [:(if_values(x -> !any(ismissing.(x))),) => [:a, :b, :c1],
                     :(-if_values(x -> !any(ismissing.(x))),) => [],
                     :(!if_values(x -> !any(ismissing.(x))),) => [],
                     :(if_eltype(Char),) => [:b],
                     :(~if_eltype(Int),) => [:b, :c1],
                     :(if_pairs((k,v) -> k == "a" || eltype(v) == Char),) => [:a, :b],
                     :(!if_pairs((k,v) -> k == "a" || eltype(v) == Char),) => [:c1]]

combined_queries = [:(if_eltype(Int) | if_matches(r"b"),) => [:a, :b],
                    :(-if_eltype(Int) | if_matches(r"b"),) => [:b, :c1],
                    :(-if_eltype(Int) & if_matches(r"b"),) => [:b],
                    :(cols(:c1, (not(:a) & if_matches(r"b"))) | cols(:a),) => [:c1, :b, :a],
                    :(not(:c1) & not(:b),) => [:a],
                    :(cols(:c1) | cols(:a),) => [:c1, :a]]

rest_queries = [:(:b, rest()) => [:b, :a, :c1],
                :(:c1, :a, rest(), :b) => [:c1, :a, :b],
                :(rest(),) => [:a, :b, :c1]]

rest_errors = [:(cols(:a) & rest()) => MethodError]

renaming_queries = [:(rest() => key_map(uppercase),) => [:a => :A, :b => :B, :c1 => :C1],
                    :(:a => :X,) => [:a => :X],
                    :(1:2 => [:X, :Y],) => [:a => :X, :b => :Y],
                    :(1:2 => key_map(uppercase),) => [:a => :A, :b => :B],
                    :(1 => key_prefix("A"), :b => key_suffix("B"),) => [:a => :Aa, :b => :bB],
                    :(:c1 => key_suffix("C"), not(:b) => key_suffix("D"),) => [:c1 => :c1CD, :a => :aD]]

renaming_queries_warn = [
    (query = :(:a => [:X, :Y],) => [:a => :a],
     msg = "Renaming array had different length (2) than target selections (1), renaming skipped."),
    (query = :(1:2 => :X,) => [:a => :a, :b => :b],
     msg = "Renaming to a sigle new name is not supported for multiple selections (2), renaming skipped.")
]

@testset "select" begin
    test_queries_and_errors("Symbol", symbol_queries, symbol_errors)
    test_queries_and_errors("Int", int_queries, int_errors)
    test_queries_and_errors("Int+Symbol", mixed_queries, mixed_errors)
    test_queries_and_errors("IntRange", int_range_queries, int_range_errors)
    test_queries_and_errors("SymbolRange", symbol_range_queries, symbol_range_errors)
    test_queries_and_errors("Bool", bool_queries, bool_errors)
    test_queries("Matches", regex_queries)
    test_queries("Predicate", predicate_queries)
    test_queries("Chaining", combined_queries)
    test_queries_and_errors("Complement", rest_queries, rest_errors)
    test_renaming_queries("Renaming", renaming_queries)
    test_renaming_queries_warn("Renaming Warning", renaming_queries_warn)
end

@testset "select!" begin
    test_queries_and_errors_bang("Symbol", symbol_queries, symbol_errors)
    test_queries_and_errors_bang("Int", int_queries, int_errors)
    test_queries_and_errors_bang("Int+Symbol", mixed_queries, mixed_errors)
    test_queries_and_errors_bang("IntRange", int_range_queries, int_range_errors)
    test_queries_and_errors_bang("SymbolRange", symbol_range_queries, symbol_range_errors)
    test_queries_and_errors_bang("Bool", bool_queries, bool_errors)
    test_queries_bang("Matches", regex_queries)
    test_queries_bang("Predicate", predicate_queries)
    test_queries_bang("Chaining", combined_queries)
    test_queries_and_errors_bang("Complement", rest_queries, rest_errors)
    test_renaming_queries_bang("Renaming", renaming_queries)
    test_renaming_queries_warn_bang("Renaming Warning", renaming_queries_warn)
end
