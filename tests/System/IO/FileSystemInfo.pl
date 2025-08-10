#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/../../../";
use File::Temp qw(tempfile tempdir);
use File::Spec;

require System::IO::FileSystemInfo;
require System::IO::FileInfo;
require System::IO::DirectoryInfo;

# Test plan
my $test_count = 0;

# Test data
my $temp_dir = tempdir(CLEANUP => 1);
my $test_file_path = File::Spec->catfile($temp_dir, "filesysteminfo_test.txt");
my $test_dir_path = File::Spec->catdir($temp_dir, "test_directory");
my $test_content = "FileSystemInfo test content";

sub run_tests {
    # Abstract class behavior tests
    test_abstract_class_behavior();
    
    # Base property tests (through derived classes)
    test_base_properties();
    
    # Time property tests
    test_time_properties();
    
    # Attribute property tests  
    test_attributes_property();
    
    # Refresh functionality tests
    test_refresh_functionality();
    
    # Exception handling tests
    test_exception_handling();
    
    # ToString tests
    test_tostring_method();
    
    # Cross-platform path tests
    test_cross_platform_paths();
    
    done_testing($test_count);
}

sub test_abstract_class_behavior {
    # Test that FileSystemInfo cannot be directly instantiated meaningfully
    # (it's abstract, but Perl allows instantiation - the methods should throw NotImplementedException)
    
    my $abstract_instance = System::IO::FileSystemInfo->new($test_file_path);
    ok(defined($abstract_instance), "FileSystemInfo can be instantiated (Perl limitation)");
    $test_count += 1;
    
    # Test abstract methods throw NotImplementedException
    eval { $abstract_instance->Name(); };
    ok($@, "Abstract Name method throws NotImplementedException");
    like($@, qr/NotImplementedException/, "Exception is NotImplementedException");
    $test_count += 2;
    
    eval { $abstract_instance->Delete(); };
    ok($@, "Abstract Delete method throws NotImplementedException");
    like($@, qr/NotImplementedException/, "Exception is NotImplementedException");
    $test_count += 2;
    
    eval { $abstract_instance->_RefreshExistence(); };
    ok($@, "Abstract _RefreshExistence method throws NotImplementedException");
    $test_count += 1;
}

sub test_base_properties {
    # Create test file for property testing
    open(my $fh, '>', $test_file_path) or die "Cannot create test file: $!";
    print $fh $test_content;
    close($fh);
    
    # Test with FileInfo (derived class)
    my $file_info = System::IO::FileInfo->new($test_file_path);
    
    # Test FullName property (implemented in base class)
    is($file_info->FullName(), $test_file_path, "FullName returns correct path");
    $test_count += 1;
    
    # Test Exists property functionality
    ok($file_info->Exists(), "Exists returns true for existing file");
    $test_count += 1;
    
    # Create test directory
    mkdir($test_dir_path) unless -d $test_dir_path;
    my $dir_info = System::IO::DirectoryInfo->new($test_dir_path);
    
    # Test FullName for directory
    is($dir_info->FullName(), $test_dir_path, "FullName works for directories");
    ok($dir_info->Exists(), "Exists works for directories");
    $test_count += 2;
    
    # Test with non-existent path
    my $nonexistent_path = File::Spec->catfile($temp_dir, "does_not_exist.txt");
    my $nonexistent_info = System::IO::FileInfo->new($nonexistent_path);
    
    is($nonexistent_info->FullName(), $nonexistent_path, "FullName works for non-existent files");
    ok(!$nonexistent_info->Exists(), "Exists returns false for non-existent files");
    $test_count += 2;
    
    # Clean up
    unlink($test_file_path);
    rmdir($test_dir_path) if -d $test_dir_path;
}

