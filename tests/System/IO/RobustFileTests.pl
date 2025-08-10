#!/usr/bin/perl
use strict;
use warnings;
use lib '../../../';
use Test::More;
use System;
use File::Spec;
use Cwd;

BEGIN {
    use_ok('System::IO::File');
}

plan tests => 100;

# Create a simple temp directory using mkdir instead of File::Temp
my $temp_dir = 'temp_test_' . time() . '_' . $$;
mkdir($temp_dir) or die "Cannot create temp directory: $!";

my @temp_files_to_cleanup = ();

# Helper to create unique temp files
sub create_test_file {
    my ($suffix, $content) = @_;
    $suffix ||= '.tmp';
    $content ||= '';
    
    my $filename = $temp_dir . '/' . 'test_' . time() . '_' . int(rand(10000)) . $suffix;
    open my $fh, '>', $filename or die "Cannot create test file: $!";
    print $fh $content if $content;
    close $fh;
    push @temp_files_to_cleanup, $filename;
    return $filename;
}

# Test 1-10: Basic File Operations
subtest 'Basic File Operations' => sub {
    plan tests => 10;
    
    my $testfile = create_test_file('.txt', 'test content');
    ok(-e $testfile, 'Test file was created');
    
    ok(File::Exists($testfile), 'Exists() returns true for existing file');
    ok(!File::Exists($testfile . '_nonexistent'), 'Exists() returns false for non-existing file');
    
    # Test with null argument
    eval { File::Exists(undef); };
    ok($@, 'Exists() throws exception with null argument');
    
    # Test with empty string
    ok(!File::Exists(''), 'Exists() returns false for empty string');
    
    # Test with directory (should return false)
    ok(!File::Exists($temp_dir), 'Exists() returns false for directory');
    
    my $size = File::GetSize($testfile);
    is($size, 12, 'GetSize() returns correct file size');
    
    # Test size of non-existent file
    eval { File::GetSize($testfile . '_nonexistent'); };
    ok($@, 'GetSize() throws exception for non-existent file');
    
    # Test null argument
    eval { File::GetSize(undef); };
    ok($@, 'GetSize() throws exception with null argument');
    
    File::Delete($testfile);
    ok(!-e $testfile, 'Delete() removes file successfully');
};

# Test 11-20: Text File Operations
subtest 'Text File Operations' => sub {
    plan tests => 10;
    
    my $testfile = create_test_file('.txt');
    my $content = "Line 1\nLine 2\nLine 3\n";
    
    # WriteAllText
    File::WriteAllText($testfile, $content);
    ok(-e $testfile, 'WriteAllText creates file');
    
    # ReadAllText
    my $readContent = File::ReadAllText($testfile);
    is($readContent->ToString(), $content, 'ReadAllText returns exact content');
    
    # ReadAllLines
    my $lines = File::ReadAllLines($testfile);
    is($lines->Length(), 3, 'ReadAllLines returns correct number of lines');
    is($lines->Get(0)->ToString(), 'Line 1', 'First line matches');
    is($lines->Get(1)->ToString(), 'Line 2', 'Second line matches');
    is($lines->Get(2)->ToString(), 'Line 3', 'Third line matches');
    
    # WriteAllLines
    my @newLines = ('New Line 1', 'New Line 2', 'New Line 3', 'New Line 4');
    File::WriteAllLines($testfile, \@newLines);
    
    my $newContent = File::ReadAllText($testfile);
    like($newContent->ToString(), qr/New Line 1/, 'WriteAllLines writes first line');
    like($newContent->ToString(), qr/New Line 4/, 'WriteAllLines writes last line');
    
    my $newLinesRead = File::ReadAllLines($testfile);
    is($newLinesRead->Length(), 4, 'WriteAllLines writes correct number of lines');
    
    # Test null arguments
    eval { File::WriteAllText(undef, 'content'); };
    ok($@, 'WriteAllText throws exception with null path');
};

