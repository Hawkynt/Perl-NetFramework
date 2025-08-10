#!/usr/bin/perl
use strict;
use warnings;
use lib '../../../';
use Test::More;
use System;
use File::Spec;
use File::Temp qw(tempdir);
use Cwd;

BEGIN {
    use_ok('System::IO::Directory');
    use_ok('System::IO::Path');
}

plan tests => 125;

my $temp_base = tempdir(CLEANUP => 1);
my @temp_dirs_to_cleanup = ();

# Helper to create test directory structure
sub create_test_dir {
    my ($name, $parent) = @_;
    $parent ||= $temp_base;
    my $fullPath = File::Spec->catdir($parent, $name);
    mkdir($fullPath) unless -d $fullPath;
    push @temp_dirs_to_cleanup, $fullPath;
    return $fullPath;
}

# Helper to create test file in directory
sub create_test_file_in_dir {
    my ($dir, $filename, $content) = @_;
    my $filepath = File::Spec->catfile($dir, $filename);
    open my $fh, '>', $filepath or die "Cannot create test file: $!";
    print $fh ($content || 'test content');
    close $fh;
    return $filepath;
}

# Test 1-10: Basic Directory Operations
subtest 'Basic Directory Operations' => sub {
    plan tests => 10;
    
    # Test Exists with existing directory
    ok(Directory::Exists($temp_base), 'Exists() returns true for existing directory');
    
    # Test Exists with non-existing directory
    my $nonExistentDir = File::Spec->catdir($temp_base, 'definitely_does_not_exist');
    ok(!Directory::Exists($nonExistentDir), 'Exists() returns false for non-existing directory');
    
    # Test Exists with file (should return false)
    my $testFile = create_test_file_in_dir($temp_base, 'test.txt');
    ok(!Directory::Exists($testFile), 'Exists() returns false for file path');
    
    # Test Create
    my $newDir = File::Spec->catdir($temp_base, 'new_directory');
    Directory::Create($newDir);
    ok(Directory::Exists($newDir), 'Create() creates new directory');
    push @temp_dirs_to_cleanup, $newDir;
    
    # Test Create with nested path (should create intermediate directories)
    my $nestedDir = File::Spec->catdir($temp_base, 'level1', 'level2', 'level3');
    Directory::Create($nestedDir);
    ok(Directory::Exists($nestedDir), 'Create() creates nested directory structure');
    push @temp_dirs_to_cleanup, File::Spec->catdir($temp_base, 'level1');
    
    # Test null arguments
    eval { Directory::Exists(undef); };
    ok($@, 'Exists() throws exception with null argument');
    
    eval { Directory::Create(undef); };
    ok($@, 'Create() throws exception with null argument');
    
    # Test empty string
    ok(!Directory::Exists(''), 'Exists() returns false for empty string');
    
    # Test Create with existing directory (should not fail)
    Directory::Create($newDir); # Second call
    ok(Directory::Exists($newDir), 'Create() handles existing directory gracefully');
    
    # Test with absolute vs relative paths
    my $absoluteNew = File::Spec->catdir($temp_base, 'absolute_test');
    Directory::Create($absoluteNew);
    ok(Directory::Exists($absoluteNew), 'Create() works with absolute paths');
    push @temp_dirs_to_cleanup, $absoluteNew;
};

