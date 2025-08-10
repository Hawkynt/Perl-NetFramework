#!/usr/bin/perl
use strict;
use warnings;
use lib '../../../';
use Test::More;
use Time::HiRes qw(time sleep);
use Config;
use POSIX qw(getpid);

# Define constants
use constant true => 1;
use constant false => 0;
use constant STRESS_TEST_DURATION => 10; # seconds
use constant PERFORMANCE_ITERATIONS => 10000;
use constant MEMORY_TEST_OBJECTS => 1000;
use constant CONCURRENT_THREADS => 10;
use constant LOAD_TEST_OPERATIONS => 100000;

# Import classes for testing
use System::Diagnostics::Stopwatch;
use System::TimeSpan;
use System::Object;
use System::String;
use System::Array;
use System::Collections::Hashtable;
use System::Random;
use System::Math;

BEGIN {
    use_ok('System::Diagnostics::Stopwatch');
    use_ok('System::TimeSpan');
}

# Performance monitoring utilities
package PerformanceMonitor {
    sub new {
        my ($class) = @_;
        return bless {
            start_time => Time::HiRes::time(),
            measurements => [],
            memory_snapshots => [],
            peak_memory => 0,
            operations_count => 0
        }, $class;
    }
    
    sub start_operation {
        my ($self, $name) = @_;
        return {
            name => $name,
            start_time => Time::HiRes::time(),
            start_memory => $self->get_memory_usage()
        };
    }
    
    sub end_operation {
        my ($self, $operation) = @_;
        my $end_time = Time::HiRes::time();
        my $end_memory = $self->get_memory_usage();
        
        my $result = {
            name => $operation->{name},
            duration => $end_time - $operation->{start_time},
            memory_delta => $end_memory - $operation->{start_memory},
            start_memory => $operation->{start_memory},
            end_memory => $end_memory
        };
        
        push @{$self->{measurements}}, $result;
        $self->{operations_count}++;
        
        if ($end_memory > $self->{peak_memory}) {
            $self->{peak_memory} = $end_memory;
        }
        
        return $result;
    }
    
    sub get_memory_usage {
        my ($self) = @_;
        # Simple memory estimation based on Perl's internal structures
        # This is platform-dependent and approximate
        my $memory = 0;
        
        if (open(my $fh, '<', "/proc/$$/status")) {
            while (my $line = <$fh>) {
                if ($line =~ /^VmRSS:\s*(\d+)\s*kB/) {
                    $memory = $1 * 1024; # Convert to bytes
                    last;
                }
            }
            close($fh);
        } elsif ($^O eq 'MSWin32') {
            # Windows - use tasklist command as approximation
            my $pid = $$;
            my $output = `tasklist /fi "PID eq $pid" /fo csv`;
            if ($output =~ /,"([\d,]+) K"/) {
                my $mem_str = $1;
                $mem_str =~ s/,//g;
                $memory = $mem_str * 1024; # Convert to bytes
            }
        }
        
        return $memory || 1; # Return 1 if we can't determine memory
    }
    
    sub get_statistics {
        my ($self) = @_;
        return undef unless @{$self->{measurements}};
        
        my @durations = map { $_->{duration} } @{$self->{measurements}};
        my @memory_deltas = map { $_->{memory_delta} } @{$self->{measurements}};
        
        my $total_duration = Time::HiRes::time() - $self->{start_time};
        
        return {
            operations_count => $self->{operations_count},
            total_duration => $total_duration,
            avg_operation_time => (List::Util::sum(@durations) / @durations),
            min_operation_time => (List::Util::min(@durations)),
            max_operation_time => (List::Util::max(@durations)),
            operations_per_second => $self->{operations_count} / $total_duration,
            avg_memory_delta => (List::Util::sum(@memory_deltas) / @memory_deltas),
            peak_memory => $self->{peak_memory},
            current_memory => $self->get_memory_usage()
        };
    }
    
    sub print_report {
        my ($self, $test_name) = @_;
        my $stats = $self->get_statistics();
        return unless $stats;
        
        Test::More::diag("=== Performance Report: $test_name ===");
        Test::More::diag(sprintf("Operations: %d", $stats->{operations_count}));
        Test::More::diag(sprintf("Total duration: %.3f seconds", $stats->{total_duration}));
        Test::More::diag(sprintf("Operations/second: %.1f", $stats->{operations_per_second}));
        Test::More::diag(sprintf("Avg operation time: %.6f seconds", $stats->{avg_operation_time}));
        Test::More::diag(sprintf("Min/Max operation time: %.6f / %.6f seconds", 
                                $stats->{min_operation_time}, $stats->{max_operation_time}));
        Test::More::diag(sprintf("Peak memory: %.2f MB", $stats->{peak_memory} / 1048576));
        Test::More::diag(sprintf("Current memory: %.2f MB", $stats->{current_memory} / 1048576));
    }
};