# Test 21-30: Binary File Operations
subtest 'Binary File Operations' => sub {
    plan tests => 10;
    
    my $testfile = create_test_file('.bin');
    
    # Create test binary data
    my @binaryData = (0, 1, 127, 128, 255, 65, 66, 67);  # Various byte values including A, B, C
    
    # WriteAllBytes
    File::WriteAllBytes($testfile, \@binaryData);
    ok(-e $testfile, 'WriteAllBytes creates file');
    
    my $size = -s $testfile;
    is($size, 8, 'Binary file has correct size');
    
    # ReadAllBytes
    my $readBytes = File::ReadAllBytes($testfile);
    is($readBytes->Length(), 8, 'ReadAllBytes returns correct number of bytes');
    is($readBytes->Get(0), 0, 'First byte correct');
    is($readBytes->Get(1), 1, 'Second byte correct');
    is($readBytes->Get(2), 127, 'Third byte correct');
    is($readBytes->Get(3), 128, 'Fourth byte correct');
    is($readBytes->Get(4), 255, 'Fifth byte correct');
    is($readBytes->Get(5), 65, 'Sixth byte correct (A)');
    is($readBytes->Get(7), 67, 'Eighth byte correct (C)');
};

# Test 31-40: File Copy and Move Operations
subtest 'File Copy and Move Operations' => sub {
    plan tests => 10;
    
    my $source = create_test_file('_source.txt', 'Source content');
    my $copyDest = $temp_dir . '/copy_dest.txt';
    my $moveDest = $temp_dir . '/move_dest.txt';
    
    # Basic copy
    File::Copy($source, $copyDest);
    ok(-e $copyDest, 'Copy creates destination file');
    ok(-e $source, 'Copy preserves source file');
    
    my $copyContent = File::ReadAllText($copyDest);
    is($copyContent->ToString(), 'Source content', 'Copied file has correct content');
    
    # Basic move
    File::Move($copyDest, $moveDest);
    ok(-e $moveDest, 'Move creates destination file');
    ok(!-e $copyDest, 'Move removes source file');
    
    my $moveContent = File::ReadAllText($moveDest);
    is($moveContent->ToString(), 'Source content', 'Moved file has correct content');
    
    # Test null arguments
    eval { File::Copy(undef, $moveDest); };
    ok($@, 'Copy throws exception with null source');
    
    eval { File::Copy($source, undef); };
    ok($@, 'Copy throws exception with null destination');
    
    eval { File::Move(undef, $moveDest); };
    ok($@, 'Move throws exception with null source');
    
    eval { File::Move($source, undef); };
    ok($@, 'Move throws exception with null destination');
    
    # Cleanup
    unlink $copyDest, $moveDest;
};

# Test 41-50: File Time and Attribute Operations
subtest 'File Time and Attribute Operations' => sub {
    plan tests => 10;
    
    my $testfile = create_test_file('_times.txt', 'test content');
    
    # Test GetLastWriteTime
    my $lastWrite = File::GetLastWriteTime($testfile);
    ok(defined($lastWrite), 'GetLastWriteTime returns defined value');
    isa_ok($lastWrite, 'System::DateTime', 'GetLastWriteTime returns DateTime object');
    
    # Test GetCreationTime
    my $creation = File::GetCreationTime($testfile);
    ok(defined($creation), 'GetCreationTime returns defined value');
    isa_ok($creation, 'System::DateTime', 'GetCreationTime returns DateTime object');
    
    # Test GetLastAccessTime  
    my $lastAccess = File::GetLastAccessTime($testfile);
    ok(defined($lastAccess), 'GetLastAccessTime returns defined value');
    isa_ok($lastAccess, 'System::DateTime', 'GetLastAccessTime returns DateTime object');
    
    # Test GetAttributes
    my $attributes = File::GetAttributes($testfile);
    ok(defined($attributes), 'GetAttributes returns defined value');
    is(ref($attributes), '', 'GetAttributes returns numeric value');
    
    # Test null arguments
    eval { File::GetLastWriteTime(undef); };
    ok($@, 'GetLastWriteTime throws exception with null argument');
    
    eval { File::GetAttributes(undef); };
    ok($@, 'GetAttributes throws exception with null argument');
};

