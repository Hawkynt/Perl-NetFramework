#!/usr/bin/perl

use strict;
use warnings;
use lib qw(. ./lib);

# Import required modules
require System::Environment;

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

print "1..70\n"; # Comprehensive Environment tests with additional coverage

# Test 1-10: Basic environment variable access
my $testVar = 'PERL_TEST_VAR_12345';
my $testValue = 'test_value_67890';

# Set and get environment variable
System::Environment->SetEnvironmentVariable($testVar, $testValue);
my $retrieved = System::Environment->GetEnvironmentVariable($testVar);
test_ok(defined($retrieved), 'GetEnvironmentVariable returns defined value');
test_ok($retrieved eq $testValue, 'Environment variable value matches');

# Test removing environment variable
System::Environment->SetEnvironmentVariable($testVar, undef);
my $removed = System::Environment->GetEnvironmentVariable($testVar);
test_ok(!defined($removed), 'Environment variable removed');

# Test getting non-existent variable
my $nonExistent = System::Environment->GetEnvironmentVariable('NON_EXISTENT_VAR_XYZ');
test_ok(!defined($nonExistent), 'Non-existent variable returns undef');

# Test GetEnvironmentVariables
my $envVars = System::Environment->GetEnvironmentVariables();
test_ok(ref($envVars) eq 'HASH', 'GetEnvironmentVariables returns hash reference');
test_ok(keys %$envVars > 0, 'Environment variables hash is not empty');

# Test that PATH or similar exists (should be in any environment)
my $hasPath = exists($envVars->{'PATH'}) || exists($envVars->{'Path'});
test_ok($hasPath, 'Environment contains PATH variable');

# Test ExpandEnvironmentVariables
System::Environment->SetEnvironmentVariable('TEST_EXPAND_VAR', 'expanded');
my $expanded = System::Environment->ExpandEnvironmentVariables('Value: %TEST_EXPAND_VAR%');
test_ok($expanded->isa('System::String'), 'ExpandEnvironmentVariables returns System::String');
test_ok($expanded =~ /expanded/, 'Environment variable was expanded');

# Clean up test variable
System::Environment->SetEnvironmentVariable('TEST_EXPAND_VAR', undef);

# Test 11-20: System information
my $machineName = System::Environment->MachineName();
test_ok($machineName->isa('System::String'), 'MachineName returns System::String');
test_ok(length($machineName) > 0, 'MachineName is not empty');

my $userName = System::Environment->UserName();
test_ok(defined($userName), 'UserName returns defined value');
test_ok(length($userName) > 0, 'UserName is not empty');

my $userDomainName = System::Environment->UserDomainName();
test_ok($userDomainName->isa('System::String'), 'UserDomainName returns System::String');

my $osVersion = System::Environment->OSVersion();
test_ok($osVersion->isa('System::String'), 'OSVersion returns System::String');
test_ok(length($osVersion) > 0, 'OSVersion is not empty');

my $processorCount = System::Environment->ProcessorCount();
test_ok($processorCount >= 1, 'ProcessorCount is at least 1');
test_ok($processorCount <= 256, 'ProcessorCount is reasonable (<=256)');

my $is64BitProcess = System::Environment->Is64BitProcess();
test_ok(defined($is64BitProcess), 'Is64BitProcess returns defined value');
test_ok($is64BitProcess == 0 || $is64BitProcess == 1, 'Is64BitProcess returns boolean value');

my $is64BitOS = System::Environment->Is64BitOperatingSystem();
test_ok(defined($is64BitOS), 'Is64BitOperatingSystem returns defined value');

my $workingSet = System::Environment->WorkingSet();
test_ok($workingSet > 0, 'WorkingSet returns positive value');

# Test 21-30: Command line and directory operations
my $commandLine = System::Environment->CommandLine();
test_ok($commandLine->isa('System::String'), 'CommandLine returns System::String');
test_ok(length($commandLine) > 0, 'CommandLine is not empty');

my $commandLineArgs = System::Environment->GetCommandLineArgs();
test_ok($commandLineArgs->isa('System::Array'), 'GetCommandLineArgs returns System::Array');
test_ok($commandLineArgs->Length() > 0, 'Command line args array is not empty');

# Test CurrentDirectory
my $originalDir = System::Environment->CurrentDirectory();
test_ok($originalDir->isa('System::String'), 'CurrentDirectory returns System::String');
test_ok(length($originalDir) > 0, 'CurrentDirectory is not empty');

# Test changing current directory (use temp dir or current dir's parent)
my $parentDir = '..';
eval {
  System::Environment->CurrentDirectory($parentDir);
  my $newDir = System::Environment->CurrentDirectory();
  test_ok($newDir ne $originalDir, 'CurrentDirectory changed successfully');
  
  # Change back to original directory
  System::Environment->CurrentDirectory($originalDir);
  my $restoredDir = System::Environment->CurrentDirectory();
  test_ok($restoredDir eq $originalDir, 'CurrentDirectory restored');
} or do {
  test_ok(0, 'CurrentDirectory changed successfully');
  test_ok(0, 'CurrentDirectory restored');
};

