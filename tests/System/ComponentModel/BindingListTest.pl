#!/usr/bin/perl

use strict;
use warnings;
use lib qw(. ./lib);

# Boolean constants
use constant true => 1;
use constant false => 0;

# Import all required modules
require System::ComponentModel::BindingList;
require System::ComponentModel::PropertyChangedEventArgs;
require System::ComponentModel::PropertyChangingEventArgs;
require System::Collections::Specialized::NotifyCollectionChangedEventArgs;
require System::Collections::Specialized::NotifyCollectionChangedAction;
require System::String;
require System::Int32;
require System::Exceptions;

# Test counters
my $tests_run = 0;
my $tests_passed = 0;

sub test_ok {
  my ($condition, $test_name) = @_;
  $tests_run++;
  if ($condition) {
    print "ok $tests_run - $test_name\n";
    $tests_passed++;
  } else {
    print "not ok $tests_run - $test_name\n";
  }
}

sub test_exception {
  my ($code, $expected_exception, $test_name) = @_;
  $tests_run++;
  
  my $caught_exception = '';
  eval {
    $code->();
  };
  
  if ($@) {
    $caught_exception = ref($@) ? ref($@) : $@;
  }
  
  if ($caught_exception =~ /$expected_exception/) {
    print "ok $tests_run - $test_name\n";
    $tests_passed++;
  } else {
    print "not ok $tests_run - $test_name (expected $expected_exception, got $caught_exception)\n";
  }
}

print "1..200\n"; # We'll have approximately 200 tests

# Test 1-10: Basic BindingList construction and properties
my $bindingList = System::ComponentModel::BindingList->new();
test_ok(defined($bindingList), 'BindingList construction');
test_ok($bindingList->isa('System::ComponentModel::BindingList'), 'BindingList isa BindingList');
test_ok($bindingList->isa('System::Collections::Generic::List'), 'BindingList inherits from List');
test_ok($bindingList->can('PropertyChanged'), 'BindingList implements PropertyChanged');
test_ok($bindingList->can('CollectionChanged'), 'BindingList implements CollectionChanged');
test_ok($bindingList->AllowEdit(), 'AllowEdit defaults to true');
test_ok($bindingList->AllowNew(), 'AllowNew defaults to true');
test_ok($bindingList->AllowRemove(), 'AllowRemove defaults to true');
test_ok($bindingList->RaiseListChangedEvents(), 'RaiseListChangedEvents defaults to true');
test_ok($bindingList->Count() == 0, 'Initial count is zero');

# Test 11-20: Property change notifications for BindingList properties
my $propertyChangedCalled = 0;
my $propertyChangingCalled = 0;
my $lastPropertyName = '';

my $propertyChangedHandler = sub {
  my ($sender, $e) = @_;
  $propertyChangedCalled++;
  $lastPropertyName = $e->PropertyName() if $e;
};

my $propertyChangingHandler = sub {
  my ($sender, $e) = @_;
  $propertyChangingCalled++;
};

$bindingList->PropertyChanged($propertyChangedHandler);
$bindingList->PropertyChanging($propertyChangingHandler);

$bindingList->AllowEdit(false);
test_ok($propertyChangedCalled == 1, 'PropertyChanged fired for AllowEdit');
test_ok($propertyChangingCalled == 1, 'PropertyChanging fired for AllowEdit');
test_ok($lastPropertyName eq 'AllowEdit', 'Correct property name in PropertyChanged event');
test_ok(!$bindingList->AllowEdit(), 'AllowEdit set to false');

$bindingList->AllowNew(false);
test_ok($propertyChangedCalled == 2, 'PropertyChanged fired for AllowNew');
test_ok($propertyChangingCalled == 2, 'PropertyChanging fired for AllowNew');
test_ok($lastPropertyName eq 'AllowNew', 'Correct property name for AllowNew');

$bindingList->AllowRemove(false);
test_ok($propertyChangedCalled == 3, 'PropertyChanged fired for AllowRemove');
test_ok($propertyChangingCalled == 3, 'PropertyChanging fired for AllowRemove');

$bindingList->RaiseListChangedEvents(false);
test_ok($propertyChangedCalled == 4, 'PropertyChanged fired for RaiseListChangedEvents');

# Test 21-30: Collection change notifications
$bindingList->RaiseListChangedEvents(true); # Reset for testing
my $collectionChangedCalled = 0;
my $lastAction = '';
my $lastNewItems = undef;
my $lastOldItems = undef;

