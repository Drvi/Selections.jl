
nums = x -> occursin(r"\d", string(x))
len1 = x->length(x) < 2
tft = [true,false,true]
len4 = x->length(x) == 4
allt = (k,v) -> true

@testset "selections" begin
@testset "selection constructors" begin
@test s.selection(:a) == s.SymbolSelection(:a)
@test s.selection(1) == s.IntSelection(1)
@test s.selection(cols(1) | cols(:b) | if_keys(nums)) == s.OrMultiSelection(s.OrMultiSelection(s.IntSelection(1), s.SymbolSelection(:b)), s.NamePredicateSelection(nums, true))
@test s.selection(-cols(1) & -if_keys(nums)) == s.AndMultiSelection(s.IntSelection(1, false), s.NamePredicateSelection(nums, false))
@test s.selection(colrange(:a, :b)) == s.RangeSelection(:a, :b, 1, true)
@test s.selection(colrange(1, 2)) == s.RangeSelection(1, 2, 1, true)
@test s.selection(1:2) == s.RangeSelection(1, 2, 1, true)
@test s.selection(1:2:3) == s.RangeSelection(1, 3, 2, true)
@test s.selection(3:-2:1) == s.RangeSelection(3, 1, -2, true)
@test s.selection(colrange(3, 1, by=2)) == s.RangeSelection(3, 1, -2, true)
@test s.selection(colrange(1, 3, by=2)) == s.RangeSelection(1, 3, 2, true)
@test s.selection(1:2) == s.RangeSelection(1, 2, 1, true)
@test s.selection(tft) == s.BoolSelection(tft)
@test s.selection((:a, :c1)) == (s.SymbolSelection(:a), s.SymbolSelection(:c1))
@test s.selection([1, 3]) == [s.IntSelection(1), s.IntSelection(3)]
@test s.selection([:b, 1]) == [s.SymbolSelection(:b), s.IntSelection(1)]
@test s.selection(if_keys(len1)) == s.NamePredicateSelection(len1, true)
@test s.selection(if_values(len4)) == s.PredicateSelection(len4, true)
@test s.selection(if_pairs(allt)) == s.PairPredicateSelection(allt, true)
end

@testset "selection errors" begin
@test_throws ArgumentError colrange(0, 1)
@test_throws ArgumentError colrange(-3, -1)
@test_throws ArgumentError colrange(-1, 1)
@test_throws ArgumentError s.selection(-3:-1:-1)
@test_throws ArgumentError s.selection(3:1:1)
@test_throws MethodError s.selection("a")
end

@testset "selection constructors negated" begin
@test s.selection(not(:a)) == s.SymbolSelection(:a, false)
@test s.selection(not(1)) == s.IntSelection(1, false)
@test s.selection(not(cols(1) | cols(:b) | if_keys(nums))) == s.OrMultiSelection(s.OrMultiSelection(s.IntSelection(1), s.SymbolSelection(:b)), s.NamePredicateSelection(nums, true), false)
@test s.selection(-colrange(:a, :b)) == s.RangeSelection(:a, :b, 1, false)
@test s.selection(-colrange(1, 2)) == s.RangeSelection(1, 2, 1, false)
@test s.selection(not(tft)) == s.BoolSelection(tft, false)
@test s.selection(not((:a, :c1))) == (s.SymbolSelection(:a, false), s.SymbolSelection(:c1, false))
@test s.selection(not([1, 3])) == [s.IntSelection(1, false), s.IntSelection(3, false)]
@test s.selection(not([:b, 1])) == [s.SymbolSelection(:b, false), s.IntSelection(1, false)]
@test s.selection(-if_keys(len1)) == s.NamePredicateSelection(len1, false)
@test s.selection(-if_values(len4)) == s.PredicateSelection(len4, false)
@test s.selection(-if_pairs(allt)) == s.PairPredicateSelection(allt, false)
end