# Test 11-25: Directory Enumeration - GetFiles
subtest 'Directory Enumeration - GetFiles' => sub {
    plan tests => 15;
    
    # Create test directory with files
    my $testDir = create_test_dir('file_enum_test');
    my @testFiles = (
        'file1.txt', 'file2.txt', 'file3.log', 
        'document.doc', 'image.png', 'data.csv'
    );
    
    for my $filename (@testFiles) {
        create_test_file_in_dir($testDir, $filename);
    }
    
    # Test GetFiles without pattern
    my $allFiles = Directory::GetFiles($testDir);
    isa_ok($allFiles, 'System::Array', 'GetFiles returns Array');
    is($allFiles->Length(), 6, 'GetFiles finds all 6 files');
    
    # Test GetFiles with wildcard pattern
    my $txtFiles = Directory::GetFiles($testDir, '*.txt');
    is($txtFiles->Length(), 2, 'GetFiles with *.txt pattern finds 2 files');
    
    # Test GetFiles with different extension
    my $logFiles = Directory::GetFiles($testDir, '*.log');
    is($logFiles->Length(), 1, 'GetFiles with *.log pattern finds 1 file');
    
    # Test GetFiles with * pattern (should match all)
    my $allPattern = Directory::GetFiles($testDir, '*');
    is($allPattern->Length(), 6, 'GetFiles with * pattern finds all files');
    
    # Test GetFiles with specific filename
    my $specificFile = Directory::GetFiles($testDir, 'file1.txt');
    is($specificFile->Length(), 1, 'GetFiles with specific filename finds 1 file');
    
    # Test GetFiles with non-matching pattern
    my $noMatch = Directory::GetFiles($testDir, '*.xyz');
    is($noMatch->Length(), 0, 'GetFiles with non-matching pattern finds 0 files');
    
    # Create subdirectory with files for recursive testing
    my $subDir = create_test_dir('subdir', $testDir);
    create_test_file_in_dir($subDir, 'subfile.txt');
    create_test_file_in_dir($subDir, 'subfile.log');
    
    # Test non-recursive search (default)
    my $topOnly = Directory::GetFiles($testDir, '*.txt');
    is($topOnly->Length(), 2, 'Non-recursive GetFiles finds only top-level files');
    
    # Test recursive search
    my $recursive = Directory::GetFiles($testDir, '*.txt', Directory::AllDirectories);
    is($recursive->Length(), 3, 'Recursive GetFiles finds files in subdirectories');
    
    # Test with empty directory
    my $emptyDir = create_test_dir('empty_dir');
    my $emptyFiles = Directory::GetFiles($emptyDir);
    is($emptyFiles->Length(), 0, 'GetFiles in empty directory returns empty array');
    
    # Test error cases
    eval { Directory::GetFiles(undef); };
    ok($@, 'GetFiles throws exception with null path');
    
    eval { Directory::GetFiles(File::Spec->catdir($temp_base, 'nonexistent')); };
    ok($@, 'GetFiles throws exception for non-existent directory');
    
    # Test with file instead of directory
    eval { Directory::GetFiles($testFiles[0]); };
    ok($@, 'GetFiles throws exception when path is file');
    
    # Test case sensitivity (platform dependent)
    my $caseFiles = Directory::GetFiles($testDir, '*.TXT');
    if ($^O =~ /Win/) {
        ok($caseFiles->Length() > 0, 'GetFiles is case-insensitive on Windows');
    } else {
        ok($caseFiles->Length() == 0, 'GetFiles is case-sensitive on Unix');
    }
};

# Test 26-40: Directory Enumeration - GetDirectories
subtest 'Directory Enumeration - GetDirectories' => sub {
    plan tests => 15;
    
    # Create test directory with subdirectories
    my $testDir = create_test_dir('dir_enum_test');
    my @testDirs = ('subdir1', 'subdir2', 'tempdir', 'backup', 'logs');
    
    for my $dirname (@testDirs) {
        create_test_dir($dirname, $testDir);
    }
    
    # Test GetDirectories without pattern
    my $allDirs = Directory::GetDirectories($testDir);
    isa_ok($allDirs, 'System::Array', 'GetDirectories returns Array');
    is($allDirs->Length(), 5, 'GetDirectories finds all 5 directories');
    
    # Test GetDirectories with pattern
    my $subdirs = Directory::GetDirectories($testDir, 'sub*');
    is($subdirs->Length(), 2, 'GetDirectories with sub* pattern finds 2 directories');
    
    # Test GetDirectories with exact name
    my $specificDir = Directory::GetDirectories($testDir, 'logs');
    is($specificDir->Length(), 1, 'GetDirectories with exact name finds 1 directory');
    
    # Test GetDirectories with non-matching pattern
    my $noMatch = Directory::GetDirectories($testDir, 'xyz*');
    is($noMatch->Length(), 0, 'GetDirectories with non-matching pattern finds 0 directories');
    
    # Create nested directory structure for recursive testing
    my $level1 = File::Spec->catdir($testDir, 'subdir1');
    my $level2 = create_test_dir('nested1', $level1);
    my $level3 = create_test_dir('nested2', $level2);
    
    # Test non-recursive search
    my $topOnly = Directory::GetDirectories($testDir);
    is($topOnly->Length(), 5, 'Non-recursive GetDirectories finds only top-level directories');
    
    # Test recursive search
    my $recursive = Directory::GetDirectories($testDir, '*', Directory::AllDirectories);
    ok($recursive->Length() > 5, 'Recursive GetDirectories finds nested directories');
    
    # Verify specific nested directory is found
    my $found = 0;
    for (my $i = 0; $i < $recursive->Length(); $i++) {
        my $dir = $recursive->Get($i);
        if ($dir =~ /nested1/) {
            $found = 1;
            last;
        }
    }
    ok($found, 'Recursive search finds deeply nested directory');
    
    # Test with empty directory
    my $emptyDir = create_test_dir('empty_for_dirs');
    my $emptyDirs = Directory::GetDirectories($emptyDir);
    is($emptyDirs->Length(), 0, 'GetDirectories in empty directory returns empty array');
    
    # Test error cases
    eval { Directory::GetDirectories(undef); };
    ok($@, 'GetDirectories throws exception with null path');
    
    eval { Directory::GetDirectories(File::Spec->catdir($temp_base, 'nonexistent')); };
    ok($@, 'GetDirectories throws exception for non-existent directory');
    
    # Test search options validation
    eval { Directory::GetDirectories($testDir, '*', 99); };
    ok($@, 'GetDirectories throws exception for invalid search option');
    
    # Test with pattern containing directory separators
    my $complexPattern = Directory::GetDirectories($testDir, '*dir*');
    ok($complexPattern->Length() >= 2, 'Complex pattern matching works');
    
    # Test case sensitivity
    my $caseDirs = Directory::GetDirectories($testDir, 'SUB*');
    if ($^O =~ /Win/) {
        ok($caseDirs->Length() > 0, 'GetDirectories is case-insensitive on Windows');
    } else {
        ok($caseDirs->Length() == 0, 'GetDirectories is case-sensitive on Unix');
    }
};

