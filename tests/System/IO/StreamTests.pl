#!/usr/bin/perl
use strict;
use warnings;
use lib '../../../';
use Test::More;

# Define constants
use constant true => 1;
use constant false => 0;

# Import all stream classes
use System::IO::Stream;
use System::IO::MemoryStream;
use System::IO::FileStream;
use System::IO::TextReader;
use System::IO::TextWriter;
use System::IO::StreamReader;
use System::IO::StreamWriter;

sub test_memory_stream {
    # Test empty MemoryStream
    my $ms = System::IO::MemoryStream->new();
    isa_ok($ms, 'System::IO::MemoryStream', 'MemoryStream creation');
    isa_ok($ms, 'System::IO::Stream', 'MemoryStream inherits from Stream');
    
    ok($ms->CanRead(), 'MemoryStream can read');
    ok($ms->CanWrite(), 'MemoryStream can write');
    ok($ms->CanSeek(), 'MemoryStream can seek');
    is($ms->Length(), 0, 'Empty MemoryStream has zero length');
    is($ms->Position(), 0, 'Initial position is zero');
    
    # Test writing to MemoryStream
    my @data = (72, 101, 108, 108, 111); # "Hello"
    $ms->Write(\@data, 0, 5);
    
    is($ms->Length(), 5, 'Length updated after write');
    is($ms->Position(), 5, 'Position updated after write');
    
    # Test reading from MemoryStream
    $ms->Position(0); # Reset position
    my @buffer = (0) x 10;
    my $bytesRead = $ms->Read(\@buffer, 0, 5);
    
    is($bytesRead, 5, 'Read correct number of bytes');
    is_deeply([@buffer[0..4]], \@data, 'Read data matches written data');
    
    # Test ToArray
    my $array = $ms->ToArray();
    isa_ok($array, 'System::Array', 'ToArray returns System::Array');
    is($array->Length(), 5, 'Array has correct length');
    is($array->GetValue(0), 72, 'First byte correct');
    is($array->GetValue(4), 111, 'Last byte correct');
}

sub test_memory_stream_with_initial_data {
    my @initialData = (65, 66, 67, 68, 69); # "ABCDE"
    my $ms = System::IO::MemoryStream->new(\@initialData);
    
    is($ms->Length(), 5, 'MemoryStream initialized with correct length');
    is($ms->Position(), 0, 'Position starts at zero');
    
    # Read data
    my @buffer = (0) x 5;
    my $bytesRead = $ms->Read(\@buffer, 0, 5);
    
    is($bytesRead, 5, 'Read all initial data');
    is_deeply(\@buffer, \@initialData, 'Read data matches initial data');
}

sub test_memory_stream_seeking {
    my @data = (1, 2, 3, 4, 5, 6, 7, 8, 9, 10);
    my $ms = System::IO::MemoryStream->new(\@data);
    
    # Test seeking from beginning
    my $newPos = $ms->Seek(3, 0); # SeekOrigin.Begin
    is($newPos, 3, 'Seek from beginning returns correct position');
    is($ms->Position(), 3, 'Position updated by seek');
    
    # Read byte at position 3
    my $byte = $ms->ReadByte();
    is($byte, 4, 'Read correct byte after seek'); # data[3] = 4
    
    # Test seeking from current position
    $newPos = $ms->Seek(2, 1); # SeekOrigin.Current
    is($newPos, 6, 'Seek from current position correct');
    
    # Test seeking from end
    $newPos = $ms->Seek(-2, 2); # SeekOrigin.End
    is($newPos, 8, 'Seek from end correct');
    
    $byte = $ms->ReadByte();
    is($byte, 9, 'Read correct byte after seek from end'); # data[8] = 9
}

sub test_file_stream {
    my $testFile = "stream_test.txt";
    
    # Clean up any existing test file
    unlink($testFile) if(-e $testFile);
    
    # Test FileStream creation and writing
    my $fs = System::IO::FileStream->new($testFile, 2, 2); # Create, Write
    isa_ok($fs, 'System::IO::FileStream', 'FileStream creation');
    isa_ok($fs, 'System::IO::Stream', 'FileStream inherits from Stream');
    
    ok(!$fs->CanRead(), 'Write-only FileStream cannot read');
    ok($fs->CanWrite(), 'FileStream can write');
    ok($fs->CanSeek(), 'FileStream can seek');
    
    my @data = (72, 101, 108, 108, 111, 32, 87, 111, 114, 108, 100); # "Hello World"
    $fs->Write(\@data, 0, 11);
    $fs->Dispose();
    
    # Test FileStream reading
    $fs = System::IO::FileStream->new($testFile, 3, 1); # Open, Read
    ok($fs->CanRead(), 'Read-only FileStream can read');
    ok(!$fs->CanWrite(), 'Read-only FileStream cannot write');
    
    is($fs->Length(), 11, 'File has correct length');
    
    my @buffer = (0) x 11;
    my $bytesRead = $fs->Read(\@buffer, 0, 11);
    
    is($bytesRead, 11, 'Read all bytes from file');
    is_deeply(\@buffer, \@data, 'File content matches written data');
    
    $fs->Dispose();
    
    # Clean up
    unlink($testFile);
}

