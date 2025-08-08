#!/usr/bin/perl
use strict;
use warnings;
use lib '../../../';
use Test::More;
use System;
use System::IO::Path;
use System::IO::DirectoryInfo;
use System::IO::FileInfo;
use File::Temp qw(tempfile tempdir);

BEGIN {
    use_ok('System::IO::Path');
    use_ok('System::IO::DirectoryInfo');
    use_ok('System::IO::FileInfo');
}

sub test_enhanced_path_methods {
    # Test IsValidPath
    ok(System::IO::Path->IsValidPath('/valid/path'), 'IsValidPath returns true for valid path');
    ok(!System::IO::Path->IsValidPath("invalid\x00path"), 'IsValidPath returns false for invalid path with null');
    
    # Test IsValidFileName
    ok(System::IO::Path->IsValidFileName('validfile.txt'), 'IsValidFileName returns true for valid filename');
    ok(!System::IO::Path->IsValidFileName('invalid<file>.txt'), 'IsValidFileName returns false for invalid filename');
    
    # Test TrimEndingDirectorySeparator
    my $path = System::IO::Path->TrimEndingDirectorySeparator('/path/to/dir/');
    is($path, '/path/to/dir', 'TrimEndingDirectorySeparator removes trailing separator');
    
    $path = System::IO::Path->TrimEndingDirectorySeparator('/path/to/dir');
    is($path, '/path/to/dir', 'TrimEndingDirectorySeparator leaves path without trailing separator');
    
    # Test EndsInDirectorySeparator
    ok(System::IO::Path->EndsInDirectorySeparator('/path/to/dir/'), 'EndsInDirectorySeparator detects trailing separator');
    ok(!System::IO::Path->EndsInDirectorySeparator('/path/to/dir'), 'EndsInDirectorySeparator detects no trailing separator');
    
    # Test Join (alias for Combine)
    $path = System::IO::Path->Join('path', 'to', 'file.txt');
    like($path->ToString(), qr/path.*to.*file\.txt/, 'Join combines path segments');
}

sub test_relative_path_calculations {
    SKIP: {
        skip "GetRelativePath complex tests", 5 unless 1; # Enable when ready
        
        # Test GetRelativePath - basic cases
        my $relativeTo = '/home/user/documents';
        my $path = '/home/user/documents/projects/test.txt';
        
        my $relative = System::IO::Path->GetRelativePath($relativeTo, $path);
        like($relative->ToString(), qr/projects.*test\.txt/, 'GetRelativePath calculates forward relative path');
        
        # Test same path
        $relative = System::IO::Path->GetRelativePath($relativeTo, $relativeTo);
        is($relative->ToString(), '.', 'GetRelativePath returns "." for same path');
        
        # Test backward relative path
        $path = '/home/user';
        $relative = System::IO::Path->GetRelativePath($relativeTo, $path);
        like($relative->ToString(), qr/\.\./, 'GetRelativePath calculates backward relative path');
    }
}

sub test_path_starts_with {
    SKIP: {
        skip "PathStartsWith tests", 3 unless 1; # Enable when ready
        
        # Test PathStartsWith
        ok(System::IO::Path->PathStartsWith('/home/user/documents', '/home/user'), 'PathStartsWith detects prefix');
        ok(!System::IO::Path->PathStartsWith('/home/user', '/home/user/documents'), 'PathStartsWith rejects non-prefix');
        ok(System::IO::Path->PathStartsWith('/home/user', '/home/user'), 'PathStartsWith handles exact match');
    }
}