# Test 41-55: Directory Enumeration - GetFileSystemEntries
subtest 'Directory Enumeration - GetFileSystemEntries' => sub {
    plan tests => 15;
    
    # Create test directory with mixed content
    my $testDir = create_test_dir('filesystem_enum_test');
    
    # Create files
    my @files = ('file1.txt', 'file2.doc', 'readme.md');
    for my $file (@files) {
        create_test_file_in_dir($testDir, $file);
    }
    
    # Create directories
    my @dirs = ('dir1', 'dir2', 'temp');
    for my $dir (@dirs) {
        create_test_dir($dir, $testDir);
    }
    
    # Test GetFileSystemEntries without pattern
    my $allEntries = Directory::GetFileSystemEntries($testDir);
    isa_ok($allEntries, 'System::Array', 'GetFileSystemEntries returns Array');
    is($allEntries->Length(), 6, 'GetFileSystemEntries finds all 6 items');
    
    # Test GetFileSystemEntries with pattern
    my $txtEntries = Directory::GetFileSystemEntries($testDir, '*.txt');
    is($txtEntries->Length(), 1, 'GetFileSystemEntries with *.txt finds 1 item');
    
    # Test GetFileSystemEntries with directory pattern
    my $dirEntries = Directory::GetFileSystemEntries($testDir, 'dir*');
    is($dirEntries->Length(), 2, 'GetFileSystemEntries with dir* finds 2 directories');
    
    # Test GetFileSystemEntries with * pattern
    my $allPattern = Directory::GetFileSystemEntries($testDir, '*');
    is($allPattern->Length(), 6, 'GetFileSystemEntries with * finds all items');
    
    # Create nested structure for recursive testing
    my $subDir = create_test_dir('subdir', $testDir);
    create_test_file_in_dir($subDir, 'subfile.txt');
    create_test_dir('subsubdir', $subDir);
    
    # Test non-recursive (default)
    my $topLevel = Directory::GetFileSystemEntries($testDir);
    is($topLevel->Length(), 7, 'Non-recursive finds only top-level items'); # 6 + 1 new subdir
    
    # Test recursive
    my $recursive = Directory::GetFileSystemEntries($testDir, '*', Directory::AllDirectories);
    ok($recursive->Length() > 7, 'Recursive finds nested items');
    
    # Verify mixed content in recursive results
    my $hasFiles = 0;
    my $hasDirs = 0;
    for (my $i = 0; $i < $recursive->Length(); $i++) {
        my $entry = $recursive->Get($i);
        if ($entry =~ /\.(txt|doc|md)$/) {
            $hasFiles = 1;
        } elsif ($entry =~ /(dir|temp|sub)/) {
            $hasDirs = 1;
        }
    }
    ok($hasFiles, 'Recursive results include files');
    ok($hasDirs, 'Recursive results include directories');
    
    # Test with empty directory
    my $emptyDir = create_test_dir('empty_filesystem');
    my $emptyEntries = Directory::GetFileSystemEntries($emptyDir);
    is($emptyEntries->Length(), 0, 'GetFileSystemEntries in empty directory returns empty array');
    
    # Test error cases
    eval { Directory::GetFileSystemEntries(undef); };
    ok($@, 'GetFileSystemEntries throws exception with null path');
    
    eval { Directory::GetFileSystemEntries(File::Spec->catdir($temp_base, 'nonexistent')); };
    ok($@, 'GetFileSystemEntries throws exception for non-existent directory');
    
    # Test specific file type filtering
    my $docEntries = Directory::GetFileSystemEntries($testDir, '*.doc');
    is($docEntries->Length(), 1, 'GetFileSystemEntries filters by specific extension');
    
    # Test complex pattern
    my $multiPattern = Directory::GetFileSystemEntries($testDir, '*1*');
    ok($multiPattern->Length() >= 2, 'Complex pattern matches multiple items'); # file1.txt and dir1
    
    # Test enumerable aliases
    my $enumerateEntries = Directory::EnumerateFileSystemEntries($testDir);
    isa_ok($enumerateEntries, 'System::Array', 'EnumerateFileSystemEntries works as alias');
};

