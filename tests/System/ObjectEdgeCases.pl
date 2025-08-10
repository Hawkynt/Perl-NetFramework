#!/usr/bin/perl
use strict;
use warnings;
use lib '../../';
use Test::More;
use System;
use System::Object;
use System::String;
use System::Array;
use Encode qw(encode decode);

BEGIN {
    use_ok('System::Object');
}

# Test comprehensive edge cases for System::Object
sub test_object_construction_edge_cases {
    # Test with various blessing scenarios
    my $obj1 = System::Object->new();
    my $obj2 = System::Object::new('System::Object');
    my $obj3 = System::Object::new(__PACKAGE__);
    
    isa_ok($obj1, 'System::Object', 'Standard constructor');
    isa_ok($obj2, 'System::Object', 'Static call constructor');
    isa_ok($obj3, 'System::Object', 'Package constructor');
    
    # Test constructor with empty class string
    eval {
        my $obj = System::Object::new('');
    };
    ok(!$@, 'Empty class name handled gracefully');
    
    # Test multiple consecutive constructions
    my @objects;
    for (1..1000) {
        push @objects, System::Object->new();
    }
    is(scalar(@objects), 1000, 'Mass object creation successful');
    
    # Verify each object is unique
    my %seen_addrs;
    for my $obj (@objects[0..99]) {  # Test first 100
        my $addr = sprintf("%x", $obj);
        ok(!exists $seen_addrs{$addr}, 'Object has unique address');
        $seen_addrs{$addr} = 1;
    }
}

sub test_toString_edge_cases {
    # Test ToString with various object states
    my $obj = System::Object->new();
    
    # Test consistency under stress
    my $str1 = $obj->ToString();
    for (1..100) {
        is($obj->ToString(), $str1, "ToString consistent on iteration $_") if $_ <= 3;
    }
    
    # Test ToString with modified object structure
    my $modified_obj = bless {}, 'System::Object';
    my $mod_str = $modified_obj->ToString();
    like($mod_str, qr/System::Object/, 'ToString works with minimal object');
    
    # Test ToString with corrupted object (but valid ref)
    my $weird_obj = bless { random_data => 'should_not_interfere' }, 'System::Object';
    my $weird_str = $weird_obj->ToString();
    like($weird_str, qr/System::Object/, 'ToString ignores extra data');
    
    # Test ToString with very deeply nested inheritance
    eval q{
        package TestDeep::Level1::Level2::Level3;
        use base 'System::Object';
        sub new { bless {}, shift; }
    };
    my $deep = TestDeep::Level1::Level2::Level3->new();
    my $deep_str = $deep->ToString();
    like($deep_str, qr/TestDeep::Level1::Level2::Level3/, 'ToString works with deep inheritance');
    
    # Test with null/undef edge cases
    eval { my $result = System::Object::ToString(undef); };
    ok($@, 'ToString properly throws with undef');
    like($@, qr/NullReferenceException/, 'Correct exception type for undef');
}

sub test_getHashCode_edge_cases {
    # Test hash code distribution and consistency
    my @objects;
    my %hash_counts;
    
    # Create many objects and check hash distribution
    for (1..1000) {
        my $obj = System::Object->new();
        push @objects, $obj;
        my $hash = $obj->GetHashCode();
        $hash_counts{$hash}++;
    }
    
    # Verify reasonable distribution (no single hash dominates)
    my $max_count = (sort { $b <=> $a } values %hash_counts)[0];
    ok($max_count < 100, 'Hash codes reasonably distributed');
    
    # Test hash code bounds
    for my $obj (@objects[0..99]) {
        my $hash = $obj->GetHashCode();
        ok($hash >= 0, 'Hash code non-negative');
        ok($hash <= 2**32, 'Hash code within reasonable bounds');
        ok($hash =~ /^\d+$/, 'Hash code is integer');
    }
    
    # Test hash code with undef
    is(System::Object::GetHashCode(undef), 0, 'Undef hash code is 0');
    
    # Test hash code consistency across method calls
    my $test_obj = System::Object->new();
    my $initial_hash = $test_obj->GetHashCode();
    
    # Call other methods, hash should remain consistent
    $test_obj->ToString();
    $test_obj->GetType();
    $test_obj->Equals($test_obj);
    is($test_obj->GetHashCode(), $initial_hash, 'Hash remains consistent after other method calls');
    
    # Test with inherited objects
    my $str_obj = System::String->new('test');
    my $str_hash1 = $str_obj->GetHashCode();
    my $str_hash2 = $str_obj->GetHashCode();
    is($str_hash1, $str_hash2, 'String object hash consistency');
    
    # Different string objects with same content should have same hash
    my $str_obj2 = System::String->new('test');
    is($str_obj->GetHashCode(), $str_obj2->GetHashCode(), 'Same content strings have same hash');
}

