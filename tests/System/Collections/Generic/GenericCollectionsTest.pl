#!/usr/bin/perl
use strict;
use warnings;
use lib '../../../../';
use Test::More;

# Define constants
use constant true => 1;
use constant false => 0;

# Import Generic Collections
use System::Collections::Generic::List;
use System::Collections::Generic::Dictionary;
use System::Collections::Generic::Stack;
use System::Collections::Generic::Queue;
use System::Collections::Generic::LinkedList;
use System::Collections::Generic::KeyValuePair;

sub test_list {
    # Test construction
    my $list = System::Collections::Generic::List->new();
    isa_ok($list, 'System::Collections::Generic::List', 'List creation');
    is($list->Count(), 0, 'Empty list has zero count');
    
    # Test Add
    $list->Add("Hello");
    $list->Add("World");
    $list->Add(42);
    is($list->Count(), 3, 'Count correct after adding items');
    
    # Test indexer (Item method)
    is($list->Item(0), "Hello", 'First item correct');
    is($list->Item(1), "World", 'Second item correct');
    is($list->Item(2), 42, 'Third item correct');
    
    # Test indexer setter
    $list->Item(1, "Beautiful");
    is($list->Item(1), "Beautiful", 'Item setter works');
    
    # Test Contains
    ok($list->Contains("Hello"), 'Contains finds existing item');
    ok(!$list->Contains("NotFound"), 'Contains returns false for missing item');
    
    # Test IndexOf
    is($list->IndexOf("Hello"), 0, 'IndexOf returns correct index');
    is($list->IndexOf("NotFound"), -1, 'IndexOf returns -1 for missing item');
    
    # Test Insert
    $list->Insert(1, "Inserted");
    is($list->Count(), 4, 'Count increased after insert');
    is($list->Item(1), "Inserted", 'Inserted item in correct position');
    is($list->Item(2), "Beautiful", 'Existing items shifted correctly');
    
    # Test Remove
    ok($list->Remove("Inserted"), 'Remove returns true for existing item');
    is($list->Count(), 3, 'Count decreased after remove');
    ok(!$list->Remove("NotFound"), 'Remove returns false for missing item');
    
    # Test RemoveAt
    $list->RemoveAt(1);
    is($list->Count(), 2, 'Count decreased after RemoveAt');
    is($list->Item(1), 42, 'Correct item after RemoveAt');
    
    # Test ToArray
    my $array = $list->ToArray();
    isa_ok($array, 'ARRAY', 'ToArray returns array reference');
    is(scalar(@$array), 2, 'Array has correct length');
    is($array->[0], "Hello", 'Array first element correct');
    is($array->[1], 42, 'Array second element correct');
    
    # Test enumeration
    my $enumerator = $list->GetEnumerator();
    isa_ok($enumerator, 'System::Collections::Generic::ListEnumerator', 'GetEnumerator returns correct type');
    
    my @enumerated = ();
    while ($enumerator->MoveNext()) {
        push @enumerated, $enumerator->Current();
    }
    is(scalar(@enumerated), 2, 'Enumerated correct number of items');
    is($enumerated[0], "Hello", 'First enumerated item correct');
    is($enumerated[1], 42, 'Second enumerated item correct');
    
    # Test Clear
    $list->Clear();
    is($list->Count(), 0, 'List empty after Clear');
    
    # Test AddRange
    $list->AddRange(["A", "B", "C"]);
    is($list->Count(), 3, 'AddRange with array works');
    is($list->Item(0), "A", 'AddRange items correct');
    
    # Test functional methods
    ok($list->Exists(sub { $_[0] eq "B" }), 'Exists finds matching item');
    ok(!$list->Exists(sub { $_[0] eq "Z" }), 'Exists returns false for non-matching');
    
    my $found = $list->Find(sub { $_[0] eq "C" });
    is($found, "C", 'Find returns correct item');
    
    my $notFound = $list->Find(sub { $_[0] eq "Z" });
    is($notFound, undef, 'Find returns undef for non-matching');
    
    my $allMatching = $list->FindAll(sub { $_[0] ne "B" });
    is($allMatching->Count(), 2, 'FindAll returns correct count');
    ok($allMatching->Contains("A"), 'FindAll contains expected item');
    ok($allMatching->Contains("C"), 'FindAll contains expected item');
    
    # Test ConvertAll
    my $converted = $list->ConvertAll(sub { "Item: $_[0]" });
    is($converted->Count(), 3, 'ConvertAll returns correct count');
    is($converted->Item(0), "Item: A", 'ConvertAll transforms correctly');
}

