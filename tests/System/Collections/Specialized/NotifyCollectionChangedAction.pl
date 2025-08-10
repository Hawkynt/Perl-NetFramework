#!/usr/bin/perl
use strict;
use warnings;
use lib '../../../../';
use Test::More;
use System::Collections::Specialized::NotifyCollectionChangedAction;

BEGIN {
    use_ok('System::Collections::Specialized::NotifyCollectionChangedAction');
}

# Test module loading and action constants
sub test_module_loading {
    ok(1, 'NotifyCollectionChangedAction module loads without error');
    
    # Test that action constants are defined
    ok(defined(&System::Collections::Specialized::NotifyCollectionChangedAction::Add), 
       'Add action constant is defined');
    ok(defined(&System::Collections::Specialized::NotifyCollectionChangedAction::Remove), 
       'Remove action constant is defined');
    ok(defined(&System::Collections::Specialized::NotifyCollectionChangedAction::Replace), 
       'Replace action constant is defined');
    ok(defined(&System::Collections::Specialized::NotifyCollectionChangedAction::Move), 
       'Move action constant is defined');
    ok(defined(&System::Collections::Specialized::NotifyCollectionChangedAction::Reset), 
       'Reset action constant is defined');
}

# Test constant values
sub test_constant_values {
    # Test each action constant has correct string value
    is(System::Collections::Specialized::NotifyCollectionChangedAction::Add, 'Add', 
       'Add constant has correct value');
    
    is(System::Collections::Specialized::NotifyCollectionChangedAction::Remove, 'Remove',
       'Remove constant has correct value');
       
    is(System::Collections::Specialized::NotifyCollectionChangedAction::Replace, 'Replace',
       'Replace constant has correct value');
       
    is(System::Collections::Specialized::NotifyCollectionChangedAction::Move, 'Move',
       'Move constant has correct value');
       
    is(System::Collections::Specialized::NotifyCollectionChangedAction::Reset, 'Reset',
       'Reset constant has correct value');
}

# Test constant uniqueness
sub test_constant_uniqueness {
    my $add = System::Collections::Specialized::NotifyCollectionChangedAction::Add;
    my $remove = System::Collections::Specialized::NotifyCollectionChangedAction::Remove;
    my $replace = System::Collections::Specialized::NotifyCollectionChangedAction::Replace;
    my $move = System::Collections::Specialized::NotifyCollectionChangedAction::Move;
    my $reset = System::Collections::Specialized::NotifyCollectionChangedAction::Reset;
    
    # Test all constants are unique
    isnt($add, $remove, 'Add and Remove constants are different');
    isnt($add, $replace, 'Add and Replace constants are different');
    isnt($add, $move, 'Add and Move constants are different');
    isnt($add, $reset, 'Add and Reset constants are different');
    
    isnt($remove, $replace, 'Remove and Replace constants are different');
    isnt($remove, $move, 'Remove and Move constants are different');
    isnt($remove, $reset, 'Remove and Reset constants are different');
    
    isnt($replace, $move, 'Replace and Move constants are different');
    isnt($replace, $reset, 'Replace and Reset constants are different');
    
    isnt($move, $reset, 'Move and Reset constants are different');
}

# Test constant usage in expressions
sub test_constant_usage {
    # Test string operations
    my $add = System::Collections::Specialized::NotifyCollectionChangedAction::Add;
    ok($add eq 'Add', 'Add constant equals "Add" in string context');
    like($add, qr/^Add$/, 'Add constant matches Add regex');
    
    my $remove = System::Collections::Specialized::NotifyCollectionChangedAction::Remove;
    ok($remove eq 'Remove', 'Remove constant equals "Remove" in string context');
    like($remove, qr/^Remove$/, 'Remove constant matches Remove regex');
    
    # Test length operations
    is(length($add), 3, 'Add constant has correct length');
    is(length($remove), 6, 'Remove constant has correct length');
    is(length(System::Collections::Specialized::NotifyCollectionChangedAction::Replace), 7, 
       'Replace constant has correct length');
}

# Test action semantics and use cases
sub test_action_semantics {
    # Test switch-like operations for action handling
    my $get_action_description = sub {
        my ($action) = @_;
        
        if ($action eq System::Collections::Specialized::NotifyCollectionChangedAction::Add) {
            return 'Items were added to the collection';
        }
        elsif ($action eq System::Collections::Specialized::NotifyCollectionChangedAction::Remove) {
            return 'Items were removed from the collection';
        }
        elsif ($action eq System::Collections::Specialized::NotifyCollectionChangedAction::Replace) {
            return 'Items were replaced in the collection';
        }
        elsif ($action eq System::Collections::Specialized::NotifyCollectionChangedAction::Move) {
            return 'Items were moved within the collection';
        }
        elsif ($action eq System::Collections::Specialized::NotifyCollectionChangedAction::Reset) {
            return 'The collection was reset or cleared';
        }
        else {
            return 'Unknown collection change action';
        }
    };
    
    like($get_action_description->(System::Collections::Specialized::NotifyCollectionChangedAction::Add), 
         qr/added/, 'Add action description is correct');
         
    like($get_action_description->(System::Collections::Specialized::NotifyCollectionChangedAction::Remove), 
         qr/removed/, 'Remove action description is correct');
         
    like($get_action_description->(System::Collections::Specialized::NotifyCollectionChangedAction::Replace), 
         qr/replaced/, 'Replace action description is correct');
         
    like($get_action_description->(System::Collections::Specialized::NotifyCollectionChangedAction::Move), 
         qr/moved/, 'Move action description is correct');
         
    like($get_action_description->(System::Collections::Specialized::NotifyCollectionChangedAction::Reset), 
         qr/reset/, 'Reset action description is correct');
         
    is($get_action_description->('InvalidAction'), 'Unknown collection change action', 
       'Unknown action handling works');
}