sub test_equals_extreme_edge_cases {
    # Test Equals with exotic scalar values
    ok(System::Object->Equals(0, '0'), 'Zero equals string zero');
    ok(System::Object->Equals('', '0'), 'Empty string equals string zero');
    ok(System::Object->Equals(0, ''), 'Zero equals empty string');
    ok(System::Object->Equals('0.0', 0), 'String 0.0 equals zero');
    ok(System::Object->Equals(0.0, 0), 'Float 0.0 equals int 0');
    
    # Test with very large numbers
    my $big1 = 999999999999999999999;
    my $big2 = 999999999999999999999;
    ok(System::Object->Equals($big1, $big2), 'Very large numbers equal');
    
    # Test with infinity and special float values
    my $inf = 9**9**9;  # Generate infinity
    my $inf2 = 9**9**9; # Another infinity
    ok(System::Object->Equals($inf, $inf2), 'Infinity equals infinity');
    
    my $neg_inf = -9**9**9;
    ok(!System::Object->Equals($inf, $neg_inf), 'Positive and negative infinity not equal');
    
    # Test with NaN-like behavior
    my $nan1 = sqrt(-1);  # This creates complex number in Perl
    my $nan2 = sqrt(-1);
    # In Perl, complex numbers stringify differently, test this behavior
    is(System::Object->Equals($nan1, $nan2), ($nan1 eq $nan2), 'NaN-like values compared correctly');
    
    # Test with very long strings
    my $long1 = 'x' x 100000;
    my $long2 = 'x' x 100000;
    my $long3 = 'y' x 100000;
    ok(System::Object->Equals($long1, $long2), 'Very long identical strings equal');
    ok(!System::Object->Equals($long1, $long3), 'Very long different strings not equal');
    
    # Test with unicode strings
    my $unicode1 = "Hello \x{1F600} World";  # Emoji
    my $unicode2 = "Hello \x{1F600} World";
    my $unicode3 = "Hello \x{1F601} World";  # Different emoji
    ok(System::Object->Equals($unicode1, $unicode2), 'Unicode strings equal');
    ok(!System::Object->Equals($unicode1, $unicode3), 'Different unicode strings not equal');
    
    # Test with null bytes and special characters
    my $null_byte1 = "Hello\x00World";
    my $null_byte2 = "Hello\x00World";
    ok(System::Object->Equals($null_byte1, $null_byte2), 'Strings with null bytes equal');
    
    # Test with mixed references and scalars
    my $obj1 = System::Object->new();
    ok(!System::Object->Equals($obj1, 'string'), 'Object not equal to string');
    ok(!System::Object->Equals('string', $obj1), 'String not equal to object');
    ok(!System::Object->Equals($obj1, 42), 'Object not equal to number');
    
    # Test with array refs and hash refs
    my $arr_ref = [1, 2, 3];
    my $hash_ref = {a => 1, b => 2};
    ok(!System::Object->Equals($arr_ref, $hash_ref), 'Array ref not equal to hash ref');
    ok(System::Object->Equals($arr_ref, $arr_ref), 'Array ref equals itself');
    
    # Test preventEquatable parameter edge cases
    my $str1 = System::String->new('test');
    my $str2 = System::String->new('test');
    ok(System::Object->Equals($str1, $str2, 0), 'preventEquatable false works');
    ok(System::Object->Equals($str1, $str2, 1), 'preventEquatable true works');
    ok(System::Object->Equals($str1, $str2, ''), 'preventEquatable empty string works');
    ok(System::Object->Equals($str1, $str2, undef), 'preventEquatable undef works');
}