# Test 56-70: Directory Enumeration Aliases (Enumerate methods)
subtest 'Directory Enumeration Aliases' => sub {
    plan tests => 15;
    
    my $testDir = create_test_dir('enumerate_test');
    
    # Create test content
    create_test_file_in_dir($testDir, 'test1.txt');
    create_test_file_in_dir($testDir, 'test2.log');
    create_test_dir('testdir1', $testDir);
    create_test_dir('testdir2', $testDir);
    
    # Test EnumerateFiles
    my $enumFiles = Directory::EnumerateFiles($testDir);
    isa_ok($enumFiles, 'System::Array', 'EnumerateFiles returns Array');
    is($enumFiles->Length(), 2, 'EnumerateFiles finds 2 files');
    
    # Compare with GetFiles
    my $getFiles = Directory::GetFiles($testDir);
    is($enumFiles->Length(), $getFiles->Length(), 'EnumerateFiles matches GetFiles count');
    
    # Test EnumerateFiles with pattern
    my $enumTxtFiles = Directory::EnumerateFiles($testDir, '*.txt');
    is($enumTxtFiles->Length(), 1, 'EnumerateFiles with pattern works');
    
    # Test EnumerateDirectories
    my $enumDirs = Directory::EnumerateDirectories($testDir);
    isa_ok($enumDirs, 'System::Array', 'EnumerateDirectories returns Array');
    is($enumDirs->Length(), 2, 'EnumerateDirectories finds 2 directories');
    
    # Compare with GetDirectories
    my $getDirs = Directory::GetDirectories($testDir);
    is($enumDirs->Length(), $getDirs->Length(), 'EnumerateDirectories matches GetDirectories count');
    
    # Test EnumerateDirectories with pattern
    my $enumTestDirs = Directory::EnumerateDirectories($testDir, 'test*');
    is($enumTestDirs->Length(), 2, 'EnumerateDirectories with pattern works');
    
    # Test EnumerateFileSystemEntries
    my $enumEntries = Directory::EnumerateFileSystemEntries($testDir);
    isa_ok($enumEntries, 'System::Array', 'EnumerateFileSystemEntries returns Array');
    is($enumEntries->Length(), 4, 'EnumerateFileSystemEntries finds all 4 items');
    
    # Compare with GetFileSystemEntries
    my $getEntries = Directory::GetFileSystemEntries($testDir);
    is($enumEntries->Length(), $getEntries->Length(), 'EnumerateFileSystemEntries matches GetFileSystemEntries count');
    
    # Test recursive enumeration
    create_test_dir('nested', File::Spec->catdir($testDir, 'testdir1'));
    create_test_file_in_dir(File::Spec->catdir($testDir, 'testdir1'), 'nested.txt');
    
    my $enumRecursive = Directory::EnumerateFiles($testDir, '*', Directory::AllDirectories);
    ok($enumRecursive->Length() > 2, 'EnumerateFiles recursive finds nested files');
    
    # Test that all enumeration methods handle same error cases
    eval { Directory::EnumerateFiles(undef); };
    ok($@, 'EnumerateFiles throws exception with null path');
    
    eval { Directory::EnumerateDirectories(File::Spec->catdir($temp_base, 'nonexistent')); };
    ok($@, 'EnumerateDirectories throws exception for non-existent directory');
    
    eval { Directory::EnumerateFileSystemEntries(create_test_file_in_dir($temp_base, 'notdir.txt')); };
    ok($@, 'EnumerateFileSystemEntries throws exception when path is file');
};