my $newLine = System::Environment->NewLine();
test_ok(defined($newLine), 'NewLine returns defined value');
test_ok($newLine eq "\n" || $newLine eq "\r\n", 'NewLine is correct for platform');

my $tickCount = System::Environment->TickCount();
test_ok($tickCount >= 0, 'TickCount returns non-negative value');

my $userInteractive = System::Environment->UserInteractive();
test_ok(defined($userInteractive), 'UserInteractive returns defined value');

# Test 31-40: Special folder operations
eval {
  my $desktopPath = System::Environment->GetFolderPath(System::Environment::SpecialFolder::Desktop());
  test_ok(defined($desktopPath), 'GetFolderPath for Desktop returns defined value');
} or test_ok(0, 'GetFolderPath for Desktop returns defined value (not implemented for this OS)');

eval {
  my $documentsPath = System::Environment->GetFolderPath(System::Environment::SpecialFolder::MyDocuments());
  test_ok(defined($documentsPath), 'GetFolderPath for MyDocuments returns defined value');
} or test_ok(0, 'GetFolderPath for MyDocuments returns defined value (not implemented for this OS)');

# Test constants existence
test_ok(defined(&System::Environment::SpecialFolder::Desktop), 'SpecialFolder::Desktop constant exists');
test_ok(defined(&System::Environment::SpecialFolder::MyDocuments), 'SpecialFolder::MyDocuments constant exists');
test_ok(defined(&System::Environment::SpecialFolder::ApplicationData), 'SpecialFolder::ApplicationData constant exists');

test_ok(defined(&System::Environment::SpecialFolderOption::None), 'SpecialFolderOption::None constant exists');
test_ok(defined(&System::Environment::SpecialFolderOption::Create), 'SpecialFolderOption::Create constant exists');

test_ok(defined(&System::EnvironmentVariableTarget::Process), 'EnvironmentVariableTarget::Process constant exists');
test_ok(defined(&System::EnvironmentVariableTarget::User), 'EnvironmentVariableTarget::User constant exists');
test_ok(defined(&System::EnvironmentVariableTarget::Machine), 'EnvironmentVariableTarget::Machine constant exists');

# Test 41-50: Error handling and edge cases
test_exception(
  sub { System::Environment->GetEnvironmentVariable(undef); },
  'ArgumentNullException',
  'GetEnvironmentVariable with null name throws exception'
);

test_exception(
  sub { System::Environment->SetEnvironmentVariable(undef, 'value'); },
  'ArgumentNullException',
  'SetEnvironmentVariable with null name throws exception'
);

test_exception(
  sub { System::Environment->CurrentDirectory(undef); },
  'ArgumentNullException',
  'CurrentDirectory setter with null throws exception'
);

test_exception(
  sub { System::Environment->CurrentDirectory(''); },
  'ArgumentException',
  'CurrentDirectory setter with empty string throws exception'
);

test_exception(
  sub { System::Environment->CurrentDirectory('/non/existent/path/xyz123'); },
  'DirectoryNotFoundException',
  'CurrentDirectory setter with invalid path throws exception'
);

test_exception(
  sub { System::Environment->ExpandEnvironmentVariables(undef); },
  'ArgumentNullException',
  'ExpandEnvironmentVariables with null throws exception'
);

# Test Exit would terminate the program, so we just test it doesn't crash when we reference it
test_ok(defined(&System::Environment::Exit), 'Exit method exists');

# Test that internal _IsWindows method works
my $isWindows = System::Environment->_IsWindows();
test_ok(defined($isWindows), '_IsWindows returns defined value');
test_ok($isWindows == 0 || $isWindows == 1, '_IsWindows returns boolean value');

# Test CurrentManagedThreadId (might be 0 if threads not available)
my $threadId = System::Environment->CurrentManagedThreadId();
test_ok(defined($threadId), 'CurrentManagedThreadId returns defined value');
test_ok($threadId >= 0, 'CurrentManagedThreadId is non-negative');

# Test that various string methods return proper objects
my $testString = System::Environment->GetEnvironmentVariable('PATH') || 
                System::Environment->GetEnvironmentVariable('Path') ||
                System::Environment->MachineName();
test_ok($testString->isa('System::String'), 'String environment values are System::String objects');

# Test 51-60: Advanced system information and cross-platform behavior
my $systemDirectory = System::Environment->SystemDirectory();
test_ok(defined($systemDirectory), 'SystemDirectory returns defined value');
test_ok(length($systemDirectory) > 0, 'SystemDirectory is not empty');

my $systemPageSize = System::Environment->SystemPageSize();
test_ok($systemPageSize > 0, 'SystemPageSize returns positive value');
test_ok($systemPageSize >= 4096, 'SystemPageSize is reasonable (>=4KB)');

my $version = System::Environment->Version();
test_ok($version->isa('System::String'), 'Version returns System::String');
test_ok(length($version) > 0, 'Version is not empty');

