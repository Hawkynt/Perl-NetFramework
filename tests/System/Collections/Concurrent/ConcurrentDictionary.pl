#!/usr/bin/perl
use strict;
use warnings;
use Test::More;

# Add parent directory to lib path
use FindBin qw($RealBin);
use lib "$RealBin/../../../..";

require System::Collections::Concurrent::ConcurrentDictionary;

# Test plan: comprehensive tests for ConcurrentDictionary
plan tests => 54;

# Test 1-3: Constructor and initial state
{
  my $dict = System::Collections::Concurrent::ConcurrentDictionary->new();
  ok(defined($dict), 'ConcurrentDictionary constructor');
  is($dict->Count(), 0, 'Initial count is zero');
  ok($dict->IsEmpty(), 'Initial dictionary is empty');
}

# Test 4-10: TryAdd operations
{
  my $dict = System::Collections::Concurrent::ConcurrentDictionary->new();
  
  my $success = $dict->TryAdd('key1', 'value1');
  ok($success, 'TryAdd succeeds for new key');
  is($dict->Count(), 1, 'Count increases after TryAdd');
  ok(!$dict->IsEmpty(), 'Dictionary not empty after TryAdd');
  
  # Try to add same key again
  $success = $dict->TryAdd('key1', 'different_value');
  ok(!$success, 'TryAdd fails for existing key');
  is($dict->Count(), 1, 'Count unchanged when TryAdd fails');
  
  # Add more keys
  $dict->TryAdd('key2', 'value2');
  $dict->TryAdd('key3', undef);
  is($dict->Count(), 3, 'Count after multiple TryAdd operations');
}

# Test 11-20: TryGetValue operations
{
  my $dict = System::Collections::Concurrent::ConcurrentDictionary->new();
  
  # Test get from empty dictionary
  my $value;
  my $success = $dict->TryGetValue('nonexistent', \$value);
  ok(!$success, 'TryGetValue fails for nonexistent key');
  ok(!defined($value), 'Value is undef when get fails');
  
  # Add values and test retrieval
  $dict->TryAdd('test_key', 'test_value');
  $dict->TryAdd('null_key', undef);
  $dict->TryAdd('zero_key', 0);
  $dict->TryAdd('empty_key', '');
  
  $success = $dict->TryGetValue('test_key', \$value);
  ok($success, 'TryGetValue succeeds for existing key');
  is($value, 'test_value', 'Retrieved correct value');
  
  $success = $dict->TryGetValue('null_key', \$value);
  ok($success, 'TryGetValue succeeds for null value');
  ok(!defined($value), 'Retrieved null value correctly');
  
  $success = $dict->TryGetValue('zero_key', \$value);
  ok($success && $value == 0, 'Retrieved zero value correctly');
  
  $success = $dict->TryGetValue('empty_key', \$value);
  ok($success && $value eq '', 'Retrieved empty string correctly');
  
  $success = $dict->TryGetValue('missing', \$value);
  ok(!$success, 'TryGetValue fails for missing key');
}

# Test 21-30: TryRemove operations
{
  my $dict = System::Collections::Concurrent::ConcurrentDictionary->new();
  
  # Test remove from empty dictionary
  my $value;
  my $success = $dict->TryRemove('nonexistent', \$value);
  ok(!$success, 'TryRemove fails for nonexistent key');
  
  # Add and remove values
  $dict->TryAdd('remove_key', 'remove_value');
  $dict->TryAdd('keep_key', 'keep_value');
  
  is($dict->Count(), 2, 'Count before remove');
  
  $success = $dict->TryRemove('remove_key', \$value);
  ok($success, 'TryRemove succeeds for existing key');
  is($value, 'remove_value', 'Removed value returned correctly');
  is($dict->Count(), 1, 'Count decreases after remove');
  
  # Verify key is actually removed
  $success = $dict->TryGetValue('remove_key', \$value);
  ok(!$success, 'Key actually removed from dictionary');
  
  # Verify other key still exists
  $success = $dict->TryGetValue('keep_key', \$value);
  ok($success && $value eq 'keep_value', 'Other keys unaffected by remove');
  
  # Test removing same key again fails
  $success = $dict->TryRemove('remove_key', \$value);
  ok(!$success, 'TryRemove fails for already removed key');
}

