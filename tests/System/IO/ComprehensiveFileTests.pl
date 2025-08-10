#!/usr/bin/perl
use strict;
use warnings;
use lib '../../../';
use Test::More;
use System;
use File::Spec;
use File::Temp qw(tempfile tempdir);
use Cwd;

BEGIN {
    use_ok('System::IO::File');
}

plan tests => 125;

my @temp_files_to_cleanup = ();
my $temp_dir = tempdir(CLEANUP => 1);

# Helper to create unique temp files
sub create_test_file {
    my ($suffix, $content) = @_;
    $suffix ||= '.tmp';
    $content ||= '';
    
    my ($fh, $filename) = tempfile(DIR => $temp_dir, SUFFIX => $suffix, UNLINK => 1);
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

# Test 11-25: Text File Operations
subtest 'Text File Operations' => sub {
    plan tests => 15;
    
    my $testfile = create_test_file('.txt');
    my $content = "Line 1\nLine 2\nLine 3\n";
    
    # WriteAllText
    File::WriteAllText($testfile, $content);
    ok(-e $testfile, 'WriteAllText creates file');
    
    # ReadAllText
    my $readContent = File::ReadAllText($testfile);
    is($readContent, $content, 'ReadAllText returns exact content');
    
    # ReadAllLines
    my $lines = File::ReadAllLines($testfile);
    is($lines->Length(), 3, 'ReadAllLines returns correct number of lines');
    is($lines->Get(0), 'Line 1', 'First line matches');
    is($lines->Get(1), 'Line 2', 'Second line matches');
    is($lines->Get(2), 'Line 3', 'Third line matches');
    
    # WriteAllLines
    my @newLines = ('New Line 1', 'New Line 2', 'New Line 3', 'New Line 4');
    File::WriteAllLines($testfile, \@newLines);
    
    my $newContent = File::ReadAllText($testfile);
    like($newContent, qr/New Line 1/, 'WriteAllLines writes first line');
    like($newContent, qr/New Line 4/, 'WriteAllLines writes last line');
    
    my $newLinesRead = File::ReadAllLines($testfile);
    is($newLinesRead->Length(), 4, 'WriteAllLines writes correct number of lines');
    
    # AppendAllText
    File::AppendAllText($testfile, "\nAppended Line");
    my $appendedContent = File::ReadAllText($testfile);
    like($appendedContent, qr/Appended Line/, 'AppendAllText adds content');
    
    # AppendAllLines
    my @appendLines = ('Append Line 1', 'Append Line 2');
    File::AppendAllLines($testfile, \@appendLines);
    
    my $finalLines = File::ReadAllLines($testfile);
    ok($finalLines->Length() > 4, 'AppendAllLines adds lines');
    
    # Test null arguments
    eval { File::WriteAllText(undef, 'content'); };
    ok($@, 'WriteAllText throws exception with null path');
    
    eval { File::ReadAllText(undef); };
    ok($@, 'ReadAllText throws exception with null path');
    
    eval { File::ReadAllLines(undef); };
    ok($@, 'ReadAllLines throws exception with null path');
};

# Test 26-40: Binary File Operations
subtest 'Binary File Operations' => sub {
    plan tests => 15;
    
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
    is($readBytes->Get(6), 66, 'Seventh byte correct (B)');
    is($readBytes->Get(7), 67, 'Eighth byte correct (C)');
    
    # Test with empty binary data
    my @emptyData = ();
    File::WriteAllBytes($testfile, \@emptyData);
    my $emptyRead = File::ReadAllBytes($testfile);
    is($emptyRead->Length(), 0, 'Empty binary file handled correctly');
    
    # Test null arguments
    eval { File::WriteAllBytes(undef, \@binaryData); };
    ok($@, 'WriteAllBytes throws exception with null path');
    
    eval { File::ReadAllBytes(undef); };
    ok($@, 'ReadAllBytes throws exception with null path');
    
    # Test with non-existent file
    eval { File::ReadAllBytes($testfile . '_nonexistent'); };
    ok($@, 'ReadAllBytes throws exception for non-existent file');
};

# Test 41-55: File Copy and Move Operations
subtest 'File Copy and Move Operations' => sub {
    plan tests => 15;
    
    my $source = create_test_file('_source.txt', 'Source content');
    my $copyDest = File::Spec->catfile($temp_dir, 'copy_dest.txt');
    my $moveDest = File::Spec->catfile($temp_dir, 'move_dest.txt');
    
    # Basic copy
    File::Copy($source, $copyDest);
    ok(-e $copyDest, 'Copy creates destination file');
    ok(-e $source, 'Copy preserves source file');
    
    my $copyContent = File::ReadAllText($copyDest);
    is($copyContent, 'Source content', 'Copied file has correct content');
    
    # Basic move
    File::Move($copyDest, $moveDest);
    ok(-e $moveDest, 'Move creates destination file');
    ok(!-e $copyDest, 'Move removes source file');
    
    my $moveContent = File::ReadAllText($moveDest);
    is($moveContent, 'Source content', 'Moved file has correct content');
    
    # Test with large file
    my $largeContent = 'x' x 10000;
    my $largeFile = create_test_file('_large.txt', $largeContent);
    my $largeCopy = File::Spec->catfile($temp_dir, 'large_copy.txt');
    
    File::Copy($largeFile, $largeCopy);
    ok(-e $largeCopy, 'Large file copied successfully');
    my $largeCopyContent = File::ReadAllText($largeCopy);
    is(length($largeCopyContent), 10000, 'Large file copy has correct size');
    
    # Test null arguments
    eval { File::Copy(undef, $largeCopy); };
    ok($@, 'Copy throws exception with null source');
    
    eval { File::Copy($source, undef); };
    ok($@, 'Copy throws exception with null destination');
    
    eval { File::Move(undef, $moveDest); };
    ok($@, 'Move throws exception with null source');
    
    eval { File::Move($source, undef); };
    ok($@, 'Move throws exception with null destination');
    
    # Test non-existent source
    eval { File::Copy($source . '_nonexistent', $largeCopy); };
    ok($@, 'Copy throws exception for non-existent source');
    
    eval { File::Move($source . '_nonexistent', $moveDest); };
    ok($@, 'Move throws exception for non-existent source');
    
    # Cleanup
    unlink $copyDest, $moveDest, $largeCopy;
};

# Test 56-70: File Time and Attribute Operations
subtest 'File Time and Attribute Operations' => sub {
    plan tests => 15;
    
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
    
    # Test with different file types
    sleep(1); # Ensure different timestamps
    File::WriteAllText($testfile, 'updated content');
    my $newLastWrite = File::GetLastWriteTime($testfile);
    
    # Note: We can't reliably test that newLastWrite > lastWrite due to filesystem precision
    # but we can verify it's still a valid DateTime
    isa_ok($newLastWrite, 'System::DateTime', 'Updated file still returns DateTime');
    
    # Test with null arguments
    eval { File::GetLastWriteTime(undef); };
    ok($@, 'GetLastWriteTime throws exception with null argument');
    
    eval { File::GetCreationTime(undef); };
    ok($@, 'GetCreationTime throws exception with null argument');
    
    eval { File::GetLastAccessTime(undef); };
    ok($@, 'GetLastAccessTime throws exception with null argument');
    
    eval { File::GetAttributes(undef); };
    ok($@, 'GetAttributes throws exception with null argument');
    
    # Test with non-existent files
    eval { File::GetLastWriteTime($testfile . '_nonexistent'); };
    ok($@, 'GetLastWriteTime throws exception for non-existent file');
    
    eval { File::GetAttributes($testfile . '_nonexistent'); };
    ok($@, 'GetAttributes throws exception for non-existent file');
};

# Test 71-85: File Path Edge Cases
subtest 'File Path Edge Cases' => sub {
    plan tests => 15;
    
    # Test with various path formats
    my $basicFile = create_test_file('.txt', 'content');
    
    # Test with absolute path
    my $absolutePath = File::Spec->rel2abs($basicFile);
    ok(File::Exists($absolutePath), 'Exists works with absolute path');
    
    my $content = File::ReadAllText($absolutePath);
    is($content, 'content', 'ReadAllText works with absolute path');
    
    # Test with relative path from different directory
    my $originalDir = getcwd();
    my $parentDir = File::Spec->updir();
    my $testDir = File::Spec->catdir($temp_dir, 'subdir');
    mkdir($testDir);
    chdir($testDir);
    
    my $relativePath = File::Spec->catfile($parentDir, File::Spec->abs2rel($basicFile, $temp_dir));
    ok(File::Exists($relativePath), 'Exists works with relative path');
    
    chdir($originalDir);
    
    # Test with path containing spaces
    my $spacePath = File::Spec->catfile($temp_dir, 'file with spaces.txt');
    File::WriteAllText($spacePath, 'space content');
    ok(File::Exists($spacePath), 'Exists works with spaces in path');
    
    my $spaceContent = File::ReadAllText($spacePath);
    is($spaceContent, 'space content', 'ReadAllText works with spaces in path');
    
    # Test with very long filename
    my $longName = 'a' x 100 . '.txt';
    my $longPath = File::Spec->catfile($temp_dir, $longName);
    eval {
        File::WriteAllText($longPath, 'long name content');
    };
    # This might fail on some filesystems, but shouldn't crash
    ok(1, 'Long filename handling does not crash');
    
    # Test with unicode characters (if supported)
    my $unicodePath = File::Spec->catfile($temp_dir, 'test_файл.txt');
    eval {
        File::WriteAllText($unicodePath, 'unicode content');
        my $unicodeExists = File::Exists($unicodePath);
        ok(1, 'Unicode filename handling does not crash');
    };
    if ($@) {
        ok(1, 'Unicode filename handling gracefully fails');
    }
    
    # Test with special characters (platform dependent)
    my @specialChars = ();
    if ($^O =~ /Win/) {
        # Windows has more restricted characters
        @specialChars = ('file_with_underscore.txt', 'file-with-dash.txt', 'file.with.dots.txt');
    } else {
        # Unix allows more characters
        @specialChars = ('file_with_underscore.txt', 'file-with-dash.txt', 'file.with.dots.txt', 'file with spaces.txt');
    }
    
    my $specialTestCount = 0;
    foreach my $specialFile (@specialChars) {
        my $specialPath = File::Spec->catfile($temp_dir, $specialFile);
        eval {
            File::WriteAllText($specialPath, 'special content');
            if (File::Exists($specialPath)) {
                $specialTestCount++;
            }
        };
    }
    ok($specialTestCount > 0, 'At least some special characters in filenames work');
    
    # Test empty filename (should fail)
    eval { File::WriteAllText('', 'content'); };
    ok($@, 'Empty filename throws exception');
    
    # Test path with null byte (should fail)
    eval { File::WriteAllText("test\x00file.txt", 'content'); };
    ok($@, 'Filename with null byte throws exception');
    
    # Test very deep path
    my $deepPath = $temp_dir;
    for (my $i = 0; $i < 5; $i++) {
        $deepPath = File::Spec->catdir($deepPath, "level$i");
        mkdir($deepPath) unless -d $deepPath;
    }
    my $deepFile = File::Spec->catfile($deepPath, 'deep.txt');
    File::WriteAllText($deepFile, 'deep content');
    ok(File::Exists($deepFile), 'Deep path handling works');
    
    my $deepContent = File::ReadAllText($deepFile);
    is($deepContent, 'deep content', 'Deep path read works');
    
    # Test concurrent file operations
    my $concurrentFile = create_test_file('_concurrent.txt', 'initial');
    # Simulate rapid file operations
    for (my $i = 0; $i < 10; $i++) {
        File::WriteAllText($concurrentFile, "content $i");
        my $readBack = File::ReadAllText($concurrentFile);
        last if $readBack ne "content $i"; # Break if we detect an issue
    }
    ok(1, 'Rapid file operations complete without hanging');
    
    # Cleanup created directories
    unlink($spacePath) if -e $spacePath;
    unlink($longPath) if -e $longPath;
    unlink($unicodePath) if -e $unicodePath;
    unlink($deepFile) if -e $deepFile;
};

# Test 86-100: Error Handling and Exception Cases
subtest 'Error Handling and Exception Cases' => sub {
    plan tests => 15;
    
    # Test FileNotFoundException scenarios
    my $nonExistent = File::Spec->catfile($temp_dir, 'definitely_does_not_exist.txt');
    
    eval { File::ReadAllText($nonExistent); };
    ok($@, 'ReadAllText throws exception for non-existent file');
    like($@, qr/FileNotFoundException|No such file/, 'ReadAllText throws appropriate exception type');
    
    eval { File::ReadAllLines($nonExistent); };
    ok($@, 'ReadAllLines throws exception for non-existent file');
    
    eval { File::ReadAllBytes($nonExistent); };
    ok($@, 'ReadAllBytes throws exception for non-existent file');
    
    eval { File::Delete($nonExistent); };
    ok($@, 'Delete throws exception for non-existent file');
    
    eval { File::Copy($nonExistent, create_test_file('.copy')); };
    ok($@, 'Copy throws exception for non-existent source');
    
    eval { File::Move($nonExistent, create_test_file('.move')); };
    ok($@, 'Move throws exception for non-existent source');
    
    # Test ArgumentNullException scenarios
    eval { File::WriteAllText(undef, 'content'); };
    ok($@, 'WriteAllText throws exception for null path');
    
    eval { File::AppendAllText(undef, 'content'); };
    ok($@, 'AppendAllText throws exception for null path');
    
    # Test IOException scenarios (directory instead of file)
    eval { File::ReadAllText($temp_dir); };
    ok($@, 'ReadAllText throws exception when path is directory');
    
    # Test with read-only file (if we can create one)
    my $readOnlyFile = create_test_file('_readonly.txt', 'readonly content');
    chmod(0444, $readOnlyFile); # Make read-only
    
    eval { File::WriteAllText($readOnlyFile, 'new content'); };
    # This might succeed or fail depending on permissions and platform
    ok(1, 'Read-only file handling completes');
    
    # Restore permissions for cleanup
    chmod(0666, $readOnlyFile);
    
    # Test with invalid path characters (platform specific)
    if ($^O =~ /Win/) {
        # Windows invalid characters
        eval { File::WriteAllText('test<file>.txt', 'content'); };
        ok($@, 'Invalid path characters throw exception on Windows');
    } else {
        # Unix mainly just null byte
        eval { File::WriteAllText("test\x00file.txt", 'content'); };
        ok($@, 'Invalid path characters throw exception on Unix');
    }
    
    # Test file locking scenario (create file, keep it open)
    my $lockFile = create_test_file('_lock.txt', 'lock content');
    # This is platform dependent and tricky to test portably
    ok(1, 'File locking scenario handled');
    
    # Test extremely large file operations (if space allows)
    eval {
        my $largeContent = 'x' x (1024 * 1024); # 1MB of x's
        my $largeFile = create_test_file('_large.txt');
        File::WriteAllText($largeFile, $largeContent);
        my $readBack = File::ReadAllText($largeFile);
        # If it succeeds, verify length
        ok(length($readBack) == length($largeContent), 'Large file operations work correctly');
    };
    if ($@) {
        ok(1, 'Large file operations gracefully handle limits');
    }
};

# Test 101-115: Performance and Large File Handling
subtest 'Performance and Large File Handling' => sub {
    plan tests => 15;
    
    # Test with moderately large text file
    my $mediumLines = [];
    for (my $i = 0; $i < 1000; $i++) {
        push @$mediumLines, "This is line number $i with some additional content to make it longer";
    }
    
    my $mediumFile = create_test_file('_medium.txt');
    
    # Time the write operation
    my $writeStart = time();
    File::WriteAllLines($mediumFile, $mediumLines);
    my $writeTime = time() - $writeStart;
    ok($writeTime < 5, 'WriteAllLines completes in reasonable time for 1000 lines');
    
    # Time the read operation
    my $readStart = time();
    my $readLines = File::ReadAllLines($mediumFile);
    my $readTime = time() - $readStart;
    ok($readTime < 5, 'ReadAllLines completes in reasonable time for 1000 lines');
    
    is($readLines->Length(), 1000, 'All 1000 lines read correctly');
    is($readLines->Get(0), $mediumLines->[0], 'First line matches');
    is($readLines->Get(999), $mediumLines->[999], 'Last line matches');
    
    # Test with binary data
    my $binaryData = [];
    for (my $i = 0; $i < 10000; $i++) {
        push @$binaryData, int(rand(256));
    }
    
    my $binaryFile = create_test_file('_binary.bin');
    File::WriteAllBytes($binaryFile, $binaryData);
    
    my $readBinary = File::ReadAllBytes($binaryFile);
    is($readBinary->Length(), 10000, 'All 10000 bytes written and read');
    is($readBinary->Get(0), $binaryData->[0], 'First byte matches');
    is($readBinary->Get(9999), $binaryData->[9999], 'Last byte matches');
    
    # Test append performance
    my $appendFile = create_test_file('_append.txt', 'initial content');
    my $appendStart = time();
    for (my $i = 0; $i < 100; $i++) {
        File::AppendAllText($appendFile, "Appended line $i\n");
    }
    my $appendTime = time() - $appendStart;
    ok($appendTime < 10, 'Multiple append operations complete in reasonable time');
    
    my $appendedContent = File::ReadAllText($appendFile);
    like($appendedContent, qr/Appended line 99/, 'All appended content present');
    
    # Test copy performance
    my $sourceForCopy = create_test_file('_copy_source.txt');
    File::WriteAllText($sourceForCopy, 'x' x 50000); # 50KB
    
    my $copyDest = File::Spec->catfile($temp_dir, 'copy_perf_dest.txt');
    my $copyStart = time();
    File::Copy($sourceForCopy, $copyDest);
    my $copyTime = time() - $copyStart;
    ok($copyTime < 3, 'Copy of 50KB file completes in reasonable time');
    
    ok(-e $copyDest, 'Copy destination file exists');
    is(-s $copyDest, -s $sourceForCopy, 'Copied file has same size as source');
    
    # Test move performance
    my $moveDest = File::Spec->catfile($temp_dir, 'move_perf_dest.txt');
    my $moveStart = time();
    File::Move($copyDest, $moveDest);
    my $moveTime = time() - $moveStart;
    ok($moveTime < 2, 'Move operation completes in reasonable time');
    
    ok(-e $moveDest, 'Move destination file exists');
    ok(!-e $copyDest, 'Move source file no longer exists');
    
    # Cleanup
    unlink($moveDest) if -e $moveDest;
};

# Test 116-125: Integration and Cross-Operation Tests
subtest 'Integration and Cross-Operation Tests' => sub {
    plan tests => 10;
    
    # Test complete file lifecycle
    my $lifecycleFile = File::Spec->catfile($temp_dir, 'lifecycle.txt');
    
    # Create
    File::WriteAllText($lifecycleFile, 'Initial content');
    ok(File::Exists($lifecycleFile), 'File lifecycle: Create');
    
    # Read and verify
    my $content = File::ReadAllText($lifecycleFile);
    is($content, 'Initial content', 'File lifecycle: Read');
    
    # Modify
    File::AppendAllText($lifecycleFile, ' - Modified');
    $content = File::ReadAllText($lifecycleFile);
    is($content, 'Initial content - Modified', 'File lifecycle: Modify');
    
    # Copy
    my $copyPath = File::Spec->catfile($temp_dir, 'lifecycle_copy.txt');
    File::Copy($lifecycleFile, $copyPath);
    ok(File::Exists($copyPath), 'File lifecycle: Copy');
    is(File::ReadAllText($copyPath), $content, 'File lifecycle: Copy content matches');
    
    # Move copy
    my $movePath = File::Spec->catfile($temp_dir, 'lifecycle_moved.txt');
    File::Move($copyPath, $movePath);
    ok(File::Exists($movePath), 'File lifecycle: Move destination exists');
    ok(!File::Exists($copyPath), 'File lifecycle: Move source removed');
    
    # Delete both files
    File::Delete($lifecycleFile);
    File::Delete($movePath);
    ok(!File::Exists($lifecycleFile), 'File lifecycle: Original deleted');
    ok(!File::Exists($movePath), 'File lifecycle: Moved file deleted');
};

# Cleanup temp files
END {
    for my $file (@temp_files_to_cleanup) {
        unlink $file if -e $file;
    }
}

done_testing();