# List::Util fallback for older Perl versions
BEGIN {
    eval { 
        require List::Util; 
        List::Util->import('sum', 'min', 'max'); 
        1 
    } or do {
        *List::Util::sum = sub { my $s = 0; $s += $_ for @_; $s };
        *List::Util::min = sub { my $m = $_[0]; $m = $_ < $m ? $_ : $m for @_; $m };
        *List::Util::max = sub { my $m = $_[0]; $m = $_ > $m ? $_ : $m for @_; $m };
    };
}

sub test_stopwatch_performance_stress {
    diag("Testing Stopwatch performance under stress");
    
    my $monitor = PerformanceMonitor->new();
    my $iterations = PERFORMANCE_ITERATIONS;
    my $errors = 0;
    
    for my $i (1..$iterations) {
        my $op = $monitor->start_operation("stopwatch_cycle");
        
        eval {
            my $sw = System::Diagnostics::Stopwatch->new();
            $sw->Start();
            
            # Simulate some work
            my $dummy = 0;
            $dummy++ for (1..100);
            
            $sw->Stop();
            my $elapsed = $sw->ElapsedTicks();
            
            # Verify result is reasonable
            if ($elapsed < 0) {
                $errors++;
            }
            
            $sw->Reset();
        };
        if ($@) {
            $errors++;
            diag("Error in iteration $i: $@") if $i <= 10; # Only show first 10 errors
        }
        
        $monitor->end_operation($op);
        
        # Progress indicator
        if ($i % 1000 == 0) {
            diag("Completed $i/$iterations iterations...");
        }
    }
    
    $monitor->print_report("Stopwatch Performance Stress");
    
    my $stats = $monitor->get_statistics();
    ok($errors == 0, "No errors in $iterations Stopwatch operations");
    ok($stats->{operations_per_second} > 1000, 
       sprintf("Stopwatch operations are fast enough: %.1f ops/sec", $stats->{operations_per_second}));
    ok($stats->{avg_operation_time} < 0.001, 
       sprintf("Average operation time is reasonable: %.6f seconds", $stats->{avg_operation_time}));
    
    return { errors => $errors, stats => $stats };
}

