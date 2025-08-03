#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempfile);

# Test the working parts of Filter::CSharp
# This documents what currently works and what needs fixing

plan tests => 10;

# First, test that the Filter::CSharp module loads
use_ok('Filter::CSharp') or BAIL_OUT("Cannot load Filter::CSharp");

# Helper function to create and execute C# filtered code
sub test_csharp_execution {
    my ($csharp_code, $expected_output_pattern, $test_name) = @_;
    
    my ($fh, $temp_file) = tempfile(SUFFIX => '.pl', UNLINK => 1);
    print $fh $csharp_code;
    close $fh;
    
    my $output = `perl -I. "$temp_file" 2>&1`;
    my $exit_code = $? >> 8;
    
    if ($exit_code == 0 && defined $expected_output_pattern) {
        like($output, $expected_output_pattern, $test_name);
    } elsif ($exit_code == 0) {
        pass($test_name);
    } else {
        fail("$test_name - execution failed: $output");
    }
}

# Test 2: var keyword (WORKS)
my $var_test = <<'CSHARP';
use Filter::CSharp;

var $name = "Alice";
var $age = 25;
var @items = ("a", "b", "c");

print "$name:$age:" . scalar(@items);
CSHARP

test_csharp_execution($var_test, qr/Alice:25:3/, "var keyword transformation works");

# Test 3: new keyword (WORKS)
my $new_test = <<'CSHARP';
use Filter::CSharp;
use System;

my $str1 = new System::String("Hello");
my $str2 = new System::String("World");

print $str1->ToString() . " " . $str2->ToString();
CSHARP

test_csharp_execution($new_test, qr/Hello World/, "new keyword transformation works");

# Test 4: Basic namespace and class (WORKS with limitations)
my $basic_class = <<'CSHARP';
use Filter::CSharp;
use System;

namespace TestApp {
    public class SimpleClass {
        public SimpleClass() {
            # Constructor without parameters works
        }
        
        public string GetMessage() {
            return "Hello from SimpleClass";
        }
    }
}

my $obj = TestApp::SimpleClass->new();
print $obj->GetMessage();
CSHARP

test_csharp_execution($basic_class, qr/Hello from SimpleClass/, "Basic class with no-parameter methods works");

# Test 5: Nested namespaces (WORKS)
my $nested_test = <<'CSHARP';
use Filter::CSharp;

namespace Outer::Inner {
    public class NestedClass {
        public NestedClass() {
        }
        
        public string GetLocation() {
            return "Outer.Inner.NestedClass";
        }
    }
}

my $obj = Outer::Inner::NestedClass->new();
print $obj->GetLocation();
CSHARP

test_csharp_execution($nested_test, qr/Outer\.Inner\.NestedClass/, "Nested namespaces work");

# Test 6: Constants (WORKS but with quirks)
my $const_test = <<'CSHARP';
use Filter::CSharp;

const string APP_NAME = "MyApp";
const int VERSION = 1;

print APP_NAME . ":" . VERSION;
CSHARP

test_csharp_execution($const_test, qr/MyApp:1/, "Constants work");

# Test 7: Static methods without parameters (WORKS)
my $static_simple = <<'CSHARP';
use Filter::CSharp;

namespace TestNS {
    public class Utility {
        public static string GetAppName() {
            return "TestApp";
        }
        
        public static int GetVersion() {
            return 42;
        }
    }
}

print TestNS::Utility->GetAppName() . ":" . TestNS::Utility->GetVersion();
CSHARP

test_csharp_execution($static_simple, qr/TestApp:42/, "Static methods without parameters work");

# Test 8: Test helper methods exist
can_ok('Filter::CSharp', '_Using');
can_ok('Filter::CSharp', '_CreateMeta');
can_ok('Filter::CSharp', '_RegisterField');

done_testing();

# Print a summary of what works and what doesn't
print "\n" . "=" x 60 . "\n";
print "FILTER::CSHARP STATUS SUMMARY\n";
print "=" x 60 . "\n";
print "✅ WORKING FEATURES:\n";
print "   • var keyword transformation (var \$x -> my \$x)\n";
print "   • new keyword transformation (new Class() -> Class->new())\n";
print "   • Basic namespace and class declarations\n";
print "   • Nested namespaces (Outer::Inner)\n";
print "   • Constants (const string X = \"value\")\n";
print "   • Static methods without parameters\n";
print "   • Basic constructors without parameters\n";
print "   • Simple method calls\n";
print "\n";
print "❌ PROBLEMATIC FEATURES:\n";
print "   • Method parameters with type annotations\n";
print "   • this keyword in methods\n";
print "   • Auto-implemented properties { get; set; }\n";
print "   • Field declarations with initialization\n";
print "   • Constructor parameters\n";
print "   • Destructor syntax (~ctor)\n";
print "   • using statements for imports\n";
print "   • Complex method signatures\n";
print "\n";
print "📝 RECOMMENDATIONS:\n";
print "   • Use simple method signatures without type annotations\n";
print "   • Avoid this keyword for now - use \$this directly\n";
print "   • Use manual property implementation instead of { get; set; }\n";
print "   • Initialize fields in constructor body\n";
print "   • Keep C# syntax simple until filter is enhanced\n";
print "=" x 60 . "\n";