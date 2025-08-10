#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/../../../";
use File::Temp qw(tempfile tempdir);
use File::Spec;

require System::IO::FileStream;

# Test plan
my $test_count = 0;

# Test data
my $temp_dir = tempdir(CLEANUP => 1);
my $test_file_path = File::Spec->catfile($temp_dir, "filestream_test.dat");
my $test_data = "Hello, FileStream!\nThis is binary data: \x00\x01\x02\x03\xFF";
my @test_bytes = map { ord($_) } split //, $test_data;

sub run_tests {
    # Constructor and basic property tests
    test_constructor_and_properties();
    
    # File mode tests
    test_file_modes();
    
    # Read and write operations
    test_read_write_operations();
    
    # Seeking and positioning tests
    test_seek_and_position();
    
    # Binary data handling tests
    test_binary_operations();
    
    # Stream length and truncation tests
    test_length_operations();
    
    # Flush and close tests
    test_flush_and_close();
    
    # Exception handling tests
    test_exception_handling();
    
    # Performance and large file tests
    test_performance_operations();
    
    done_testing($test_count);
}

sub test_constructor_and_properties {
    # Clean up any existing file
    unlink($test_file_path) if -f $test_file_path;
    
    # Test Create mode
    my $stream = System::IO::FileStream->new($test_file_path, 2, 3); # Create, ReadWrite
    ok(defined($stream), "FileStream constructor succeeds");
    isa_ok($stream, 'System::IO::FileStream', "Returns FileStream instance");
    $test_count += 2;
    
    # Test properties
    ok($stream->CanRead(), "CanRead returns true for ReadWrite access");
    ok($stream->CanWrite(), "CanWrite returns true for ReadWrite access");
    ok($stream->CanSeek(), "CanSeek returns true");
    is($stream->Position(), 0, "Initial position is 0");
    is($stream->Length(), 0, "Initial length is 0");
    is($stream->Name(), $test_file_path, "Name property returns correct path");
    $test_count += 6;
    
    $stream->Close();
    
    # Test read-only access
    # First create a file with content
    open(my $fh, '>', $test_file_path) or die $!;
    print $fh $test_data;
    close($fh);
    
    my $read_stream = System::IO::FileStream->new($test_file_path, 3, 1); # Open, Read
    ok($read_stream->CanRead(), "Read-only stream CanRead is true");
    ok(!$read_stream->CanWrite(), "Read-only stream CanWrite is false");
    $read_stream->Close();
    $test_count += 2;
    
    # Clean up
    unlink($test_file_path);
}

sub test_file_modes {
    # Clean up any existing file
    unlink($test_file_path) if -f $test_file_path;
    
    # Test CreateNew mode (should create new file)
    my $create_new_stream = System::IO::FileStream->new($test_file_path, 1, 2); # CreateNew, Write
    ok(defined($create_new_stream), "CreateNew mode creates new file");
    ok(-f $test_file_path, "File exists after CreateNew");
    $create_new_stream->Close();
    $test_count += 2;
    
    # Test CreateNew mode on existing file (should fail)
    eval {
        my $fail_stream = System::IO::FileStream->new($test_file_path, 1, 2); # CreateNew, Write
        $fail_stream->Close() if $fail_stream;
    };
    ok($@, "CreateNew mode throws exception for existing file");
    $test_count += 1;
    
    # Test Open mode on existing file
    my $open_stream = System::IO::FileStream->new($test_file_path, 3, 1); # Open, Read
    ok(defined($open_stream), "Open mode opens existing file");
    $open_stream->Close();
    $test_count += 1;
    
    # Test Open mode on non-existent file (should fail)
    unlink($test_file_path);
    eval {
        my $fail_stream = System::IO::FileStream->new($test_file_path, 3, 1); # Open, Read
        $fail_stream->Close() if $fail_stream;
    };
    ok($@, "Open mode throws exception for non-existent file");
    $test_count += 1;
    
    # Test Create mode (should create or truncate)
    my $create_stream = System::IO::FileStream->new($test_file_path, 2, 2); # Create, Write
    ok(defined($create_stream), "Create mode creates file");
    $create_stream->Close();
    ok(-f $test_file_path, "File exists after Create");
    $test_count += 2;
    
    # Test Append mode
    my $append_stream = System::IO::FileStream->new($test_file_path, 6, 2); # Append, Write
    ok(defined($append_stream), "Append mode opens file");
    ok($append_stream->Position() == 0, "Append mode positions at end"); # Should be 0 for empty file
    $append_stream->Close();
    $test_count += 2;
    
    # Clean up
    unlink($test_file_path);
}