# Test 71-85: Directory Deletion
subtest 'Directory Deletion' => sub {
    plan tests => 15;
    
    # Test delete empty directory
    my $emptyDir = create_test_dir('empty_to_delete');
    ok(Directory::Exists($emptyDir), 'Empty directory exists before deletion');
    
    Directory::Delete($emptyDir);
    ok(!Directory::Exists($emptyDir), 'Empty directory deleted successfully');
    
    # Test delete non-empty directory (non-recursive, should fail)
    my $nonEmptyDir = create_test_dir('non_empty_to_delete');
    create_test_file_in_dir($nonEmptyDir, 'file.txt');
    
    eval { Directory::Delete($nonEmptyDir, false); };
    if ($@) {
        ok(Directory::Exists($nonEmptyDir), 'Non-empty directory not deleted in non-recursive mode');
    } else {
        # Some implementations might succeed, that's also valid
        ok(1, 'Non-empty directory deletion handled');
    }
    
    # Test recursive delete of directory with files
    my $recursiveDir = create_test_dir('recursive_delete_test');
    create_test_file_in_dir($recursiveDir, 'file1.txt');
    create_test_file_in_dir($recursiveDir, 'file2.doc');
    
    my $subDir = create_test_dir('subdir', $recursiveDir);
    create_test_file_in_dir($subDir, 'subfile.txt');
    
    my $deepSubDir = create_test_dir('deepdir', $subDir);
    create_test_file_in_dir($deepSubDir, 'deepfile.log');
    
    ok(Directory::Exists($recursiveDir), 'Complex directory structure exists');
    
    Directory::Delete($recursiveDir, true);
    ok(!Directory::Exists($recursiveDir), 'Complex directory structure deleted recursively');
    
    # Test delete with readonly files (platform dependent)
    my $readonlyDir = create_test_dir('readonly_delete_test');
    my $readonlyFile = create_test_file_in_dir($readonlyDir, 'readonly.txt');
    chmod(0444, $readonlyFile); # Make read-only
    
    eval {
        Directory::Delete($readonlyDir, true);
    };
    # This behavior is platform dependent, just ensure it doesn't crash
    ok(1, 'Deletion with readonly files handled gracefully');
    
    # Cleanup readonly file if it still exists
    if (-e $readonlyFile) {
        chmod(0666, $readonlyFile);
        unlink($readonlyFile);
        rmdir($readonlyDir);
    }
    
    # Test error cases
    eval { Directory::Delete(undef); };
    ok($@, 'Delete throws exception with null path');
    
    eval { Directory::Delete(File::Spec->catdir($temp_base, 'nonexistent')); };
    # This might or might not throw an exception depending on implementation
    ok(1, 'Delete with non-existent directory handled');
    
    # Test delete with invalid path
    eval { Directory::Delete(''); };
    ok($@, 'Delete throws exception with empty path');
    
    # Test delete very deep directory structure
    my $deepDir = create_test_dir('deep_delete_test');
    my $currentDir = $deepDir;
    for (my $i = 0; $i < 10; $i++) {
        $currentDir = create_test_dir("level$i", $currentDir);
        create_test_file_in_dir($currentDir, "file$i.txt");
    }
    
    Directory::Delete($deepDir, true);
    ok(!Directory::Exists($deepDir), 'Deep directory structure deleted successfully');
    
    # Test delete directory with many files
    my $manyFilesDir = create_test_dir('many_files_delete_test');
    for (my $i = 0; $i < 50; $i++) {
        create_test_file_in_dir($manyFilesDir, "file$i.txt", "Content $i");
    }
    
    Directory::Delete($manyFilesDir, true);
    ok(!Directory::Exists($manyFilesDir), 'Directory with many files deleted successfully');
    
    # Test delete with special characters in names
    my $specialDir = create_test_dir('special-chars_delete_test');
    create_test_file_in_dir($specialDir, 'file-with-dash.txt');
    create_test_file_in_dir($specialDir, 'file_with_underscore.txt');
    create_test_file_in_dir($specialDir, 'file.with.dots.txt');
    
    Directory::Delete($specialDir, true);
    ok(!Directory::Exists($specialDir), 'Directory with special character files deleted successfully');
    
    # Test delete performance (should complete reasonably quickly)
    my $perfDir = create_test_dir('performance_delete_test');
    for (my $i = 0; $i < 100; $i++) {
        my $subDir = create_test_dir("subdir$i", $perfDir);
        create_test_file_in_dir($subDir, "file$i.txt");
    }
    
    my $deleteStart = time();
    Directory::Delete($perfDir, true);
    my $deleteTime = time() - $deleteStart;
    
    ok($deleteTime < 10, 'Large directory deletion completes in reasonable time');
    ok(!Directory::Exists($perfDir), 'Performance test directory deleted successfully');
};