sub test_dictionary {
    # Test construction
    my $dict = System::Collections::Generic::Dictionary->new();
    isa_ok($dict, 'System::Collections::Generic::Dictionary', 'Dictionary creation');
    is($dict->Count(), 0, 'Empty dictionary has zero count');
    
    # Test Add
    $dict->Add("name", "John");
    $dict->Add("age", 30);
    $dict->Add("city", "New York");
    is($dict->Count(), 3, 'Count correct after adding items');
    
    # Test Item accessor (getter)
    is($dict->Item("name"), "John", 'Item getter works');
    is($dict->Item("age"), 30, 'Item getter with number works');
    
    # Test Item accessor (setter)
    $dict->Item("age", 31);
    is($dict->Item("age"), 31, 'Item setter works');
    
    # Test ContainsKey
    ok($dict->ContainsKey("name"), 'ContainsKey finds existing key');
    ok(!$dict->ContainsKey("email"), 'ContainsKey returns false for missing key');
    
    # Test ContainsValue
    ok($dict->ContainsValue("John"), 'ContainsValue finds existing value');
    ok(!$dict->ContainsValue("Jane"), 'ContainsValue returns false for missing value');
    
    # Test TryGetValue
    my $value;
    ok($dict->TryGetValue("name", \$value), 'TryGetValue returns true for existing key');
    is($value, "John", 'TryGetValue sets correct value');
    
    ok(!$dict->TryGetValue("email", \$value), 'TryGetValue returns false for missing key');
    
    # Test Keys collection
    my $keys = $dict->Keys();
    isa_ok($keys, 'System::Collections::Generic::DictionaryKeyCollection', 'Keys returns correct type');
    is($keys->Count(), 3, 'Keys collection has correct count');
    ok($keys->Contains("name"), 'Keys collection contains expected key');
    
    my $keyArray = $keys->ToArray();
    is(scalar(@$keyArray), 3, 'Keys array has correct length');
    
    # Test Values collection
    my $values = $dict->Values();
    isa_ok($values, 'System::Collections::Generic::DictionaryValueCollection', 'Values returns correct type');
    is($values->Count(), 3, 'Values collection has correct count');
    ok($values->Contains("John"), 'Values collection contains expected value');
    
    # Test enumeration (KeyValuePairs)
    my $enumerator = $dict->GetEnumerator();
    isa_ok($enumerator, 'System::Collections::Generic::DictionaryEnumerator', 'GetEnumerator returns correct type');
    
    my $kvpCount = 0;
    while ($enumerator->MoveNext()) {
        my $kvp = $enumerator->Current();
        isa_ok($kvp, 'System::Collections::Generic::KeyValuePair', 'Enumerator returns KeyValuePair');
        ok(defined($kvp->Key()), 'KeyValuePair has key');
        ok(defined($kvp->Value()), 'KeyValuePair has value');
        $kvpCount++;
    }
    is($kvpCount, 3, 'Enumerated correct number of key-value pairs');
    
    # Test Remove
    ok($dict->Remove("age"), 'Remove returns true for existing key');
    is($dict->Count(), 2, 'Count decreased after remove');
    ok(!$dict->Remove("nonexistent"), 'Remove returns false for missing key');
    
    # Test Clear
    $dict->Clear();
    is($dict->Count(), 0, 'Dictionary empty after Clear');
}