# Test 31-38: TryUpdate operations
{
  my $dict = System::Collections::Concurrent::ConcurrentDictionary->new();
  
  # Test update on nonexistent key
  my $success = $dict->TryUpdate('missing', 'new_value', 'comparison_value');
  ok(!$success, 'TryUpdate fails for nonexistent key');
  
  # Add key and test successful update
  $dict->TryAdd('update_key', 'original_value');
  
  $success = $dict->TryUpdate('update_key', 'new_value', 'original_value');
  ok($success, 'TryUpdate succeeds with correct comparison value');
  
  my $value;
  $dict->TryGetValue('update_key', \$value);
  is($value, 'new_value', 'Value updated correctly');
  
  # Test update with wrong comparison value
  $success = $dict->TryUpdate('update_key', 'newer_value', 'wrong_comparison');
  ok(!$success, 'TryUpdate fails with wrong comparison value');
  
  $dict->TryGetValue('update_key', \$value);
  is($value, 'new_value', 'Value unchanged when update fails');
  
  # Test update with null values
  $dict->TryAdd('null_key', undef);
  $success = $dict->TryUpdate('null_key', 'from_null', undef);
  ok($success, 'TryUpdate works with null comparison');
  
  $dict->TryGetValue('null_key', \$value);
  is($value, 'from_null', 'Null value updated correctly');
}

# Test 39-44: GetOrAdd operations
{
  my $dict = System::Collections::Concurrent::ConcurrentDictionary->new();
  
  # Test add new key
  my $result = $dict->GetOrAdd('new_key', 'new_value');
  is($result, 'new_value', 'GetOrAdd returns added value for new key');
  is($dict->Count(), 1, 'Count increases with GetOrAdd');
  
  # Test get existing key
  $result = $dict->GetOrAdd('new_key', 'different_value');
  is($result, 'new_value', 'GetOrAdd returns existing value');
  is($dict->Count(), 1, 'Count unchanged when getting existing key');
  
  # Test with null values
  $result = $dict->GetOrAdd('null_key', undef);
  ok(!defined($result), 'GetOrAdd works with null values');
  is($dict->Count(), 2, 'Count increases with null GetOrAdd');
}

# Test 45-50: AddOrUpdate operations
{
  my $dict = System::Collections::Concurrent::ConcurrentDictionary->new();
  
  # Test add new key
  my $result = $dict->AddOrUpdate('new_key', 'add_value', 'update_value');
  is($result, 'add_value', 'AddOrUpdate adds new key with add value');
  is($dict->Count(), 1, 'Count increases with AddOrUpdate add');
  
  # Test update existing key
  $result = $dict->AddOrUpdate('new_key', 'different_add', 'update_value');
  is($result, 'update_value', 'AddOrUpdate updates existing key');
  
  my $value;
  $dict->TryGetValue('new_key', \$value);
  is($value, 'update_value', 'Key value updated correctly');
  is($dict->Count(), 1, 'Count unchanged with AddOrUpdate update');
}

# Test 51-55: ContainsKey operations
{
  my $dict = System::Collections::Concurrent::ConcurrentDictionary->new();
  
  ok(!$dict->ContainsKey('missing'), 'ContainsKey false for empty dictionary');
  
  $dict->TryAdd('exists', 'value');
  $dict->TryAdd('null_val', undef);
  
  ok($dict->ContainsKey('exists'), 'ContainsKey true for existing key');
  ok($dict->ContainsKey('null_val'), 'ContainsKey true for key with null value');
  ok(!$dict->ContainsKey('missing'), 'ContainsKey false for missing key');
  
  $dict->TryRemove('exists', undef);
  ok(!$dict->ContainsKey('exists'), 'ContainsKey false for removed key');
}

# Test 56-60: Keys, Values, and Clear operations
{
  my $dict = System::Collections::Concurrent::ConcurrentDictionary->new();
  
  my $keys = $dict->Keys();
  is(scalar(@$keys), 0, 'Keys returns empty array for empty dictionary');
  
  $dict->TryAdd('k1', 'v1');
  $dict->TryAdd('k2', 'v2');
  $dict->TryAdd('k3', 'v3');
  
  $keys = $dict->Keys();
  my $values = $dict->Values();
  
  is(scalar(@$keys), 3, 'Keys returns correct number of keys');
  is(scalar(@$values), 3, 'Values returns correct number of values');
  
  $dict->Clear();
  is($dict->Count(), 0, 'Count zero after Clear');
  ok($dict->IsEmpty(), 'Dictionary empty after Clear');
}

done_testing();