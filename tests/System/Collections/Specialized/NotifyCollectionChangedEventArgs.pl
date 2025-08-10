#!/usr/bin/perl
use strict;
use warnings;
use lib '../../../../';
use Test::More;
use System;

BEGIN {
    use_ok('System::Collections::Specialized::NotifyCollectionChangedEventArgs');
    use_ok('System::Collections::Specialized::NotifyCollectionChangedAction');
    use_ok('System::EventArgs');
}

# Test constants
use constant {
    TEST_ITEMS => ["item1", "item2", "item3"],
    TEST_OLD_ITEMS => ["old1", "old2"],
    TEST_NEW_ITEMS => ["new1", "new2"],
    VALID_INDEX => 5,
    INVALID_INDEX => -2,
};

#===========================================
# BASIC CONSTRUCTOR TESTS
#===========================================

sub test_basic_constructor {
    # Test 1: Basic constructor with all parameters
    my $args = eval {
        System::Collections::Specialized::NotifyCollectionChangedEventArgs->new(
            'Add', TEST_ITEMS, VALID_INDEX, undef, -1
        );
    };
    ok(!$@, 'Basic constructor executes without error');
    ok(defined $args, 'Constructor returns defined object');
    isa_ok($args, 'System::Collections::Specialized::NotifyCollectionChangedEventArgs', 
           'Constructor returns correct type');
    isa_ok($args, 'System::EventArgs', 'Inherits from EventArgs');
}

sub test_constructor_parameter_validation {
    # Test 2: Constructor with null action throws exception
    eval {
        System::Collections::Specialized::NotifyCollectionChangedEventArgs->new(
            undef, TEST_ITEMS, VALID_INDEX
        );
    };
    like($@, qr/ArgumentNullException/, 'Null action throws ArgumentNullException');
    
    # Test 3: Constructor with invalid action throws exception
    eval {
        System::Collections::Specialized::NotifyCollectionChangedEventArgs->new(
            'InvalidAction', TEST_ITEMS, VALID_INDEX
        );
    };
    like($@, qr/ArgumentException/, 'Invalid action throws ArgumentException');
    
    # Test 4: Valid actions should work
    for my $action ('Add', 'Remove', 'Replace', 'Move', 'Reset') {
        my $args = eval {
            System::Collections::Specialized::NotifyCollectionChangedEventArgs->new($action);
        };
        ok(!$@ || $@->isa('System::ArgumentException'), "Action '$action' validation works");
    }
}

#===========================================
# CONVENIENCE CONSTRUCTOR TESTS
#===========================================

sub test_new_add_constructor {
    # Test 5: NewAdd convenience constructor
    my $add_args = System::Collections::Specialized::NotifyCollectionChangedEventArgs->NewAdd(
        TEST_ITEMS, VALID_INDEX
    );
    
    ok(defined $add_args, 'NewAdd returns defined object');
    is($add_args->Action(), 'Add', 'NewAdd sets correct action');
    is_deeply($add_args->NewItems(), TEST_ITEMS, 'NewAdd sets correct new items');
    is($add_args->NewStartingIndex(), VALID_INDEX, 'NewAdd sets correct starting index');
    ok(!defined $add_args->OldItems(), 'NewAdd has no old items');
    is($add_args->OldStartingIndex(), -1, 'NewAdd has -1 old starting index');
}

sub test_new_remove_constructor {
    # Test 6: NewRemove convenience constructor
    my $remove_args = System::Collections::Specialized::NotifyCollectionChangedEventArgs->NewRemove(
        TEST_OLD_ITEMS, VALID_INDEX
    );
    
    ok(defined $remove_args, 'NewRemove returns defined object');
    is($remove_args->Action(), 'Remove', 'NewRemove sets correct action');
    ok(!defined $remove_args->NewItems(), 'NewRemove has no new items');
    is($remove_args->NewStartingIndex(), -1, 'NewRemove has -1 new starting index');
    is_deeply($remove_args->OldItems(), TEST_OLD_ITEMS, 'NewRemove sets correct old items');
    is($remove_args->OldStartingIndex(), VALID_INDEX, 'NewRemove sets correct old starting index');
}

