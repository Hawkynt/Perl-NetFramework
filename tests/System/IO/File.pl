#!/usr/bin/perl
use strict;
use warnings;
use lib '../../../';
use Test::More;
use System;
use File::Spec;

BEGIN {
    use_ok('System::IO::File');
}

# Simple cross-platform temp file helper
sub create_temp_file {
    my ($suffix) = @_;
    $suffix ||= '.tmp';
    
    # Use a simple time-based temp name in current directory for cross-platform compatibility
    my $tempfile = "test_temp_" . time() . "_$$" . $suffix;
    
    # Return just the filename - we're already in the right directory
    return $tempfile;
}

my @temp_files_to_cleanup = ();

sub test_file_exists {
    my $tempfile = create_temp_file('.tmp');
    push @temp_files_to_cleanup, $tempfile;
    
    # Create the temp file
    open my $fh, '>', $tempfile or die "Cannot create temp file: $!";
    close $fh;
    
    ok(File::Exists($tempfile), 'Exists returns true for existing file');
    ok(!File::Exists($tempfile . "_nonexistent"), 'Exists returns false for non-existing file');
}

sub test_file_read_write {
    my $testfile = create_temp_file('_test.txt');
    push @temp_files_to_cleanup, $testfile;
    
    my $content = "Hello, World!\nSecond line.";
    
    File::WriteAllText($testfile, $content);
    ok(-e $testfile, 'File was created');
    
    my $readContent = File::ReadAllText($testfile);
    is($readContent, $content, 'ReadAllText returns correct content');
    
    my $lines = File::ReadAllLines($testfile);
    is($lines->Length(), 2, 'ReadAllLines returns correct number of lines');
    is($lines->Get(0), "Hello, World!", 'First line correct');
    is($lines->Get(1), "Second line.", 'Second line correct');
}

sub test_file_append {
    my $testfile = create_temp_file('_append.txt');
    push @temp_files_to_cleanup, $testfile;
    
    File::WriteAllText($testfile, "First line\n");
    File::AppendAllText($testfile, "Second line\n");
    File::AppendAllText($testfile, "Third line");
    
    my $content = File::ReadAllText($testfile);
    like($content, qr/First line.*Second line.*Third line/s, 'AppendAllText works correctly');
}

sub test_file_copy_move {
    my $source = create_temp_file('_source.txt');
    my $copy = create_temp_file('_copy.txt');
    my $move = create_temp_file('_moved.txt');
    push @temp_files_to_cleanup, ($source, $copy, $move);
    
    File::WriteAllText($source, "Test content");
    
    File::Copy($source, $copy);
    ok(-e $copy, 'File was copied');
    is(File::ReadAllText($copy), "Test content", 'Copied file has correct content');
    
    File::Move($copy, $move);
    ok(-e $move, 'File was moved to new location');
    ok(!-e $copy, 'Original copy location no longer exists');
    is(File::ReadAllText($move), "Test content", 'Moved file has correct content');
}

sub test_file_delete {
    my $testfile = create_temp_file('_delete.txt');
    push @temp_files_to_cleanup, $testfile;
    
    File::WriteAllText($testfile, "To be deleted");
    ok(-e $testfile, 'File exists before deletion');
    
    File::Delete($testfile);
    ok(!-e $testfile, 'File no longer exists after deletion');
}

sub test_file_attributes {
    my $testfile = create_temp_file('_attributes.txt');
    push @temp_files_to_cleanup, $testfile;
    
    File::WriteAllText($testfile, "Test");
    
    my $size = File::GetSize($testfile);
    is($size, 4, 'GetSize returns correct file size');
    
    my $lastWrite = File::GetLastWriteTime($testfile);
    ok(defined($lastWrite), 'GetLastWriteTime returns a value');
    
    my $creation = File::GetCreationTime($testfile);
    ok(defined($creation), 'GetCreationTime returns a value');
}

test_file_exists();
test_file_read_write();
test_file_append();
test_file_copy_move();
test_file_delete();
test_file_attributes();

done_testing();

# Cleanup temp files
for my $file (@temp_files_to_cleanup) {
    unlink $file if -e $file;
}