sub test_system_objects_memory_stress {
    diag("Testing System objects memory usage under stress");
    
    my $monitor = PerformanceMonitor->new();
    my $objects = MEMORY_TEST_OBJECTS;
    my $errors = 0;
    my @created_objects;
    
    # Test object creation stress
    for my $i (1..$objects) {
        my $op = $monitor->start_operation("object_creation");
        
        eval {
            # Create various types of objects
            my $obj = System::Object->new();
            my $str = System::String->new("Test string $i");
            my $arr = System::Array->new([1, 2, 3, $i]);
            my $hash = System::Collections::Hashtable->new();
            my $ts = System::TimeSpan->FromSeconds($i);
            my $sw = System::Diagnostics::Stopwatch->new();
            
            # Store some to prevent immediate garbage collection
            if ($i % 100 == 0) {
                push @created_objects, [$obj, $str, $arr, $hash, $ts, $sw];
            }
            
            # Test basic operations
            my $str_len = $str->Length();
            my $arr_len = $arr->Length();
            $hash->Add("key$i", "value$i");
            my $ts_ms = $ts->TotalMilliseconds();
            
            # Verify results are reasonable
            if ($str_len != length("Test string $i") || $arr_len != 4) {
                $errors++;
            }
        };
        if ($@) {
            $errors++;
            diag("Error creating objects in iteration $i: $@") if $i <= 10;
        }
        
        $monitor->end_operation($op);
        
        if ($i % 100 == 0) {
            diag("Created $i/$objects objects...");
        }
    }
    
    # Test accessing stored objects
    for my $i (0..$#created_objects) {
        my $op = $monitor->start_operation("object_access");
        
        eval {
            my ($obj, $str, $arr, $hash, $ts, $sw) = @{$created_objects[$i]};
            
            # Access methods to ensure objects are still valid
            my $obj_str = $obj->ToString();
            my $str_len = $str->Length();
            my $arr_val = $arr->GetValue(0);
            my $hash_count = $hash->Count();
            my $ts_secs = $ts->TotalSeconds();
            my $sw_running = $sw->IsRunning();
            
            # Verify basic functionality
            if (!defined($obj_str) || $str_len <= 0) {
                $errors++;
            }
        };
        if ($@) {
            $errors++;
            diag("Error accessing stored object $i: $@") if $i <= 5;
        }
        
        $monitor->end_operation($op);
    }
    
    $monitor->print_report("System Objects Memory Stress");
    
    my $stats = $monitor->get_statistics();
    ok($errors == 0, "No errors in memory stress test with $objects objects");
    ok($stats->{operations_per_second} > 100, 
       sprintf("Object operations are fast enough: %.1f ops/sec", $stats->{operations_per_second}));
    
    # Memory should not grow excessively
    my $memory_per_object = $stats->{peak_memory} / $objects;
    diag(sprintf("Estimated memory per object: %.1f bytes", $memory_per_object));
    
    return { errors => $errors, stats => $stats };
}

sub test_concurrent_stress {
    diag("Testing concurrent operations under stress");
    
    unless ($Config{useithreads}) {
        diag("Threads not available, skipping concurrent stress tests");
        return { errors => 0, stats => {} };
    }
    
    use threads;
    use threads::shared;
    
    my @results :shared;
    my @errors :shared;
    my $num_threads = CONCURRENT_THREADS;
    my $operations_per_thread = 1000;
    
    my @threads;
    for my $thread_id (1..$num_threads) {
        my $thread = threads->create(sub {
            my $id = shift;
            my $thread_errors = 0;
            my $start_time = Time::HiRes::time();
            
            for my $i (1..$operations_per_thread) {
                eval {
                    # Mix of different operations
                    my $sw = System::Diagnostics::Stopwatch->StartNew();
                    
                    # Create and manipulate various objects
                    my $str = System::String->new("Thread $id iteration $i");
                    my $arr = System::Array->new([1, 2, $i]);
                    my $hash = System::Collections::Hashtable->new();
                    
                    $hash->Add("thread", $id);
                    $hash->Add("iteration", $i);
                    
                    # Some computation
                    my $math_result = System::Math->Abs(-$i);
                    my $random = System::Random->new($i);
                    my $rand_val = $random->Next(1, 100);
                    
                    # TimeSpan operations
                    my $ts = System::TimeSpan->FromMilliseconds($i);
                    my $ts_seconds = $ts->TotalSeconds();
                    
                    $sw->Stop();
                    my $elapsed = $sw->ElapsedMicroseconds();
                    
                    # Verify results are reasonable
                    if ($math_result != $i || $rand_val < 1 || $rand_val > 100 || $elapsed < 0) {
                        $thread_errors++;
                    }
                };
                if ($@) {
                    $thread_errors++;
                }
            }
            
            my $end_time = Time::HiRes::time();
            my $duration = $end_time - $start_time;
            my $ops_per_sec = $operations_per_thread / $duration;
            
            push @results, "Thread$id:$operations_per_thread:$duration:$ops_per_sec";
            push @errors, "Thread$id:$thread_errors" if $thread_errors > 0;
            
        }, $thread_id);
        
        push @threads, $thread;
    }
    
    # Wait for all threads
    for my $thread (@threads) {
        $thread->join();
    }
    
    # Analyze results
    my $total_operations = $num_threads * $operations_per_thread;
    my $total_errors = scalar(@errors);
    my @thread_stats;
    
    for my $result (@results) {
        my ($thread, $ops, $duration, $ops_per_sec) = split /:/, $result;
        push @thread_stats, {
            thread => $thread,
            operations => $ops,
            duration => $duration,
            ops_per_second => $ops_per_sec
        };
    }
    
    diag("Concurrent stress test completed:");
    diag("Total operations: $total_operations");
    diag("Total errors: $total_errors");
    
    my $total_ops_per_sec = 0;
    my $total_duration = 0;
    for my $stat (@thread_stats) {
        diag(sprintf("%s: %d ops in %.3fs (%.1f ops/sec)", 
                     $stat->{thread}, $stat->{operations}, $stat->{duration}, $stat->{ops_per_second}));
        $total_ops_per_sec += $stat->{ops_per_second};
        $total_duration += $stat->{duration};
    }
    
    my $avg_ops_per_sec = $total_ops_per_sec / @thread_stats;
    my $avg_duration = $total_duration / @thread_stats;
    
    ok($total_errors == 0, "No errors in concurrent stress test");
    ok($avg_ops_per_sec > 100, sprintf("Concurrent operations are fast enough: %.1f ops/sec average", $avg_ops_per_sec));
    
    return { 
        errors => $total_errors, 
        stats => {
            total_operations => $total_operations,
            avg_ops_per_second => $avg_ops_per_sec,
            avg_duration => $avg_duration
        }
    };
}

