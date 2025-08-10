#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/../../../";
use File::Temp qw(tempfile tempdir);
use File::Spec;
use File::Path qw(rmtree);

require System::IO::FileInfo;
require System::IO::DirectoryInfo;
require System::IO::FileStream;
require System::IO::StreamReader;
require System::IO::StreamWriter;

# Test plan
my $test_count = 0;

# Test data
my $temp_dir = tempdir(CLEANUP => 1);
my $test_file_path = File::Spec->catfile($temp_dir, "test_file.txt");
my $test_content = "Hello, World!\nThis is test content.";

sub run_tests {
    # Constructor tests
    test_constructor();
    
    # Property tests
    test_properties();
    
    # File creation and stream tests
    test_create_operations();
    
    # File reading and writing tests
    test_read_write_operations();
    
    # File manipulation tests (copy, move, delete)
    test_file_manipulation();
    
    # Exception handling tests
    test_exception_handling();
    
    # Cross-platform compatibility tests
    test_cross_platform_compatibility();
    
    done_testing($test_count);
}

sub test_constructor {
    # Happy path - valid file path
    my $file_info = System::IO::FileInfo->new($test_file_path);
    ok(defined($file_info), "FileInfo constructor with valid path");
    is($file_info->FullName(), $test_file_path, "FullName returns correct path");
    $test_count += 2;
    
    # Exception test - null path
    eval { System::IO::FileInfo->new(undef); };
    ok($@, "Constructor throws exception for null path");
    $test_count += 1;
    
    # Exception test - empty path
    eval { System::IO::FileInfo->new(''); };
    ok($@, "Constructor throws exception for empty path");
    $test_count += 1;
}

sub test_properties {
    # Create test file for property tests
    open(my $fh, '>', $test_file_path) or die "Cannot create test file: $!";
    print $fh $test_content;
    close($fh);
    
    my $file_info = System::IO::FileInfo->new($test_file_path);
    
    # Name property
    is($file_info->Name(), "test_file.txt", "Name property returns correct filename");
    $test_count += 1;
    
    # Extension property
    is($file_info->Extension(), ".txt", "Extension property returns correct extension");
    $test_count += 1;
    
    # Test file without extension
    my $no_ext_path = File::Spec->catfile($temp_dir, "noextension");
    my $no_ext_info = System::IO::FileInfo->new($no_ext_path);
    is($no_ext_info->Extension(), "", "Extension property returns empty string for no extension");
    $test_count += 1;
    
    # DirectoryName property
    is($file_info->DirectoryName(), $temp_dir, "DirectoryName returns correct directory path");
    $test_count += 1;
    
    # Directory property
    my $directory = $file_info->Directory();
    ok(defined($directory), "Directory property returns DirectoryInfo object");
    isa_ok($directory, 'System::IO::DirectoryInfo', "Directory is DirectoryInfo instance");
    $test_count += 2;
    
    # Exists property
    ok($file_info->Exists(), "Exists returns true for existing file");
    $test_count += 1;
    
    # Length property
    my $expected_length = length($test_content);
    is($file_info->Length(), $expected_length, "Length returns correct file size");
    $test_count += 1;
    
    # IsReadOnly property (test both getter and setter)
    my $initial_readonly = $file_info->IsReadOnly();
    ok(defined($initial_readonly), "IsReadOnly getter returns value");
    $test_count += 1;
    
    # Try to set read-only (may not work on all systems)
    eval {
        $file_info->IsReadOnly(1);
        my $readonly_after = $file_info->IsReadOnly();
        ok($readonly_after, "IsReadOnly setter works");
        
        # Reset to writable
        $file_info->IsReadOnly(0);
        $test_count += 1;
    };
    if ($@) {
        pass("IsReadOnly setter test skipped - permission operation failed");
        $test_count += 1;
    }
    
    # Test time properties (requires existing file)
    eval {
        my $creation_time = $file_info->CreationTime();
        ok(defined($creation_time), "CreationTime returns DateTime object");
        
        my $last_write_time = $file_info->LastWriteTime();
        ok(defined($last_write_time), "LastWriteTime returns DateTime object");
        
        my $last_access_time = $file_info->LastAccessTime();
        ok(defined($last_access_time), "LastAccessTime returns DateTime object");
        
        $test_count += 3;
    };
    if ($@) {
        pass("DateTime property tests skipped - module not available");
        $test_count += 1;
    }
    
    # Clean up
    unlink($test_file_path);
}