@testset "selection constructors renamed" begin
@test s.selection(:a => :A) == s.SymbolSelection(:a, true, s.ToSymbol(:A))
@test s.selection(1 => :A) == (s.IntSelection(1) => :A)
@test s.selection((cols(1) => :A) | (cols(:b) => :B) | (if_keys(nums) => key_map(uppercase))) == s.OrMultiSelection(s.OrMultiSelection(s.IntSelection(1) => :A, s.SymbolSelection(:b, true) => :B), (s.NamePredicateSelection(nums, true) => s.SelectionRename(uppercase)))
@test s.selection((-cols(1) => :A) & (-if_keys(nums) => :C)) == s.AndMultiSelection(s.IntSelection(1, false) => :A, s.NamePredicateSelection(nums, false) => :C)
@test s.selection(colrange(:a, :b) => :A) == (s.RangeSelection(:a, :b, 1, true) => :A)
@test s.selection(colrange(1, 2) => :A) == (s.RangeSelection(1, 2, 1, true) => :A)
@test s.selection(1:2 => :A) == (s.RangeSelection(1, 2, 1, true) => :A)
@test s.selection(tft => :A) == (s.BoolSelection(tft, true) => :A)
@test s.selection((:a, :c1) => :A) == ((s.SymbolSelection(:a), s.SymbolSelection(:c1)) => :A)
@test s.selection([1, 3] => :A) == ([s.IntSelection(1), s.IntSelection(3)] => :A)
@test s.selection([:b, 1] => :A) == ([s.SymbolSelection(:b), s.IntSelection(1)] => :A)
@test s.selection((:a => :A, :c1 => :C)) == (s.SymbolSelection(:a, true, s.ToSymbol(:A)), s.SymbolSelection(:c1, true, s.ToSymbol(:C)))
@test s.selection([1 => :A, 3] => :A) == ([s.IntSelection(1) => :A, s.IntSelection(3)] => :A)
@test s.selection([:b => :B, 1] => :A) == ([s.SymbolSelection(:b, true, s.ToSymbol(:B)), s.IntSelection(1)] => :A)
@test s.selection(if_keys(len1) => :A) == (s.NamePredicateSelection(len1, true) => :A)
@test s.selection(if_values(len4) => :A) == (s.PredicateSelection(len4, true) => :A)
@test s.selection(if_pairs(allt) => :A) == (s.PairPredicateSelection(allt, true) => :A)
end

@testset "selection constructors negated renamed" begin
@test s.selection(not(:a) => :A) == (s.SymbolSelection(:a, false) => :A)
@test s.selection(not(1) => :A) == (s.IntSelection(1, false) => :A)
@test s.selection(not((cols(1) => :A) | (cols(:b) => :B) | (if_keys(nums) => key_map(uppercase)))) == s.OrMultiSelection(s.OrMultiSelection(s.IntSelection(1) => :A, s.SymbolSelection(:b, true) => :B), (s.NamePredicateSelection(nums, true) => s.SelectionRename(uppercase)), false)
@test s.selection(-colrange(:a, :b) => :A) == (s.RangeSelection(:a, :b, 1, false) => :A)
@test s.selection(-colrange(1, 2) => :A) == (s.RangeSelection(1, 2, 1, false) => :A)
@test s.selection(not(1:2) => :A) == (s.RangeSelection(1, 2, 1, false) => :A)
@test s.selection(not(tft) => :A) == (s.BoolSelection(tft, false) => :A)
@test s.selection(not((:a, :c1)) => :A) == ((s.SymbolSelection(:a, false), s.SymbolSelection(:c1, false)) => :A)
@test s.selection(not([1, 3]) => :A) == ([s.IntSelection(1, false), s.IntSelection(3, false)] => :A)
@test s.selection(not([:b, 1]) => :A) == ([s.SymbolSelection(:b, false), s.IntSelection(1, false)] => :A)
@test s.selection(not((:a => :A, :c1 => :C))) == (s.SymbolSelection(:a, false, s.ToSymbol(:A)), s.SymbolSelection(:c1, false, s.ToSymbol(:C)))
@test s.selection(not([1 => :A, 3]) => :A) == ([s.IntSelection(1, false) => :A, s.IntSelection(3, false)] => :A)
@test s.selection(not([:b, 1] => :A) => :A) == (([s.SymbolSelection(:b, false), s.IntSelection(1, false)] => :A) => :A)
@test s.selection(-if_keys(len1) => :A) == (s.NamePredicateSelection(len1, false) => :A)
@test s.selection(-if_values(len4) => :A) == (s.PredicateSelection(len4, false) => :A)
@test s.selection(-if_pairs(allt) => :A) == (s.PairPredicateSelection(allt, false) => :A)
end