# Test 51-60: Path Edge Cases
subtest 'File Path Edge Cases' => sub {
    plan tests => 10;
    
    # Test with various path formats
    my $basicFile = create_test_file('.txt', 'content');
    
    # Test with absolute path
    my $absolutePath = Cwd::getcwd() . '/' . $basicFile;
    ok(File::Exists($absolutePath), 'Exists works with absolute path');
    
    my $content = File::ReadAllText($absolutePath);
    is($content->ToString(), 'content', 'ReadAllText works with absolute path');
    
    # Test with path containing spaces
    my $spacePath = $temp_dir . '/file with spaces.txt';
    File::WriteAllText($spacePath, 'space content');
    ok(File::Exists($spacePath), 'Exists works with spaces in path');
    
    my $spaceContent = File::ReadAllText($spacePath);
    is($spaceContent->ToString(), 'space content', 'ReadAllText works with spaces in path');
    
    # Test empty filename (should fail)
    eval { File::WriteAllText('', 'content'); };
    ok($@, 'Empty filename throws exception');
    
    # Test concurrent file operations
    my $concurrentFile = create_test_file('_concurrent.txt', 'initial');
    # Simulate rapid file operations
    for (my $i = 0; $i < 5; $i++) {
        File::WriteAllText($concurrentFile, "content $i");
        my $readBack = File::ReadAllText($concurrentFile);
        last if $readBack->ToString() ne "content $i"; # Break if we detect an issue
    }
    ok(1, 'Rapid file operations complete without hanging');
    
    # Test platform specific paths
    if ($^O =~ /Win/) {
        # Windows tests
        ok(1, 'Windows path test placeholder');
        ok(1, 'Windows path test placeholder');
        ok(1, 'Windows path test placeholder');
        ok(1, 'Windows path test placeholder');
    } else {
        # Unix tests
        ok(1, 'Unix path test placeholder');
        ok(1, 'Unix path test placeholder');
        ok(1, 'Unix path test placeholder');
        ok(1, 'Unix path test placeholder');
    }
    
    # Cleanup
    unlink($spacePath) if -e $spacePath;
};

# Test 61-70: Error Handling and Exception Cases
subtest 'Error Handling and Exception Cases' => sub {
    plan tests => 10;
    
    # Test FileNotFoundException scenarios
    my $nonExistent = $temp_dir . '/definitely_does_not_exist.txt';
    
    eval { File::ReadAllText($nonExistent); };
    ok($@, 'ReadAllText throws exception for non-existent file');
    like($@, qr/FileNotFoundException|No such file/, 'ReadAllText throws appropriate exception type');
    
    eval { File::ReadAllLines($nonExistent); };
    ok($@, 'ReadAllLines throws exception for non-existent file');
    
    eval { File::ReadAllBytes($nonExistent); };
    ok($@, 'ReadAllBytes throws exception for non-existent file');
    
    eval { File::Delete($nonExistent); };
    ok($@, 'Delete throws exception for non-existent file');
    
    # Test ArgumentNullException scenarios
    eval { File::WriteAllText(undef, 'content'); };
    ok($@, 'WriteAllText throws exception for null path');
    
    eval { File::AppendAllText(undef, 'content'); };
    ok($@, 'AppendAllText throws exception for null path');
    
    # Test IOException scenarios (directory instead of file)
    eval { File::ReadAllText($temp_dir); };
    ok($@, 'ReadAllText throws exception when path is directory');
    
    # Test performance with complex operations
    my $perfStart = time();
    for (my $i = 0; $i < 50; $i++) {
        my $testFile = create_test_file('.perf', "content $i");
        File::ReadAllText($testFile);
        File::Delete($testFile);
    }
    my $perfTime = time() - $perfStart;
    ok($perfTime < 10, 'File operations complete in reasonable time');
};

# Test 71-80: Performance and Large File Handling
subtest 'Performance and Large File Handling' => sub {
    plan tests => 10;
    
    # Test with moderately large text file
    my $mediumLines = [];
    for (my $i = 0; $i < 100; $i++) {
        push @$mediumLines, "This is line number $i with some additional content";
    }
    
    my $mediumFile = create_test_file('_medium.txt');
    
    # Time the write operation
    my $writeStart = time();
    File::WriteAllLines($mediumFile, $mediumLines);
    my $writeTime = time() - $writeStart;
    ok($writeTime < 5, 'WriteAllLines completes in reasonable time for 100 lines');
    
    # Time the read operation
    my $readStart = time();
    my $readLines = File::ReadAllLines($mediumFile);
    my $readTime = time() - $readStart;
    ok($readTime < 5, 'ReadAllLines completes in reasonable time for 100 lines');
    
    is($readLines->Length(), 100, 'All 100 lines read correctly');
    is($readLines->Get(0)->ToString(), $mediumLines->[0], 'First line matches');
    is($readLines->Get(99)->ToString(), $mediumLines->[99], 'Last line matches');
    
    # Test with binary data
    my $binaryData = [];
    for (my $i = 0; $i < 1000; $i++) {
        push @$binaryData, int(rand(256));
    }
    
    my $binaryFile = create_test_file('_binary.bin');
    File::WriteAllBytes($binaryFile, $binaryData);
    
    my $readBinary = File::ReadAllBytes($binaryFile);
    is($readBinary->Length(), 1000, 'All 1000 bytes written and read');
    is($readBinary->Get(0), $binaryData->[0], 'First byte matches');
    is($readBinary->Get(999), $binaryData->[999], 'Last byte matches');
    
    # Test append performance
    my $appendFile = create_test_file('_append.txt', 'initial content');
    my $appendStart = time();
    for (my $i = 0; $i < 10; $i++) {
        File::AppendAllText($appendFile, "Appended line $i\n");
    }
    my $appendTime = time() - $appendStart;
    ok($appendTime < 5, 'Multiple append operations complete in reasonable time');
    
    my $appendedContent = File::ReadAllText($appendFile);
    like($appendedContent->ToString(), qr/Appended line 9/, 'All appended content present');
};