sub test_exception_handling_stress {
    diag("Testing exception handling under stress");
    
    my $monitor = PerformanceMonitor->new();
    my $iterations = 5000;
    my $exceptions_thrown = 0;
    my $exceptions_caught = 0;
    my $errors = 0;
    
    for my $i (1..$iterations) {
        my $op = $monitor->start_operation("exception_test");
        
        # Test various exception scenarios
        my $test_type = $i % 6;
        
        eval {
            if ($test_type == 0) {
                # NullReferenceException
                my $null_obj;
                $null_obj->ToString();
            } elsif ($test_type == 1) {
                # ArgumentNullException
                System::String->new(undef);
            } elsif ($test_type == 2) {
                # ArgumentOutOfRangeException
                my $str = System::String->new("test");
                $str->Substring(-1, 10);
            } elsif ($test_type == 3) {
                # IndexOutOfBoundsException
                my $arr = System::Array->new([1, 2, 3]);
                $arr->GetValue(100);
            } elsif ($test_type == 4) {
                # InvalidOperationException
                my $hash = System::Collections::Hashtable->new();
                $hash->Add("duplicate", "value1");
                $hash->Add("duplicate", "value2");
            } else {
                # Normal operation (no exception)
                my $sw = System::Diagnostics::Stopwatch->new();
                $sw->Start();
                $sw->Stop();
                my $elapsed = $sw->ElapsedTicks();
            }
        };
        
        if ($@) {
            $exceptions_thrown++;
            
            # Verify we got the expected exception type
            if (ref($@) && $@->isa('System::Exception')) {
                $exceptions_caught++;
                
                # Test exception methods
                eval {
                    my $msg = $@->Message();
                    my $str = $@->ToString();
                    
                    if (!defined($msg) || length($msg) == 0) {
                        $errors++;
                    }
                };
                if ($@) {
                    $errors++;
                }
            } else {
                $errors++;
            }
        }
        
        $monitor->end_operation($op);
        
        if ($i % 500 == 0) {
            diag("Completed $i/$iterations exception tests...");
        }
    }
    
    $monitor->print_report("Exception Handling Stress");
    
    my $stats = $monitor->get_statistics();
    
    diag("Exception handling results:");
    diag("Exceptions thrown: $exceptions_thrown");
    diag("Exceptions caught: $exceptions_caught");
    diag("Processing errors: $errors");
    
    ok($errors == 0, "No errors processing exceptions");
    ok($exceptions_caught > ($iterations * 5 / 6 * 0.8), "Most exceptions were caught properly");
    ok($stats->{operations_per_second} > 500, 
       sprintf("Exception handling is fast enough: %.1f ops/sec", $stats->{operations_per_second}));
    
    return { 
        errors => $errors,
        exceptions_thrown => $exceptions_thrown,
        exceptions_caught => $exceptions_caught,
        stats => $stats 
    };
}