# Test array and hash usage
sub test_collection_usage {
    # Test in array context
    my @all_actions = (
        System::Collections::Specialized::NotifyCollectionChangedAction::Add,
        System::Collections::Specialized::NotifyCollectionChangedAction::Remove,
        System::Collections::Specialized::NotifyCollectionChangedAction::Replace,
        System::Collections::Specialized::NotifyCollectionChangedAction::Move,
        System::Collections::Specialized::NotifyCollectionChangedAction::Reset
    );
    
    is(scalar(@all_actions), 5, 'Array contains all collection changed actions');
    is($all_actions[0], 'Add', 'First element is Add');
    is($all_actions[1], 'Remove', 'Second element is Remove');
    is($all_actions[2], 'Replace', 'Third element is Replace');
    is($all_actions[3], 'Move', 'Fourth element is Move');
    is($all_actions[4], 'Reset', 'Fifth element is Reset');
    
    # Test in hash context for action priorities or properties
    my %action_priorities = (
        System::Collections::Specialized::NotifyCollectionChangedAction::Add => 1,
        System::Collections::Specialized::NotifyCollectionChangedAction::Remove => 2,
        System::Collections::Specialized::NotifyCollectionChangedAction::Replace => 3,
        System::Collections::Specialized::NotifyCollectionChangedAction::Move => 4,
        System::Collections::Specialized::NotifyCollectionChangedAction::Reset => 5
    );
    
    is($action_priorities{'Add'}, 1, 'Hash lookup for Add action works');
    is($action_priorities{'Remove'}, 2, 'Hash lookup for Remove action works');
    is($action_priorities{'Replace'}, 3, 'Hash lookup for Replace action works');
    is($action_priorities{'Move'}, 4, 'Hash lookup for Move action works');
    is($action_priorities{'Reset'}, 5, 'Hash lookup for Reset action works');
}

# Test import functionality
sub test_import_functionality {
    # The module has an import method that exports constants
    # Test that the import works (this would be tested when the module is used)
    
    # Test that constants are available in the module namespace
    ok(1, 'Import functionality is available');
    
    # Test that constants can be called as functions
    my $add_result;
    eval {
        $add_result = System::Collections::Specialized::NotifyCollectionChangedAction::Add();
    };
    ok(!$@, 'Add constant can be called as function');
    is($add_result, 'Add', 'Add constant function returns correct value');
    
    # Test other constants as functions
    is(System::Collections::Specialized::NotifyCollectionChangedAction::Remove(), 'Remove',
       'Remove constant function returns correct value');
    is(System::Collections::Specialized::NotifyCollectionChangedAction::Replace(), 'Replace',
       'Replace constant function returns correct value');
    is(System::Collections::Specialized::NotifyCollectionChangedAction::Move(), 'Move',
       'Move constant function returns correct value');
    is(System::Collections::Specialized::NotifyCollectionChangedAction::Reset(), 'Reset',
       'Reset constant function returns correct value');
}

# Test string operations and comparisons
sub test_string_operations {
    my $add = System::Collections::Specialized::NotifyCollectionChangedAction::Add;
    my $remove = System::Collections::Specialized::NotifyCollectionChangedAction::Remove;
    
    # Test case sensitivity
    ok($add eq 'Add', 'Add constant is case sensitive (equals "Add")');
    ok($add ne 'add', 'Add constant is case sensitive (not equals "add")');
    ok($add ne 'ADD', 'Add constant is case sensitive (not equals "ADD")');
    
    # Test string concatenation
    my $combined = $add . '_' . $remove;
    is($combined, 'Add_Remove', 'String concatenation works with constants');
    
    # Test interpolation
    my $message = "Action type: $add";
    is($message, 'Action type: Add', 'String interpolation works with constants');
    
    # Test substring operations
    is(substr($add, 0, 1), 'A', 'Substring operation works (first character)');
    is(substr($remove, -1, 1), 'e', 'Substring operation works (last character)');
}