sub test_new_replace_constructor {
    # Test 7: NewReplace convenience constructor
    my $replace_args = System::Collections::Specialized::NotifyCollectionChangedEventArgs->NewReplace(
        TEST_NEW_ITEMS, TEST_OLD_ITEMS, VALID_INDEX
    );
    
    ok(defined $replace_args, 'NewReplace returns defined object');
    is($replace_args->Action(), 'Replace', 'NewReplace sets correct action');
    is_deeply($replace_args->NewItems(), TEST_NEW_ITEMS, 'NewReplace sets correct new items');
    is($replace_args->NewStartingIndex(), VALID_INDEX, 'NewReplace sets correct new starting index');
    is_deeply($replace_args->OldItems(), TEST_OLD_ITEMS, 'NewReplace sets correct old items');
    is($replace_args->OldStartingIndex(), VALID_INDEX, 'NewReplace sets correct old starting index');
}

sub test_new_move_constructor {
    # Test 8: NewMove convenience constructor
    my $new_index = 10;
    my $old_index = 5;
    my $move_args = System::Collections::Specialized::NotifyCollectionChangedEventArgs->NewMove(
        TEST_ITEMS, $new_index, $old_index
    );
    
    ok(defined $move_args, 'NewMove returns defined object');
    is($move_args->Action(), 'Move', 'NewMove sets correct action');
    is_deeply($move_args->NewItems(), TEST_ITEMS, 'NewMove sets correct new items');
    is($move_args->NewStartingIndex(), $new_index, 'NewMove sets correct new starting index');
    is_deeply($move_args->OldItems(), TEST_ITEMS, 'NewMove sets correct old items (same as new)');
    is($move_args->OldStartingIndex(), $old_index, 'NewMove sets correct old starting index');
}

sub test_new_reset_constructor {
    # Test 9: NewReset convenience constructor
    my $reset_args = System::Collections::Specialized::NotifyCollectionChangedEventArgs->NewReset();
    
    ok(defined $reset_args, 'NewReset returns defined object');
    is($reset_args->Action(), 'Reset', 'NewReset sets correct action');
    ok(!defined $reset_args->NewItems(), 'NewReset has no new items');
    is($reset_args->NewStartingIndex(), -1, 'NewReset has -1 new starting index');
    ok(!defined $reset_args->OldItems(), 'NewReset has no old items');
    is($reset_args->OldStartingIndex(), -1, 'NewReset has -1 old starting index');
}

#===========================================
# PROPERTY ACCESS TESTS
#===========================================

sub test_property_access {
    my $args = System::Collections::Specialized::NotifyCollectionChangedEventArgs->new(
        'Replace', TEST_NEW_ITEMS, VALID_INDEX, TEST_OLD_ITEMS, VALID_INDEX + 1
    );
    
    # Test 10: All properties accessible
    is($args->Action(), 'Replace', 'Action property returns correct value');
    is_deeply($args->NewItems(), TEST_NEW_ITEMS, 'NewItems property returns correct value');
    is($args->NewStartingIndex(), VALID_INDEX, 'NewStartingIndex property returns correct value');
    is_deeply($args->OldItems(), TEST_OLD_ITEMS, 'OldItems property returns correct value');
    is($args->OldStartingIndex(), VALID_INDEX + 1, 'OldStartingIndex property returns correct value');
}

sub test_null_reference_protection {
    # Test 11: Properties throw NullReferenceException on undefined object
    my $null_args = undef;
    
    eval { $null_args->Action(); };
    like($@, qr/NullReferenceException/, 'Action throws NullReferenceException on null object');
    
    eval { $null_args->NewItems(); };
    like($@, qr/NullReferenceException/, 'NewItems throws NullReferenceException on null object');
    
    eval { $null_args->NewStartingIndex(); };
    like($@, qr/NullReferenceException/, 'NewStartingIndex throws NullReferenceException on null object');
    
    eval { $null_args->OldItems(); };
    like($@, qr/NullReferenceException/, 'OldItems throws NullReferenceException on null object');
    
    eval { $null_args->OldStartingIndex(); };
    like($@, qr/NullReferenceException/, 'OldStartingIndex throws NullReferenceException on null object');
}

#===========================================
# ARGUMENT VALIDATION TESTS
#===========================================

sub test_add_action_validation {
    # Test 12: Add action with null items should throw
    eval {
        System::Collections::Specialized::NotifyCollectionChangedEventArgs->new(
            'Add', undef, 0
        );
    };
    like($@, qr/ArgumentException.*changedItems cannot be null for Add/, 'Add with null items throws exception');
    
    # Test 13: Add action with negative index should throw
    eval {
        System::Collections::Specialized::NotifyCollectionChangedEventArgs->new(
            'Add', TEST_ITEMS, -1
        );
    };
    like($@, qr/ArgumentException.*startingIndex must be >= 0 for Add/, 'Add with negative index throws exception');
    
    # Test 14: Add action with old items should throw
    eval {
        System::Collections::Specialized::NotifyCollectionChangedEventArgs->new(
            'Add', TEST_ITEMS, 0, TEST_OLD_ITEMS
        );
    };
    like($@, qr/ArgumentException.*oldItems must be null for Add/, 'Add with old items throws exception');
}