# Test HasShutdownStarted (should be false during normal execution)
my $hasShutdown = System::Environment->HasShutdownStarted();
test_ok(defined($hasShutdown), 'HasShutdownStarted returns defined value');
test_ok($hasShutdown == 0, 'HasShutdownStarted is false during normal execution');

# Test ExitCode (should be 0 by default)
my $exitCode = System::Environment->ExitCode();
test_ok(defined($exitCode), 'ExitCode returns defined value');
test_ok($exitCode == 0, 'ExitCode is 0 by default');

# Test StackTrace
my $stackTrace = System::Environment->StackTrace();
test_ok(defined($stackTrace), 'StackTrace returns defined value');

# Test 61-70: Additional special folders and logical drives
eval {
    my $appDataPath = System::Environment->GetFolderPath(System::Environment::SpecialFolder::ApplicationData());
    test_ok(defined($appDataPath), 'GetFolderPath for ApplicationData returns defined value');
} or test_ok(0, 'GetFolderPath for ApplicationData returns defined value (not implemented for this OS)');

eval {
    my $tempPath = System::Environment->GetFolderPath(System::Environment::SpecialFolder::LocalApplicationData());
    test_ok(defined($tempPath), 'GetFolderPath for LocalApplicationData returns defined value');
} or test_ok(0, 'GetFolderPath for LocalApplicationData returns defined value (not implemented for this OS)');

# Test GetLogicalDrives
eval {
    my $drives = System::Environment->GetLogicalDrives();
    test_ok($drives->isa('System::Array'), 'GetLogicalDrives returns System::Array');
    test_ok($drives->Length() > 0, 'GetLogicalDrives returns non-empty array');
} or do {
    test_ok(0, 'GetLogicalDrives returns System::Array');
    test_ok(0, 'GetLogicalDrives returns non-empty array');
};

# Test FailFast method existence (don't actually call it as it would terminate)
test_ok(defined(&System::Environment::FailFast), 'FailFast method exists');

# Test multiple environment variable operations in sequence
System::Environment->SetEnvironmentVariable('TEST_MULTI_1', 'value1');
System::Environment->SetEnvironmentVariable('TEST_MULTI_2', 'value2');
System::Environment->SetEnvironmentVariable('TEST_MULTI_3', 'value3');

my $multi1 = System::Environment->GetEnvironmentVariable('TEST_MULTI_1');
my $multi2 = System::Environment->GetEnvironmentVariable('TEST_MULTI_2');
my $multi3 = System::Environment->GetEnvironmentVariable('TEST_MULTI_3');

test_ok($multi1 eq 'value1' && $multi2 eq 'value2' && $multi3 eq 'value3', 'Multiple environment variables handled correctly');

# Clean up multiple test variables
System::Environment->SetEnvironmentVariable('TEST_MULTI_1', undef);
System::Environment->SetEnvironmentVariable('TEST_MULTI_2', undef);
System::Environment->SetEnvironmentVariable('TEST_MULTI_3', undef);

# Test environment variable expansion with multiple variables
System::Environment->SetEnvironmentVariable('TEST_EXPAND_A', 'Hello');
System::Environment->SetEnvironmentVariable('TEST_EXPAND_B', 'World');
my $multiExpanded = System::Environment->ExpandEnvironmentVariables('%TEST_EXPAND_A% %TEST_EXPAND_B%!');
test_ok($multiExpanded =~ /Hello.*World/, 'Multiple environment variable expansion works');

# Clean up expansion test variables
System::Environment->SetEnvironmentVariable('TEST_EXPAND_A', undef);
System::Environment->SetEnvironmentVariable('TEST_EXPAND_B', undef);

# Test cross-platform detection methods
my $detectedWindows = System::Environment->_IsWindows();
test_ok(defined($detectedWindows), 'Cross-platform detection returns defined value');

# Test that platform-specific methods don't crash on other platforms
eval {
    my $proc_count = System::Environment->ProcessorCount();
    my $os_ver = System::Environment->OSVersion();
    my $machine = System::Environment->MachineName();
    test_ok($proc_count > 0 && defined($os_ver) && defined($machine), 'Platform-specific methods work across platforms');
} or test_ok(0, 'Platform-specific methods work across platforms');

# Test consistency of repeated calls
my $name1 = System::Environment->MachineName();
my $name2 = System::Environment->MachineName();
test_ok($name1 eq $name2, 'MachineName is consistent across calls');

my $proc1 = System::Environment->ProcessorCount();
my $proc2 = System::Environment->ProcessorCount();
test_ok($proc1 == $proc2, 'ProcessorCount is consistent across calls');

print "\n# System::Environment Tests completed: $tests_run\n";
print "# System::Environment Tests passed: $tests_passed\n";
print "# Pass rate: " . sprintf("%.1f%%", ($tests_passed / $tests_run) * 100) . "\n";

exit($tests_passed == $tests_run ? 0 : 1);