sub test_referenceEquals_edge_cases {
    # Test ReferenceEquals with various scenarios
    
    # Both undef should be equal
    ok(System::Object->ReferenceEquals(undef, undef), 'Both undef references equal');
    
    # Test with objects
    my $obj1 = System::Object->new();
    my $obj2 = System::Object->new();
    my $obj1_alias = $obj1;
    
    ok(System::Object->ReferenceEquals($obj1, $obj1_alias), 'Same object references equal');
    ok(!System::Object->ReferenceEquals($obj1, $obj2), 'Different objects not reference equal');
    
    # Test exception cases
    eval { System::Object->ReferenceEquals($obj1, undef); };
    ok($@, 'ReferenceEquals throws with one undef');
    like($@, qr/ArgumentException/, 'Correct exception type');
    
    eval { System::Object->ReferenceEquals(undef, $obj1); };
    ok($@, 'ReferenceEquals throws with first arg undef');
    
    eval { System::Object->ReferenceEquals(42, $obj1); };
    ok($@, 'ReferenceEquals throws with scalar first arg');
    
    eval { System::Object->ReferenceEquals($obj1, 'string'); };
    ok($@, 'ReferenceEquals throws with scalar second arg');
    
    eval { System::Object->ReferenceEquals([], {}); };
    ok($@, 'ReferenceEquals throws with non-object refs');
    
    # Test calling variations (static vs package)
    ok(System::Object::ReferenceEquals($obj1, $obj1_alias), 'Package call works');
    
    # Test with inherited objects
    my $str1 = System::String->new('test');
    my $str2 = System::String->new('test');
    my $str1_ref = $str1;
    
    ok(System::Object->ReferenceEquals($str1, $str1_ref), 'String object reference equal');
    ok(!System::Object->ReferenceEquals($str1, $str2), 'Different string objects not reference equal');
}

sub test_is_as_methods_edge_cases {
    # Test Is method with edge cases
    my $obj = System::Object->new();
    
    # Test with null
    ok(!System::Object::Is(undef, 'System::Object'), 'undef Is not System::Object');
    ok(!$obj->Is(''), 'Is with empty class name');
    ok(!$obj->Is(undef), 'Is with undef class name');
    
    # Test with scalars
    ok(!System::Object::Is(42, 'System::Object'), 'Scalar not Is object');
    ok(!System::Object::Is('string', 'System::Object'), 'String not Is object');
    ok(!System::Object::Is([], 'System::Object'), 'Array ref not Is object');
    
    # Test As method edge cases
    ok(!defined($obj->As('')), 'As empty class returns undef');
    ok(!defined($obj->As(undef)), 'As undef class returns undef');
    ok(!defined(System::Object::As(undef, 'System::Object')), 'As from undef returns undef');
    ok(!defined(System::Object::As(42, 'System::Object')), 'As from scalar returns undef');
    
    # Test with deep inheritance chains
    eval q{
        package TestAs::Parent;
        use base 'System::Object';
        
        package TestAs::Child;
        use base 'TestAs::Parent';
        
        package TestAs::GrandChild;
        use base 'TestAs::Child';
    };
    
    my $grandchild = bless {}, 'TestAs::GrandChild';
    ok($grandchild->Is('TestAs::GrandChild'), 'GrandChild Is GrandChild');
    ok($grandchild->Is('TestAs::Child'), 'GrandChild Is Child');
    ok($grandchild->Is('TestAs::Parent'), 'GrandChild Is Parent');
    ok($grandchild->Is('System::Object'), 'GrandChild Is Object');
    ok(!$grandchild->Is('System::String'), 'GrandChild not Is String');
    
    is($grandchild->As('TestAs::GrandChild'), $grandchild, 'As to same class');
    is($grandchild->As('TestAs::Child'), $grandchild, 'As to parent class');
    is($grandchild->As('System::Object'), $grandchild, 'As to base class');
    ok(!defined($grandchild->As('System::String')), 'As to unrelated class');
}

