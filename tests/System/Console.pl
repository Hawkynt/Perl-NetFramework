#!/usr/bin/perl

use strict;
use warnings;
use lib qw(. ./lib);

# Import required modules
require System::Console;

# Test counters
my $tests_run = 0;
my $tests_passed = 0;

sub test_ok {
  my ($condition, $test_name) = @_;
  $tests_run++;
  if ($condition) {
    print "ok $tests_run - $test_name\n";
    $tests_passed++;
  } else {
    print "not ok $tests_run - $test_name\n";
  }
}

sub test_exception {
  my ($code, $expected_exception, $test_name) = @_;
  $tests_run++;
  
  my $caught_exception = '';
  eval {
    $code->();
  };
  
  if ($@) {
    $caught_exception = ref($@) ? ref($@) : $@;
  }
  
  if ($caught_exception =~ /$expected_exception/) {
    print "ok $tests_run - $test_name\n";
    $tests_passed++;
  } else {
    print "not ok $tests_run - $test_name (expected $expected_exception, got $caught_exception)\n";
  }
}

# Capture output for testing
sub capture_output {
  my ($code) = @_;
  
  # Redirect STDOUT to capture output
  open my $original_stdout, '>&', STDOUT or die "Cannot dup stdout: $!";
  my $output = '';
  close STDOUT;
  open STDOUT, '>', \$output or die "Cannot redirect stdout: $!";
  
  eval { $code->(); };
  my $error = $@;
  
  # Restore original STDOUT
  close STDOUT;
  open STDOUT, '>&', $original_stdout or die "Cannot restore stdout: $!";
  
  die $error if $error;
  return $output;
}

print "1..40\n"; # Comprehensive Console tests

# Test 1-5: Basic console instantiation and properties
test_exception(
  sub { System::Console->new(); },
  'InvalidOperationException',
  'Console cannot be instantiated'
);

# Test stream properties
my $in = System::Console->In();
test_ok($in->isa('System::IO::TextReader'), 'In returns TextReader');

my $out = System::Console->Out();
test_ok($out->isa('System::IO::TextWriter'), 'Out returns TextWriter');

my $error = System::Console->Error();
test_ok($error->isa('System::IO::TextWriter'), 'Error returns TextWriter');

# Test that stream properties return same instance
my $in2 = System::Console->In();
test_ok($in eq $in2, 'In returns same instance');

# Test 6-10: Color properties
my $foregroundColor = System::Console->ForegroundColor();
test_ok(defined($foregroundColor), 'ForegroundColor returns defined value');
test_ok($foregroundColor eq 'Gray', 'Default ForegroundColor is Gray');

System::Console->ForegroundColor('Red');
my $newForegroundColor = System::Console->ForegroundColor();
test_ok($newForegroundColor eq 'Red', 'ForegroundColor setter works');

my $backgroundColor = System::Console->BackgroundColor();
test_ok(defined($backgroundColor), 'BackgroundColor returns defined value');
test_ok($backgroundColor eq 'Black', 'Default BackgroundColor is Black');

# Test 11-15: Window size properties
my $windowWidth = System::Console->WindowWidth();
test_ok($windowWidth > 0, 'WindowWidth returns positive value');
test_ok($windowWidth >= 80, 'WindowWidth is at least 80 (reasonable minimum)');

my $windowHeight = System::Console->WindowHeight();
test_ok($windowHeight > 0, 'WindowHeight returns positive value');
test_ok($windowHeight >= 25, 'WindowHeight is at least 25 (reasonable minimum)');

# Test redirection detection
my $inputRedirected = System::Console->IsInputRedirected();
test_ok(defined($inputRedirected), 'IsInputRedirected returns defined value');

# Test 16-20: Basic output methods (testing without actual output)
my $writeOutput = capture_output(sub {
  System::Console->Write('Hello');
});
test_ok($writeOutput eq 'Hello', 'Write outputs correct text');

my $writeLineOutput = capture_output(sub {
  System::Console->WriteLine('World');
});
test_ok($writeLineOutput =~ /World/, 'WriteLine outputs text');
test_ok($writeLineOutput =~ /\n|\r\n$/, 'WriteLine adds newline');

