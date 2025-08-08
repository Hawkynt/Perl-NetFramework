#!/usr/bin/perl
use strict;
use warnings;
use lib '../../../';
use Test::More;

# Define constants
use constant true => 1;
use constant false => 0;

# Import LINQ classes
use System::Linq;
use System::Array;
use System::String;

sub test_join_operations {
    # Test Join
    my $outer = System::Array->new(
        { id => 1, name => "Alice" },
        { id => 2, name => "Bob" },
        { id => 3, name => "Charlie" }
    );
    
    my $inner = System::Array->new(
        { personId => 1, city => "New York" },
        { personId => 2, city => "London" },
        { personId => 3, city => "Tokyo" }
    );
    
    my $joined = $outer->Join(
        $inner,
        sub { $_[0]->{id} },           # outer key selector
        sub { $_[0]->{personId} },     # inner key selector
        sub { 
            my ($person, $location) = @_;
            return "$person->{name} lives in $location->{city}";
        }
    );
    
    is($joined->Length(), 3, 'Join produces correct number of results');
    is($joined->GetValue(0), "Alice lives in New York", 'Join result 1 correct');
    is($joined->GetValue(1), "Bob lives in London", 'Join result 2 correct');
    is($joined->GetValue(2), "Charlie lives in Tokyo", 'Join result 3 correct');
    
    # Test GroupJoin
    my $grouped = $outer->GroupJoin(
        $inner,
        sub { $_[0]->{id} },           # outer key selector
        sub { $_[0]->{personId} },     # inner key selector
        sub {
            my ($person, $locations) = @_;
            return "$person->{name}: " . $locations->Count() . " locations";
        }
    );
    
    is($grouped->Length(), 3, 'GroupJoin produces correct number of results');
    is($grouped->GetValue(0), "Alice: 1 locations", 'GroupJoin result 1 correct');
    is($grouped->GetValue(1), "Bob: 1 locations", 'GroupJoin result 2 correct');
    is($grouped->GetValue(2), "Charlie: 1 locations", 'GroupJoin result 3 correct');
}

sub test_single_operations {
    my $singleArray = System::Array->new(42);
    my $multiArray = System::Array->new(1, 2, 3, 4, 5);
    my $emptyArray = System::Array->new();
    
    # Test Single
    is($singleArray->Single(), 42, 'Single with one element');
    
    eval { $multiArray->Single() };
    ok($@, 'Single throws on multiple elements');
    
    eval { $emptyArray->Single() };
    ok($@, 'Single throws on empty sequence');
    
    # Test Single with predicate
    is($multiArray->Single(sub { $_[0] == 3 }), 3, 'Single with predicate finds element');
    
    eval { $multiArray->Single(sub { $_[0] > 3 }) };
    ok($@, 'Single with predicate throws on multiple matches');
    
    # Test SingleOrDefault
    is($singleArray->SingleOrDefault(undef, 99), 42, 'SingleOrDefault with one element');
    is($emptyArray->SingleOrDefault(undef, 99), 99, 'SingleOrDefault returns default for empty');
    is($multiArray->SingleOrDefault(sub { $_[0] > 10 }, 99), 99, 'SingleOrDefault returns default for no match');
    is($multiArray->SingleOrDefault(sub { $_[0] > 3 }, 99), 99, 'SingleOrDefault returns default for multiple matches');
    
    # Test LastOrDefault
    is($multiArray->LastOrDefault(undef, 99), 5, 'LastOrDefault finds last element');
    is($emptyArray->LastOrDefault(undef, 99), 99, 'LastOrDefault returns default for empty');
    is($multiArray->LastOrDefault(sub { $_[0] > 3 }, 99), 5, 'LastOrDefault with predicate finds last match');
    is($multiArray->LastOrDefault(sub { $_[0] > 10 }, 99), 99, 'LastOrDefault returns default for no match');
}

