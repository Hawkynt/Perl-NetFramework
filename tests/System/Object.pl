#!/usr/bin/perl
use strict;
use warnings;
use lib '../../';
use Test::More;
use System;

BEGIN {
    use_ok('System::Object');
}

sub test_object_creation {
    my $obj = System::Object->new();
    isa_ok($obj, 'System::Object', 'Object creation');
}

sub test_toString {
    my $obj = System::Object->new();
    like($obj->ToString(), qr/System::Object/, 'ToString returns class name');
}

sub test_equals {
    my $obj1 = System::Object->new();
    my $obj2 = System::Object->new();
    
    ok($obj1->Equals($obj1), 'Object equals itself');
    ok(!$obj1->Equals($obj2), 'Different objects are not equal');
    ok(!$obj1->Equals(undef), 'Object does not equal undef');
}

sub test_getHashCode {
    my $obj1 = System::Object->new();
    my $obj2 = System::Object->new();
    
    is($obj1->GetHashCode(), $obj1->GetHashCode(), 'Hash code is consistent');
    isnt($obj1->GetHashCode(), $obj2->GetHashCode(), 'Different objects have different hash codes');
}

sub test_getType {
    my $obj = System::Object->new();
    is($obj->GetType(), 'System::Object', 'GetType returns correct type');
}

test_object_creation();
test_toString();
test_equals();
test_getHashCode();
test_getType();

done_testing();