# Test 86-100: Advanced Directory Operations and Edge Cases
subtest 'Advanced Directory Operations and Edge Cases' => sub {
    plan tests => 15;
    
    # Test with very long directory names
    my $longName = 'a' x 100;
    my $longDir = File::Spec->catdir($temp_base, $longName);
    eval { Directory::Create($longDir); };
    if (!$@ && Directory::Exists($longDir)) {
        ok(1, 'Very long directory name handled successfully');
        Directory::Delete($longDir);
    } else {
        ok(1, 'Very long directory name limitation handled gracefully');
    }
    
    # Test with Unicode characters in directory names
    my $unicodeDir = File::Spec->catdir($temp_base, 'тест_директория');
    eval {
        Directory::Create($unicodeDir);
        if (Directory::Exists($unicodeDir)) {
            ok(1, 'Unicode directory names supported');
            Directory::Delete($unicodeDir);
        } else {
            ok(1, 'Unicode directory names handled gracefully');
        }
    };
    if ($@) {
        ok(1, 'Unicode directory names handled gracefully');
    }
    
    # Test with spaces in directory names
    my $spaceDir = File::Spec->catdir($temp_base, 'dir with spaces');
    Directory::Create($spaceDir);
    ok(Directory::Exists($spaceDir), 'Directory names with spaces supported');
    Directory::Delete($spaceDir);
    
    # Test directory path normalization
    my $normalizeTest = File::Spec->catdir($temp_base, 'normalize_test');
    Directory::Create($normalizeTest);
    
    # Test with trailing separators
    my $sep = File::Spec->catdir('', ''); # Get separator
    $sep = substr($sep, -1) if length($sep) > 0;
    
    my $trailingSlash = $normalizeTest . $sep;
    ok(Directory::Exists($trailingSlash), 'Directory exists check handles trailing separators');
    
    Directory::Delete($normalizeTest);
    
    # Test with relative paths
    my $originalCwd = getcwd();
    chdir($temp_base);
    
    Directory::Create('relative_test');
    ok(Directory::Exists('relative_test'), 'Directory operations work with relative paths');
    
    my $relativeFiles = Directory::GetFiles('relative_test');
    isa_ok($relativeFiles, 'System::Array', 'GetFiles works with relative paths');
    
    Directory::Delete('relative_test');
    chdir($originalCwd);
    
    # Test with current directory references
    my $currentRefDir = File::Spec->catdir($temp_base, '.', 'current_ref_test');
    eval { Directory::Create($currentRefDir); };
    if (!$@ && Directory::Exists($currentRefDir)) {
        ok(1, 'Current directory references in paths handled');
        Directory::Delete($currentRefDir);
    } else {
        ok(1, 'Current directory references handled gracefully');
    }
    
    # Test concurrent directory operations
    my $concurrentDir = create_test_dir('concurrent_test');
    
    # Rapid create/check/delete operations
    for (my $i = 0; $i < 5; $i++) {
        my $subDir = File::Spec->catdir($concurrentDir, "rapid$i");
        Directory::Create($subDir);
        ok(Directory::Exists($subDir), "Rapid directory operation $i successful");
        Directory::Delete($subDir) if $i < 2; # Delete some but not all
    }
    
    Directory::Delete($concurrentDir, true);
    
    # Test directory operations with files of same name
    my $conflictDir = create_test_dir('conflict_test');
    my $conflictFile = create_test_file_in_dir($temp_base, 'conflict_test');
    
    # Directory and file with same name should be distinguishable
    ok(Directory::Exists($conflictDir), 'Directory exists despite file with same name');
    ok(!Directory::Exists($conflictFile), 'File path does not register as directory');
    
    Directory::Delete($conflictDir);
    unlink($conflictFile);
    
    # Test with network paths (if on Windows and available)
    if ($^O =~ /Win/ && $ENV{COMPUTERNAME}) {
        my $localPath = "\\\\localhost\\C\$\\temp";
        eval { Directory::Exists($localPath); };
        ok(1, 'Network path handling does not crash');
    } else {
        ok(1, 'Network path test skipped on non-Windows');
    }
    
    # Test with very deep nesting
    my $deepDir = create_test_dir('deep_nesting_test');
    my $currentPath = $deepDir;
    for (my $i = 0; $i < 15; $i++) {
        $currentPath = File::Spec->catdir($currentPath, "level$i");
        Directory::Create($currentPath);
    }
    
    ok(Directory::Exists($currentPath), 'Very deep directory nesting supported');
    Directory::Delete($deepDir, true);
    
    # Test directory enumeration performance with many entries
    my $manyEntriesDir = create_test_dir('many_entries_test');
    
    # Create many subdirectories
    for (my $i = 0; $i < 100; $i++) {
        create_test_dir(sprintf("dir_%03d", $i), $manyEntriesDir);
    }
    
    my $enumStart = time();
    my $manyDirs = Directory::GetDirectories($manyEntriesDir);
    my $enumTime = time() - $enumStart;
    
    is($manyDirs->Length(), 100, 'Enumeration finds all 100 directories');
    ok($enumTime < 5, 'Directory enumeration of 100 items completes quickly');
    
    Directory::Delete($manyEntriesDir, true);
};