sub test_sequence_operations {
    my $array = System::Array->new(1, 2, 3, 4, 5);
    
    # Test Reverse
    my $reversed = $array->Reverse();
    is($reversed->Length(), 5, 'Reverse preserves length');
    is($reversed->GetValue(0), 5, 'Reverse first element correct');
    is($reversed->GetValue(4), 1, 'Reverse last element correct');
    
    # Test SequenceEqual
    my $array2 = System::Array->new(1, 2, 3, 4, 5);
    my $array3 = System::Array->new(5, 4, 3, 2, 1);
    my $array4 = System::Array->new(1, 2, 3);
    
    ok($array->SequenceEqual($array2), 'SequenceEqual returns true for identical sequences');
    ok(!$array->SequenceEqual($array3), 'SequenceEqual returns false for different order');
    ok(!$array->SequenceEqual($array4), 'SequenceEqual returns false for different lengths');
    
    # Test SequenceEqual with custom comparer
    my $stringArray1 = System::Array->new("a", "B", "c");
    my $stringArray2 = System::Array->new("A", "b", "C");
    
    ok(!$stringArray1->SequenceEqual($stringArray2), 'SequenceEqual case sensitive by default');
    ok($stringArray1->SequenceEqual($stringArray2, sub { 
        return lc($_[0]) eq lc($_[1]); 
    }), 'SequenceEqual with case-insensitive comparer');
    
    # Test Zip
    my $numbers = System::Array->new(1, 2, 3, 4);
    my $letters = System::Array->new("a", "b", "c");
    
    my $zipped = $numbers->Zip($letters, sub {
        my ($num, $letter) = @_;
        return "$num$letter";
    });
    
    is($zipped->Length(), 3, 'Zip length matches shorter sequence');
    is($zipped->GetValue(0), "1a", 'Zip result 1 correct');
    is($zipped->GetValue(1), "2b", 'Zip result 2 correct');
    is($zipped->GetValue(2), "3c", 'Zip result 3 correct');
}

sub test_type_operations {
    # Create mixed array with different types
    require System::String;
    my $str1 = System::String->new("Hello");
    my $str2 = System::String->new("World");
    my $num1 = 42;
    my $num2 = 3.14;
    
    my $mixedArray = System::Array->new($str1, $num1, $str2, $num2);
    
    # Test OfType
    my $strings = $mixedArray->OfType('System::String');
    is($strings->Length(), 2, 'OfType filters correct number of strings');
    isa_ok($strings->GetValue(0), 'System::String', 'OfType result 1 is string');
    isa_ok($strings->GetValue(1), 'System::String', 'OfType result 2 is string');
    
    # Test Cast - should work with all strings
    my $stringArray = System::Array->new($str1, $str2);
    my $casted = $stringArray->Cast('System::String');
    is($casted->Length(), 2, 'Cast preserves length for valid types');
    
    # Test Cast with invalid cast
    eval { $mixedArray->Cast('System::String') };
    ok($@, 'Cast throws on invalid cast');
}

sub test_enumerable_static_methods {
    # Test Empty
    my $empty = System::Linq::Enumerable::Empty('String');
    isa_ok($empty, 'System::Array', 'Empty returns System::Array');
    is($empty->Length(), 0, 'Empty array has zero length');
    
    # Test Repeat
    my $repeated = System::Linq::Enumerable::Repeat("Hello", 3, 'String');
    isa_ok($repeated, 'System::Array', 'Repeat returns System::Array');
    is($repeated->Length(), 3, 'Repeat creates correct length');
    is($repeated->GetValue(0), "Hello", 'Repeat element 1 correct');
    is($repeated->GetValue(1), "Hello", 'Repeat element 2 correct');
    is($repeated->GetValue(2), "Hello", 'Repeat element 3 correct');
    
    # Test Repeat with zero count
    my $zeroRepeated = System::Linq::Enumerable::Repeat("Test", 0, 'String');
    is($zeroRepeated->Length(), 0, 'Repeat with zero count creates empty array');
    
    # Test Repeat with negative count throws
    eval { System::Linq::Enumerable::Repeat("Test", -1, 'String') };
    ok($@, 'Repeat with negative count throws');
}

