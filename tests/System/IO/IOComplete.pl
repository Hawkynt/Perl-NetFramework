#!/usr/bin/perl
use strict;
use warnings;
use lib '../../../';
use Test::More;

# Define constants
use constant true => 1;
use constant false => 0;

# Import the classes we need
use System::IO::File;
use System::IO::Directory;
use System::IO::Path;

sub test_path_operations {
    # Test path combination
    my $combined = System::IO::Path::Combine("C:", "Users", "Test");
    like($combined->ToString(), qr/Users.*Test/, 'Path combine works');
    
    # Test path components
    my $testPath = "C:\\Users\\Test\\document.txt";
    my $dir = System::IO::Path::GetDirectoryName($testPath);
    like($dir->ToString(), qr/Users.*Test/, 'GetDirectoryName works');
    
    my $filename = System::IO::Path::GetFileName($testPath);
    is($filename->ToString(), "document.txt", 'GetFileName works');
    
    my $filenameWithoutExt = System::IO::Path::GetFileNameWithoutExtension($testPath);
    is($filenameWithoutExt->ToString(), "document", 'GetFileNameWithoutExtension works');
    
    my $extension = System::IO::Path::GetExtension($testPath);
    is($extension->ToString(), ".txt", 'GetExtension works');
    
    # Test path validation
    ok(System::IO::Path::HasExtension($testPath), 'HasExtension returns true for file with extension');
    ok(!System::IO::Path::HasExtension("C:\\Users\\Test"), 'HasExtension returns false for path without extension');
    
    # Test invalid chars
    my $invalidFileChars = System::IO::Path::GetInvalidFileNameChars();
    isa_ok($invalidFileChars, 'System::Array', 'GetInvalidFileNameChars returns array');
    ok($invalidFileChars->Length() > 0, 'Invalid file name chars array not empty');
    
    my $invalidPathChars = System::IO::Path::GetInvalidPathChars();
    isa_ok($invalidPathChars, 'System::Array', 'GetInvalidPathChars returns array');
    ok($invalidPathChars->Length() > 0, 'Invalid path chars array not empty');
}

sub test_file_operations {
    my $testFile = "test_file.txt";
    my $testContent = "Hello, World!\nThis is a test file.";
    
    # Clean up any existing test file
    unlink($testFile) if(-e $testFile);
    
    # Test file existence
    ok(!System::IO::File::Exists($testFile), 'File does not exist initially');
    
    # Test writing and reading text
    System::IO::File::WriteAllText($testFile, $testContent);
    ok(System::IO::File::Exists($testFile), 'File exists after writing');
    
    my $readContent = System::IO::File::ReadAllText($testFile);
    is($readContent->ToString(), $testContent, 'Read content matches written content');
    
    # Test file size
    my $size = System::IO::File::GetSize($testFile);
    is($size, length($testContent), 'File size is correct');
    
    # Test file times
    my $lastWrite = System::IO::File::GetLastWriteTime($testFile);
    isa_ok($lastWrite, 'System::DateTime', 'GetLastWriteTime returns DateTime');
    
    my $creation = System::IO::File::GetCreationTime($testFile);
    isa_ok($creation, 'System::DateTime', 'GetCreationTime returns DateTime');
    
    my $lastAccess = System::IO::File::GetLastAccessTime($testFile);
    isa_ok($lastAccess, 'System::DateTime', 'GetLastAccessTime returns DateTime');
    
    # Test attributes
    my $attrs = System::IO::File::GetAttributes($testFile);
    ok(defined($attrs), 'GetAttributes returns value');
    
    # Test reading lines
    my $lines = System::IO::File::ReadAllLines($testFile);
    isa_ok($lines, 'System::Array', 'ReadAllLines returns array');
    is($lines->Length(), 2, 'Correct number of lines read');
    is($lines->GetValue(0)->ToString(), "Hello, World!", 'First line correct');
    is($lines->GetValue(1)->ToString(), "This is a test file.", 'Second line correct');
    
    # Test appending
    System::IO::File::AppendAllText($testFile, "\nAppended line");
    my $appendedContent = System::IO::File::ReadAllText($testFile);
    like($appendedContent->ToString(), qr/Appended line$/, 'Content was appended');
    
    # Test copying
    my $copyFile = "test_copy.txt";
    unlink($copyFile) if(-e $copyFile);
    System::IO::File::Copy($testFile, $copyFile);
    ok(System::IO::File::Exists($copyFile), 'File was copied');
    
    my $copyContent = System::IO::File::ReadAllText($copyFile);
    is($copyContent->ToString(), $appendedContent->ToString(), 'Copied content matches original');
    
    # Test moving
    my $moveFile = "test_moved.txt";
    unlink($moveFile) if(-e $moveFile);
    System::IO::File::Move($copyFile, $moveFile);
    ok(!System::IO::File::Exists($copyFile), 'Original file no longer exists after move');
    ok(System::IO::File::Exists($moveFile), 'File exists at new location after move');
    
    # Clean up
    System::IO::File::Delete($testFile);
    System::IO::File::Delete($moveFile);
    ok(!System::IO::File::Exists($testFile), 'Test file deleted');
    ok(!System::IO::File::Exists($moveFile), 'Moved file deleted');
}

