#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempfile tempdir);
use File::Spec;

# Integration tests for Filter::CSharp that actually execute filtered code
plan tests => 15;

# First, test that the Filter::CSharp module loads
use_ok('Filter::CSharp') or BAIL_OUT("Cannot load Filter::CSharp");

# Helper function to create and execute C# filtered code
sub test_csharp_execution {
    my ($csharp_code, $expected_output_pattern, $test_name) = @_;
    
    # Create a temporary file with C# syntax
    my ($fh, $temp_file) = tempfile(SUFFIX => '.pl', UNLINK => 1);
    print $fh $csharp_code;
    close $fh;
    
    # Execute the file and capture output
    my $output = `perl -I. "$temp_file" 2>&1`;
    my $exit_code = $? >> 8;
    
    if ($exit_code == 0 && defined $expected_output_pattern) {
        like($output, $expected_output_pattern, $test_name);
    } elsif ($exit_code == 0) {
        pass($test_name);
    } else {
        fail("$test_name - execution failed with exit code $exit_code: $output");
    }
}

# Test 2: Basic var keyword functionality
my $var_test = <<'CSHARP';
use Filter::CSharp;

var $name = "Alice";
var $age = 25;

print "$name:$age";
CSHARP

test_csharp_execution($var_test, qr/Alice:25/, "var keyword works in practice");

# Test 3: this keyword in methods
my $this_test = <<'CSHARP';
use Filter::CSharp;
use System;

namespace TestNS {
    public class Person {
        private string name;
        
        public Person(string n) {
            this.name = n;
        }
        
        public string GetName() {
            return this.name;
        }
        
        public void SetName(string newName) {
            this.name = newName;
        }
    }
}

my $person = TestNS::Person->new("John");
print $person->GetName();
$person->SetName("Jane");
print ":" . $person->GetName();
CSHARP

test_csharp_execution($this_test, qr/John:Jane/, "this keyword works in methods");

# Test 4: new keyword transformation
my $new_test = <<'CSHARP';
use Filter::CSharp;
use System;

my $str1 = new System::String("Hello");
my $str2 = new System::String("World");

print $str1->ToString() . " " . $str2->ToString();
CSHARP

test_csharp_execution($new_test, qr/Hello World/, "new keyword transformation works");

# Test 5: Properties with get/set
my $props_test = <<'CSHARP';
use Filter::CSharp;
use System;

namespace TestNS {
    public class User {
        public string Name { get; set; }
        public int Age { get; set; }
        
        public User(string name, int age) {
            this.Name = name;
            this.Age = age;
        }
    }
}

my $user = TestNS::User->new("Bob", 30);
print $user->Name() . ":" . $user->Age();

$user->Name("Charlie");
$user->Age(35);
print ":" . $user->Name() . ":" . $user->Age();
CSHARP

test_csharp_execution($props_test, qr/Bob:30:Charlie:35/, "Properties work correctly");

# Test 6: Static methods
my $static_test = <<'CSHARP';
use Filter::CSharp;
use System;

namespace TestNS {
    public class MathUtil {
        public static int Add(int a, int b) {
            return a + b;
        }
        
        public static string Concat(string s1, string s2) {
            return s1 . s2;
        }
    }
}

my $sum = TestNS::MathUtil->Add(10, 20);
my $text = TestNS::MathUtil->Concat("Hello", "World");

print "$sum:$text";
CSHARP

test_csharp_execution($static_test, qr/30:HelloWorld/, "Static methods work correctly");

# Test 7: Constants
my $const_test = <<'CSHARP';
use Filter::CSharp;

namespace TestNS {
    public class Config {
        public const string APP_NAME = "MyApp";
        public const int VERSION = 42;
        
        public static string GetInfo() {
            return Config.APP_NAME . ":" . Config.VERSION;
        }
    }
}

print TestNS::Config->GetInfo();
CSHARP

