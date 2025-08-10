#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use lib '.';

# Import required modules
use System::Delegate;
use System::Exceptions;

# Test new() - Happy path
sub test_new_happy {
    # Test with target and method name
    my $target = bless {}, 'TestClass';
    my $delegate = System::Delegate->new($target, 'test_method');
    ok(defined($delegate), "new() creates delegate with target and method");
    is($delegate->Target(), $target, "Target property returns correct target");
    is($delegate->Method(), 'test_method', "Method property returns correct method");
}

# Test new() - Code reference
sub test_new_code_reference {
    my $code_ref = sub { return "hello" };
    my $delegate = System::Delegate->new(undef, $code_ref);
    ok(defined($delegate), "new() creates delegate with code reference");
    is($delegate->Target(), undef, "Target is undef for code reference");
    is($delegate->Method(), $code_ref, "Method returns code reference");
}

# Test new() - Exception handling
sub test_new_exceptions {
    # Test invalid argument combinations
    eval {
        System::Delegate->new("target", undef);
    };
    ok($@ =~ /ArgumentException/, "new() throws ArgumentException for target without method");
    
    eval {
        System::Delegate->new(undef, "method");
    };
    ok($@ =~ /ArgumentException/, "new() throws ArgumentException for method without target (non-code)");
}

# Test Target property - Exception handling
sub test_target_exceptions {
    eval {
        System::Delegate::Target(undef);
    };
    ok($@ =~ /NullReferenceException/, "Target() throws NullReferenceException on undef");
}

# Test Method property - Exception handling
sub test_method_exceptions {
    eval {
        System::Delegate::Method(undef);
    };
    ok($@ =~ /NullReferenceException/, "Method() throws NullReferenceException on undef");
}

# Test Invoke() - Code reference
sub test_invoke_code_reference {
    my $code_ref = sub { my $arg = shift; return "result: $arg" };
    my $delegate = System::Delegate->new(undef, $code_ref);
    
    my $result = $delegate->Invoke("test");
    is($result, "result: test", "Invoke() works with code reference");
}

# Test Invoke() - Exception handling
sub test_invoke_exceptions {
    eval {
        System::Delegate::Invoke(undef, "arg");
    };
    ok($@ =~ /NullReferenceException/, "Invoke() throws NullReferenceException on undef");
}

# Test Combine() - Static method
sub test_combine_static {
    my $code1 = sub { return "first" };
    my $code2 = sub { return "second" };
    my $delegate1 = System::Delegate->new(undef, $code1);
    my $delegate2 = System::Delegate->new(undef, $code2);
    
    my $combined = System::Delegate->Combine($delegate1, $delegate2);
    ok(defined($combined), "Combine() creates combined delegate");
    isa_ok($combined, 'System::Delegate', "Combined result is System::Delegate");
}

# Test Combine() - With undef parameters
sub test_combine_with_undef {
    my $code1 = sub { return "first" };
    my $delegate1 = System::Delegate->new(undef, $code1);
    
    my $result1 = System::Delegate->Combine(undef, $delegate1);
    is($result1, $delegate1, "Combine() returns second delegate when first is undef");
    
    my $result2 = System::Delegate->Combine($delegate1, undef);
    is($result2, $delegate1, "Combine() returns first delegate when second is undef");
}

# Test Combine() - Exception handling
sub test_combine_exceptions {
    my $delegate = System::Delegate->new(undef, sub { });
    
    eval {
        System::Delegate->Combine("not_a_delegate", $delegate);
    };
    ok($@ =~ /ArgumentException/, "Combine() throws ArgumentException for non-delegate first arg");
    
    eval {
        System::Delegate->Combine($delegate, "not_a_delegate");
    };
    ok($@ =~ /ArgumentException/, "Combine() throws ArgumentException for non-delegate second arg");
}

# Test Remove() - Static method
sub test_remove_static {
    my $code1 = sub { return "first" };
    my $code2 = sub { return "second" };
    my $delegate1 = System::Delegate->new(undef, $code1);
    my $delegate2 = System::Delegate->new(undef, $code2);
    
    my $combined = System::Delegate->Combine($delegate1, $delegate2);
    my $removed = System::Delegate->Remove($combined, $delegate2);
    
    ok(defined($removed), "Remove() returns result");
}

