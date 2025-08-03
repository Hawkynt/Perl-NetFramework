#!/usr/bin/perl
use strict;
use warnings;
use lib '../../../';
use Test::More;
use System;

BEGIN {
    use_ok('System::Collections::Hashtable');
}

sub test_hashtable_creation {
    my $ht = System::Collections::Hashtable->new();
    isa_ok($ht, 'System::Collections::Hashtable', 'Hashtable creation');
    is($ht->Count(), 0, 'Empty hashtable has zero count');
}

sub test_hashtable_add_get {
    my $ht = System::Collections::Hashtable->new();
    
    $ht->Add("key1", "value1");
    is($ht->Count(), 1, 'Count increases after add');
    is($ht->Get("key1"), "value1", 'Get returns correct value');
    
    $ht->Set("key2", "value2");
    is($ht->Count(), 2, 'Count increases with Set');
    is($ht->Get("key2"), "value2", 'Set value can be retrieved');
}

sub test_hashtable_contains {
    my $ht = System::Collections::Hashtable->new();
    $ht->Add("exists", "value");
    
    ok($ht->ContainsKey("exists"), 'ContainsKey returns true for existing key');
    ok(!$ht->ContainsKey("missing"), 'ContainsKey returns false for missing key');
    
    ok($ht->ContainsValue("value"), 'ContainsValue returns true for existing value');
    ok(!$ht->ContainsValue("missing"), 'ContainsValue returns false for missing value');
}

sub test_hashtable_remove {
    my $ht = System::Collections::Hashtable->new();
    $ht->Add("temp", "value");
    is($ht->Count(), 1, 'Item added');
    
    $ht->Remove("temp");
    is($ht->Count(), 0, 'Item removed');
    ok(!$ht->ContainsKey("temp"), 'Key no longer exists after removal');
}

sub test_hashtable_clear {
    my $ht = System::Collections::Hashtable->new();
    $ht->Add("key1", "value1");
    $ht->Add("key2", "value2");
    is($ht->Count(), 2, 'Multiple items added');
    
    $ht->Clear();
    is($ht->Count(), 0, 'All items cleared');
}

sub test_hashtable_enumeration {
    my $ht = System::Collections::Hashtable->new();
    $ht->Add("a", 1);
    $ht->Add("b", 2);
    $ht->Add("c", 3);
    
    my $enumerator = $ht->GetEnumerator();
    my $count = 0;
    while ($enumerator->MoveNext()) {
        my $entry = $enumerator->Current();
        $count++;
    }
    is($count, 3, 'Enumeration visits all items');
}

sub test_hashtable_keys_values {
    my $ht = System::Collections::Hashtable->new();
    $ht->Add("x", 10);
    $ht->Add("y", 20);
    
    my $keys = $ht->Keys();
    my $values = $ht->Values();
    
    is($keys->Count(), 2, 'Keys collection has correct count');
    is($values->Count(), 2, 'Values collection has correct count');
}

test_hashtable_creation();
test_hashtable_add_get();
test_hashtable_contains();
test_hashtable_remove();
test_hashtable_clear();
test_hashtable_enumeration();
test_hashtable_keys_values();

done_testing();