@testset "selection constructors renamed (function)" begin
@test s.selection(:a => key_map(uppercase)) == (s.SymbolSelection(:a, true) => s.SelectionRename(uppercase))
@test s.selection(1 => key_map(uppercase)) == (s.IntSelection(1) => s.SelectionRename(uppercase))
@test s.selection((-cols(1) => key_map(uppercase)) & (-if_keys(nums) => key_map(uppercase))) == s.AndMultiSelection(s.IntSelection(1, false) => s.SelectionRename(uppercase), s.NamePredicateSelection(nums, false) => s.SelectionRename(uppercase))
@test s.selection(colrange(:a, :b) => key_map(uppercase)) == (s.RangeSelection(:a, :b, 1, true) => s.SelectionRename(uppercase))
@test s.selection(colrange(1, 2) => key_map(uppercase)) == (s.RangeSelection(1, 2, 1, true) => s.SelectionRename(uppercase))
@test s.selection(1:2 => key_map(uppercase)) == (s.RangeSelection(1, 2, 1, true) => s.SelectionRename(uppercase))
@test s.selection(tft => key_map(uppercase)) == (s.BoolSelection(tft, true) => s.SelectionRename(uppercase))
@test s.selection((:a, :c1) => key_map(uppercase)) == ((s.SymbolSelection(:a), s.SymbolSelection(:c1)) => s.SelectionRename(uppercase))
@test s.selection([1, 3] => key_map(uppercase)) == ([s.IntSelection(1), s.IntSelection(3)] => s.SelectionRename(uppercase))
@test s.selection([:b, 1] => key_map(uppercase)) == ([s.SymbolSelection(:b), s.IntSelection(1)] => s.SelectionRename(uppercase))
@test s.selection((:a => key_map(uppercase), :c1 => key_map(uppercase))) == (s.SymbolSelection(:a, true) => s.SelectionRename(uppercase), s.SymbolSelection(:c1, true) => s.SelectionRename(uppercase))
@test s.selection([1 => key_map(uppercase), 3] => key_map(uppercase)) == ([s.IntSelection(1) => s.SelectionRename(uppercase), s.IntSelection(3)] => s.SelectionRename(uppercase))
@test s.selection([:b => key_map(uppercase), 1] => key_map(uppercase)) == ([s.SymbolSelection(:b, true) => s.SelectionRename(uppercase), s.IntSelection(1)] => s.SelectionRename(uppercase))
@test s.selection(if_keys(len1) => key_map(uppercase)) == (s.NamePredicateSelection(len1, true) => s.SelectionRename(uppercase))
@test s.selection(if_values(len4) => key_map(uppercase)) == (s.PredicateSelection(len4, true) => s.SelectionRename(uppercase))
@test s.selection(if_pairs(allt) => key_map(uppercase)) == (s.PairPredicateSelection(allt, true) => s.SelectionRename(uppercase))
end