my $emptyLineOutput = capture_output(sub {
  System::Console->WriteLine();
});
test_ok($emptyLineOutput =~ /^\n|\r\n$/, 'WriteLine() outputs just newline');

# Test formatted output
my $formattedOutput = capture_output(sub {
  System::Console->Write('Number: {0}', 42);
});
test_ok($formattedOutput =~ /42/, 'Write with formatting works');

# Test 21-25: Cursor properties and methods
my $cursorLeft = System::Console->CursorLeft();
test_ok(defined($cursorLeft), 'CursorLeft returns defined value');
test_ok($cursorLeft >= 0, 'CursorLeft is non-negative');

my $cursorTop = System::Console->CursorTop();
test_ok(defined($cursorTop), 'CursorTop returns defined value');
test_ok($cursorTop >= 0, 'CursorTop is non-negative');

my $cursorVisible = System::Console->CursorVisible();
test_ok(defined($cursorVisible), 'CursorVisible returns defined value');

# Test 26-30: Console control methods
# Test SetCursorPosition (should not throw for valid positions)
eval {
  System::Console->SetCursorPosition(0, 0);
  test_ok(1, 'SetCursorPosition with valid coordinates works');
} or test_ok(0, 'SetCursorPosition with valid coordinates works');

test_exception(
  sub { System::Console->SetCursorPosition(-1, 0); },
  'ArgumentOutOfRangeException',
  'SetCursorPosition with negative left throws exception'
);

test_exception(
  sub { System::Console->SetCursorPosition(0, -1); },
  'ArgumentOutOfRangeException',
  'SetCursorPosition with negative top throws exception'
);

# Test Title property
my $originalTitle = System::Console->Title();
test_ok(defined($originalTitle), 'Title returns defined value');

eval {
  System::Console->Title('Test Title');
  test_ok(1, 'Title setter works');
} or test_ok(0, 'Title setter works');

# Test 31-35: Advanced functionality
# Test ResetColor (should not throw)
eval {
  System::Console->ResetColor();
  test_ok(1, 'ResetColor works');
} or test_ok(0, 'ResetColor works');

# Verify ResetColor resets colors
my $resetForeground = System::Console->ForegroundColor();
my $resetBackground = System::Console->BackgroundColor();
test_ok($resetForeground eq 'Gray', 'ResetColor resets foreground to Gray');
test_ok($resetBackground eq 'Black', 'ResetColor resets background to Black');

# Test Beep (should not throw)
eval {
  System::Console->Beep();
  test_ok(1, 'Beep() works');
} or test_ok(0, 'Beep() works');

# Test Beep with parameters
eval {
  System::Console->Beep(1000, 100);
  test_ok(1, 'Beep(frequency, duration) works');
} or test_ok(0, 'Beep(frequency, duration) works');

# Test 36-40: Input/Output redirection and object output
my $outputRedirected = System::Console->IsOutputRedirected();
test_ok(defined($outputRedirected), 'IsOutputRedirected returns defined value');

my $errorRedirected = System::Console->IsErrorRedirected();
test_ok(defined($errorRedirected), 'IsErrorRedirected returns defined value');

# Test writing objects with ToString method
require System::String;
my $stringObj = System::String->new('Test Object');
my $objectOutput = capture_output(sub {
  System::Console->Write($stringObj);
});
test_ok($objectOutput eq 'Test Object', 'Write outputs ToString() of objects');

# Test Clear (should not throw)
eval {
  System::Console->Clear();
  test_ok(1, 'Clear() works');
} or test_ok(0, 'Clear() works');

# Test cursor visibility setting
eval {
  System::Console->CursorVisible(0);  # Hide cursor
  System::Console->CursorVisible(1);  # Show cursor
  test_ok(1, 'CursorVisible setter works');
} or test_ok(0, 'CursorVisible setter works');

print "\n# System::Console Tests completed: $tests_run\n";
print "# System::Console Tests passed: $tests_passed\n";
print "# Pass rate: " . sprintf("%.1f%%", ($tests_passed / $tests_run) * 100) . "\n";

exit($tests_passed == $tests_run ? 0 : 1);