my $collectionChangedHandler = sub {
  my ($sender, $e) = @_;
  $collectionChangedCalled++;
  $lastAction = $e->Action() if $e;
  $lastNewItems = $e->NewItems() if $e;
  $lastOldItems = $e->OldItems() if $e;
};

$bindingList->CollectionChanged($collectionChangedHandler);

# Reset AllowNew for adding items
$bindingList->AllowNew(true);

# Test adding items
my $item1 = System::String->new("Item1");
my $item2 = System::String->new("Item2");

$bindingList->Add($item1);
test_ok($collectionChangedCalled == 1, 'CollectionChanged fired for Add');
test_ok($lastAction eq 'Add', 'Correct action for Add');
test_ok(defined($lastNewItems) && @$lastNewItems == 1, 'NewItems contains one item for Add');
test_ok($bindingList->Count() == 1, 'Count updated after Add');

$bindingList->Insert(0, $item2);
test_ok($collectionChangedCalled == 2, 'CollectionChanged fired for Insert');
test_ok($lastAction eq 'Add', 'Correct action for Insert');
test_ok($bindingList->Count() == 2, 'Count updated after Insert');
test_ok($bindingList->Item(0) eq $item2, 'Item inserted at correct position');

# Test 31-40: Remove operations
$bindingList->AllowRemove(true);

$bindingList->RemoveAt(0);
test_ok($collectionChangedCalled == 3, 'CollectionChanged fired for RemoveAt');
test_ok($lastAction eq 'Remove', 'Correct action for RemoveAt');
test_ok(defined($lastOldItems) && @$lastOldItems == 1, 'OldItems contains removed item');
test_ok($bindingList->Count() == 1, 'Count updated after RemoveAt');

$bindingList->Add($item2);
my $removed = $bindingList->Remove($item2);
test_ok($removed, 'Remove returns true for existing item');
test_ok($collectionChangedCalled == 5, 'CollectionChanged fired for both Add and Remove'); # Add + Remove
test_ok($bindingList->Count() == 1, 'Count correct after Remove');

my $notRemoved = $bindingList->Remove($item2);
test_ok(!$notRemoved, 'Remove returns false for non-existing item');
test_ok($collectionChangedCalled == 5, 'CollectionChanged not fired for failed Remove');

# Test 41-50: Replace operations
my $item3 = System::String->new("Item3");
$bindingList->AllowEdit(true);

$bindingList->Item(0, $item3);
test_ok($collectionChangedCalled == 6, 'CollectionChanged fired for SetItem');
test_ok($lastAction eq 'Replace', 'Correct action for SetItem');
test_ok(defined($lastNewItems) && @$lastNewItems == 1, 'NewItems for Replace');
test_ok(defined($lastOldItems) && @$lastOldItems == 1, 'OldItems for Replace');
test_ok($bindingList->Item(0) eq $item3, 'Item replaced correctly');

# Clear operation
$bindingList->Add($item1);
$bindingList->Add($item2);
test_ok($bindingList->Count() == 3, 'Items added before Clear');

$bindingList->Clear();
test_ok($collectionChangedCalled >= 8, 'CollectionChanged fired for Clear (after Add operations)');
test_ok($bindingList->Count() == 0, 'List cleared');

# Test 51-70: Exception handling for restricted operations
$bindingList->AllowNew(false);
test_exception(
  sub { $bindingList->Add($item1); },
  'NotSupportedException',
  'Add throws when AllowNew is false'
);

test_exception(
  sub { $bindingList->Insert(0, $item1); },
  'NotSupportedException',
  'Insert throws when AllowNew is false'
);

$bindingList->AllowNew(true);
$bindingList->Add($item1);
$bindingList->AllowEdit(false);

test_exception(
  sub { $bindingList->Item(0, $item2); },
  'NotSupportedException',
  'SetItem throws when AllowEdit is false'
);

$bindingList->AllowRemove(false);
test_exception(
  sub { $bindingList->RemoveAt(0); },
  'NotSupportedException',
  'RemoveAt throws when AllowRemove is false'
);

test_exception(
  sub { $bindingList->Remove($item1); },
  'NotSupportedException',
  'Remove throws when AllowRemove is false'
);

test_exception(
  sub { $bindingList->Clear(); },
  'NotSupportedException',
  'Clear throws when AllowRemove is false'
);

# Test 71-90: ArgumentException and edge cases
$bindingList->AllowNew(true);
$bindingList->AllowEdit(true);
$bindingList->AllowRemove(true);
$bindingList->Clear();

test_exception(
  sub { $bindingList->RemoveAt(-1); },
  'ArgumentOutOfRangeException',
  'RemoveAt throws for negative index'
);