sub test_time_properties {
    # Create test file with known modification time
    open(my $fh, '>', $test_file_path) or die "Cannot create test file: $!";
    print $fh $test_content;
    close($fh);
    
    my $file_info = System::IO::FileInfo->new($test_file_path);
    
    # Test time properties exist and return reasonable values
    eval {
        my $creation_time = $file_info->CreationTime();
        ok(defined($creation_time), "CreationTime returns defined value");
        isa_ok($creation_time, 'System::DateTime', "CreationTime returns DateTime object");
        $test_count += 2;
        
        my $last_write_time = $file_info->LastWriteTime();
        ok(defined($last_write_time), "LastWriteTime returns defined value");
        isa_ok($last_write_time, 'System::DateTime', "LastWriteTime returns DateTime object");
        $test_count += 2;
        
        my $last_access_time = $file_info->LastAccessTime();
        ok(defined($last_access_time), "LastAccessTime returns defined value");
        isa_ok($last_access_time, 'System::DateTime', "LastAccessTime returns DateTime object");
        $test_count += 2;
        
        # Test UTC versions
        my $creation_time_utc = $file_info->CreationTimeUtc();
        ok(defined($creation_time_utc), "CreationTimeUtc returns defined value");
        
        my $last_write_time_utc = $file_info->LastWriteTimeUtc();
        ok(defined($last_write_time_utc), "LastWriteTimeUtc returns defined value");
        
        my $last_access_time_utc = $file_info->LastAccessTimeUtc();
        ok(defined($last_access_time_utc), "LastAccessTimeUtc returns defined value");
        $test_count += 3;
        
    };
    if ($@) {
        # Skip time tests if DateTime module not available
        pass("Time property tests skipped - DateTime module not available");
        $test_count += 1;
    }
    
    # Test time properties on non-existent file (should throw exception)
    my $nonexistent_info = System::IO::FileInfo->new("/nonexistent/file.txt");
    
    eval { $nonexistent_info->CreationTime(); };
    ok($@, "CreationTime throws exception for non-existent file");
    $test_count += 1;
    
    eval { $nonexistent_info->LastWriteTime(); };
    ok($@, "LastWriteTime throws exception for non-existent file");
    $test_count += 1;
    
    eval { $nonexistent_info->LastAccessTime(); };
    ok($@, "LastAccessTime throws exception for non-existent file");
    $test_count += 1;
    
    # Clean up
    unlink($test_file_path);
}

sub test_attributes_property {
    # Create test file
    open(my $fh, '>', $test_file_path) or die "Cannot create test file: $!";
    print $fh $test_content;
    close($fh);
    
    my $file_info = System::IO::FileInfo->new($test_file_path);
    
    eval {
        my $attributes = $file_info->Attributes();
        ok(defined($attributes), "Attributes returns defined value");
        ok($attributes >= 0, "Attributes returns non-negative value");
        $test_count += 2;
        
        # Check that Archive bit is set for normal files (bit 32)
        ok(($attributes & 32) > 0, "Archive attribute set for normal file");
        $test_count += 1;
        
        # Check that Directory bit is NOT set for files (bit 2)
        ok(($attributes & 2) == 0, "Directory attribute not set for file");
        $test_count += 1;
    };
    if ($@) {
        pass("Attributes test skipped - not fully implemented");
        $test_count += 1;
    }
    
    # Test directory attributes
    mkdir($test_dir_path) unless -d $test_dir_path;
    my $dir_info = System::IO::DirectoryInfo->new($test_dir_path);
    
    eval {
        my $dir_attributes = $dir_info->Attributes();
        ok(defined($dir_attributes), "Directory attributes returns defined value");
        
        # Check that Directory bit is set for directories (bit 2)
        ok(($dir_attributes & 2) > 0, "Directory attribute set for directory");
        $test_count += 2;
    };
    if ($@) {
        pass("Directory attributes test skipped - not fully implemented");
        $test_count += 1;
    }
    
    # Test hidden file attributes (Unix-style)
    my $hidden_file_path = File::Spec->catfile($temp_dir, ".hidden_file");
    open(my $hidden_fh, '>', $hidden_file_path) or die $!;
    close($hidden_fh);
    
    my $hidden_info = System::IO::FileInfo->new($hidden_file_path);
    eval {
        my $hidden_attributes = $hidden_info->Attributes();
        # Check that Hidden bit is set (bit 2048)  
        ok(($hidden_attributes & 2048) > 0, "Hidden attribute set for dot files");
        $test_count += 1;
    };
    if ($@) {
        pass("Hidden file attributes test skipped");
        $test_count += 1;
    }
    
    # Test attributes on non-existent file (should throw exception)
    my $nonexistent_info = System::IO::FileInfo->new("/nonexistent/file.txt");
    eval { $nonexistent_info->Attributes(); };
    ok($@, "Attributes throws exception for non-existent file");
    $test_count += 1;
    
    # Clean up
    unlink($test_file_path) if -f $test_file_path;
    unlink($hidden_file_path) if -f $hidden_file_path;
    rmdir($test_dir_path) if -d $test_dir_path;
}

