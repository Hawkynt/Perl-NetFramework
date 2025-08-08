#!/usr/bin/perl
use strict;
use warnings;
use lib '../../';
use Test::More;

# Define constants
use constant true => 1;
use constant false => 0;

# Import all the major System classes for integration testing
use System::Array;
use System::String;
use System::DateTime;
use System::TimeSpan;
use System::Diagnostics::Stopwatch;
use System::IO::File;
use System::IO::Directory;
use System::IO::Path;
use System::Collections::Hashtable;

sub test_datetime_timespan_integration {
    my $dt1 = System::DateTime->new(2023, 1, 1, 12, 0, 0);
    my $dt2 = System::DateTime->new(2023, 1, 2, 12, 0, 0);
    
    # Test DateTime arithmetic with TimeSpan
    my $diff = $dt2->Subtract($dt1);
    isa_ok($diff, 'System::TimeSpan', 'DateTime subtraction creates TimeSpan');
    is($diff->Days(), 1, 'TimeSpan shows correct day difference');
    
    # Test adding TimeSpan to DateTime
    my $timespan = System::TimeSpan->FromHours(6);
    my $dt3 = $dt1->Add($timespan);
    is($dt3->Hour(), 18, 'Adding TimeSpan to DateTime works');
    
    # Test TimeSpan arithmetic
    my $span1 = System::TimeSpan->FromMinutes(30);
    my $span2 = System::TimeSpan->FromMinutes(45);
    my $totalSpan = $span1->Add($span2);
    is($totalSpan->TotalMinutes(), 75, 'TimeSpan addition works');
}

sub test_array_linq_integration {
    my $numbers = System::Array->new(1, 2, 3, 4, 5, 6, 7, 8, 9, 10);
    
    # Test LINQ operations on Array
    my $evenNumbers = $numbers->Where(sub { $_[0] % 2 == 0 })->ToArray();
    is($evenNumbers->Length(), 5, 'LINQ Where filters correctly');
    
    my $doubledNumbers = $numbers->Select(sub { $_[0] * 2 })->ToArray();
    is($doubledNumbers->Length(), 10, 'LINQ Select maintains count');
    is($doubledNumbers->GetValue(0), 2, 'LINQ Select transforms correctly');
    
    # Test mathematical operations
    my $sum = $numbers->Sum();
    is($sum, 55, 'LINQ Sum calculates correctly');
    
    my $average = $numbers->Average();
    is($average, 5.5, 'LINQ Average calculates correctly');
    
    my $min = $numbers->Min();
    is($min, 1, 'LINQ Min finds correct value');
    
    my $max = $numbers->Max();
    is($max, 10, 'LINQ Max finds correct value');
}

sub test_string_array_integration {
    my $words = System::Array->new(
        System::String->new("apple"),
        System::String->new("banana"), 
        System::String->new("cherry"),
        System::String->new("date")
    );
    
    # Test LINQ operations on String Array
    my $longWords = $words->Where(sub { $_[0]->Length() > 5 })->ToArray();
    is($longWords->Length(), 2, 'String length filtering works');
    
    my $upperWords = $words->Select(sub { $_[0]->ToUpper() })->ToArray();
    is($upperWords->GetValue(0)->ToString(), "APPLE", 'String transformation in LINQ works');
    
    # Test string concatenation through LINQ
    my $concatenated = $words->Aggregate(System::String->new(""), sub { 
        $_[0]->Concat($_[1])->Concat(System::String->new(" "))
    });
    like($concatenated->ToString(), qr/apple banana cherry date/, 'String aggregation works');
}

sub test_stopwatch_datetime_integration {
    my $sw = System::Diagnostics::Stopwatch->new();
    my $startTime = System::DateTime->Now();
    
    $sw->Start();
    # Simulate some work
    select(undef, undef, undef, 0.01); # Sleep 10ms
    $sw->Stop();
    
    my $endTime = System::DateTime->Now();
    my $elapsed = $sw->Elapsed();
    
    ok($sw->ElapsedMilliseconds() > 0, 'Stopwatch measured time');
    isa_ok($elapsed, 'System::TimeSpan', 'Stopwatch returns TimeSpan');
    
    # Verify timing correlation
    my $timeDiff = $endTime->Subtract($startTime);
    # Should be roughly similar timing (allowing for variance)
    ok(abs($elapsed->TotalMilliseconds() - $timeDiff->TotalMilliseconds()) < 50, 
       'Stopwatch and DateTime measurements correlate');
}

sub test_io_datetime_integration {
    my $testFile = "integration_test.txt";
    my $testContent = "Integration test at " . System::DateTime->Now()->ToString();
    
    # Clean up any existing test file
    unlink($testFile) if(-e $testFile);
    
    # Write file and test timestamps
    System::IO::File::WriteAllText($testFile, $testContent);
    ok(System::IO::File::Exists($testFile), 'File created successfully');
    
    my $writeTime = System::IO::File::GetLastWriteTime($testFile);
    isa_ok($writeTime, 'System::DateTime', 'File timestamp returns DateTime');
    
    my $now = System::DateTime->Now();
    my $timeDiff = $now->Subtract($writeTime);
    ok($timeDiff->TotalSeconds() < 5, 'File timestamp is recent');
    
    # Test reading back content
    my $readContent = System::IO::File::ReadAllText($testFile);
    isa_ok($readContent, 'System::String', 'File content returns String');
    like($readContent->ToString(), qr/Integration test/, 'File content matches');
    
    # Clean up
    System::IO::File::Delete($testFile);
    ok(!System::IO::File::Exists($testFile), 'Test file cleaned up');
}