sub test_long_running_stability {
    diag("Testing long-running stability");
    
    my $duration = STRESS_TEST_DURATION;
    my $end_time = time() + $duration;
    my $monitor = PerformanceMonitor->new();
    my $errors = 0;
    my $cycles = 0;
    
    diag("Running stability test for ${duration} seconds...");
    
    while (time() < $end_time) {
        my $op = $monitor->start_operation("stability_cycle");
        
        eval {
            # Perform a mix of operations
            my $sw = System::Diagnostics::Stopwatch->StartNew();
            
            # Create objects
            my @objects;
            for (1..10) {
                push @objects, System::String->new("Test $_");
                push @objects, System::Array->new([1, 2, $_]);
                push @objects, System::TimeSpan->FromSeconds($_);
            }
            
            # Manipulate objects
            for my $obj (@objects) {
                if ($obj->isa('System::String')) {
                    my $len = $obj->Length();
                } elsif ($obj->isa('System::Array')) {
                    my $len = $obj->Length();
                    my $val = $obj->GetValue(0) if $len > 0;
                } elsif ($obj->isa('System::TimeSpan')) {
                    my $ms = $obj->TotalMilliseconds();
                }
            }
            
            $sw->Stop();
            my $elapsed = $sw->ElapsedMilliseconds();
            
            # Verify timing is reasonable
            if ($elapsed < 0 || $elapsed > 1000) { # Should not take more than 1 second
                $errors++;
            }
            
            $cycles++;
        };
        if ($@) {
            $errors++;
            diag("Error in stability cycle $cycles: $@") if $errors <= 5;
        }
        
        $monitor->end_operation($op);
        
        # Brief pause to prevent excessive CPU usage
        sleep(0.001) if $cycles % 100 == 0;
    }
    
    $monitor->print_report("Long-Running Stability");
    
    my $stats = $monitor->get_statistics();
    
    diag("Stability test results:");
    diag("Cycles completed: $cycles");
    diag("Errors encountered: $errors");
    diag(sprintf("Duration: %.1f seconds", $stats->{total_duration}));
    
    ok($cycles > 100, "Completed sufficient cycles: $cycles");
    ok($errors == 0, "No errors during stability test");
    ok($stats->{operations_per_second} > 10, 
       sprintf("Stability test maintained reasonable performance: %.1f ops/sec", $stats->{operations_per_second}));
    
    # Check that performance didn't degrade significantly over time
    my $measurements = $monitor->{measurements};
    if (@$measurements >= 100) {
        my @early = @$measurements[0..49];
        my @late = @$measurements[-50..-1];
        
        my $early_avg = (List::Util::sum(map { $_->{duration} } @early)) / @early;
        my $late_avg = (List::Util::sum(map { $_->{duration} } @late)) / @late;
        
        my $performance_degradation = ($late_avg - $early_avg) / $early_avg;
        
        ok($performance_degradation < 0.5, 
           sprintf("Performance degradation is acceptable: %.1f%%", $performance_degradation * 100));
    }
    
    return { errors => $errors, cycles => $cycles, stats => $stats };
}