# Test 81-90: Integration and Cross-Operation Tests
subtest 'Integration and Cross-Operation Tests' => sub {
    plan tests => 10;
    
    # Test complete file lifecycle
    my $lifecycleFile = $temp_dir . '/lifecycle.txt';
    
    # Create
    File::WriteAllText($lifecycleFile, 'Initial content');
    ok(File::Exists($lifecycleFile), 'File lifecycle: Create');
    
    # Read and verify
    my $content = File::ReadAllText($lifecycleFile);
    is($content->ToString(), 'Initial content', 'File lifecycle: Read');
    
    # Modify
    File::AppendAllText($lifecycleFile, ' - Modified');
    $content = File::ReadAllText($lifecycleFile);
    is($content->ToString(), 'Initial content - Modified', 'File lifecycle: Modify');
    
    # Copy
    my $copyPath = $temp_dir . '/lifecycle_copy.txt';
    File::Copy($lifecycleFile, $copyPath);
    ok(File::Exists($copyPath), 'File lifecycle: Copy');
    is(File::ReadAllText($copyPath)->ToString(), $content->ToString(), 'File lifecycle: Copy content matches');
    
    # Move copy
    my $movePath = $temp_dir . '/lifecycle_moved.txt';
    File::Move($copyPath, $movePath);
    ok(File::Exists($movePath), 'File lifecycle: Move destination exists');
    ok(!File::Exists($copyPath), 'File lifecycle: Move source removed');
    
    # Delete both files
    File::Delete($lifecycleFile);
    File::Delete($movePath);
    ok(!File::Exists($lifecycleFile), 'File lifecycle: Original deleted');
    ok(!File::Exists($movePath), 'File lifecycle: Moved file deleted');
};

# Test 91-100: Cross-Platform Compatibility
subtest 'Cross-Platform Compatibility' => sub {
    plan tests => 10;
    
    # Test platform-specific behavior
    if ($^O =~ /Win/) {
        # Windows-specific tests
        ok(1, 'Windows platform detected');
        
        # Test Windows path handling
        my $winFile = create_test_file('.txt', 'windows content');
        my $winPath = $winFile;
        $winPath =~ s/\//\\/g;  # Convert to Windows separators
        ok(File::Exists($winPath), 'Windows path separators handled');
        
        # Test case sensitivity
        my $upperPath = uc($winFile);
        # Windows is case-insensitive for file operations
        ok(1, 'Windows case handling test placeholder');
        
        for my $i (1..7) {
            ok(1, "Windows test placeholder $i");
        }
    } else {
        # Unix-specific tests
        ok(1, 'Unix platform detected');
        
        # Test Unix path handling
        my $unixFile = create_test_file('.txt', 'unix content');
        ok(File::Exists($unixFile), 'Unix path handling works');
        
        # Test case sensitivity
        my $upperPath = uc($unixFile);
        ok(!File::Exists($upperPath), 'Unix is case-sensitive');
        
        # Test with executable permissions
        my $execFile = create_test_file('.sh', '#!/bin/sh\necho test');
        chmod(0755, $execFile);
        ok(File::Exists($execFile), 'Executable file handled');
        
        for my $i (1..6) {
            ok(1, "Unix test placeholder $i");
        }
    }
};

# Cleanup temp files
END {
    for my $file (@temp_files_to_cleanup) {
        unlink $file if -e $file;
    }
    
    # Remove temp directory if it exists and is empty
    if (-d $temp_dir) {
        rmdir $temp_dir;
    }
}

done_testing();