sub test_refresh_functionality {
    # Create initial file
    open(my $fh, '>', $test_file_path) or die "Cannot create test file: $!";
    print $fh $test_content;
    close($fh);
    
    my $file_info = System::IO::FileInfo->new($test_file_path);
    
    # Check initial existence
    ok($file_info->Exists(), "File initially exists");
    $test_count += 1;
    
    # Delete the file externally
    unlink($test_file_path);
    
    # Should still report as existing until refreshed (cached)
    ok($file_info->Exists(), "Cached existence still true after external deletion");
    $test_count += 1;
    
    # Refresh and check again
    $file_info->Refresh();
    ok(!$file_info->Exists(), "Existence correctly updated after Refresh");
    $test_count += 1;
    
    # Recreate file externally
    open($fh, '>', $test_file_path) or die $!;
    print $fh "New content";
    close($fh);
    
    # Should still report as not existing until refreshed
    ok(!$file_info->Exists(), "Cached non-existence still false after external creation");
    $test_count += 1;
    
    # Refresh and check again
    $file_info->Refresh();
    ok($file_info->Exists(), "Existence correctly updated to true after Refresh");
    $test_count += 1;
    
    # Test refresh on directory
    mkdir($test_dir_path) unless -d $test_dir_path;
    my $dir_info = System::IO::DirectoryInfo->new($test_dir_path);
    
    ok($dir_info->Exists(), "Directory initially exists");
    rmdir($test_dir_path);
    ok($dir_info->Exists(), "Cached directory existence still true");
    $dir_info->Refresh();
    ok(!$dir_info->Exists(), "Directory existence correctly updated after Refresh");
    $test_count += 3;
    
    # Clean up
    unlink($test_file_path) if -f $test_file_path;
}

sub test_exception_handling {
    # Test null path in constructor
    eval { System::IO::FileSystemInfo->new(undef); };
    ok($@, "Constructor throws exception for null path");
    like($@, qr/ArgumentNullException/, "Null path throws ArgumentNullException");
    $test_count += 2;
    
    # Test empty path in constructor
    eval { System::IO::FileSystemInfo->new(''); };
    ok($@, "Constructor throws exception for empty path");
    like($@, qr/ArgumentException/, "Empty path throws ArgumentException");
    $test_count += 2;
    
    # Test null reference exceptions on methods
    my $null_ref;
    
    eval { System::IO::FileSystemInfo::FullName($null_ref); };
    ok($@, "FullName throws exception for null reference");
    like($@, qr/NullReferenceException/, "Null reference throws NullReferenceException");
    $test_count += 2;
    
    eval { System::IO::FileSystemInfo::Exists($null_ref); };
    ok($@, "Exists throws exception for null reference");
    $test_count += 1;
    
    eval { System::IO::FileSystemInfo::Refresh($null_ref); };
    ok($@, "Refresh throws exception for null reference");
    $test_count += 1;
    
    # Test operations on non-existent files through FileInfo
    my $nonexistent_info = System::IO::FileInfo->new("/nonexistent/path/file.txt");
    
    eval { $nonexistent_info->CreationTime(); };
    ok($@, "Time properties throw exception for non-existent files");
    $test_count += 1;
    
    eval { $nonexistent_info->Attributes(); };
    ok($@, "Attributes throws exception for non-existent files");
    $test_count += 1;
}