sub test_remove_action_validation {
    # Test 15: Remove action with null old items should throw
    eval {
        System::Collections::Specialized::NotifyCollectionChangedEventArgs->new(
            'Remove', undef, -1, undef, 0
        );
    };
    like($@, qr/ArgumentException.*oldItems cannot be null for Remove/, 'Remove with null old items throws exception');
    
    # Test 16: Remove action with negative old index should throw
    eval {
        System::Collections::Specialized::NotifyCollectionChangedEventArgs->new(
            'Remove', undef, -1, TEST_OLD_ITEMS, -1
        );
    };
    like($@, qr/ArgumentException.*oldStartingIndex must be >= 0 for Remove/, 'Remove with negative old index throws exception');
    
    # Test 17: Remove action with new items should throw
    eval {
        System::Collections::Specialized::NotifyCollectionChangedEventArgs->new(
            'Remove', TEST_NEW_ITEMS, 0, TEST_OLD_ITEMS, 0
        );
    };
    like($@, qr/ArgumentException.*newItems must be null for Remove/, 'Remove with new items throws exception');
}

sub test_replace_action_validation {
    # Test 18: Replace action with null new items should throw
    eval {
        System::Collections::Specialized::NotifyCollectionChangedEventArgs->new(
            'Replace', undef, 0, TEST_OLD_ITEMS, 0
        );
    };
    like($@, qr/ArgumentException.*newItems cannot be null for Replace/, 'Replace with null new items throws exception');
    
    # Test 19: Replace action with null old items should throw
    eval {
        System::Collections::Specialized::NotifyCollectionChangedEventArgs->new(
            'Replace', TEST_NEW_ITEMS, 0, undef, 0
        );
    };
    like($@, qr/ArgumentException.*oldItems cannot be null for Replace/, 'Replace with null old items throws exception');
    
    # Test 20: Replace action with negative starting index should throw
    eval {
        System::Collections::Specialized::NotifyCollectionChangedEventArgs->new(
            'Replace', TEST_NEW_ITEMS, -1, TEST_OLD_ITEMS, -1
        );
    };
    like($@, qr/ArgumentException.*startingIndex must be >= 0 for Replace/, 'Replace with negative index throws exception');
    
    # Test 21: Replace action with mismatched indices should throw
    eval {
        System::Collections::Specialized::NotifyCollectionChangedEventArgs->new(
            'Replace', TEST_NEW_ITEMS, 5, TEST_OLD_ITEMS, 6
        );
    };
    like($@, qr/ArgumentException.*oldStartingIndex must equal newStartingIndex for Replace/, 'Replace with mismatched indices throws exception');
}

sub test_move_action_validation {
    # Test 22: Move action with null items should throw
    eval {
        System::Collections::Specialized::NotifyCollectionChangedEventArgs->new(
            'Move', undef, 5, undef, 6
        );
    };
    like($@, qr/ArgumentException.*changedItems cannot be null for Move/, 'Move with null items throws exception');
    
    # Test 23: Move action with negative new index should throw
    eval {
        System::Collections::Specialized::NotifyCollectionChangedEventArgs->new(
            'Move', TEST_ITEMS, -1, TEST_ITEMS, 5
        );
    };
    like($@, qr/ArgumentException.*newStartingIndex must be >= 0 for Move/, 'Move with negative new index throws exception');
    
    # Test 24: Move action with negative old index should throw
    eval {
        System::Collections::Specialized::NotifyCollectionChangedEventArgs->new(
            'Move', TEST_ITEMS, 5, TEST_ITEMS, -1
        );
    };
    like($@, qr/ArgumentException.*oldStartingIndex must be >= 0 for Move/, 'Move with negative old index throws exception');
    
    # Test 25: Move action with same indices should throw
    eval {
        System::Collections::Specialized::NotifyCollectionChangedEventArgs->new(
            'Move', TEST_ITEMS, 5, TEST_ITEMS, 5
        );
    };
    like($@, qr/ArgumentException.*newStartingIndex cannot equal oldStartingIndex for Move/, 'Move with same indices throws exception');
}