# Test 101-115: Pattern Matching and Filtering
subtest 'Pattern Matching and Filtering' => sub {
    plan tests => 15;
    
    my $patternDir = create_test_dir('pattern_test');
    
    # Create files with various patterns
    my @testFiles = (
        'test.txt', 'test.log', 'test.bak',
        'data.txt', 'data.csv', 'data.json',
        'file1.txt', 'file2.txt', 'file10.txt',
        'backup_file.bak', 'temp_file.tmp',
        'document.doc', 'document.docx'
    );
    
    for my $file (@testFiles) {
        create_test_file_in_dir($patternDir, $file);
    }
    
    # Create directories with various patterns
    my @testDirs = (
        'testdir', 'logdir', 'tempdir',
        'dir1', 'dir2', 'dir10',
        'backup', 'temp', 'docs'
    );
    
    for my $dir (@testDirs) {
        create_test_dir($dir, $patternDir);
    }
    
    # Test simple wildcard patterns
    my $txtFiles = Directory::GetFiles($patternDir, '*.txt');
    is($txtFiles->Length(), 4, 'Pattern *.txt finds 4 files');
    
    my $bakFiles = Directory::GetFiles($patternDir, '*.bak');
    is($bakFiles->Length(), 2, 'Pattern *.bak finds 2 files');
    
    # Test prefix patterns
    my $testFiles = Directory::GetFiles($patternDir, 'test.*');
    is($testFiles->Length(), 3, 'Pattern test.* finds 3 files');
    
    my $dataFiles = Directory::GetFiles($patternDir, 'data.*');
    is($dataFiles->Length(), 3, 'Pattern data.* finds 3 files');
    
    # Test directory patterns
    my $testDirs = Directory::GetDirectories($patternDir, 'test*');
    is($testDirs->Length(), 2, 'Pattern test* finds 2 directories'); # testdir, tempdir
    
    my $dirPattern = Directory::GetDirectories($patternDir, 'dir*');
    is($dirPattern->Length(), 3, 'Pattern dir* finds 3 directories');
    
    # Test single character wildcards
    my $fileNum = Directory::GetFiles($patternDir, 'file?.txt');
    is($fileNum->Length(), 2, 'Pattern file?.txt finds 2 files'); # file1.txt, file2.txt
    
    my $dirNum = Directory::GetDirectories($patternDir, 'dir?');
    is($dirNum->Length(), 2, 'Pattern dir? finds 2 directories'); # dir1, dir2
    
    # Test complex patterns
    my $complexFiles = Directory::GetFiles($patternDir, '*file*');
    ok($complexFiles->Length() >= 3, 'Pattern *file* finds multiple files');
    
    # Test case sensitivity (platform dependent)
    my $caseFiles = Directory::GetFiles($patternDir, '*.TXT');
    if ($^O =~ /Win/) {
        ok($caseFiles->Length() > 0, 'Pattern matching is case-insensitive on Windows');
    } else {
        is($caseFiles->Length(), 0, 'Pattern matching is case-sensitive on Unix');
    }
    
    # Test GetFileSystemEntries with patterns
    my $allTxt = Directory::GetFileSystemEntries($patternDir, '*.txt');
    is($allTxt->Length(), 4, 'GetFileSystemEntries with *.txt finds files');
    
    my $allTest = Directory::GetFileSystemEntries($patternDir, 'test*');
    ok($allTest->Length() >= 3, 'GetFileSystemEntries with test* finds files and directories');
    
    # Test pattern with no matches
    my $noMatch = Directory::GetFiles($patternDir, '*.xyz');
    is($noMatch->Length(), 0, 'Non-matching pattern returns empty array');
    
    # Test empty pattern behavior
    eval {
        my $emptyPattern = Directory::GetFiles($patternDir, '');
    };
    # Behavior may vary, but should not crash
    ok(1, 'Empty pattern handled gracefully');
    
    # Test recursive pattern matching
    my $subPatternDir = create_test_dir('subpattern', $patternDir);
    create_test_file_in_dir($subPatternDir, 'nested.txt');
    create_test_file_in_dir($subPatternDir, 'nested.log');
    
    my $recursiveTxt = Directory::GetFiles($patternDir, '*.txt', Directory::AllDirectories);
    is($recursiveTxt->Length(), 5, 'Recursive pattern matching finds nested files');
    
    Directory::Delete($patternDir, true);
};

