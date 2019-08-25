
df = DataFrame(a = 1:4, b = 'a':'d', c1 = [[float(i)] for i in 1:4])

function test_renaming_queries(section, queries)
    @testset "$section" begin
        @testset "queries" begin
            for (sel, res) in queries
                eval(:(@test s.select(df, $sel...) == s.rename(df[:, $(first.(res))], $(res...))))
            end
        end
    end
end

function test_queries(section, queries)
    @testset "$section" begin
        @testset "queries" begin
            for (sel, res) in queries
                eval(:(@test s.select(df, $sel...) == df[:, $res]))
            end
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

symbol_queries = [:(:a,) => [:a], :(-cols(:b),) => [:a, :c1], :(not(:c1),) => [:a, :b], :(not(:a, :b, :c1),) => [],
                  :(:b, :a) => [:b, :a], :((:b, :a)) => [:b, :a], :(-cols(:b, :c1),) => [:a],  :(not(:b, :c1),) => [:a],
                  :(-(cols(:b) | cols(:c1)),) => [:a],  :(not(cols(:b) & cols(:c1)),) => [:a, :b, :c1], :(not(not(:a)),) => [:a]]

symbol_errors = [:(:A,) => ErrorException, :(cols(:A),) => ErrorException, :((:a, :A)) => ErrorException, :(-cols(:A),) => ErrorException]

int_queries = [:(1,) => [:a], :(-cols(:b),) => [:a, :c1], :(not(3),) => [:a, :b], :((-3,)) => [:a, :b],
               :(2, 1) => [:b, :a], :((2, 1)) => [:b, :a], :(-cols(2, 3),) => [:a],  :(not(2, 3),) => [:a],
               :(-(cols(2) | cols(3)),) => [:a],  :(not(cols(2) & cols(3)),) => [:a, :b, :c1]]

int_errors = [:((4,)) => ErrorException, :(:(0,)) => MethodError, :((4, 1)) => ErrorException, :(:(0, -2)) => MethodError, :(-cols(4),) => ErrorException]

mixed_queries = [:(1, :b) => [:a , :b], :((2, :a)) => [:b , :a], :([2, :a],) => [:b, :a], :(-cols(2, :c1),) => [:a],
                 :(!cols(2, :c1),) => [:a], :(~cols(2, :c1),) => [:a], :(cols(:b, 1),) => [:b, :a]]
mixed_errors = [:(:c1, 4) => ErrorException, :(0, :a) => ErrorException, :(1, :D) => ErrorException]

int_range_queries = [:(1:1,) => [:a], :(!cols(2:2),) => [:a, :c1], :(-3:-3,) => [:a, :b],
                     :(1:2,) => [:a, :b], (1:2:3,) => [:a, :c1],
                      (-3:2:-1,) => [:b]]

int_range_errors = [:(0:3,) => AssertionError, :(4:4,) => BoundsError, :(-4:-4) => ErrorException] # AssertionError

symbol_range_queries = [:(colrange(:a, :a),) => [:a], :(!colrange(:b, :b),) => [:a, :c1],
                        :(colrange(:c1, :b),) => [:c1, :b], :(colrange(:a, :b),) => [:a, :b],
                        :(colrange(:c1, :a, by=2),) => [:c1, :a],
                        :(colrange(1, 1),) => [:a], :(!colrange(2, 2),) => [:a, :c1],
                        :(colrange(3, 2),) => [:c1, :b], :(colrange(1, 2),) => [:a, :b],
                        :(colrange(3, 1, by=2),) => [:c1, :a]]

symbol_range_errors = [:(colrange(:a, :d),) => ErrorException,
                       :(colrange(:d, :d),) => ErrorException,
                       :(-colrange(:d, :d),) => ErrorException,
                       :(colrange(1, 4),) => BoundsError,
                       :(colrange(0, 0),) => AssertionError,
                       :(-colrange(4, 0),) => AssertionError]

bool_queries = [:([true, true, true],) => [:a, :b, :c1], :(:b, [false, false, false], :a) => [:b, :a],
                :([false, true, false],) => [:b],  :(!cols([true, false, true]),) => [:b],
                :(.![false, true, false],) => [:a, :c1]]
bool_errors = [:([true],) => ErrorException, :([false, false, false, false],) => ErrorException]

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
                    :(:a => [:X, :Y],) => [:a => :a],
                    :(1:2 => :X,) => [:a => :a, :b => :b],
                    :(1:2 => [:X, :Y],) => [:a => :X, :b => :Y],
                    :(1:2 => key_map(uppercase),) => [:a => :A, :b => :B],
                    :(1 => key_prefix("A"), :b => key_suffix("B"),) => [:a => :Aa, :b => :bB],
                    :(:c1 => key_suffix("C"), not(:b) => key_suffix("D"),) => [:c1 => :c1CD, :a => :aD]]

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
end