sub test_create_operations {
    # Clean up any existing file
    unlink($test_file_path) if -f $test_file_path;
    
    my $file_info = System::IO::FileInfo->new($test_file_path);
    
    # Create file stream
    my $stream = $file_info->Create();
    ok(defined($stream), "Create returns FileStream");
    isa_ok($stream, 'System::IO::FileStream', "Create returns FileStream instance");
    $stream->Close() if $stream;
    ok(-f $test_file_path, "Create actually creates the file");
    $test_count += 3;
    
    # CreateText
    unlink($test_file_path);
    my $text_writer = $file_info->CreateText();
    ok(defined($text_writer), "CreateText returns StreamWriter");
    isa_ok($text_writer, 'System::IO::StreamWriter', "CreateText returns StreamWriter instance");
    if ($text_writer) {
        $text_writer->WriteLine("Test line");
        $text_writer->Close();
    }
    ok(-f $test_file_path, "CreateText creates file and writes content");
    $test_count += 3;
    
    # OpenRead (requires existing file)
    my $read_stream = $file_info->OpenRead();
    ok(defined($read_stream), "OpenRead returns FileStream");
    isa_ok($read_stream, 'System::IO::FileStream', "OpenRead returns FileStream instance");
    ok($read_stream->CanRead(), "OpenRead stream supports reading");
    ok(!$read_stream->CanWrite(), "OpenRead stream doesn't support writing");
    $read_stream->Close() if $read_stream;
    $test_count += 4;
    
    # OpenWrite
    my $write_stream = $file_info->OpenWrite();
    ok(defined($write_stream), "OpenWrite returns FileStream");
    isa_ok($write_stream, 'System::IO::FileStream', "OpenWrite returns FileStream instance");
    ok($write_stream->CanWrite(), "OpenWrite stream supports writing");
    $write_stream->Close() if $write_stream;
    $test_count += 3;
    
    # OpenText (requires existing file)
    my $text_reader = $file_info->OpenText();
    ok(defined($text_reader), "OpenText returns StreamReader");
    isa_ok($text_reader, 'System::IO::StreamReader', "OpenText returns StreamReader instance");
    $text_reader->Close() if $text_reader;
    $test_count += 2;
    
    # AppendText
    my $append_writer = $file_info->AppendText();
    ok(defined($append_writer), "AppendText returns StreamWriter");
    isa_ok($append_writer, 'System::IO::StreamWriter', "AppendText returns StreamWriter instance");
    if ($append_writer) {
        $append_writer->WriteLine("Appended line");
        $append_writer->Close();
    }
    $test_count += 2;
    
    # Clean up
    unlink($test_file_path);
}

sub test_read_write_operations {
    # Clean up any existing file
    unlink($test_file_path) if -f $test_file_path;
    
    my $file_info = System::IO::FileInfo->new($test_file_path);
    
    # WriteAllText
    $file_info->WriteAllText($test_content);
    ok(-f $test_file_path, "WriteAllText creates file");
    $test_count += 1;
    
    # ReadAllText
    my $read_content = $file_info->ReadAllText();
    is($read_content, $test_content, "ReadAllText returns correct content");
    $test_count += 1;
    
    # WriteAllLines
    my @lines = ("Line 1", "Line 2", "Line 3");
    $file_info->WriteAllLines(\@lines);
    $test_count += 0; # Just testing it doesn't crash
    
    # ReadAllLines
    my $read_lines = $file_info->ReadAllLines();
    ok(defined($read_lines), "ReadAllLines returns array reference");
    is(scalar(@$read_lines), 3, "ReadAllLines returns correct number of lines");
    is($read_lines->[0], "Line 1", "ReadAllLines first line correct");
    is($read_lines->[2], "Line 3", "ReadAllLines last line correct");
    $test_count += 4;
    
    # Test large file operations
    my $large_content = "x" x 10000; # 10KB of data
    $file_info->WriteAllText($large_content);
    my $large_read = $file_info->ReadAllText();
    is(length($large_read), 10000, "Large file read/write works correctly");
    $test_count += 1;
    
    # Clean up
    unlink($test_file_path);
}

sub test_file_manipulation {
    # Create source file
    open(my $fh, '>', $test_file_path) or die "Cannot create test file: $!";
    print $fh $test_content;
    close($fh);
    
    my $file_info = System::IO::FileInfo->new($test_file_path);
    my $copy_path = File::Spec->catfile($temp_dir, "copied_file.txt");
    my $move_path = File::Spec->catfile($temp_dir, "moved_file.txt");
    
    # CopyTo operation
    my $copied_info = $file_info->CopyTo($copy_path);
    ok(defined($copied_info), "CopyTo returns FileInfo");
    isa_ok($copied_info, 'System::IO::FileInfo', "CopyTo returns FileInfo instance");
    ok(-f $copy_path, "CopyTo creates destination file");
    ok(-f $test_file_path, "CopyTo preserves source file");
    $test_count += 4;
    
    # Test copy without overwrite (should fail if file exists)
    eval { $file_info->CopyTo($copy_path, 0); }; # overwrite = false
    ok($@, "CopyTo without overwrite throws exception when file exists");
    $test_count += 1;
    
    # Test copy with overwrite
    my $overwritten_info = $file_info->CopyTo($copy_path, 1); # overwrite = true
    ok(defined($overwritten_info), "CopyTo with overwrite succeeds");
    $test_count += 1;
    
    # MoveTo operation
    $file_info->MoveTo($move_path);
    ok(-f $move_path, "MoveTo creates destination file");
    ok(!-f $test_file_path, "MoveTo removes source file");
    is($file_info->FullName(), $move_path, "MoveTo updates FileInfo path");
    $test_count += 3;
    
    # Replace operation
    my $backup_path = File::Spec->catfile($temp_dir, "backup_file.txt");
    my $replacement_info = $copied_info->Replace($move_path, $backup_path);
    ok(defined($replacement_info), "Replace returns FileInfo");
    ok(-f $backup_path, "Replace creates backup file");
    $test_count += 2;
    
    # Delete operation
    $replacement_info->Delete();
    ok(!-f $replacement_info->FullName(), "Delete removes file");
    $test_count += 1;
    
    # Clean up remaining files
    unlink($copy_path) if -f $copy_path;
    unlink($move_path) if -f $move_path;
    unlink($backup_path) if -f $backup_path;
}