test_exception(
  sub { $bindingList->RemoveAt(5); },
  'ArgumentOutOfRangeException',
  'RemoveAt throws for index beyond count'
);

test_exception(
  sub { $bindingList->Item(-1, $item1); },
  'ArgumentOutOfRangeException',
  'SetItem throws for negative index'
);

test_exception(
  sub { $bindingList->Item(5, $item1); },
  'ArgumentOutOfRangeException',
  'SetItem throws for index beyond count'
);

# Test null reference exceptions
test_exception(
  sub { 
    my $null_list = undef;
    $null_list->Add($item1);
  },
  'NullReferenceException',
  'Add throws NullReferenceException for null list'
);

# Test 91-120: Event argument validation
my $eventArgs1 = System::ComponentModel::PropertyChangedEventArgs->new('TestProperty');
test_ok(defined($eventArgs1), 'PropertyChangedEventArgs construction');
test_ok($eventArgs1->PropertyName() eq 'TestProperty', 'PropertyChangedEventArgs property name');

my $eventArgs2 = System::ComponentModel::PropertyChangedEventArgs->new(undef);
test_ok(defined($eventArgs2), 'PropertyChangedEventArgs with null property name');
test_ok(!defined($eventArgs2->PropertyName()), 'Null property name preserved');

my $eventArgs3 = System::ComponentModel::PropertyChangingEventArgs->new('TestProperty');
test_ok(defined($eventArgs3), 'PropertyChangingEventArgs construction');
test_ok($eventArgs3->PropertyName() eq 'TestProperty', 'PropertyChangingEventArgs property name');

# Test CancelEventArgs
my $cancelArgs1 = System::ComponentModel::CancelEventArgs->new();
test_ok(defined($cancelArgs1), 'CancelEventArgs default construction');
test_ok(!$cancelArgs1->Cancel(), 'CancelEventArgs defaults to false');

my $cancelArgs2 = System::ComponentModel::CancelEventArgs->new(true);
test_ok($cancelArgs2->Cancel(), 'CancelEventArgs constructor sets Cancel');

$cancelArgs2->Cancel(false);
test_ok(!$cancelArgs2->Cancel(), 'CancelEventArgs Cancel property setter');

# Test 121-150: Collection Changed EventArgs validation
my $addArgs = System::Collections::Specialized::NotifyCollectionChangedEventArgs->NewAdd([$item1], 0);
test_ok(defined($addArgs), 'NotifyCollectionChangedEventArgs Add construction');
test_ok($addArgs->Action() eq 'Add', 'Add action correct');
test_ok(defined($addArgs->NewItems()), 'Add has NewItems');
test_ok($addArgs->NewStartingIndex() == 0, 'Add starting index correct');

my $removeArgs = System::Collections::Specialized::NotifyCollectionChangedEventArgs->NewRemove([$item1], 0);
test_ok(defined($removeArgs), 'NotifyCollectionChangedEventArgs Remove construction');
test_ok($removeArgs->Action() eq 'Remove', 'Remove action correct');
test_ok(defined($removeArgs->OldItems()), 'Remove has OldItems');
test_ok($removeArgs->OldStartingIndex() == 0, 'Remove old starting index correct');

my $replaceArgs = System::Collections::Specialized::NotifyCollectionChangedEventArgs->NewReplace([$item2], [$item1], 0);
test_ok(defined($replaceArgs), 'NotifyCollectionChangedEventArgs Replace construction');
test_ok($replaceArgs->Action() eq 'Replace', 'Replace action correct');
test_ok(defined($replaceArgs->NewItems()), 'Replace has NewItems');
test_ok(defined($replaceArgs->OldItems()), 'Replace has OldItems');

my $moveArgs = System::Collections::Specialized::NotifyCollectionChangedEventArgs->NewMove([$item1], 1, 0);
test_ok(defined($moveArgs), 'NotifyCollectionChangedEventArgs Move construction');
test_ok($moveArgs->Action() eq 'Move', 'Move action correct');
test_ok($moveArgs->NewStartingIndex() == 1, 'Move new index correct');
test_ok($moveArgs->OldStartingIndex() == 0, 'Move old index correct');

my $resetArgs = System::Collections::Specialized::NotifyCollectionChangedEventArgs->NewReset();
test_ok(defined($resetArgs), 'NotifyCollectionChangedEventArgs Reset construction');
test_ok($resetArgs->Action() eq 'Reset', 'Reset action correct');

# Test 151-170: Edge cases and error conditions for EventArgs
test_exception(
  sub { System::Collections::Specialized::NotifyCollectionChangedEventArgs->new('InvalidAction'); },
  'ArgumentException',
  'Invalid action throws ArgumentException'
);