sub test_stack {
    # Test construction
    my $stack = System::Collections::Generic::Stack->new();
    isa_ok($stack, 'System::Collections::Generic::Stack', 'Stack creation');
    is($stack->Count(), 0, 'Empty stack has zero count');
    
    # Test Push
    $stack->Push("First");
    $stack->Push("Second");
    $stack->Push("Third");
    is($stack->Count(), 3, 'Count correct after pushing items');
    
    # Test Peek
    is($stack->Peek(), "Third", 'Peek returns top item');
    is($stack->Count(), 3, 'Count unchanged after Peek');
    
    # Test Pop
    is($stack->Pop(), "Third", 'Pop returns correct item');
    is($stack->Count(), 2, 'Count decreased after Pop');
    is($stack->Peek(), "Second", 'New top item correct after Pop');
    
    # Test Contains
    ok($stack->Contains("First"), 'Contains finds existing item');
    ok(!$stack->Contains("Third"), 'Contains returns false for popped item');
    
    # Test ToArray (returns in stack order - top to bottom)
    $stack->Push("Fourth");
    my $array = $stack->ToArray();
    isa_ok($array, 'ARRAY', 'ToArray returns array reference');
    is(scalar(@$array), 3, 'Array has correct length');
    is($array->[0], "Fourth", 'Array first element is top of stack');
    is($array->[2], "First", 'Array last element is bottom of stack');
    
    # Test enumeration (top to bottom)
    my $enumerator = $stack->GetEnumerator();
    isa_ok($enumerator, 'System::Collections::Generic::StackEnumerator', 'GetEnumerator returns correct type');
    
    my @enumerated = ();
    while ($enumerator->MoveNext()) {
        push @enumerated, $enumerator->Current();
    }
    is(scalar(@enumerated), 3, 'Enumerated correct number of items');
    is($enumerated[0], "Fourth", 'First enumerated item is top');
    is($enumerated[2], "First", 'Last enumerated item is bottom');
    
    # Test Clear
    $stack->Clear();
    is($stack->Count(), 0, 'Stack empty after Clear');
}

sub test_queue {
    # Test construction
    my $queue = System::Collections::Generic::Queue->new();
    isa_ok($queue, 'System::Collections::Generic::Queue', 'Queue creation');
    is($queue->Count(), 0, 'Empty queue has zero count');
    
    # Test Enqueue
    $queue->Enqueue("First");
    $queue->Enqueue("Second");
    $queue->Enqueue("Third");
    is($queue->Count(), 3, 'Count correct after enqueuing items');
    
    # Test Peek
    is($queue->Peek(), "First", 'Peek returns front item');
    is($queue->Count(), 3, 'Count unchanged after Peek');
    
    # Test Dequeue
    is($queue->Dequeue(), "First", 'Dequeue returns correct item');
    is($queue->Count(), 2, 'Count decreased after Dequeue');
    is($queue->Peek(), "Second", 'New front item correct after Dequeue');
    
    # Test Contains
    ok($queue->Contains("Second"), 'Contains finds existing item');
    ok(!$queue->Contains("First"), 'Contains returns false for dequeued item');
    
    # Test ToArray (returns in queue order - front to back)
    $queue->Enqueue("Fourth");
    my $array = $queue->ToArray();
    isa_ok($array, 'ARRAY', 'ToArray returns array reference');
    is(scalar(@$array), 3, 'Array has correct length');
    is($array->[0], "Second", 'Array first element is front of queue');
    is($array->[2], "Fourth", 'Array last element is back of queue');
    
    # Test enumeration (front to back)
    my $enumerator = $queue->GetEnumerator();
    isa_ok($enumerator, 'System::Collections::Generic::QueueEnumerator', 'GetEnumerator returns correct type');
    
    my @enumerated = ();
    while ($enumerator->MoveNext()) {
        push @enumerated, $enumerator->Current();
    }
    is(scalar(@enumerated), 3, 'Enumerated correct number of items');
    is($enumerated[0], "Second", 'First enumerated item is front');
    is($enumerated[2], "Fourth", 'Last enumerated item is back');
    
    # Test Clear
    $queue->Clear();
    is($queue->Count(), 0, 'Queue empty after Clear');
}