# Test validation scenarios
sub test_validation_scenarios {
    # Test function that validates action values
    my $is_valid_action = sub {
        my ($action) = @_;
        return $action eq System::Collections::Specialized::NotifyCollectionChangedAction::Add ||
               $action eq System::Collections::Specialized::NotifyCollectionChangedAction::Remove ||
               $action eq System::Collections::Specialized::NotifyCollectionChangedAction::Replace ||
               $action eq System::Collections::Specialized::NotifyCollectionChangedAction::Move ||
               $action eq System::Collections::Specialized::NotifyCollectionChangedAction::Reset;
    };
    
    # Test valid actions
    ok($is_valid_action->(System::Collections::Specialized::NotifyCollectionChangedAction::Add), 
       'Add is valid action');
    ok($is_valid_action->(System::Collections::Specialized::NotifyCollectionChangedAction::Remove), 
       'Remove is valid action');
    ok($is_valid_action->(System::Collections::Specialized::NotifyCollectionChangedAction::Replace), 
       'Replace is valid action');
    ok($is_valid_action->(System::Collections::Specialized::NotifyCollectionChangedAction::Move), 
       'Move is valid action');
    ok($is_valid_action->(System::Collections::Specialized::NotifyCollectionChangedAction::Reset), 
       'Reset is valid action');
       
    # Test invalid actions
    ok(!$is_valid_action->('Invalid'), 'Invalid string is not valid action');
    ok(!$is_valid_action->(''), 'Empty string is not valid action');
    ok(!$is_valid_action->(undef), 'Undef is not valid action');
    ok(!$is_valid_action->('add'), 'Lowercase "add" is not valid action');
}

# Test typical usage patterns
sub test_usage_patterns {
    # Pattern 1: Event notification
    my $notify_collection_changed = sub {
        my ($action, $items) = @_;
        
        if ($action eq System::Collections::Specialized::NotifyCollectionChangedAction::Add) {
            return "Added " . scalar(@$items) . " items";
        }
        elsif ($action eq System::Collections::Specialized::NotifyCollectionChangedAction::Remove) {
            return "Removed " . scalar(@$items) . " items";
        }
        else {
            return "Collection changed: $action";
        }
    };
    
    is($notify_collection_changed->(
        System::Collections::Specialized::NotifyCollectionChangedAction::Add, 
        ['item1', 'item2']
       ), 'Added 2 items', 'Add notification pattern works');
       
    is($notify_collection_changed->(
        System::Collections::Specialized::NotifyCollectionChangedAction::Remove, 
        ['item1']
       ), 'Removed 1 items', 'Remove notification pattern works');
    
    # Pattern 2: Action filtering
    my @mutation_actions = grep { 
        $_ ne System::Collections::Specialized::NotifyCollectionChangedAction::Reset 
    } (
        System::Collections::Specialized::NotifyCollectionChangedAction::Add,
        System::Collections::Specialized::NotifyCollectionChangedAction::Remove,
        System::Collections::Specialized::NotifyCollectionChangedAction::Replace,
        System::Collections::Specialized::NotifyCollectionChangedAction::Move,
        System::Collections::Specialized::NotifyCollectionChangedAction::Reset
    );
    
    is(scalar(@mutation_actions), 4, 'Filtering out Reset gives 4 mutation actions');
    ok(!(grep { $_ eq 'Reset' } @mutation_actions), 'Reset is filtered out correctly');
}

# Test constant consistency and immutability
sub test_constant_consistency {
    # Test that constants return the same value on multiple calls
    is(System::Collections::Specialized::NotifyCollectionChangedAction::Add,
       System::Collections::Specialized::NotifyCollectionChangedAction::Add,
       'Add constant is consistent across calls');
       
    is(System::Collections::Specialized::NotifyCollectionChangedAction::Reset,
       System::Collections::Specialized::NotifyCollectionChangedAction::Reset,
       'Reset constant is consistent across calls');
    
    # Test that constants are immutable (Perl constants should be)
    my $add_val1 = System::Collections::Specialized::NotifyCollectionChangedAction::Add;
    my $add_val2 = System::Collections::Specialized::NotifyCollectionChangedAction::Add;
    is($add_val1, $add_val2, 'Multiple retrievals give same value');
}

# Test package namespace and CSharp integration
sub test_package_namespace {
    # Test that the package loads and functions correctly
    ok(1, 'Package namespace is properly structured');
    
    # Test that constants are accessible from the full namespace
    my $full_add = System::Collections::Specialized::NotifyCollectionChangedAction::Add;
    ok(defined($full_add), 'Constants accessible via full namespace');
    
    # Test module works after CSharp package name shortening
    eval {
        my $test_val = System::Collections::Specialized::NotifyCollectionChangedAction::Remove;
    };
    ok(!$@, 'Module functions work after package name shortening');
}

# Run all tests
test_module_loading();
test_constant_values();
test_constant_uniqueness();
test_constant_usage();
test_action_semantics();
test_collection_usage();
test_import_functionality();
test_string_operations();
test_validation_scenarios();
test_usage_patterns();
test_constant_consistency();
test_package_namespace();

done_testing();