test_csharp_execution($const_test, qr/MyApp:42/, "Constants work correctly");

# Test 8: Multiple classes in one namespace
my $multi_class_test = <<'CSHARP';
use Filter::CSharp;
use System;

namespace TestNS {
    public class ClassA {
        public string GetValue() {
            return "A";
        }
    }
    
    public class ClassB {
        public string GetValue() {
            return "B";
        }
    }
}

my $a = TestNS::ClassA->new();
my $b = TestNS::ClassB->new();

print $a->GetValue() . $b->GetValue();
CSHARP

test_csharp_execution($multi_class_test, qr/AB/, "Multiple classes in namespace work");

# Test 9: Nested namespaces
my $nested_ns_test = <<'CSHARP';
use Filter::CSharp;

namespace Outer::Inner {
    public class NestedClass {
        public string GetLocation() {
            return "Outer.Inner";
        }
    }
}

my $obj = Outer::Inner::NestedClass->new();
print $obj->GetLocation();
CSHARP

test_csharp_execution($nested_ns_test, qr/Outer\.Inner/, "Nested namespaces work");

# Test 10: Constructor and destructor
my $ctor_dtor_test = <<'CSHARP';
use Filter::CSharp;

namespace TestNS {
    public class Resource {
        private string id;
        
        public Resource(string resourceId) {
            this.id = resourceId;
            print "Created:" . this.id . ";";
        }
        
        ~Resource() {
            print "Destroyed:" . this.id . ";";
        }
        
        public string GetId() {
            return this.id;
        }
    }
}

{
    my $res = TestNS::Resource->new("R001");
    print "Using:" . $res->GetId() . ";";
}

print "Done";
CSHARP

test_csharp_execution($ctor_dtor_test, qr/Created:R001;Using:R001;.*Done/, "Constructor and destructor work");

# Test 11: Access modifiers (basic test)
my $access_test = <<'CSHARP';
use Filter::CSharp;

namespace TestNS {
    public class AccessTest {
        private string secret;
        public string visible;
        
        public AccessTest() {
            this.secret = "hidden";
            this.visible = "shown";
        }
        
        public string GetSecret() {
            return this.secret;
        }
    }
}

my $obj = TestNS::AccessTest->new();
print $obj->GetSecret() . ":" . $obj->visible;
CSHARP

test_csharp_execution($access_test, qr/hidden:shown/, "Access modifiers work");

# Test 12: Method parameters and return types
my $method_test = <<'CSHARP';
use Filter::CSharp;

namespace TestNS {
    public class Calculator {
        public int Multiply(int x, int y) {
            return x * y;
        }
        
        public string Format(string template, string value) {
            return template . ":" . value;
        }
    }
}

my $calc = TestNS::Calculator->new();
my $result = $calc->Multiply(6, 7);
my $formatted = $calc->Format("Result", $result);

print $formatted;
CSHARP

test_csharp_execution($method_test, qr/Result:42/, "Method parameters and return types work");

# Test 13: Field initialization
my $field_test = <<'CSHARP';
use Filter::CSharp;

namespace TestNS {
    public class Counter {
        public int count = 0;
        private string name = "default";
        
        public Counter(string counterName) {
            this.name = counterName;
        }
        
        public void Increment() {
            this.count++;
        }
        
        public string GetStatus() {
            return this.name . ":" . this.count;
        }
    }
}

my $counter = TestNS::Counter->new("TestCounter");
print $counter->GetStatus() . ";";
$counter->Increment();
$counter->Increment();
print $counter->GetStatus();
CSHARP

test_csharp_execution($field_test, qr/TestCounter:0;TestCounter:2/, "Field initialization works");

# Test 14: using statement (if implemented)
my $using_test = <<'CSHARP';
use Filter::CSharp;
using System::String;

my $str = String->new("Hello");
print $str->ToString();
CSHARP

test_csharp_execution($using_test, qr/Hello/, "using statement works");

done_testing();