sub test_linq_chaining_with_new_operators {
    my $people = System::Array->new(
        { name => "Alice", age => 30, city => "New York" },
        { name => "Bob", age => 25, city => "London" },
        { name => "Charlie", age => 35, city => "Tokyo" },
        { name => "Diana", age => 28, city => "New York" },
        { name => "Eve", age => 32, city => "London" }
    );
    
    # Complex chaining with new operators
    my $result = $people
        ->Where(sub { $_[0]->{age} > 25 })
        ->OrderBy(sub { $_[0]->{age} })
        ->Select(sub { $_[0]->{name} })
        ->Reverse()
        ->Take(3);
    
    my $resultArray = $result->ToArray();
    is($resultArray->Length(), 3, 'Chained operations produce correct count');
    is($resultArray->GetValue(0), "Charlie", 'Chained result 1 correct');
    is($resultArray->GetValue(1), "Eve", 'Chained result 2 correct');
    is($resultArray->GetValue(2), "Alice", 'Chained result 3 correct');
    
    # Test with Zip in chain
    my $numbers = System::Array->new(1, 2, 3, 4, 5);
    my $letters = System::Array->new("a", "b", "c", "d", "e");
    
    my $combined = $numbers
        ->Take(3)
        ->Zip($letters->Take(3), sub { "$_[0]-$_[1]" })
        ->Where(sub { $_[0] =~ /[13]/ });
    
    my $combinedArray = $combined->ToArray();
    is($combinedArray->Length(), 2, 'Complex chain with Zip correct count');
    is($combinedArray->GetValue(0), "1-a", 'Complex chain result 1 correct');
    is($combinedArray->GetValue(1), "3-c", 'Complex chain result 2 correct');
}

sub test_modern_linq_operators {
    my $people = System::Array->new(
        { name => "Alice", age => 30, salary => 50000 },
        { name => "Bob", age => 25, salary => 60000 },
        { name => "Charlie", age => 35, salary => 45000 },
        { name => "Diana", age => 28, salary => 55000 },
        { name => "Eve", age => 32, salary => 65000 }
    );
    
    # Test MinBy
    my $youngest = $people->MinBy(sub { $_[0]->{age} });
    is($youngest->{name}, "Bob", 'MinBy finds youngest person');
    is($youngest->{age}, 25, 'MinBy result has correct age');
    
    # Test MaxBy  
    my $oldest = $people->MaxBy(sub { $_[0]->{age} });
    is($oldest->{name}, "Charlie", 'MaxBy finds oldest person');
    is($oldest->{age}, 35, 'MaxBy result has correct age');
    
    my $highestPaid = $people->MaxBy(sub { $_[0]->{salary} });
    is($highestPaid->{name}, "Eve", 'MaxBy finds highest paid person');
    is($highestPaid->{salary}, 65000, 'MaxBy result has correct salary');
    
    # Test DistinctBy (using age groups)
    my $peopleWithDupeAges = System::Array->new(
        { name => "Alice", age => 30 },
        { name => "Bob", age => 25 },  
        { name => "Charlie", age => 30 },  # Same age as Alice
        { name => "Diana", age => 25 },    # Same age as Bob
        { name => "Eve", age => 32 }
    );
    
    my $distinctByAge = $peopleWithDupeAges->DistinctBy(sub { $_[0]->{age} });
    is($distinctByAge->Length(), 3, 'DistinctBy removes duplicates by age');
    
    # Test CountBy
    my $ageGroups = $peopleWithDupeAges->CountBy(sub { $_[0]->{age} });
    is($ageGroups->Length(), 3, 'CountBy creates correct number of groups');
    
    # Find the count for age 30
    my $age30Count = 0;
    for my $i (0..$ageGroups->Length()-1) {
        my $group = $ageGroups->GetValue($i);
        if ($group->{Key} eq "30") {
            $age30Count = $group->{Count};
            last;
        }
    }
    is($age30Count, 2, 'CountBy correctly counts age 30 group');
}

