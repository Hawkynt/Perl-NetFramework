#!/usr/bin/perl
# Test that Filter::CSharp preserves line numbers during transformation
# Based on original SourceFilterTest.pl from x/ directory

use strict;
use warnings;
use Test::More;
use File::Temp qw(tempfile);

plan tests => 5;

# Test that Filter::CSharp loads
use_ok('Filter::CSharp') or BAIL_OUT("Cannot load Filter::CSharp");

# Helper function to test line number preservation
sub test_line_preservation {
    my ($csharp_code, $test_name) = @_;
    
    my ($fh, $temp_file) = tempfile(SUFFIX => '.pl', UNLINK => 1);
    print $fh $csharp_code;
    close $fh;
    
    my $output = `perl -I. "$temp_file" 2>&1`;
    my $exit_code = $? >> 8;
    
    if ($exit_code == 0) {
        like($output, qr/Line Numbers do match/, $test_name);
    } else {
        fail("$test_name - execution failed: $output");
    }
}

# Test 2: Basic line number preservation
my $basic_lines = <<'CSHARP';
use Filter::CSharp;

BEGIN { our %I = (); }

namespace Test {
    public class TestClass {
        var $test_var = 42;
        BEGIN { $main::I{8} = __LINE__; }
        
        const int TEST_CONST = 100;
        BEGIN { $main::I{11} = __LINE__; }
        
        public static void TestMethod() {
            print "method called";
        }
        BEGIN { $main::I{16} = __LINE__; }
    }
}

BEGIN {
    my $failed = 0;
    for my $key (sort keys %main::I) {
        next if $key == $main::I{$key};
        print "Line number mismatch! Line $key seems to be at $main::I{$key}\n";
        $failed = 1;
    }
    print "Line Numbers do match, everything is working right.\n" unless $failed;
}
CSHARP

test_line_preservation($basic_lines, "Basic C# constructs preserve line numbers");

# Test 3: var declarations preserve line numbers
my $var_lines = <<'CSHARP';
use Filter::CSharp;

BEGIN { our %I = (); }

var $variable1;
BEGIN { $main::I{6} = __LINE__; }

var $variable2 = "test";
BEGIN { $main::I{9} = __LINE__; }

var @array_var = (1, 2, 3);
BEGIN { $main::I{12} = __LINE__; }

BEGIN {
    my $failed = 0;
    for my $key (sort keys %main::I) {
        next if $key == $main::I{$key};
        print "var declaration line mismatch! Line $key at $main::I{$key}\n";
        $failed = 1;
    }
    print "Line Numbers do match, everything is working right.\n" unless $failed;
}
CSHARP

test_line_preservation($var_lines, "var declarations preserve line numbers");

# Test 4: Method definitions preserve line numbers
my $method_lines = <<'CSHARP';
use Filter::CSharp;

BEGIN { our %I = (); }

namespace Test {
    public static class MethodTest {
        public static void Method1() {
            print "method1";
        }
        BEGIN { $main::I{10} = __LINE__; }
        
        public static void Method2() {
            print "method2";
        }
        BEGIN { $main::I{15} = __LINE__; }
    }
}

BEGIN {
    my $failed = 0;
    for my $key (sort keys %main::I) {
        next if $key == $main::I{$key};
        print "Method line mismatch! Line $key at $main::I{$key}\n";
        $failed = 1;
    }
    print "Line Numbers do match, everything is working right.\n" unless $failed;
}
CSHARP

test_line_preservation($method_lines, "Method definitions preserve line numbers");

# Test 5: Properties preserve line numbers
my $property_lines = <<'CSHARP';
use Filter::CSharp;

BEGIN { our %I = (); }

namespace Test {
    public class PropertyTest {
        public int Property1 { get; set; }
        BEGIN { $main::I{8} = __LINE__; }
        
        public string Property2 { get; set; }
        BEGIN { $main::I{11} = __LINE__; }
    }
}

BEGIN {
    my $failed = 0;
    for my $key (sort keys %main::I) {
        next if $key == $main::I{$key};
        print "Property line mismatch! Line $key at $main::I{$key}\n";
        $failed = 1;
    }
    print "Line Numbers do match, everything is working right.\n" unless $failed;
}
CSHARP

test_line_preservation($property_lines, "Property definitions preserve line numbers");

done_testing();

print "\n" . "=" x 60 . "\n";
print "LINE NUMBER PRESERVATION TEST SUMMARY\n";
print "=" x 60 . "\n";
print "✅ TESTED CONSTRUCTS:\n";
print "   • Basic C# class and method definitions\n";
print "   • var variable declarations\n";
print "   • Static method definitions\n";
print "   • Property declarations\n";
print "\n";
print "📝 PURPOSE:\n";
print "   Line number preservation ensures that error messages\n";
print "   and debugging information point to the correct lines\n";
print "   in the original C# source code.\n";
print "\n";
print "⚙️  MECHANISM:\n";
print "   The Filter::CSharp uses regex transformations that\n";
print "   should not add or remove lines, maintaining the\n";
print "   original line numbering for debugging.\n";
print "=" x 60 . "\n";