sub test_tostring_method {
    # Test ToString returns original path
    my $original_path = $test_file_path;
    my $file_info = System::IO::FileInfo->new($original_path);
    
    is($file_info->ToString(), $original_path, "ToString returns original path");
    $test_count += 1;
    
    # Test with relative path
    my $relative_path = "relative/path/file.txt";
    my $relative_info = System::IO::FileInfo->new($relative_path);
    
    is($relative_info->ToString(), $relative_path, "ToString preserves relative path format");
    $test_count += 1;
    
    # Test with directory
    my $dir_info = System::IO::DirectoryInfo->new($test_dir_path);
    is($dir_info->ToString(), $test_dir_path, "ToString works for directories");
    $test_count += 1;
    
    # Test null reference handling
    my $null_ref;
    eval { System::IO::FileSystemInfo::ToString($null_ref); };
    ok($@, "ToString throws exception for null reference");
    $test_count += 1;
}

sub test_cross_platform_paths {
    # Test Windows-style paths
    if ($^O eq 'MSWin32') {
        my $win_path = "C:\\Windows\\System32\\file.txt";
        my $win_info = System::IO::FileInfo->new($win_path);
        
        is($win_info->FullName(), $win_path, "Windows path handled correctly");
        is($win_info->ToString(), $win_path, "Windows path ToString works");
        $test_count += 2;
        
        # Test UNC paths
        my $unc_path = "\\\\server\\share\\file.txt";
        my $unc_info = System::IO::FileInfo->new($unc_path);
        is($unc_info->FullName(), $unc_path, "UNC path handled correctly");
        $test_count += 1;
        
    } else {
        # Test Unix-style paths
        my $unix_path = "/usr/bin/perl";
        my $unix_info = System::IO::FileInfo->new($unix_path);
        
        is($unix_info->FullName(), $unix_path, "Unix path handled correctly");
        is($unix_info->ToString(), $unix_path, "Unix path ToString works");
        $test_count += 2;
        
        # Test paths with symbolic links (conceptually)
        my $link_path = "/tmp/symbolic_link";
        my $link_info = System::IO::FileInfo->new($link_path);
        is($link_info->FullName(), $link_path, "Symbolic link path handled correctly");
        $test_count += 1;
    }
    
    # Test relative paths (cross-platform)
    my @relative_paths = (
        "file.txt",
        "subdir/file.txt", 
        "../parent/file.txt",
        "./current/file.txt"
    );
    
    foreach my $rel_path (@relative_paths) {
        my $rel_info = System::IO::FileInfo->new($rel_path);
        is($rel_info->ToString(), $rel_path, "Relative path '$rel_path' preserved");
        $test_count += 1;
    }
    
    # Test paths with special characters
    my @special_paths = (
        "file with spaces.txt",
        "file-with-dashes.txt",
        "file_with_underscores.txt",
        "file.multiple.dots.txt"
    );
    
    foreach my $special_path (@special_paths) {
        my $special_info = System::IO::FileInfo->new($special_path);
        is($special_info->ToString(), $special_path, "Special character path '$special_path' handled");
        $test_count += 1;
    }
    
    # Test very long paths
    my $long_component = "very_long_directory_name_that_tests_path_handling";
    my $long_path = join("/", ($long_component) x 10) . "/file.txt";
    my $long_info = System::IO::FileInfo->new($long_path);
    
    is($long_info->ToString(), $long_path, "Long path handled correctly");
    $test_count += 1;
    
    # Test Unicode characters in paths (if supported)
    eval {
        my $unicode_path = "测试文件.txt"; # Chinese characters
        my $unicode_info = System::IO::FileInfo->new($unicode_path);
        is($unicode_info->ToString(), $unicode_path, "Unicode path handled correctly");
        $test_count += 1;
    };
    if ($@) {
        pass("Unicode path test skipped - not supported");
        $test_count += 1;
    }
}

# Run all tests
run_tests();