sub test_resource_cleanup {
    diag("Testing resource cleanup and garbage collection behavior");
    
    my $initial_memory = PerformanceMonitor->new()->get_memory_usage();
    my $objects_created = 0;
    my $cleanup_cycles = 10;
    
    for my $cycle (1..$cleanup_cycles) {
        diag("Cleanup test cycle $cycle/$cleanup_cycles");
        
        # Create many objects in a limited scope
        {
            my @temp_objects;
            for (1..1000) {
                push @temp_objects, System::Diagnostics::Stopwatch->new();
                push @temp_objects, System::String->new("Temporary string $_");
                push @temp_objects, System::Array->new([1, 2, 3, $_]);
                push @temp_objects, System::Collections::Hashtable->new();
                $objects_created += 4;
            }
            
            # Use the objects briefly
            for my $obj (@temp_objects) {
                if ($obj->isa('System::Diagnostics::Stopwatch')) {
                    $obj->Start();
                    $obj->Stop();
                } elsif ($obj->isa('System::String')) {
                    my $len = $obj->Length();
                } elsif ($obj->isa('System::Array')) {
                    my $len = $obj->Length();
                } elsif ($obj->isa('System::Collections::Hashtable')) {
                    $obj->Add("key", "value");
                }
            }
        } # Objects should go out of scope here
        
        # Force potential garbage collection
        if ($] >= 5.008) {
            # Only available in newer Perl versions
            eval { require Devel::Peek; Devel::Peek::SvREFCNT_dec($_) for (1..100); };
        }
        
        my $current_memory = PerformanceMonitor->new()->get_memory_usage();
        diag(sprintf("Memory after cycle %d: %.2f MB", $cycle, $current_memory / 1048576));
    }
    
    my $final_memory = PerformanceMonitor->new()->get_memory_usage();
    my $memory_growth = $final_memory - $initial_memory;
    
    diag(sprintf("Resource cleanup test completed:"));
    diag(sprintf("Objects created: %d", $objects_created));
    diag(sprintf("Initial memory: %.2f MB", $initial_memory / 1048576));
    diag(sprintf("Final memory: %.2f MB", $final_memory / 1048576));
    diag(sprintf("Memory growth: %.2f MB", $memory_growth / 1048576));
    
    # Memory growth should be reasonable
    my $memory_per_object = $memory_growth / $objects_created;
    ok($memory_per_object < 1000, 
       sprintf("Memory growth per object is reasonable: %.1f bytes", $memory_per_object));
    
    # Total memory growth should not be excessive
    my $growth_mb = $memory_growth / 1048576;
    ok($growth_mb < 100, sprintf("Total memory growth is acceptable: %.1f MB", $growth_mb));
    
    return { 
        objects_created => $objects_created,
        memory_growth => $memory_growth,
        memory_per_object => $memory_per_object
    };
}

# Run all stress and performance tests
diag("=== System Diagnostics Performance and Stress Tests ===");
diag("Platform: $^O");
diag("Perl version: $]");
diag("PID: $$");
diag("Available memory estimation: " . (PerformanceMonitor->new()->get_memory_usage() > 1 ? "Yes" : "No"));
diag("Threads available: " . ($Config{useithreads} ? "Yes" : "No"));

my $results = {};

$results->{stopwatch_performance} = test_stopwatch_performance_stress();
$results->{memory_stress} = test_system_objects_memory_stress();
$results->{concurrent_stress} = test_concurrent_stress();
$results->{exception_stress} = test_exception_handling_stress();
$results->{stability} = test_long_running_stability();
$results->{cleanup} = test_resource_cleanup();

# Summary report
diag("=== Performance and Stress Test Summary ===");
my $total_errors = 0;
for my $test_name (keys %$results) {
    my $result = $results->{$test_name};
    my $errors = $result->{errors} || 0;
    $total_errors += $errors;
    diag(sprintf("%-20s: %s", $test_name, $errors == 0 ? "PASS" : "FAIL ($errors errors)"));
}

diag(sprintf("Total errors across all tests: %d", $total_errors));
ok($total_errors == 0, "All stress and performance tests passed without errors");

done_testing();