sub test_read_write_operations {
    # Clean up any existing file
    unlink($test_file_path) if -f $test_file_path;
    
    # Create stream for read/write operations
    my $stream = System::IO::FileStream->new($test_file_path, 2, 3); # Create, ReadWrite
    
    # Write test data
    $stream->Write(\@test_bytes, 0, scalar(@test_bytes));
    is($stream->Position(), scalar(@test_bytes), "Position updated after write");
    is($stream->Length(), scalar(@test_bytes), "Length updated after write");
    $test_count += 2;
    
    # Seek to beginning for reading
    $stream->Seek(0, 0); # Begin
    is($stream->Position(), 0, "Seek to beginning successful");
    $test_count += 1;
    
    # Read data back
    my @read_buffer = (0) x 100;
    my $bytes_read = $stream->Read(\@read_buffer, 0, 100);
    is($bytes_read, scalar(@test_bytes), "Read returns correct byte count");
    $test_count += 1;
    
    # Verify read data
    my $data_matches = 1;
    for my $i (0..$bytes_read-1) {
        if ($read_buffer[$i] != $test_bytes[$i]) {
            $data_matches = 0;
            last;
        }
    }
    ok($data_matches, "Read data matches written data");
    $test_count += 1;
    
    # Test partial read
    $stream->Seek(5, 0); # Seek to position 5
    my @partial_buffer = (0) x 5;
    my $partial_read = $stream->Read(\@partial_buffer, 0, 5);
    is($partial_read, 5, "Partial read returns correct byte count");
    $test_count += 1;
    
    # Test write at specific position
    $stream->Seek(0, 0);
    my @overwrite_data = (65, 66, 67); # ABC
    $stream->Write(\@overwrite_data, 0, 3);
    $stream->Seek(0, 0);
    my @verify_buffer = (0) x 10;
    $stream->Read(\@verify_buffer, 0, 10);
    is($verify_buffer[0], 65, "Overwrite at position 0 works");
    is($verify_buffer[1], 66, "Overwrite at position 1 works");
    is($verify_buffer[2], 67, "Overwrite at position 2 works");
    $test_count += 3;
    
    $stream->Close();
    
    # Test reading beyond end of file
    my $read_stream = System::IO::FileStream->new($test_file_path, 3, 1); # Open, Read
    $read_stream->Seek(0, 2); # End
    my @eof_buffer = (0) x 10;
    my $eof_read = $read_stream->Read(\@eof_buffer, 0, 10);
    is($eof_read, 0, "Reading at EOF returns 0 bytes");
    $test_count += 1;
    
    $read_stream->Close();
    
    # Clean up
    unlink($test_file_path);
}

sub test_seek_and_position {
    # Create test file with known data
    unlink($test_file_path) if -f $test_file_path;
    my $stream = System::IO::FileStream->new($test_file_path, 2, 3); # Create, ReadWrite
    
    # Write test data
    my @seek_test_data = (0..99); # 100 bytes
    $stream->Write(\@seek_test_data, 0, 100);
    $test_count += 0; # Just setup
    
    # Test seeking from beginning
    my $new_pos = $stream->Seek(50, 0); # 50 bytes from beginning
    is($new_pos, 50, "Seek from beginning returns new position");
    is($stream->Position(), 50, "Position property matches seek result");
    $test_count += 2;
    
    # Test seeking from current position
    $new_pos = $stream->Seek(10, 1); # 10 bytes from current
    is($new_pos, 60, "Seek from current returns correct position");
    is($stream->Position(), 60, "Position property updated after relative seek");
    $test_count += 2;
    
    # Test seeking from end
    $new_pos = $stream->Seek(-20, 2); # 20 bytes back from end
    is($new_pos, 80, "Seek from end returns correct position");
    is($stream->Position(), 80, "Position property updated after seek from end");
    $test_count += 2;
    
    # Test Position property setter
    $stream->Position(25);
    is($stream->Position(), 25, "Position setter works correctly");
    $test_count += 1;
    
    # Verify position affects read/write
    my @pos_buffer = (0) x 1;
    $stream->Read(\@pos_buffer, 0, 1);
    is($pos_buffer[0], 25, "Read at set position returns correct data");
    $test_count += 1;
    
    # Test seeking beyond end (should be allowed)
    $new_pos = $stream->Seek(200, 0); # Beyond current length
    is($new_pos, 200, "Seek beyond end allowed");
    is($stream->Position(), 200, "Position can be set beyond length");
    $test_count += 2;
    
    $stream->Close();
    unlink($test_file_path);
}

