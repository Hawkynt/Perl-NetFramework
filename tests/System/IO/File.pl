#!/usr/bin/perl
use strict;
use warnings;
use lib '../../../';
use Test::More;
use System;
use File::Temp qw(tempfile tempdir);

BEGIN {
    use_ok('System::IO::File');
}

sub test_file_exists {
    my $tempdir = tempdir(CLEANUP => 1);
    my ($fh, $tempfile) = tempfile(DIR => $tempdir, CLEANUP => 1);
    close $fh;
    
    ok(File::Exists($tempfile), 'Exists returns true for existing file');
    ok(!File::Exists($tempfile . "_nonexistent"), 'Exists returns false for non-existing file');
}

sub test_file_read_write {
    my $tempdir = tempdir(CLEANUP => 1);
    my $testfile = "$tempdir/test.txt";
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
    my $tempdir = tempdir(CLEANUP => 1);
    my $testfile = "$tempdir/append.txt";
    
    File::WriteAllText($testfile, "First line\n");
    File::AppendAllText($testfile, "Second line\n");
    File::AppendAllText($testfile, "Third line");
    
    my $content = File::ReadAllText($testfile);
    like($content, qr/First line.*Second line.*Third line/s, 'AppendAllText works correctly');
}

sub test_file_copy_move {
    my $tempdir = tempdir(CLEANUP => 1);
    my $source = "$tempdir/source.txt";
    my $copy = "$tempdir/copy.txt";
    my $move = "$tempdir/moved.txt";
    
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
    my $tempdir = tempdir(CLEANUP => 1);
    my $testfile = "$tempdir/delete.txt";
    
    File::WriteAllText($testfile, "To be deleted");
    ok(-e $testfile, 'File exists before deletion');
    
    File::Delete($testfile);
    ok(!-e $testfile, 'File no longer exists after deletion');
}

sub test_file_attributes {
    my $tempdir = tempdir(CLEANUP => 1);
    my $testfile = "$tempdir/attributes.txt";
    
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