sub test_reset_action_validation {
    # Test 26: Reset action with new items should throw
    eval {
        System::Collections::Specialized::NotifyCollectionChangedEventArgs->new(
            'Reset', TEST_NEW_ITEMS, -1, undef, -1
        );
    };
    like($@, qr/ArgumentException.*newItems must be null for Reset/, 'Reset with new items throws exception');
    
    # Test 27: Reset action with old items should throw
    eval {
        System::Collections::Specialized::NotifyCollectionChangedEventArgs->new(
            'Reset', undef, -1, TEST_OLD_ITEMS, -1
        );
    };
    like($@, qr/ArgumentException.*oldItems must be null for Reset/, 'Reset with old items throws exception');
}

#===========================================
# EDGE CASE TESTS
#===========================================

sub test_empty_arrays {
    # Test 28: Add with empty array
    my $empty_add = System::Collections::Specialized::NotifyCollectionChangedEventArgs->NewAdd([], 0);
    ok(defined $empty_add, 'Add with empty array works');
    is_deeply($empty_add->NewItems(), [], 'Empty array preserved in Add');
    
    # Test 29: Remove with empty array
    my $empty_remove = System::Collections::Specialized::NotifyCollectionChangedEventArgs->NewRemove([], 0);
    ok(defined $empty_remove, 'Remove with empty array works');
    is_deeply($empty_remove->OldItems(), [], 'Empty array preserved in Remove');
    
    # Test 30: Replace with empty arrays
    my $empty_replace = System::Collections::Specialized::NotifyCollectionChangedEventArgs->NewReplace([], [], 0);
    ok(defined $empty_replace, 'Replace with empty arrays works');
    is_deeply($empty_replace->NewItems(), [], 'Empty new items preserved in Replace');
    is_deeply($empty_replace->OldItems(), [], 'Empty old items preserved in Replace');
}

sub test_large_arrays {
    # Test 31: Large array handling
    my @large_array = map { "item_$_" } (1..1000);
    
    my $large_add = System::Collections::Specialized::NotifyCollectionChangedEventArgs->NewAdd(\@large_array, 0);
    ok(defined $large_add, 'Add with large array works');
    is(scalar(@{$large_add->NewItems()}), 1000, 'Large array size preserved');
    is($large_add->NewItems()->[0], 'item_1', 'Large array first item correct');
    is($large_add->NewItems()->[999], 'item_1000', 'Large array last item correct');
}

sub test_special_values {
    # Test 32: Arrays with undefined values
    my @mixed_array = ("normal", undef, "another", undef);
    
    my $mixed_add = System::Collections::Specialized::NotifyCollectionChangedEventArgs->NewAdd(\@mixed_array, 0);
    ok(defined $mixed_add, 'Add with mixed array (including undef) works');
    is(scalar(@{$mixed_add->NewItems()}), 4, 'Mixed array size preserved');
    is($mixed_add->NewItems()->[0], 'normal', 'Mixed array normal value preserved');
    ok(!defined $mixed_add->NewItems()->[1], 'Mixed array undef value preserved');
    
    # Test 33: Arrays with special strings
    my @special_array = ("", "string\nwith\nnewlines", "string\twith\ttabs", "string with spaces");
    
    my $special_add = System::Collections::Specialized::NotifyCollectionChangedEventArgs->NewAdd(\@special_array, 0);
    ok(defined $special_add, 'Add with special string array works');
    is($special_add->NewItems()->[0], '', 'Empty string preserved');
    is($special_add->NewItems()->[1], "string\nwith\nnewlines", 'String with newlines preserved');
    is($special_add->NewItems()->[2], "string\twith\ttabs", 'String with tabs preserved');
    is($special_add->NewItems()->[3], "string with spaces", 'String with spaces preserved');
}

#===========================================
# INDEX BOUNDARY TESTS
#===========================================

sub test_index_boundaries {
    # Test 34: Zero index (valid)
    my $zero_index = System::Collections::Specialized::NotifyCollectionChangedEventArgs->NewAdd(TEST_ITEMS, 0);
    is($zero_index->NewStartingIndex(), 0, 'Zero index is valid');
    
    # Test 35: Large positive index (valid)
    my $large_index = 999999;
    my $large_index_args = System::Collections::Specialized::NotifyCollectionChangedEventArgs->NewAdd(TEST_ITEMS, $large_index);
    is($large_index_args->NewStartingIndex(), $large_index, 'Large positive index is valid');
    
    # Test 36: Default indices for actions that don't use them
    my $reset_indices = System::Collections::Specialized::NotifyCollectionChangedEventArgs->NewReset();
    is($reset_indices->NewStartingIndex(), -1, 'Reset has -1 new starting index by default');
    is($reset_indices->OldStartingIndex(), -1, 'Reset has -1 old starting index by default');
}