sub test_stream_reader {
    # Test with MemoryStream
    my @data = map { ord($_) } split //, "Hello\nWorld\nTest";
    my $ms = System::IO::MemoryStream->new(\@data);
    
    my $reader = System::IO::StreamReader->new($ms);
    isa_ok($reader, 'System::IO::StreamReader', 'StreamReader creation');
    isa_ok($reader, 'System::IO::TextReader', 'StreamReader inherits from TextReader');
    
    ok(!$reader->EndOfStream(), 'Not at end of stream initially');
    
    my $line1 = $reader->ReadLine();
    isa_ok($line1, 'System::String', 'ReadLine returns System::String');
    is($line1->ToString(), "Hello", 'First line correct');
    
    my $line2 = $reader->ReadLine();
    is($line2->ToString(), "World", 'Second line correct');
    
    my $line3 = $reader->ReadLine();
    is($line3->ToString(), "Test", 'Third line correct');
    
    my $line4 = $reader->ReadLine();
    ok(!defined($line4), 'ReadLine returns undef at end of stream');
    
    ok($reader->EndOfStream(), 'At end of stream after reading all data');
    
    $reader->Dispose();
}

sub test_stream_reader_read_to_end {
    my @data = map { ord($_) } split //, "This is a test\nwith multiple lines\nfor ReadToEnd";
    my $ms = System::IO::MemoryStream->new(\@data);
    
    my $reader = System::IO::StreamReader->new($ms);
    my $content = $reader->ReadToEnd();
    
    isa_ok($content, 'System::String', 'ReadToEnd returns System::String');
    is($content->ToString(), "This is a test\nwith multiple lines\nfor ReadToEnd", 'ReadToEnd content correct');
    
    $reader->Dispose();
}

sub test_stream_writer {
    my $ms = System::IO::MemoryStream->new();
    my $writer = System::IO::StreamWriter->new($ms);
    
    isa_ok($writer, 'System::IO::StreamWriter', 'StreamWriter creation');
    isa_ok($writer, 'System::IO::TextWriter', 'StreamWriter inherits from TextWriter');
    
    $writer->Write("Hello");
    $writer->WriteLine(" World");
    $writer->WriteLine("Second line");
    $writer->Flush();
    
    # Read back the data
    $ms->Position(0);
    my $reader = System::IO::StreamReader->new($ms);
    
    my $line1 = $reader->ReadLine();
    is($line1->ToString(), "Hello World", 'First line written correctly');
    
    my $line2 = $reader->ReadLine();
    is($line2->ToString(), "Second line", 'Second line written correctly');
    
    $writer->Dispose();
    $reader->Dispose();
}

sub test_stream_writer_with_file {
    my $testFile = "writer_test.txt";
    
    # Clean up any existing test file
    unlink($testFile) if(-e $testFile);
    
    # Test StreamWriter with file path
    my $writer = System::IO::StreamWriter->new($testFile);
    
    $writer->WriteLine("Line 1");
    $writer->WriteLine("Line 2");
    $writer->WriteFormat("Formatted: %d + %d = %d\n", 2, 3, 5);
    $writer->Dispose();
    
    # Verify file was created and has correct content
    ok(-e $testFile, 'File was created');
    
    my $reader = System::IO::StreamReader->new($testFile);
    my $line1 = $reader->ReadLine();
    is($line1->ToString(), "Line 1", 'File line 1 correct');
    
    my $line2 = $reader->ReadLine();
    is($line2->ToString(), "Line 2", 'File line 2 correct');
    
    my $line3 = $reader->ReadLine();
    is($line3->ToString(), "Formatted: 2 + 3 = 5", 'Formatted line correct');
    
    $reader->Dispose();
    
    # Clean up
    unlink($testFile);
}

sub test_stream_copy_operations {
    # Test copying between streams
    my @sourceData = (1, 2, 3, 4, 5, 6, 7, 8, 9, 10);
    my $source = System::IO::MemoryStream->new(\@sourceData);
    my $destination = System::IO::MemoryStream->new();
    
    $source->CopyTo($destination);
    
    is($destination->Length(), 10, 'Destination has correct length after copy');
    
    my $destArray = $destination->ToArray();
    my @destData = ();
    for my $i (0..$destArray->Length()-1) {
        push @destData, $destArray->GetValue($i);
    }
    
    is_deeply(\@destData, \@sourceData, 'Copied data matches source data');
    
    $source->Dispose();
    $destination->Dispose();
}

sub test_auto_flush {
    my $ms = System::IO::MemoryStream->new();
    my $writer = System::IO::StreamWriter->new($ms);
    
    # Test AutoFlush property
    ok(!$writer->AutoFlush(), 'AutoFlush is false by default');
    
    $writer->AutoFlush(true);
    ok($writer->AutoFlush(), 'AutoFlush can be set to true');
    
    $writer->Write("Test");
    # With AutoFlush on, data should be immediately available
    $ms->Position(0);
    my $reader = System::IO::StreamReader->new($ms);
    my $content = $reader->ReadToEnd();
    is($content->ToString(), "Test", 'AutoFlush works correctly');
    
    $writer->Dispose();
    $reader->Dispose();
}

# Run all tests
test_memory_stream();
test_memory_stream_with_initial_data();
test_memory_stream_seeking();
test_file_stream();
test_stream_reader();
test_stream_reader_read_to_end();
test_stream_writer();
test_stream_writer_with_file();
test_stream_copy_operations();
test_auto_flush();

done_testing();