@testset "selection constructors negated renamed (function)" begin
@test s.selection(not(:a) => key_map(uppercase)) == (s.SymbolSelection(:a, false) => s.SelectionRename(uppercase))
@test s.selection(not(1) => key_map(uppercase)) == (s.IntSelection(1, false) => s.SelectionRename(uppercase))
@test s.selection(-colrange(:a, :b) => key_map(uppercase)) == (s.RangeSelection(:a, :b, 1, false) => s.SelectionRename(uppercase))
@test s.selection(-colrange(1, 2) => key_map(uppercase)) == (s.RangeSelection(1, 2, 1, false) => s.SelectionRename(uppercase))
@test s.selection(not(1:2) => key_map(uppercase)) == (s.RangeSelection(1, 2, 1, false) => s.SelectionRename(uppercase))
@test s.selection(not(tft) => key_map(uppercase)) == (s.BoolSelection(tft, false) => s.SelectionRename(uppercase))
@test s.selection(not((:a, :c1)) => key_map(uppercase)) == ((s.SymbolSelection(:a, false), s.SymbolSelection(:c1, false)) => s.SelectionRename(uppercase))
@test s.selection(not([1, 3]) => key_map(uppercase)) == ([s.IntSelection(1, false), s.IntSelection(3, false)] => s.SelectionRename(uppercase))
@test s.selection(not([:b, 1]) => key_map(uppercase)) == ([s.SymbolSelection(:b, false), s.IntSelection(1, false)] => s.SelectionRename(uppercase))
@test s.selection(not((:a => key_map(uppercase), :c1 => key_map(uppercase)))) == (s.SymbolSelection(:a, false) => s.SelectionRename(uppercase), s.SymbolSelection(:c1, false) => s.SelectionRename(uppercase))
@test s.selection(not([1 => key_map(uppercase), 3]) => key_map(uppercase)) == ([s.IntSelection(1, false) => s.SelectionRename(uppercase), s.IntSelection(3, false)] => s.SelectionRename(uppercase))
@test s.selection(not([:b, 1] => key_map(uppercase)) => key_map(uppercase)) == (([s.SymbolSelection(:b, false), s.IntSelection(1, false)] => s.SelectionRename(uppercase)) => s.SelectionRename(uppercase))
@test s.selection(-if_keys(len1) => key_map(uppercase)) == (s.NamePredicateSelection(len1, false) => s.SelectionRename(uppercase))
@test s.selection(-if_values(len4) => key_map(uppercase)) == (s.PredicateSelection(len4, false) => s.SelectionRename(uppercase))
@test s.selection(-if_pairs(allt) => key_map(uppercase)) == (s.PairPredicateSelection(allt, false) => s.SelectionRename(uppercase))
end
# Selection from length-one arrays of common types
@testset "selection constructors length-one containers" begin
@test s.selection([:a]) == [s.SymbolSelection(:a)]
@test s.selection([1]) == [s.IntSelection(1)]
@test s.selection([1:2]) == [s.RangeSelection(1, 2, 1, true)]
@test s.selection([tft]) == [s.BoolSelection(tft, true)]
@test s.selection((:a,)) == (s.SymbolSelection(:a),)
@test s.selection((1,)) == (s.IntSelection(1),)
@test s.selection((1:2,)) == (s.RangeSelection(1, 2, 1, true),)
@test s.selection((tft,)) == (s.BoolSelection(tft, true),)
@test s.selection(cols(:a)) == s.SymbolSelection(:a)
@test s.selection(cols(1)) == s.IntSelection(1)
@test s.selection(cols(1:2)) == s.RangeSelection(1, 2, 1, true)
@test s.selection(cols(tft)) == s.BoolSelection(tft)
@test s.selection([cols(:a)]) == [s.SymbolSelection(:a)]
end

