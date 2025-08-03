#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempfile tempdir);
use File::Spec;

# Test the Filter::CSharp syntax transformations by using MO=Deparse 
# to see the actual transformed code and then testing the behavior

plan tests => 20;

# First, test that the Filter::CSharp module loads
use_ok('Filter::CSharp') or BAIL_OUT("Cannot load Filter::CSharp");

# Helper function to test C# syntax transformation and behavior
sub test_csharp_behavior {
    my ($csharp_code, $test_code, $test_name) = @_;
    
    # Create a temporary file with C# syntax
    my ($fh, $temp_file) = tempfile(SUFFIX => '.pl', UNLINK => 1);
    print $fh $csharp_code;
    close $fh;
    
    # Use MO=Deparse to get the transformed Perl code
    my $deparse_output = `perl -I. -MO=Deparse $temp_file 2>/dev/null`;
    
    if ($? != 0) {
        fail("$test_name - Filter transformation failed");
        return;
    }
    
    # Create another temp file with the transformed code
    my ($transformed_fh, $transformed_file) = tempfile(SUFFIX => '.pl', UNLINK => 1);
    print $transformed_fh $deparse_output;
    close $transformed_fh;
    
    # Now test the behavior by requiring the transformed module
    eval {
        # Execute the test code which should use the transformed functionality
        my $result = eval $test_code;
        if ($@) {
            die "Test execution failed: $@";
        }
        if (defined $result && !$result) {
            die "Test assertion failed";
        }
    };
    
    if ($@) {
        fail("$test_name - $@");
    } else {
        pass($test_name);
    }
}

# Helper to test simple transformations without full behavior testing
sub test_simple_transformation {
    my ($csharp_code, $expected_pattern, $test_name) = @_;
    
    my ($fh, $temp_file) = tempfile(SUFFIX => '.pl', UNLINK => 1);
    print $fh $csharp_code;
    close $fh;
    
    my $deparse_output = `perl -I. -MO=Deparse $temp_file 2>/dev/null`;
    
    if ($? != 0) {
        fail("$test_name - transformation failed");
        return;
    }
    
    like($deparse_output, $expected_pattern, $test_name);
}

# Test 2: var keyword transformation
test_simple_transformation(
    "use Filter::CSharp;\nvar \$name = 'test';",
    qr/my \$name = 'test'/,
    "var keyword transforms to my"
);

# Test 3: using statement transformation  
test_simple_transformation(
    "use Filter::CSharp;\nusing System::Collections;",
    qr/use.*System::Collections/,
    "using statement transforms to use"
);

# Test 4: new keyword transformation
test_simple_transformation(
    "use Filter::CSharp;\nmy \$obj = new TestClass('arg');",
    qr/TestClass->new/,
    "new keyword transforms to ->new"
);

# Test 5: Basic class creation and instantiation
my $basic_class_code = <<'CSHARP';
use Filter::CSharp;
use System;

namespace TestApp {
    public class Person {
        private string name;
        
        public Person(string n) {
            this.name = n;
        }
        
        public string GetName() {
            return this.name;
        }
    }
}
CSHARP

test_simple_transformation(
    $basic_class_code,
    qr/package.*TestApp::Person/,
    "Basic class declaration creates proper package"
);

# Test 6: Properties with get/set
my $properties_code = <<'CSHARP';
use Filter::CSharp;

namespace TestApp {
    public class User {
        public string Name { get; set; }
        public int Age { get; set; }
    }
}
CSHARP

test_simple_transformation(
    $properties_code,
    qr/_RegisterProperty.*Name/,
    "Auto-implemented properties generate registration calls"
);

# Test 7: Constructor and method generation
test_simple_transformation(
    $basic_class_code,
    qr/__ctor_Person/,
    "Constructor transforms to __ctor method"
);

# Test 8: this keyword transformation
my $this_code = <<'CSHARP';
use Filter::CSharp;

namespace Test {
    public class Sample {
        private string value;
        
        public Sample(string v) {
            this.value = v;
        }
        
        public string GetValue() {
            return this.value;
        }
    }
}
CSHARP

test_simple_transformation(
    $this_code,
    qr/\$this->/,
    "this keyword transforms to \$this->"
);

# Test 9: Static methods
my $static_code = <<'CSHARP';
use Filter::CSharp;

namespace Test {
    public class MathHelper {
        public static int Add(int a, int b) {
            return a + b;
        }
    }
}
CSHARP

test_simple_transformation(
    $static_code,
    qr/sub.*Add/,
    "Static methods transform to subs"
);

# Test 10: Constants
test_simple_transformation(
    "use Filter::CSharp;\nconst string TEST = 'value';",
    qr/use.*constant.*TEST/,
    "const declarations transform to use constant"
);

# Test 11: Field declarations
my $field_code = <<'CSHARP';
use Filter::CSharp;

namespace Test {
    public class Sample {
        private string name;
        public int count;
    }
}
CSHARP

test_simple_transformation(
    $field_code,
    qr/_RegisterField/,
    "Field declarations generate registration calls"
);

# Test 12: Test Filter::CSharp helper methods exist
can_ok('Filter::CSharp', '_Using');
can_ok('Filter::CSharp', '_GetMetaForPackage'); 
can_ok('Filter::CSharp', '_CreateMeta');
can_ok('Filter::CSharp', '_RegisterField');
can_ok('Filter::CSharp', '_RegisterProperty');

# Test 13: Test meta creation functionality
eval {
    my $meta = Filter::CSharp::_CreateMeta("TestPackage", "test.pm", "TestClass", "", 0, "public");
    pass("Meta creation works") if defined($meta) && ref($meta) eq 'CSharp::__Meta';
};
fail("Meta creation failed: $@") if $@;

# Test 14: Test field registration
eval {
    my $meta = Filter::CSharp::_CreateMeta("TestPackage", "test.pm", "TestClass", "", 0, "public");
    Filter::CSharp::_RegisterField($meta, 'string', 0, 0, 1, 1, __FILE__, __LINE__, 'testField');
    pass("Field registration works") if exists $meta->{fieldInfos}->{testField};
};
fail("Field registration failed: $@") if $@;

# Test 15: Test property registration  
eval {
    my $meta = Filter::CSharp::_CreateMeta("TestPackage", "test.pm", "TestClass", "", 0, "public");
    Filter::CSharp::_RegisterProperty($meta, 'string', 0, 1, 1, __FILE__, __LINE__, 'testProperty');
    pass("Property registration works") if exists $meta->{propertyInfos}->{testProperty};
};
fail("Property registration failed: $@") if $@;

done_testing();