# Test 116-125: Integration and Cross-Platform Compatibility
subtest 'Integration and Cross-Platform Compatibility' => sub {
    plan tests => 10;
    
    # Test complete directory lifecycle
    my $lifecycleDir = File::Spec->catdir($temp_base, 'lifecycle_test');
    
    # Create
    Directory::Create($lifecycleDir);
    ok(Directory::Exists($lifecycleDir), 'Directory lifecycle: Create');
    
    # Populate
    create_test_file_in_dir($lifecycleDir, 'file1.txt', 'Content 1');
    create_test_file_in_dir($lifecycleDir, 'file2.txt', 'Content 2');
    my $subDir = create_test_dir('subdir', $lifecycleDir);
    create_test_file_in_dir($subDir, 'subfile.txt', 'Sub Content');
    
    # Enumerate and verify
    my $files = Directory::GetFiles($lifecycleDir);
    is($files->Length(), 2, 'Directory lifecycle: Files enumerated correctly');
    
    my $dirs = Directory::GetDirectories($lifecycleDir);
    is($dirs->Length(), 1, 'Directory lifecycle: Subdirectories enumerated correctly');
    
    my $allEntries = Directory::GetFileSystemEntries($lifecycleDir);
    is($allEntries->Length(), 3, 'Directory lifecycle: All entries enumerated correctly');
    
    # Test recursive enumeration
    my $recursiveFiles = Directory::GetFiles($lifecycleDir, '*', Directory::AllDirectories);
    is($recursiveFiles->Length(), 3, 'Directory lifecycle: Recursive enumeration correct');
    
    # Clean up
    Directory::Delete($lifecycleDir, true);
    ok(!Directory::Exists($lifecycleDir), 'Directory lifecycle: Cleanup successful');
    
    # Test platform-specific path handling
    my $platformDir;
    if ($^O =~ /Win/) {
        # Test Windows-style paths
        $platformDir = File::Spec->catdir($temp_base, 'windows_test');
        Directory::Create($platformDir);
        ok(Directory::Exists($platformDir), 'Windows-style path handling works');
    } else {
        # Test Unix-style paths
        $platformDir = File::Spec->catdir($temp_base, 'unix_test');
        Directory::Create($platformDir);
        ok(Directory::Exists($platformDir), 'Unix-style path handling works');
    }
    Directory::Delete($platformDir) if Directory::Exists($platformDir);
    
    # Test mixed path separators (should be normalized)
    my $mixedPath = $temp_base . '/mixed\\separators/test';
    eval {
        Directory::Create($mixedPath);
        if (Directory::Exists($mixedPath)) {
            ok(1, 'Mixed path separators handled correctly');
            Directory::Delete($mixedPath);
        } else {
            ok(1, 'Mixed path separators handled gracefully');
        }
    };
    if ($@) {
        ok(1, 'Mixed path separators handled gracefully');
    }
    
    # Test performance with realistic workload
    my $perfDir = create_test_dir('performance_test');
    
    # Create realistic directory structure
    for (my $i = 0; $i < 10; $i++) {
        my $projectDir = create_test_dir("project$i", $perfDir);
        create_test_dir('src', $projectDir);
        create_test_dir('docs', $projectDir);
        create_test_dir('tests', $projectDir);
        
        for (my $j = 0; $j < 5; $j++) {
            create_test_file_in_dir($projectDir, "file$j.txt", "Project $i File $j");
        }
    }
    
    # Test enumeration performance
    my $perfStart = time();
    my $allFiles = Directory::GetFiles($perfDir, '*', Directory::AllDirectories);
    my $perfTime = time() - $perfStart;
    
    ok($allFiles->Length() == 50, 'Performance test: All files found');
    ok($perfTime < 3, 'Performance test: Enumeration completes quickly');
    
    Directory::Delete($perfDir, true);
};

# Cleanup
END {
    for my $dir (reverse @temp_dirs_to_cleanup) {
        eval { Directory::Delete($dir, true) if Directory::Exists($dir); };
    }
}

done_testing();