# Selection from mixed chains of common types
@testset "selection constructors mixed-arrays" begin
@test s.selection([:a, 1, 1:2, tft]) == [s.SymbolSelection(:a), s.IntSelection(1), s.RangeSelection(1, 2, 1, true), s.BoolSelection(tft, true)]
@test s.selection((:a, 1, 1:2, tft)) == (s.SymbolSelection(:a), s.IntSelection(1), s.RangeSelection(1, 2, 1, true), s.BoolSelection(tft, true))
@test s.selection(cols(:a, 1, 1:2, tft)) == s.OrMultiSelection(s.OrMultiSelection(s.OrMultiSelection(s.SymbolSelection(:a), s.IntSelection(1)), s.RangeSelection(1, 2, 1, true)), s.BoolSelection(tft, true))
@test_throws MethodError s.selection(:a, 1, 1:2, tft) # should error -- no splatting in s.selection
end
# s.selection(:a | 1 | 1:2 | tft) # should error -- explicit chaining should be only allowed for "cols" or "not" wrappers
@testset "selection constructors chains" begin
@test s.selection(cols(:a) | cols(1) | cols(1:2) | cols(tft)) == s.OrMultiSelection(s.OrMultiSelection(s.OrMultiSelection(s.SymbolSelection(:a), s.IntSelection(1)), s.RangeSelection(1, 2, 1, true)), s.BoolSelection(tft, true))
@test s.selection(cols(:a) & cols(1) & cols(1:2) & cols(tft)) == s.AndMultiSelection(s.AndMultiSelection(s.AndMultiSelection(s.SymbolSelection(:a), s.IntSelection(1)), s.RangeSelection(1, 2, 1, true)), s.BoolSelection(tft, true))
@test s.selection(((cols(:a) & cols(1)) | cols(1:2)) & cols(tft)) == s.AndMultiSelection(s.OrMultiSelection(s.AndMultiSelection(s.SymbolSelection(:a), s.IntSelection(1)), s.RangeSelection(1, 2, 1, true)), s.BoolSelection(tft, true))
@test s.selection(((cols(:a) | cols(1)) & cols(1:2)) | cols(tft)) == s.OrMultiSelection(s.AndMultiSelection(s.OrMultiSelection(s.SymbolSelection(:a), s.IntSelection(1)), s.RangeSelection(1, 2, 1, true)), s.BoolSelection(tft, true))
end
# Negating chained mixed common types
@testset "selection constructors chains negated" begin
@test s.selection(-cols(:a) | -cols(1) | -cols(1:2) | -cols(tft)) == s.OrMultiSelection(s.OrMultiSelection(s.OrMultiSelection(s.SymbolSelection(:a, false), s.IntSelection(1, false)), s.RangeSelection(1, 2, 1, false)), s.BoolSelection(tft, false))
@test s.selection(-cols(:a) & -cols(1) & -cols(1:2) & -cols(tft)) == s.AndMultiSelection(s.AndMultiSelection(s.AndMultiSelection(s.SymbolSelection(:a, false), s.IntSelection(1, false)), s.RangeSelection(1, 2, 1, false)), s.BoolSelection(tft, false))
@test s.selection(((-cols(:a) & -cols(1)) | -cols(1:2)) & -cols(tft)) == s.AndMultiSelection(s.OrMultiSelection(s.AndMultiSelection(s.SymbolSelection(:a, false), s.IntSelection(1, false)), s.RangeSelection(1, 2, 1, false)), s.BoolSelection(tft, false))
@test s.selection(((-cols(:a) | -cols(1)) & -cols(1:2)) | -cols(tft)) == s.OrMultiSelection(s.AndMultiSelection(s.OrMultiSelection(s.SymbolSelection(:a, false), s.IntSelection(1, false)), s.RangeSelection(1, 2, 1, false)), s.BoolSelection(tft, false))
@test s.selection(not(((-cols(:a) & -cols(1)) | -cols(1:2)) & -cols(tft))) == s.AndMultiSelection(s.OrMultiSelection(s.AndMultiSelection(s.SymbolSelection(:a, false), s.IntSelection(1, false)), s.RangeSelection(1, 2, 1, false)), s.BoolSelection(tft, false), false)
end

@testset "selection constructors rest" begin
@test s.selection(rest()) == s.Complement(s.SelectionRename(identity), identity)
@test s.selection([:a, rest(), :c1]) == [s.SymbolSelection(:a), s.Complement(s.SelectionRename(identity), identity), s.SymbolSelection(:c1)]
@test s.selection(rest() => :A) == (s.Complement(s.SelectionRename(identity), identity) => :A)
@test s.selection([rest() => :A, :a => :AA]) == [s.Complement(s.SelectionRename(identity), identity) => :A, s.SymbolSelection(:a) => :AA]
@test_throws MethodError s.selection(-rest())
@test s.selection(rest() => key_map(uppercase)) == s.Complement(s.SelectionRename(uppercase), identity)
@test s.selection([rest() => key_map(uppercase), :a => key_map(uppercase)]) == [s.Complement(s.SelectionRename(identity), identity) => key_map(uppercase), s.SymbolSelection(:a) => key_map(uppercase)]
end
end