sub test_hashtable_array_integration {
    my $data = System::Collections::Hashtable->new();
    
    # Store arrays in hashtable
    $data->Add("numbers", System::Array->new(1, 2, 3, 4, 5));
    $data->Add("strings", System::Array->new("a", "b", "c"));
    $data->Add("mixed", System::Array->new(1, "two", 3.0, true));
    
    # Test retrieval and LINQ operations
    my $numbers = $data->Get("numbers");
    isa_ok($numbers, 'System::Array', 'Retrieved array from hashtable');
    
    my $sum = $numbers->Sum();
    is($sum, 15, 'LINQ operations work on hashtable-stored arrays');
    
    my $strings = $data->Get("strings");
    my $count = $strings->Count();
    is($count, 3, 'String array count is correct');
    
    # Test enumeration of hashtable contents
    my $keys = $data->Keys();
    is($keys->Count(), 3, 'Hashtable has correct number of keys');
}

sub test_path_directory_integration {
    my $testDir = "integration_test_dir";
    my $subDir = "subdir";
    my $testFile = "test.txt";
    
    # Clean up any existing test directory
    if(System::IO::Directory::Exists($testDir)) {
        System::IO::Directory::Delete($testDir, true);
    }
    
    # Create directory structure using Path operations
    System::IO::Directory::Create($testDir);
    my $subDirPath = System::IO::Path::Combine($testDir, $subDir);
    System::IO::Directory::Create($subDirPath->ToString());
    
    # Create test file using Path operations
    my $filePath = System::IO::Path::Combine($subDirPath->ToString(), $testFile);
    System::IO::File::WriteAllText($filePath->ToString(), "Test content");
    
    # Test path decomposition
    my $directory = System::IO::Path::GetDirectoryName($filePath->ToString());
    my $filename = System::IO::Path::GetFileName($filePath->ToString());
    my $extension = System::IO::Path::GetExtension($filePath->ToString());
    
    like($directory->ToString(), qr/subdir/, 'Path directory extraction works');
    is($filename->ToString(), $testFile, 'Path filename extraction works');
    is($extension->ToString(), ".txt", 'Path extension extraction works');
    
    # Test directory enumeration
    my $files = System::IO::Directory::GetFiles($subDirPath->ToString());
    is($files->Length(), 1, 'Directory enumeration finds test file');
    
    # Clean up
    System::IO::Directory::Delete($testDir, true);
    ok(!System::IO::Directory::Exists($testDir), 'Test directory cleaned up');
}

sub test_cross_type_compatibility {
    # Test that different types work together correctly
    my $dt = System::DateTime->new(2023, 6, 15, 14, 30, 0);
    my $str = System::String->new("Current time: ");
    my $combined = $str->Concat($dt->ToString());
    
    like($combined->ToString(), qr/Current time: 2023-06-15 14:30:00/, 
         'String and DateTime integration works');
    
    # Test arrays containing different types
    my $mixedArray = System::Array->new(
        42,
        System::String->new("test"),
        $dt,
        true
    );
    
    is($mixedArray->Length(), 4, 'Mixed type array has correct length');
    isa_ok($mixedArray->GetValue(2), 'System::DateTime', 'DateTime preserved in mixed array');
    
    # Test counting different types
    my $stringCount = $mixedArray->Count(sub { 
        ref($_[0]) && $_[0]->isa('System::String') 
    });
    is($stringCount, 1, 'Type-specific counting works');
}

sub test_performance_integration {
    # Test that the framework can handle reasonably sized data
    my $largeArray = System::Array->new(1..1000);
    
    my $sw = System::Diagnostics::Stopwatch->StartNew();
    my $sum = $largeArray->Sum();
    $sw->Stop();
    
    is($sum, 500500, 'Large array sum is correct');
    ok($sw->ElapsedMilliseconds() < 1000, 'Large array operation completed in reasonable time');
    
    # Test chained operations performance
    $sw->Restart();
    my $result = $largeArray
        ->Where(sub { $_[0] % 2 == 0 })
        ->Select(sub { $_[0] * $_[0] })
        ->Sum();
    $sw->Stop();
    
    ok($result > 0, 'Chained operations produce result');
    ok($sw->ElapsedMilliseconds() < 2000, 'Chained operations complete in reasonable time');
}

# Run all integration tests
test_datetime_timespan_integration();
test_array_linq_integration();
test_string_array_integration();
test_stopwatch_datetime_integration();
test_io_datetime_integration();
test_hashtable_array_integration();
test_path_directory_integration();
test_cross_type_compatibility();
test_performance_integration();

done_testing();