#===========================================
# IMMUTABILITY TESTS
#===========================================

sub test_property_immutability {
    my @original_items = @{TEST_ITEMS()};
    my $args = System::Collections::Specialized::NotifyCollectionChangedEventArgs->NewAdd(\@original_items, 0);
    
    # Test 37: Modifying original array doesn't affect stored items
    push @original_items, "new_item";
    isnt(scalar(@{$args->NewItems()}), scalar(@original_items), 
         'Modifying original array does not affect stored items');
    
    # Test 38: Properties return the same values on multiple calls
    my $action1 = $args->Action();
    my $action2 = $args->Action();
    is($action1, $action2, 'Action property is consistent across calls');
    
    my $items1 = $args->NewItems();
    my $items2 = $args->NewItems();
    is_deeply($items1, $items2, 'NewItems property is consistent across calls');
    
    my $index1 = $args->NewStartingIndex();
    my $index2 = $args->NewStartingIndex();
    is($index1, $index2, 'NewStartingIndex property is consistent across calls');
}

#===========================================
# INTEGRATION TESTS
#===========================================

sub test_event_args_usage_pattern {
    # Test 39: Typical event handler usage pattern
    my $args = System::Collections::Specialized::NotifyCollectionChangedEventArgs->NewAdd(["test_item"], 2);
    
    # Simulate typical event handler code
    my $handler_result = eval {
        my $action = $args->Action();
        
        if ($action eq 'Add') {
            my $items = $args->NewItems();
            my $index = $args->NewStartingIndex();
            
            return {
                action => $action,
                item_count => scalar(@$items),
                first_item => $items->[0],
                index => $index
            };
        }
        
        return undef;
    };
    
    ok(!$@, 'Typical event handler pattern executes without error');
    ok(defined $handler_result, 'Event handler returns result');
    is($handler_result->{action}, 'Add', 'Handler correctly reads action');
    is($handler_result->{item_count}, 1, 'Handler correctly counts items');
    is($handler_result->{first_item}, 'test_item', 'Handler correctly reads item');
    is($handler_result->{index}, 2, 'Handler correctly reads index');
}

sub test_all_actions_comprehensive {
    # Test 40: Comprehensive test of all action types
    my @test_cases = (
        {
            factory => sub { System::Collections::Specialized::NotifyCollectionChangedEventArgs->NewAdd(["add_item"], 1) },
            expected_action => 'Add',
            description => 'Add action comprehensive test'
        },
        {
            factory => sub { System::Collections::Specialized::NotifyCollectionChangedEventArgs->NewRemove(["remove_item"], 2) },
            expected_action => 'Remove',
            description => 'Remove action comprehensive test'
        },
        {
            factory => sub { System::Collections::Specialized::NotifyCollectionChangedEventArgs->NewReplace(["new_item"], ["old_item"], 3) },
            expected_action => 'Replace',
            description => 'Replace action comprehensive test'
        },
        {
            factory => sub { System::Collections::Specialized::NotifyCollectionChangedEventArgs->NewMove(["move_item"], 5, 4) },
            expected_action => 'Move',
            description => 'Move action comprehensive test'
        },
        {
            factory => sub { System::Collections::Specialized::NotifyCollectionChangedEventArgs->NewReset() },
            expected_action => 'Reset',
            description => 'Reset action comprehensive test'
        }
    );
    
    for my $test_case (@test_cases) {
        my $args = $test_case->{factory}->();
        ok(defined $args, $test_case->{description} . ': object created');
        is($args->Action(), $test_case->{expected_action}, $test_case->{description} . ': correct action');
        isa_ok($args, 'System::Collections::Specialized::NotifyCollectionChangedEventArgs', 
               $test_case->{description} . ': correct type');
    }
}

# Run all tests
test_basic_constructor();
test_constructor_parameter_validation();
test_new_add_constructor();
test_new_remove_constructor();
test_new_replace_constructor();
test_new_move_constructor();
test_new_reset_constructor();
test_property_access();
test_null_reference_protection();
test_add_action_validation();
test_remove_action_validation();
test_replace_action_validation();
test_move_action_validation();
test_reset_action_validation();
test_empty_arrays();
test_large_arrays();
test_special_values();
test_index_boundaries();
test_property_immutability();
test_event_args_usage_pattern();
test_all_actions_comprehensive();

done_testing();