sub test_directoryinfo_enhanced {
    # Create temporary directory for testing
    my $tempDir = tempdir(CLEANUP => 1);
    my $dirInfo = System::IO::DirectoryInfo->new($tempDir);
    
    # Test basic properties
    isa_ok($dirInfo, 'System::IO::DirectoryInfo', 'DirectoryInfo creation');
    ok($dirInfo->Exists(), 'DirectoryInfo detects existing directory');
    like($dirInfo->FullName(), qr/\Q$tempDir\E/, 'DirectoryInfo FullName matches temp directory');
    
    # Test subdirectory creation
    my $subDir = $dirInfo->CreateSubdirectory('testsubdir');
    isa_ok($subDir, 'System::IO::DirectoryInfo', 'CreateSubdirectory returns DirectoryInfo');
    ok($subDir->Exists(), 'Created subdirectory exists');
    
    # Create test files in directory
    my ($fh1, $filename1) = tempfile(DIR => $tempDir, SUFFIX => '.txt');
    print $fh1 "Test content 1\n";
    close $fh1;
    
    my ($fh2, $filename2) = tempfile(DIR => $tempDir, SUFFIX => '.log');
    print $fh2 "Test content 2\n";
    close $fh2;
    
    # Test file enumeration
    my $files = $dirInfo->GetFiles();
    isa_ok($files, 'System::Array', 'GetFiles returns Array');
    ok($files->Length() >= 2, 'GetFiles found created files');
    
    # Test file enumeration with pattern
    my $txtFiles = $dirInfo->GetFiles('*.txt');
    ok($txtFiles->Length() >= 1, 'GetFiles with pattern found txt files');
    
    # Test directory enumeration
    my $dirs = $dirInfo->GetDirectories();
    ok($dirs->Length() >= 1, 'GetDirectories found subdirectory');
    
    # Test FileSystemInfos enumeration
    my $items = $dirInfo->GetFileSystemInfos();
    ok($items->Length() >= 3, 'GetFileSystemInfos found files and directories');
}

sub test_fileinfo_enhanced {
    # Create temporary file for testing
    my ($fh, $tempFile) = tempfile(CLEANUP => 1, SUFFIX => '.txt');
    print $fh "Test file content\nSecond line\n";
    close $fh;
    
    my $fileInfo = System::IO::FileInfo->new($tempFile);
    
    # Test basic properties
    isa_ok($fileInfo, 'System::IO::FileInfo', 'FileInfo creation');
    ok($fileInfo->Exists(), 'FileInfo detects existing file');
    like($fileInfo->Extension(), qr/\.txt/, 'FileInfo Extension property');
    ok($fileInfo->Length() > 0, 'FileInfo Length property');
    
    # Test DirectoryName and Directory properties
    ok(defined($fileInfo->DirectoryName()), 'DirectoryName is defined');
    isa_ok($fileInfo->Directory(), 'System::IO::DirectoryInfo', 'Directory property returns DirectoryInfo');
    
    # Test ReadAllText
    my $content = $fileInfo->ReadAllText();
    like($content, qr/Test file content/, 'ReadAllText reads file content');
    
    # Test ReadAllLines
    my $lines = $fileInfo->ReadAllLines();
    is(scalar(@$lines), 2, 'ReadAllLines returns correct number of lines');
    like($lines->[0], qr/Test file content/, 'ReadAllLines first line correct');
    
    # Test WriteAllText
    $fileInfo->WriteAllText("New content for test\n");
    $content = $fileInfo->ReadAllText();
    like($content, qr/New content for test/, 'WriteAllText updates file content');
    
    # Test WriteAllLines
    my @newLines = ("Line 1", "Line 2", "Line 3");
    $fileInfo->WriteAllLines(\@newLines);
    $lines = $fileInfo->ReadAllLines();
    is(scalar(@$lines), 3, 'WriteAllLines writes correct number of lines');
    is($lines->[1], 'Line 2', 'WriteAllLines second line correct');
    
    # Test CopyTo
    my $copyPath = $tempFile . '.copy';
    my $copiedFile = $fileInfo->CopyTo($copyPath);
    isa_ok($copiedFile, 'System::IO::FileInfo', 'CopyTo returns FileInfo');
    ok($copiedFile->Exists(), 'Copied file exists');
    
    # Clean up copy
    unlink $copyPath;
}

sub test_io_exception_handling {
    # Test exception throwing for non-existent files
    eval {
        my $nonExistent = System::IO::FileInfo->new('/nonexistent/path/file.txt');
        $nonExistent->ReadAllText();
    };
    ok($@, 'FileInfo throws exception for non-existent file operations');
    
    # Test exception for invalid operations
    eval {
        my $invalidDir = System::IO::DirectoryInfo->new('/nonexistent/invalid/path');
        $invalidDir->GetFiles();
    };
    ok($@, 'DirectoryInfo throws exception for invalid directory operations');
}

# Run all tests
test_enhanced_path_methods();
test_relative_path_calculations();
test_path_starts_with();
test_directoryinfo_enhanced();
test_fileinfo_enhanced();
test_io_exception_handling();

done_testing();