sub test_inheritance_edge_cases {
    # Test complex inheritance scenarios
    
    # Test with multiple inheritance paths
    eval q{
        package TestMultiple::Interface1;
        use base 'System::Object';
        
        package TestMultiple::Interface2;
        use base 'System::Object';
        
        package TestMultiple::Implementation;
        use base qw(TestMultiple::Interface1 TestMultiple::Interface2);
    };
    
    my $multi_obj = bless {}, 'TestMultiple::Implementation';
    ok($multi_obj->isa('TestMultiple::Interface1'), 'Multiple inheritance path 1');
    ok($multi_obj->isa('TestMultiple::Interface2'), 'Multiple inheritance path 2');
    ok($multi_obj->isa('System::Object'), 'Multiple inheritance base class');
    
    # Test method resolution
    ok(defined($multi_obj->ToString()), 'ToString works with multiple inheritance');
    ok(defined($multi_obj->GetHashCode()), 'GetHashCode works with multiple inheritance');
    
    # Test GetType with inheritance
    is($multi_obj->GetType(), 'TestMultiple::Implementation', 'GetType returns exact class');
    
    # Test with objects that override methods
    eval q{
        package TestOverride::Child;
        use base 'System::Object';
        
        sub ToString {
            return "Custom ToString";
        }
        
        sub GetHashCode {
            return 12345;
        }
    };
    
    my $override_obj = bless {}, 'TestOverride::Child';
    is($override_obj->ToString(), 'Custom ToString', 'Overridden ToString works');
    is($override_obj->GetHashCode(), 12345, 'Overridden GetHashCode works');
    is($override_obj->GetType(), 'TestOverride::Child', 'GetType still works with overrides');
}

sub test_memory_pressure_edge_cases {
    # Test behavior under memory pressure scenarios
    
    # Create and destroy many objects rapidly
    my $iterations = 10000;
    for (1..$iterations) {
        my $obj = System::Object->new();
        my $str = $obj->ToString();
        my $hash = $obj->GetHashCode();
        my $type = $obj->GetType();
        
        # Verify basic functionality still works
        ok(defined($str), "ToString works iteration $_") if $_ <= 3;
        ok($hash >= 0, "Hash valid iteration $_") if $_ <= 3;
        ok($type eq 'System::Object', "GetType correct iteration $_") if $_ <= 3;
    }
    
    # Test with many objects held in memory simultaneously
    my @held_objects;
    for (1..1000) {
        my $obj = System::Object->new();
        push @held_objects, $obj;
    }
    
    # Verify all objects still work
    for my $i (0..99) {  # Test first 100
        my $obj = $held_objects[$i];
        ok(defined($obj->ToString()), "Held object $i ToString works");
        ok($obj->GetHashCode() >= 0, "Held object $i hash works");
    }
    
    # Test circular references don't break basic functionality
    my $circular1 = System::Object->new();
    my $circular2 = System::Object->new();
    $circular1->{ref_to_2} = $circular2;
    $circular2->{ref_to_1} = $circular1;
    
    ok(defined($circular1->ToString()), 'Circular ref object 1 ToString works');
    ok(defined($circular2->ToString()), 'Circular ref object 2 ToString works');
    ok($circular1->GetHashCode() >= 0, 'Circular ref object 1 hash works');
    ok($circular2->GetHashCode() >= 0, 'Circular ref object 2 hash works');
}