sub test_directory_operations {
    my $testDir = "test_directory";
    
    # Clean up any existing test directory
    if(System::IO::Directory::Exists($testDir)) {
        System::IO::Directory::Delete($testDir, true);
    }
    
    # Test directory existence
    ok(!System::IO::Directory::Exists($testDir), 'Directory does not exist initially');
    
    # Test creating directory
    System::IO::Directory::Create($testDir);
    ok(System::IO::Directory::Exists($testDir), 'Directory exists after creation');
    
    # Create some test files in the directory
    my $testFile1 = System::IO::Path::Combine($testDir, "file1.txt");
    my $testFile2 = System::IO::Path::Combine($testDir, "file2.log");
    System::IO::File::WriteAllText($testFile1, "Content 1");
    System::IO::File::WriteAllText($testFile2, "Content 2");
    
    # Test getting files
    my $files = System::IO::Directory::GetFiles($testDir);
    isa_ok($files, 'System::Array', 'GetFiles returns array');
    is($files->Length(), 2, 'Correct number of files found');
    
    # Test enumeration methods (aliases)
    my $enumFiles = System::IO::Directory::EnumerateFiles($testDir);
    isa_ok($enumFiles, 'System::Array', 'EnumerateFiles returns array');
    is($enumFiles->Length(), 2, 'EnumerateFiles finds correct number of files');
    
    # Test with pattern
    my $txtFiles = System::IO::Directory::GetFiles($testDir, "*.txt");
    is($txtFiles->Length(), 1, 'Pattern matching works for txt files');
    
    my $logFiles = System::IO::Directory::GetFiles($testDir, "*.log");
    is($logFiles->Length(), 1, 'Pattern matching works for log files');
    
    # Test getting all file system entries
    my $allEntries = System::IO::Directory::GetFileSystemEntries($testDir);
    is($allEntries->Length(), 2, 'GetFileSystemEntries finds all entries');
    
    # Test recursive deletion
    System::IO::Directory::Delete($testDir, true);
    ok(!System::IO::Directory::Exists($testDir), 'Directory deleted recursively');
}

sub test_temp_operations {
    # Test temporary path
    my $tempPath = System::IO::Path::GetTempPath();
    isa_ok($tempPath, 'System::String', 'GetTempPath returns string');
    ok(length($tempPath->ToString()) > 0, 'Temp path is not empty');
    
    # Test temporary filename
    my $tempFile = System::IO::Path::GetTempFileName();
    isa_ok($tempFile, 'System::String', 'GetTempFileName returns string');
    ok(System::IO::File::Exists($tempFile->ToString()), 'Temp file was created');
    
    # Clean up temp file
    System::IO::File::Delete($tempFile->ToString());
    ok(!System::IO::File::Exists($tempFile->ToString()), 'Temp file was cleaned up');
    
    # Test random filename
    my $randomFile = System::IO::Path::GetRandomFileName();
    isa_ok($randomFile, 'System::String', 'GetRandomFileName returns string');
    ok(length($randomFile->ToString()) > 0, 'Random filename is not empty');
}

sub test_byte_operations {
    my $testFile = "test_bytes.bin";
    my @testBytes = (72, 101, 108, 108, 111, 32, 87, 111, 114, 108, 100); # "Hello World"
    
    # Clean up any existing file
    unlink($testFile) if(-e $testFile);
    
    # Write bytes
    System::IO::File::WriteAllBytes($testFile, \@testBytes);
    ok(System::IO::File::Exists($testFile), 'Binary file was created');
    
    # Read bytes
    my $readBytes = System::IO::File::ReadAllBytes($testFile);
    isa_ok($readBytes, 'System::Array', 'ReadAllBytes returns array');
    is($readBytes->Length(), scalar(@testBytes), 'Correct number of bytes read');
    
    # Verify byte values
    for my $i (0..$#testBytes) {
        is($readBytes->GetValue($i), $testBytes[$i], "Byte $i matches");
    }
    
    # Clean up
    System::IO::File::Delete($testFile);
    ok(!System::IO::File::Exists($testFile), 'Binary test file deleted');
}

# Run all tests
test_path_operations();
test_file_operations();
test_directory_operations();
test_temp_operations();
test_byte_operations();

done_testing();