# Test Remove() - With undef parameters
sub test_remove_with_undef {
    my $delegate = System::Delegate->new(undef, sub { });
    
    my $result1 = System::Delegate->Remove(undef, $delegate);
    is($result1, undef, "Remove() returns undef when source is undef");
    
    my $result2 = System::Delegate->Remove($delegate, undef);
    is($result2, $delegate, "Remove() returns source when value is undef");
}

# Test Remove() - Exception handling
sub test_remove_exceptions {
    my $delegate = System::Delegate->new(undef, sub { });
    
    eval {
        System::Delegate->Remove("not_a_delegate", $delegate);
    };
    ok($@ =~ /ArgumentException/, "Remove() throws ArgumentException for non-delegate source");
    
    eval {
        System::Delegate->Remove($delegate, "not_a_delegate");
    };
    ok($@ =~ /ArgumentException/, "Remove() throws ArgumentException for non-delegate value");
}

# Test Equals() method
sub test_equals_method {
    my $code_ref = sub { return "test" };
    my $delegate1 = System::Delegate->new(undef, $code_ref);
    my $delegate2 = System::Delegate->new(undef, $code_ref);
    
    ok($delegate1->Equals($delegate2), "Equals() returns true for delegates with same code ref");
    
    my $other_code = sub { return "other" };
    my $delegate3 = System::Delegate->new(undef, $other_code);
    ok(!$delegate1->Equals($delegate3), "Equals() returns false for delegates with different code ref");
}

# Test Equals() - Exception handling
sub test_equals_exceptions {
    eval {
        System::Delegate::Equals(undef, bless {}, 'System::Delegate');
    };
    ok($@ =~ /NullReferenceException/, "Equals() throws NullReferenceException on undef this");
}

# Test GetHashCode() method
sub test_gethashcode_method {
    my $code_ref = sub { return "test" };
    my $delegate = System::Delegate->new(undef, $code_ref);
    
    my $hash = $delegate->GetHashCode();
    ok(defined($hash), "GetHashCode() returns defined value");
    ok($hash =~ /^\d+$/, "GetHashCode() returns numeric value");
}

# Test GetHashCode() - Exception handling
sub test_gethashcode_exceptions {
    eval {
        System::Delegate::GetHashCode(undef);
    };
    ok($@ =~ /NullReferenceException/, "GetHashCode() throws NullReferenceException on undef");
}

# Test multicast delegate invocation
sub test_multicast_invocation {
    my $results = [];
    my $code1 = sub { push @$results, "first"; return "first" };
    my $code2 = sub { push @$results, "second"; return "second" };
    
    my $delegate1 = System::Delegate->new(undef, $code1);
    my $delegate2 = System::Delegate->new(undef, $code2);
    
    my $combined = System::Delegate->Combine($delegate1, $delegate2);
    my @invoke_results = $combined->Invoke();
    
    is_deeply($results, ["first", "second"], "Multicast delegate invokes all delegates");
    is($invoke_results[-1], "second", "Multicast delegate returns last result in scalar context");
}

# Test edge cases
sub test_edge_cases {
    # Test empty multicast delegate after all removed
    my $delegate1 = System::Delegate->new(undef, sub { return "test" });
    my $combined = System::Delegate->Combine($delegate1, $delegate1);
    my $removed_all = System::Delegate->Remove($combined, $delegate1);
    
    ok(defined($removed_all), "Remove() handles removing from multicast delegate");
}

# Run all tests
sub run_tests {
    test_new_happy();
    test_new_code_reference();
    test_new_exceptions();
    test_target_exceptions();
    test_method_exceptions();
    test_invoke_code_reference();
    test_invoke_exceptions();
    test_combine_static();
    test_combine_with_undef();
    test_combine_exceptions();
    test_remove_static();
    test_remove_with_undef();
    test_remove_exceptions();
    test_equals_method();
    test_equals_exceptions();
    test_gethashcode_method();
    test_gethashcode_exceptions();
    test_multicast_invocation();
    test_edge_cases();
}

# Execute tests
run_tests();

done_testing();