sub test_chunk_and_index {
    my $numbers = System::Array->new(1, 2, 3, 4, 5, 6, 7, 8, 9, 10);
    
    # Test Chunk
    my $chunks = $numbers->Chunk(3);
    is($chunks->Length(), 4, 'Chunk creates correct number of chunks');
    
    my $firstChunk = $chunks->GetValue(0);
    is($firstChunk->Length(), 3, 'First chunk has correct size');
    is($firstChunk->GetValue(0), 1, 'First chunk first element correct');
    is($firstChunk->GetValue(2), 3, 'First chunk last element correct');
    
    my $lastChunk = $chunks->GetValue(3);
    is($lastChunk->Length(), 1, 'Last chunk has remaining element');
    is($lastChunk->GetValue(0), 10, 'Last chunk element correct');
    
    # Test Index
    my $letters = System::Array->new("a", "b", "c");
    my $indexed = $letters->Index();
    
    is($indexed->Length(), 3, 'Index creates correct number of items');
    
    my $firstIndexed = $indexed->GetValue(0);
    is($firstIndexed->{Index}, 0, 'First indexed item has correct index');
    is($firstIndexed->{Item}, "a", 'First indexed item has correct value');
    
    my $lastIndexed = $indexed->GetValue(2);
    is($lastIndexed->{Index}, 2, 'Last indexed item has correct index');
    is($lastIndexed->{Item}, "c", 'Last indexed item has correct value');
}

sub test_append_prepend {
    my $numbers = System::Array->new(2, 3, 4);
    
    # Test Append
    my $appended = $numbers->Append(5);
    is($appended->Length(), 4, 'Append increases length');
    is($appended->GetValue(0), 2, 'Append preserves first element');
    is($appended->GetValue(3), 5, 'Append adds element at end');
    
    # Test Prepend
    my $prepended = $numbers->Prepend(1);
    is($prepended->Length(), 4, 'Prepend increases length');
    is($prepended->GetValue(0), 1, 'Prepend adds element at start');
    is($prepended->GetValue(3), 4, 'Prepend preserves last element');
    
    # Test chaining Append and Prepend
    my $both = $numbers->Prepend(1)->Append(5);
    is($both->Length(), 5, 'Chained Prepend/Append correct length');
    is($both->GetValue(0), 1, 'Chained result first element correct');
    is($both->GetValue(4), 5, 'Chained result last element correct');
}

sub test_additional_operators {
    my $numbers = System::Array->new(1, 2, 3, 4, 5);
    
    # Test LongCount (same as Count but for conceptual completeness)
    is($numbers->LongCount(), 5, 'LongCount returns correct count');
    is($numbers->LongCount(sub { $_[0] > 3 }), 2, 'LongCount with predicate correct');
    
    # Test ElementAtOrDefault
    is($numbers->ElementAtOrDefault(2, 99), 3, 'ElementAtOrDefault finds existing element');
    is($numbers->ElementAtOrDefault(10, 99), 99, 'ElementAtOrDefault returns default for out of range');
    is($numbers->ElementAtOrDefault(-1, 99), 99, 'ElementAtOrDefault returns default for negative index');
    
    # Test TryGetNonEnumeratedCount
    my ($count, $success) = $numbers->TryGetNonEnumeratedCount();
    is($success, true, 'TryGetNonEnumeratedCount succeeds for Array');
    is($count, 5, 'TryGetNonEnumeratedCount returns correct count');
}

# Run all tests
test_join_operations();
test_single_operations();
test_sequence_operations();
test_type_operations();
test_enumerable_static_methods();
test_linq_chaining_with_new_operators();

done_testing();