sub test_unicode_and_encoding_edge_cases {
    # Test with various unicode scenarios
    
    # Test with different unicode normalization forms
    my $unicode_nfc = "\x{1E9B}\x{0323}";  # NFC form
    my $unicode_nfd = "s\x{0307}\x{0323}"; # NFD form (decomposed)
    
    # These may or may not be equal depending on Perl's unicode handling
    my $unicode_equal = System::Object->Equals($unicode_nfc, $unicode_nfd);
    ok(defined($unicode_equal), 'Unicode comparison does not crash');
    
    # Test with emoji and surrogate pairs
    my $emoji1 = "\x{1F600}";  # Grinning face
    my $emoji2 = "\x{1F600}";
    my $emoji3 = "\x{1F601}";  # Different emoji
    
    ok(System::Object->Equals($emoji1, $emoji2), 'Same emoji equal');
    ok(!System::Object->Equals($emoji1, $emoji3), 'Different emoji not equal');
    
    # Test with combining characters
    my $base = "e";
    my $accented = "e\x{0301}";  # e with combining acute accent
    my $precomposed = "\x{00E9}"; # é (precomposed)
    
    # Test that our equality handles these correctly
    ok(!System::Object->Equals($base, $accented), 'Base char not equal to accented');
    ok(defined(System::Object->Equals($accented, $precomposed)), 'Combining vs precomposed handled');
    
    # Test with right-to-left text
    my $rtl1 = "\x{0627}\x{0644}\x{0639}\x{0631}\x{0628}\x{064A}\x{0629}"; # Arabic
    my $rtl2 = "\x{0627}\x{0644}\x{0639}\x{0631}\x{0628}\x{064A}\x{0629}";
    ok(System::Object->Equals($rtl1, $rtl2), 'RTL text equality works');
    
    # Test with mixed LTR/RTL
    my $mixed1 = "Hello \x{0627}\x{0644}\x{0639}\x{0631}\x{0628}\x{064A}\x{0629} World";
    my $mixed2 = "Hello \x{0627}\x{0644}\x{0639}\x{0631}\x{0628}\x{064A}\x{0629} World";
    ok(System::Object->Equals($mixed1, $mixed2), 'Mixed LTR/RTL equality works');
    
    # Test with zero-width characters
    my $zwj1 = "a\x{200D}b";  # Zero-width joiner
    my $zwj2 = "a\x{200D}b";
    my $no_zwj = "ab";
    ok(System::Object->Equals($zwj1, $zwj2), 'Zero-width joiner equality');
    ok(!System::Object->Equals($zwj1, $no_zwj), 'ZWJ string not equal to plain string');
}

sub test_performance_edge_cases {
    # Test performance characteristics
    use Time::HiRes qw(time);
    
    # Test that ToString performance is reasonable
    my $obj = System::Object->new();
    my $start_time = time();
    for (1..10000) {
        $obj->ToString();
    }
    my $elapsed = time() - $start_time;
    ok($elapsed < 5, 'ToString performance reasonable (< 5 seconds for 10k calls)');
    
    # Test that GetHashCode is fast and consistent
    $start_time = time();
    my $hash1 = $obj->GetHashCode();
    for (1..10000) {
        my $hash = $obj->GetHashCode();
        is($hash, $hash1, "Hash consistent iteration $_") if $_ <= 3;
    }
    $elapsed = time() - $start_time;
    ok($elapsed < 5, 'GetHashCode performance reasonable (< 5 seconds for 10k calls)');
    
    # Test Equals performance with complex objects
    my $str1 = System::String->new('x' x 10000);
    my $str2 = System::String->new('x' x 10000);
    my $str3 = System::String->new('y' x 10000);
    
    $start_time = time();
    for (1..1000) {
        System::Object->Equals($str1, $str2);
        System::Object->Equals($str1, $str3);
    }
    $elapsed = time() - $start_time;
    ok($elapsed < 5, 'Equals performance reasonable with large strings');
}

# Run all comprehensive edge case tests
test_object_construction_edge_cases();
test_toString_edge_cases();
test_getHashCode_edge_cases();
test_equals_extreme_edge_cases();
test_referenceEquals_edge_cases();
test_is_as_methods_edge_cases();
test_inheritance_edge_cases();
test_memory_pressure_edge_cases();
test_unicode_and_encoding_edge_cases();
test_performance_edge_cases();

done_testing();