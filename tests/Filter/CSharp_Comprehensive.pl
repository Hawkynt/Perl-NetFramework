#!/usr/bin/perl
# Comprehensive C# syntax test based on DemoClass.pm
# Tests a wide variety of C# language constructs

use strict;
use warnings;
use Test::More;
use File::Temp qw(tempfile);

plan tests => 15;

# Test that Filter::CSharp loads
use_ok('Filter::CSharp') or BAIL_OUT("Cannot load Filter::CSharp");

# Helper function to test syntax compilation
sub test_csharp_syntax {
    my ($csharp_code, $test_name) = @_;
    
    my ($fh, $temp_file) = tempfile(SUFFIX => '.pl', UNLINK => 1);
    print $fh $csharp_code;
    close $fh;
    
    # Test compilation only (syntax check)
    my $output = `perl -I. -c "$temp_file" 2>&1`;
    my $exit_code = $? >> 8;
    
    if ($exit_code == 0) {
        pass($test_name);
    } else {
        fail("$test_name - syntax error: $output");
    }
}

# Test 2: Basic static class
my $static_class = <<'CSHARP';
use Filter::CSharp;

namespace StaticTest {
    static class StaticClass {
        const int constantValue = 42;
        static int staticField = 100;
        
        static StaticClass() {
            # static constructor
        }
    }
}
CSHARP

test_csharp_syntax($static_class, "Static class with constants and fields compiles");

# Test 3: Public static class with methods
my $public_static = <<'CSHARP';
use Filter::CSharp;

namespace StaticTest {
    public static class PublicStaticClass {
        public static void StaticMethod() {
            print "static method";
        }
    }
}
CSHARP

test_csharp_syntax($public_static, "Public static class with methods compiles");

# Test 4: Nested namespaces
my $nested_ns = <<'CSHARP';
use Filter::CSharp;

namespace StaticTest::SubSpace {
    static class StaticClass {
        private const int privateConstantValue = 42;
    }
}
CSHARP

test_csharp_syntax($nested_ns, "Nested namespaces compile");

# Test 5: Class inheritance
my $inheritance = <<'CSHARP';
use Filter::CSharp;

package EmptyPackage;
sub test { }

use Filter::CSharp;

namespace Test {
    static class InheritedClass : EmptyPackage {
        static readonly int readonlyField = 42;
    }
}
CSHARP

test_csharp_syntax($inheritance, "Class inheritance compiles");

# Test 6: Multiple field types and modifiers
my $fields = <<'CSHARP';
use Filter::CSharp;

namespace Test {
    static class FieldTest {
        static int staticFieldWithoutValue;
        static int staticFieldWithValue = 42;
        private static int privateStaticField = 100;
        public static int publicStaticField = 200;
    }
}
CSHARP

test_csharp_syntax($fields, "Multiple field types and modifiers compile");

# Test 7: Static properties (auto-implemented)
my $static_props = <<'CSHARP';
use Filter::CSharp;

namespace Test {
    static class PropertyTest {
        static int AutoProp { get; set; }
        static int AutoPropInverse { set; get; }
        static int GetOnlyProp { get; }
        static int SetOnlyProp { set; }
    }
}
CSHARP

test_csharp_syntax($static_props, "Static auto-implemented properties compile");

# Test 8: Instance class with methods
my $instance_class = <<'CSHARP';
use Filter::CSharp;

namespace InstanceTest {
    class NormalClass {
        public int fieldWithValue = 42;
        private int fieldWithoutValue;
        
        NormalClass() {
            # normal constructor
        }
    }
}
CSHARP

test_csharp_syntax($instance_class, "Instance class with fields compiles");

# Test 9: Instance properties
my $instance_props = <<'CSHARP';
use Filter::CSharp;

namespace Test {
    class PropertyClass {
        int AutoProp { get; set; }
        private int AutoPropInverse { set; get; }
        public int GetOnlyProp { get; }
        protected int SetOnlyProp { set; }
    }
}
CSHARP

test_csharp_syntax($instance_props, "Instance auto-implemented properties compile");

# Test 10: Multiple inheritance
my $multi_inherit = <<'CSHARP';
use Filter::CSharp;

package EmptyPackage;
sub test { }

use Filter::CSharp;
use System::Collections;

namespace Test {
    class MultiInherited : EmptyPackage, System::Collections::IEnumerable {
    }
}
CSHARP

test_csharp_syntax($multi_inherit, "Multiple inheritance compiles");

# Test 11: var declarations
my $var_test = <<'CSHARP';
use Filter::CSharp;

var $variable_without_definition;
var $variable_with_definition = 42;
var @array_variable = (1, 2, 3);

print "vars declared";
CSHARP

test_csharp_syntax($var_test, "var declarations compile");

# Test 12: Lambda expressions (basic syntax)
my $lambda_test = <<'CSHARP';
use Filter::CSharp;

var $lambda_simple = () => { return 42; };
var $lambda_with_param = ($x) => { return $x * 2; };

print "lambdas declared";
CSHARP

test_csharp_syntax($lambda_test, "Lambda expressions compile");

# Test 13: using statements
my $using_test = <<'CSHARP';
use Filter::CSharp;

using System;
using System::IO;
using System::Linq;

print "using statements processed";
CSHARP

test_csharp_syntax($using_test, "using statements compile");

# Test 14: Constants and readonly fields
my $const_test = <<'CSHARP';
use Filter::CSharp;

namespace Test {
    class ConstTest {
        const int CONSTANT = 42;
        private const string PRIVATE_CONST = "test";
        static readonly int READONLY_FIELD = 100;
    }
}
CSHARP

test_csharp_syntax($const_test, "Constants and readonly fields compile");

done_testing();

print "\n" . "=" x 60 . "\n";
print "COMPREHENSIVE C# SYNTAX TEST SUMMARY\n";
print "=" x 60 . "\n";
print "✅ SYNTAX COMPILATION TESTS:\n";
print "   • Static classes and methods\n";
print "   • Public/private access modifiers\n";
print "   • Nested namespaces\n";
print "   • Class inheritance (single and multiple)\n";
print "   • Field declarations with various modifiers\n";
print "   • Auto-implemented properties\n";
print "   • Instance classes and constructors\n";
print "   • var declarations\n";
print "   • Lambda expressions (basic syntax)\n";
print "   • using statements\n";
print "   • Constants and readonly fields\n";
print "\n";
print "📝 NOTE: These tests verify that the C# syntax compiles\n";
print "   to valid Perl. Runtime behavior may vary.\n";
print "=" x 60 . "\n";