sub test_linkedlist {
    # Test construction
    my $list = System::Collections::Generic::LinkedList->new();
    isa_ok($list, 'System::Collections::Generic::LinkedList', 'LinkedList creation');
    is($list->Count(), 0, 'Empty list has zero count');
    is($list->First(), undef, 'Empty list has no first node');
    is($list->Last(), undef, 'Empty list has no last node');
    
    # Test AddFirst/AddLast
    my $node2 = $list->AddLast("Second");
    my $node1 = $list->AddFirst("First");
    my $node3 = $list->AddLast("Third");
    
    isa_ok($node1, 'System::Collections::Generic::LinkedListNode', 'AddFirst returns node');
    isa_ok($node2, 'System::Collections::Generic::LinkedListNode', 'AddLast returns node');
    
    is($list->Count(), 3, 'Count correct after adding nodes');
    is($list->First()->Value(), "First", 'First node correct');
    is($list->Last()->Value(), "Third", 'Last node correct');
    
    # Test node navigation
    is($node1->Next()->Value(), "Second", 'Node navigation forward works');
    is($node3->Previous()->Value(), "Second", 'Node navigation backward works');
    is($node1->Previous(), undef, 'First node has no previous');
    is($node3->Next(), undef, 'Last node has no next');
    
    # Test AddAfter/AddBefore
    my $node2_5 = $list->AddAfter($node2, "Second.5");
    my $node1_5 = $list->AddBefore($node2, "First.5");
    
    is($list->Count(), 5, 'Count correct after inserting nodes');
    is($node1_5->Previous()->Value(), "First", 'AddBefore links correctly');
    is($node1_5->Next()->Value(), "Second", 'AddBefore links correctly');
    is($node2_5->Previous()->Value(), "Second", 'AddAfter links correctly');
    is($node2_5->Next()->Value(), "Third", 'AddAfter links correctly');
    
    # Test Find
    my $found = $list->Find("Second");
    is($found->Value(), "Second", 'Find returns correct node');
    
    my $notFound = $list->Find("NotExists");
    is($notFound, undef, 'Find returns undef for missing value');
    
    # Test Contains
    ok($list->Contains("First"), 'Contains finds existing value');
    ok(!$list->Contains("NotExists"), 'Contains returns false for missing value');
    
    # Test Remove by value
    ok($list->Remove("First.5"), 'Remove by value returns true');
    is($list->Count(), 4, 'Count decreased after remove');
    ok(!$list->Contains("First.5"), 'Removed value no longer in list');
    
    # Test Remove by node
    $list->Remove($node2_5);
    is($list->Count(), 3, 'Count decreased after removing node');
    
    # Test enumeration
    my $enumerator = $list->GetEnumerator();
    isa_ok($enumerator, 'System::Collections::Generic::LinkedListEnumerator', 'GetEnumerator returns correct type');
    
    my @enumerated = ();
    while ($enumerator->MoveNext()) {
        push @enumerated, $enumerator->Current();
    }
    is(scalar(@enumerated), 3, 'Enumerated correct number of items');
    is($enumerated[0], "First", 'First enumerated item correct');
    is($enumerated[1], "Second", 'Second enumerated item correct');
    is($enumerated[2], "Third", 'Third enumerated item correct');
    
    # Test ToArray
    my $array = $list->ToArray();
    isa_ok($array, 'ARRAY', 'ToArray returns array reference');
    is(scalar(@$array), 3, 'Array has correct length');
    is($array->[0], "First", 'Array order correct');
    is($array->[2], "Third", 'Array order correct');
    
    # Test RemoveFirst/RemoveLast
    $list->RemoveFirst();
    is($list->Count(), 2, 'Count decreased after RemoveFirst');
    is($list->First()->Value(), "Second", 'New first node correct');
    
    $list->RemoveLast();
    is($list->Count(), 1, 'Count decreased after RemoveLast');
    is($list->Last()->Value(), "Second", 'New last node correct');
    
    # Test Clear
    $list->Clear();
    is($list->Count(), 0, 'List empty after Clear');
    is($list->First(), undef, 'No first node after Clear');
    is($list->Last(), undef, 'No last node after Clear');
}

sub test_keyvaluepair {
    # Test construction
    my $kvp = System::Collections::Generic::KeyValuePair->new("key1", "value1");
    isa_ok($kvp, 'System::Collections::Generic::KeyValuePair', 'KeyValuePair creation');
    
    # Test properties
    is($kvp->Key(), "key1", 'Key property correct');
    is($kvp->Value(), "value1", 'Value property correct');
    
    # Test ToString
    is($kvp->ToString(), "[key1, value1]", 'ToString format correct');
    
    # Test with null values
    my $kvp_null = System::Collections::Generic::KeyValuePair->new(undef, undef);
    is($kvp_null->ToString(), "[<null>, <null>]", 'ToString with nulls correct');
    
    # Test Equals
    my $kvp2 = System::Collections::Generic::KeyValuePair->new("key1", "value1");
    ok($kvp->Equals($kvp2), 'Equal KeyValuePairs compare correctly');
    
    my $kvp3 = System::Collections::Generic::KeyValuePair->new("key2", "value1");
    ok(!$kvp->Equals($kvp3), 'Different KeyValuePairs compare correctly');
    
    # Test GetHashCode
    is($kvp->GetHashCode(), $kvp2->GetHashCode(), 'Equal KeyValuePairs have same hash code');
}

# Run all tests
test_list();
test_dictionary();
test_stack();
test_queue();
test_linkedlist();
test_keyvaluepair();

done_testing();