test_exception(
  sub { System::Collections::Specialized::NotifyCollectionChangedEventArgs->new(undef); },
  'ArgumentNullException',
  'Null action throws ArgumentNullException'
);

test_exception(
  sub { System::Collections::Specialized::NotifyCollectionChangedEventArgs->NewAdd(undef, 0); },
  'ArgumentException',
  'Add with null items throws ArgumentException'
);

test_exception(
  sub { System::Collections::Specialized::NotifyCollectionChangedEventArgs->NewAdd([$item1], -1); },
  'ArgumentException',
  'Add with negative index throws ArgumentException'
);

test_exception(
  sub { System::Collections::Specialized::NotifyCollectionChangedEventArgs->NewRemove(undef, 0); },
  'ArgumentException',
  'Remove with null items throws ArgumentException'
);

test_exception(
  sub { System::Collections::Specialized::NotifyCollectionChangedEventArgs->NewMove([$item1], 0, 0); },
  'ArgumentException',
  'Move with same indices throws ArgumentException'
);

# Test 171-190: Complex scenarios
my $complexList = System::ComponentModel::BindingList->new();
my $eventCount = 0;
my $propertyEventCount = 0;

$complexList->CollectionChanged(sub { $eventCount++; });
$complexList->PropertyChanged(sub { $propertyEventCount++; });

# Batch operations
$complexList->Add($item1);
$complexList->Add($item2);
$complexList->Add($item3);
test_ok($eventCount == 3, 'Multiple adds generate multiple events');

$complexList->RaiseListChangedEvents(false);
test_ok($propertyEventCount >= 1, 'Property events generated for RaiseListChangedEvents');

my $oldEventCount = $eventCount;
$complexList->Add(System::String->new("Item4"));
test_ok($eventCount == $oldEventCount, 'No collection events when RaiseListChangedEvents is false');

$complexList->RaiseListChangedEvents(true);
$complexList->Clear();
test_ok($eventCount > $oldEventCount, 'Collection events resume when RaiseListChangedEvents is true');

# Test 191-200: Performance and stress testing
my $stressList = System::ComponentModel::BindingList->new();
my $stressEventCount = 0;
$stressList->CollectionChanged(sub { $stressEventCount++; });

# Add many items
for my $i (1..20) {
  $stressList->Add(System::String->new("StressItem$i"));
}
test_ok($stressEventCount == 20, 'All stress test additions generated events');
test_ok($stressList->Count() == 20, 'All stress test items added');

# Remove many items
for my $i (1..10) {
  $stressList->RemoveAt(0);
}
test_ok($stressEventCount == 30, 'All stress test removals generated events'); # 20 adds + 10 removes
test_ok($stressList->Count() == 10, 'Correct count after stress test removals');

# Final validation tests
test_ok($stressList->isa('System::ComponentModel::INotifyPropertyChanged'), 'BindingList implements INotifyPropertyChanged interface');
test_ok($stressList->can('PropertyChanged'), 'PropertyChanged method available');
test_ok($stressList->can('CollectionChanged'), 'CollectionChanged method available');

# Test interface validation (should not throw)
my $interfaceTest = 1;
eval {
  System::ComponentModel::INotifyPropertyChanged->_validate_implementation(ref($stressList));
};
$interfaceTest = 0 if $@;
test_ok($interfaceTest, 'BindingList satisfies INotifyPropertyChanged interface contract');

# Test change notification enable/disable
my $notificationList = System::ComponentModel::BindingList->new();
$notificationList->EnableChangeNotification(true);
$notificationList->Add($item1);
test_ok($notificationList->Count() == 1, 'Change notification enabled works');

# Property event validation edge cases
my $edgeEventArgs = System::ComponentModel::PropertyChangedEventArgs->new('');
test_ok($edgeEventArgs->PropertyName() eq '', 'Empty string property name allowed');

# Final stress test with property changes
my $propertyChangeCount = 0;
my $finalList = System::ComponentModel::BindingList->new();
$finalList->PropertyChanged(sub { $propertyChangeCount++; });

$finalList->AllowEdit(false);
$finalList->AllowNew(false); 
$finalList->AllowRemove(false);
$finalList->RaiseListChangedEvents(false);
test_ok($propertyChangeCount == 4, 'All property changes generated events');

print "\n# Tests completed: $tests_run\n";
print "# Tests passed: $tests_passed\n";
print "# Pass rate: " . sprintf("%.1f%%", ($tests_passed / $tests_run) * 100) . "\n";

exit($tests_passed == $tests_run ? 0 : 1);