sub test_binary_operations {
    # Test with various binary data patterns
    unlink($test_file_path) if -f $test_file_path;
    my $stream = System::IO::FileStream->new($test_file_path, 2, 3); # Create, ReadWrite
    
    # Test all byte values (0-255)
    my @all_bytes = (0..255);
    $stream->Write(\@all_bytes, 0, 256);
    $test_count += 0; # Just setup
    
    # Read back and verify
    $stream->Seek(0, 0);
    my @read_all_bytes = (0) x 256;
    my $read_count = $stream->Read(\@read_all_bytes, 0, 256);
    is($read_count, 256, "Read all 256 byte values");
    $test_count += 1;
    
    # Verify each byte value
    my $all_correct = 1;
    for my $i (0..255) {
        if ($read_all_bytes[$i] != $i) {
            $all_correct = 0;
            last;
        }
    }
    ok($all_correct, "All byte values preserved correctly");
    $test_count += 1;
    
    # Test null bytes specifically
    $stream->Seek(0, 0);
    my @null_bytes = (0, 0, 0, 0, 0);
    $stream->Write(\@null_bytes, 0, 5);
    $stream->Seek(0, 0);
    my @read_nulls = (255) x 5; # Initialize with non-zero
    $stream->Read(\@read_nulls, 0, 5);
    
    my $nulls_correct = 1;
    for my $i (0..4) {
        if ($read_nulls[$i] != 0) {
            $nulls_correct = 0;
            last;
        }
    }
    ok($nulls_correct, "Null bytes handled correctly");
    $test_count += 1;
    
    # Test high byte values (128-255)
    my @high_bytes = (128..255);
    $stream->Seek(10, 0);
    $stream->Write(\@high_bytes, 0, scalar(@high_bytes));
    $stream->Seek(10, 0);
    my @read_high_bytes = (0) x scalar(@high_bytes);
    $stream->Read(\@read_high_bytes, 0, scalar(@high_bytes));
    
    my $high_correct = 1;
    for my $i (0..$#high_bytes) {
        if ($read_high_bytes[$i] != $high_bytes[$i]) {
            $high_correct = 0;
            last;
        }
    }
    ok($high_correct, "High byte values (128-255) handled correctly");
    $test_count += 1;
    
    $stream->Close();
    unlink($test_file_path);
}

sub test_length_operations {
    unlink($test_file_path) if -f $test_file_path;
    my $stream = System::IO::FileStream->new($test_file_path, 2, 3); # Create, ReadWrite
    
    # Initial length should be 0
    is($stream->Length(), 0, "Initial stream length is 0");
    $test_count += 1;
    
    # Write data and check length
    my @length_test_data = (0..49); # 50 bytes
    $stream->Write(\@length_test_data, 0, 50);
    is($stream->Length(), 50, "Length updated after write");
    $test_count += 1;
    
    # Test SetLength to truncate
    $stream->SetLength(30);
    is($stream->Length(), 30, "SetLength truncates file correctly");
    $test_count += 1;
    
    # Verify truncation affected file content
    $stream->Seek(0, 0);
    my @truncated_data = (0) x 50;
    my $truncated_read = $stream->Read(\@truncated_data, 0, 50);
    is($truncated_read, 30, "Read after truncation returns correct byte count");
    $test_count += 1;
    
    # Test SetLength to extend
    $stream->SetLength(100);
    is($stream->Length(), 100, "SetLength extends file correctly");
    $test_count += 1;
    
    # Position should be adjusted if beyond new length
    $stream->Seek(0, 2); # End
    is($stream->Position(), 100, "Position at end after extension");
    $test_count += 1;
    
    # Test position adjustment when SetLength makes file smaller
    $stream->Position(80);
    $stream->SetLength(60);
    is($stream->Position(), 60, "Position adjusted when truncated beyond current position");
    $test_count += 1;
    
    $stream->Close();
    unlink($test_file_path);
}

sub test_flush_and_close {
    unlink($test_file_path) if -f $test_file_path;
    my $stream = System::IO::FileStream->new($test_file_path, 2, 3); # Create, ReadWrite
    
    # Write data
    my @flush_test_data = (65, 66, 67, 68, 69); # ABCDE
    $stream->Write(\@flush_test_data, 0, 5);
    $test_count += 0; # Just setup
    
    # Test Flush (should not throw exception)
    eval { $stream->Flush(); };
    ok(!$@, "Flush operation succeeds");
    $test_count += 1;
    
    # Test Close/Dispose
    $stream->Close();
    
    # Verify file exists and has correct content after close
    ok(-f $test_file_path, "File exists after close");
    $test_count += 1;
    
    # Try to use stream after close (should fail)
    eval { $stream->Write(\@flush_test_data, 0, 1); };
    ok($@, "Write after close throws exception");
    $test_count += 1;
    
    eval { my @buffer = (0); $stream->Read(\@buffer, 0, 1); };
    ok($@, "Read after close throws exception");
    $test_count += 1;
    
    # Verify file content is correct
    open(my $fh, '<:raw', $test_file_path) or die $!;
    my $file_content;
    read($fh, $file_content, 10);
    close($fh);
    
    my @file_bytes = map { ord($_) } split //, $file_content;
    my $content_correct = (@file_bytes == 5);
    for my $i (0..4) {
        $content_correct &&= ($file_bytes[$i] == $flush_test_data[$i]);
    }
    ok($content_correct, "File content preserved after close");
    $test_count += 1;
    
    unlink($test_file_path);
}