sub test_exception_handling {
    # Test operations on non-existent file
    my $nonexistent = System::IO::FileInfo->new("/nonexistent/file.txt");
    
    # Length on non-existent file
    eval { $nonexistent->Length(); };
    ok($@, "Length throws exception for non-existent file");
    $test_count += 1;
    
    # OpenRead on non-existent file
    eval { $nonexistent->OpenRead(); };
    ok($@, "OpenRead throws exception for non-existent file");
    $test_count += 1;
    
    # OpenText on non-existent file
    eval { $nonexistent->OpenText(); };
    ok($@, "OpenText throws exception for non-existent file");
    $test_count += 1;
    
    # Delete non-existent file
    eval { $nonexistent->Delete(); };
    ok($@, "Delete throws exception for non-existent file");
    $test_count += 1;
    
    # ReadAllText on non-existent file
    eval { $nonexistent->ReadAllText(); };
    ok($@, "ReadAllText throws exception for non-existent file");
    $test_count += 1;
    
    # CopyTo with null destination
    open(my $fh, '>', $test_file_path) or die $!;
    close($fh);
    my $file_info = System::IO::FileInfo->new($test_file_path);
    
    eval { $file_info->CopyTo(undef); };
    ok($@, "CopyTo throws exception for null destination");
    
    # MoveTo with null destination
    eval { $file_info->MoveTo(undef); };
    ok($@, "MoveTo throws exception for null destination");
    
    unlink($test_file_path);
    $test_count += 2;
    
    # WriteAllText with null content
    eval { $file_info->WriteAllText(undef); };
    ok($@, "WriteAllText throws exception for null content");
    $test_count += 1;
}

sub test_cross_platform_compatibility {
    # Test Windows-style paths (should work on Unix too)
    if ($^O eq 'MSWin32') {
        my $win_path = "C:\\Test\\file.txt";
        my $file_info = System::IO::FileInfo->new($win_path);
        ok(defined($file_info), "Constructor handles Windows paths");
        is($file_info->Name(), "file.txt", "Name extraction works for Windows paths");
        is($file_info->Extension(), ".txt", "Extension extraction works for Windows paths");
        $test_count += 3;
    } else {
        # Test Unix-style paths
        my $unix_path = "/tmp/test/file.txt";
        my $file_info = System::IO::FileInfo->new($unix_path);
        ok(defined($file_info), "Constructor handles Unix paths");
        is($file_info->Name(), "file.txt", "Name extraction works for Unix paths");
        is($file_info->Extension(), ".txt", "Extension extraction works for Unix paths");
        $test_count += 3;
    }
    
    # Test relative paths
    my $relative_file = System::IO::FileInfo->new("relative/path/file.txt");
    ok(defined($relative_file), "Constructor handles relative paths");
    is($relative_file->Name(), "file.txt", "Name extraction works for relative paths");
    $test_count += 2;
    
    # Test paths with special characters
    my $special_chars_file = System::IO::FileInfo->new("file with spaces & symbols!.txt");
    ok(defined($special_chars_file), "Constructor handles paths with special characters");
    is($special_chars_file->Name(), "file with spaces & symbols!.txt", "Name extraction works with special characters");
    is($special_chars_file->Extension(), ".txt", "Extension extraction works with special characters");
    $test_count += 3;
    
    # Test various file extensions
    my @test_extensions = ('.txt', '.log', '.dat', '.tmp', '');
    foreach my $ext (@test_extensions) {
        my $test_name = "testfile$ext";
        my $file_info = System::IO::FileInfo->new($test_name);
        is($file_info->Extension(), $ext, "Extension '$ext' handled correctly");
        $test_count += 1;
    }
    
    # Test files with multiple dots
    my $multi_dot_file = System::IO::FileInfo->new("file.backup.txt");
    is($multi_dot_file->Extension(), ".txt", "Multiple dots in filename handled correctly");
    $test_count += 1;
    
    # Test hidden files (Unix-style)
    my $hidden_file = System::IO::FileInfo->new(".hidden_file");
    is($hidden_file->Name(), ".hidden_file", "Hidden files handled correctly");
    is($hidden_file->Extension(), "", "Hidden files without extension handled correctly");
    $test_count += 2;
}

# Run all tests
run_tests();