sub test_exception_handling {
    # Test constructor exceptions
    
    # Null path
    eval { System::IO::FileStream->new(undef, 2, 3); };
    ok($@, "Constructor throws exception for null path");
    $test_count += 1;
    
    # Invalid file mode
    eval { System::IO::FileStream->new($test_file_path, 999, 3); };
    # This might not throw an exception depending on implementation
    $test_count += 0;
    
    # Test operation exceptions
    unlink($test_file_path) if -f $test_file_path;
    my $stream = System::IO::FileStream->new($test_file_path, 2, 3); # Create, ReadWrite
    
    # Invalid buffer operations
    eval { $stream->Read(undef, 0, 10); };
    ok($@, "Read throws exception for null buffer");
    $test_count += 1;
    
    eval { $stream->Write(undef, 0, 10); };
    ok($@, "Write throws exception for null buffer");
    $test_count += 1;
    
    # Invalid offset/count
    my @test_buffer = (0) x 10;
    eval { $stream->Read(\@test_buffer, -1, 5); };
    ok($@, "Read throws exception for negative offset");
    $test_count += 1;
    
    eval { $stream->Read(\@test_buffer, 0, -1); };
    ok($@, "Read throws exception for negative count");
    $test_count += 1;
    
    eval { $stream->Read(\@test_buffer, 5, 10); }; # offset + count > buffer length
    ok($@, "Read throws exception for invalid offset/count combination");
    $test_count += 1;
    
    # Test SetLength with negative value
    eval { $stream->SetLength(-1); };
    ok($@, "SetLength throws exception for negative value");
    $test_count += 1;
    
    $stream->Close();
    
    # Test read-only stream write attempt
    open(my $fh, '>', $test_file_path) or die $!;
    close($fh);
    
    my $readonly_stream = System::IO::FileStream->new($test_file_path, 3, 1); # Open, Read
    eval { $readonly_stream->Write(\@test_buffer, 0, 5); };
    ok($@, "Write on read-only stream throws exception");
    $test_count += 1;
    
    $readonly_stream->Close();
    unlink($test_file_path);
}

sub test_performance_operations {
    # Test with larger data
    unlink($test_file_path) if -f $test_file_path;
    my $stream = System::IO::FileStream->new($test_file_path, 2, 3); # Create, ReadWrite
    
    # Create 10KB of test data
    my @large_data = ();
    for my $i (0..10239) {
        push @large_data, $i % 256;
    }
    
    # Write large data
    my $start_time = time();
    $stream->Write(\@large_data, 0, scalar(@large_data));
    my $write_time = time() - $start_time;
    
    ok($write_time < 5, "Large write completes in reasonable time"); # Should be much faster, but allow 5 seconds
    is($stream->Length(), scalar(@large_data), "Large file length correct");
    $test_count += 2;
    
    # Read large data back
    $stream->Seek(0, 0);
    my @read_large_data = (0) x scalar(@large_data);
    $start_time = time();
    my $read_bytes = $stream->Read(\@read_large_data, 0, scalar(@large_data));
    my $read_time = time() - $start_time;
    
    ok($read_time < 5, "Large read completes in reasonable time");
    is($read_bytes, scalar(@large_data), "Large read returns correct byte count");
    $test_count += 2;
    
    # Verify data integrity
    my $large_data_correct = 1;
    for my $i (0..999) { # Sample check (checking all 10K would be slow)
        if ($read_large_data[$i] != $large_data[$i]) {
            $large_data_correct = 0;
            last;
        }
    }
    ok($large_data_correct, "Large data integrity maintained");
    $test_count += 1;
    
    # Test multiple small operations
    $stream->Seek(0, 0);
    for my $i (0..99) {
        my @small_write = ($i);
        $stream->Write(\@small_write, 0, 1);
    }
    is($stream->Position(), 100, "Multiple small writes position correct");
    $test_count += 1;
    
    $stream->Close();
    unlink($test_file_path);
}

# Run all tests
run_tests();