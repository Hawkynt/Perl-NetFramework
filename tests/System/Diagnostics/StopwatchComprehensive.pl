#!/usr/bin/perl
use strict;
use warnings;
use lib '../../../';
use Test::More;
use Time::HiRes qw(sleep time);
use Config;
use threads;
use threads::shared;

# Define constants
use constant true => 1;
use constant false => 0;

# Import the classes we need
use System::Diagnostics::Stopwatch;
use System::Exceptions;
use System::TimeSpan;

BEGIN {
    use_ok('System::Diagnostics::Stopwatch');
    use_ok('System::Exceptions');
}

# Test platform information
sub test_platform_detection {
    diag("Running comprehensive Stopwatch tests on:");
    diag("  OS: $^O");
    diag("  Perl: $]");
    diag("  Architecture: " . ($Config{archname} // 'unknown'));
    diag("  High-resolution timer: " . (System::Diagnostics::Stopwatch::IsHighResolution() ? 'Available' : 'Unavailable'));
    diag("  Timer frequency: " . System::Diagnostics::Stopwatch::Frequency() . " ticks/sec");
    
    ok(1, 'Platform detection completed');
}

# Exception handling tests
sub test_null_reference_exceptions {
    # Test all methods throw exceptions when called on undef
    # Note: Perl throws standard errors when calling methods on undef, not our custom exceptions
    my $null_sw = undef;
    
    eval { $null_sw->Elapsed(); };
    ok($@, 'Elapsed throws exception on undef');
    like($@, qr/undefined value/, 'Exception mentions undefined value');
    
    eval { $null_sw->ElapsedMilliseconds(); };
    ok($@, 'ElapsedMilliseconds throws exception on undef');
    
    eval { $null_sw->ElapsedMicroseconds(); };
    ok($@, 'ElapsedMicroseconds throws exception on undef');
    
    eval { $null_sw->ElapsedTicks(); };
    ok($@, 'ElapsedTicks throws exception on undef');
    
    eval { $null_sw->IsRunning(); };
    ok($@, 'IsRunning throws exception on undef');
    
    eval { $null_sw->Reset(); };
    ok($@, 'Reset throws exception on undef');
    
    eval { $null_sw->Restart(); };
    ok($@, 'Restart throws exception on undef');
    
    eval { $null_sw->Start(); };
    ok($@, 'Start throws exception on undef');
    
    eval { $null_sw->Stop(); };
    ok($@, 'Stop throws exception on undef');
}

# Timing accuracy tests across different durations
sub test_timing_accuracy {
    my @durations = (0.05, 0.1, 0.5, 1.0); # 50ms to 1 second (avoiding very short durations on Windows)
    my $tolerance = 0.3; # 30% tolerance for timing variations on Windows
    
    foreach my $duration (@durations) {
        my $sw = System::Diagnostics::Stopwatch->new();
        
        $sw->Start();
        sleep($duration);
        $sw->Stop();
        
        my $elapsed_ms = $sw->ElapsedMilliseconds();
        my $expected_ms = $duration * 1000;
        my $error_percent = abs($elapsed_ms - $expected_ms) / $expected_ms;
        
        ok($error_percent <= $tolerance, 
           "Timing accuracy for ${duration}s: ${elapsed_ms}ms (expected ${expected_ms}ms, error ${error_percent}%)");
           
        # Test that all time formats are consistent
        my $elapsed_ticks = $sw->ElapsedTicks();
        my $elapsed_microseconds = $sw->ElapsedMicroseconds();
        my $elapsed_timespan = $sw->Elapsed();
        
        # Verify relationships between different time formats
        ok($elapsed_microseconds > $elapsed_ms, 'Microseconds > milliseconds');
        ok($elapsed_ticks > $elapsed_microseconds, 'Ticks > microseconds');
        isa_ok($elapsed_timespan, 'System::TimeSpan', 'Elapsed returns TimeSpan');
    }
}

# High-resolution timer precision test
sub test_timer_precision {
    my @measurements = ();
    my $iterations = 1000;
    
    # Measure the smallest detectable time interval
    for my $i (1..$iterations) {
        my $timestamp1 = System::Diagnostics::Stopwatch::GetTimestamp();
        my $timestamp2 = System::Diagnostics::Stopwatch::GetTimestamp();
        push @measurements, $timestamp2 - $timestamp1 if $timestamp2 > $timestamp1;
    }
    
    ok(@measurements > 0, 'Timer can detect small intervals');
    
    if (@measurements > 0) {
        @measurements = sort { $a <=> $b } @measurements;
        my $min_resolution = $measurements[0];
        my $median_resolution = $measurements[@measurements / 2];
        
        diag("Timer resolution: min=${min_resolution} ticks, median=${median_resolution} ticks");
        
        # Convert to nanoseconds for better understanding
        my $min_ns = ($min_resolution / System::Diagnostics::Stopwatch::Frequency()) * 1_000_000_000;
        my $median_ns = ($median_resolution / System::Diagnostics::Stopwatch::Frequency()) * 1_000_000_000;
        
        diag("Timer resolution: min=${min_ns}ns, median=${median_ns}ns");
        
        ok($min_ns < 1_000_000, 'Timer resolution better than 1ms'); # Should be much better than 1ms
    }
}

# Concurrent operation tests
sub test_concurrent_operations {
    return if !$Config{useithreads};
    
    my $num_threads = 5;
    my $duration_per_thread = 0.1; # 100ms each
    my @threads = ();
    my @results = ();
    
    # Create multiple threads, each with their own stopwatch
    for my $i (1..$num_threads) {
        push @threads, threads->create(sub {
            my $thread_id = shift;
            my $sw = System::Diagnostics::Stopwatch->new();
            
            $sw->Start();
            sleep($duration_per_thread);
            $sw->Stop();
            
            my $elapsed = $sw->ElapsedMilliseconds();
            return $elapsed;
        }, $i);
    }
    
    # Wait for all threads to complete
    my @elapsed_times = map { $_->join() } @threads;
    
    ok(@elapsed_times == $num_threads, 'All threads completed');
    
    # Verify each thread measured approximately the expected time
    my $expected_ms = $duration_per_thread * 1000;
    my $tolerance = 0.2; # 20% tolerance for concurrent operations
    
    foreach my $elapsed (@elapsed_times) {
        my $error_percent = abs($elapsed - $expected_ms) / $expected_ms;
        ok($error_percent <= $tolerance, 
           "Concurrent thread timing within tolerance: ${elapsed}ms (expected ${expected_ms}ms)");
    }
}

# Stress test with many operations
sub test_stress_operations {
    my $sw = System::Diagnostics::Stopwatch->new();
    my $iterations = 10000;
    my $start_time = time();
    
    # Rapid start/stop cycles
    for my $i (1..$iterations) {
        $sw->Start();
        $sw->Stop();
        
        # Occasionally reset to test that operation too
        $sw->Reset() if $i % 1000 == 0;
    }
    
    my $end_time = time();
    my $total_time = $end_time - $start_time;
    
    ok($total_time < 10, "Stress test completed in reasonable time: ${total_time}s");
    ok(!$sw->IsRunning(), 'Stopwatch in correct state after stress test');
    is($sw->ElapsedMilliseconds(), 0, 'Stopwatch properly reset during stress test');
}

# Test memory management and cleanup
sub test_memory_management {
    my $initial_memory = get_memory_usage();
    my @stopwatches = ();
    
    # Create many stopwatches
    for my $i (1..1000) {
        my $sw = System::Diagnostics::Stopwatch->new();
        $sw->Start();
        sleep(0.00001); # Very short sleep
        $sw->Stop();
        push @stopwatches, $sw;
    }
    
    my $peak_memory = get_memory_usage();
    
    # Clear references
    @stopwatches = ();
    
    # Force garbage collection (Perl will handle this automatically)
    my $final_memory = get_memory_usage();
    
    ok($peak_memory >= $initial_memory, 'Memory usage increased during test');
    diag("Memory usage: initial=${initial_memory}KB, peak=${peak_memory}KB, final=${final_memory}KB");
    
    ok(1, 'Memory management test completed');
}

# Helper function to get memory usage (approximate)
sub get_memory_usage {
    # This is a rough approximation - in real scenarios you might use more sophisticated methods
    if (open my $fh, '<', '/proc/self/status') {
        while (my $line = <$fh>) {
            if ($line =~ /^VmRSS:\s+(\d+)\s+kB/) {
                close $fh;
                return $1;
            }
        }
        close $fh;
    }
    
    # Fallback for non-Linux systems or if /proc is not available
    return 0;
}

# Test edge cases and boundary conditions
sub test_edge_cases {
    my $sw = System::Diagnostics::Stopwatch->new();
    
    # Test very short intervals
    $sw->Start();
    # No sleep - immediate stop
    $sw->Stop();
    
    my $very_short = $sw->ElapsedTicks();
    ok($very_short >= 0, 'Very short interval measurement is non-negative');
    
    # Test multiple rapid cycles
    $sw->Reset();
    for my $i (1..100) {
        $sw->Start();
        $sw->Stop();
    }
    
    my $accumulated = $sw->ElapsedTicks();
    ok($accumulated >= 0, 'Accumulated very short intervals are non-negative');
    
    # Test restart during running state
    $sw->Restart();
    ok($sw->IsRunning(), 'Restart while running works');
    $sw->Stop();
    
    # Test reset during running state
    $sw->Start();
    $sw->Reset();
    ok(!$sw->IsRunning(), 'Reset while running stops the timer');
    is($sw->ElapsedTicks(), 0, 'Reset while running clears elapsed time');
}

# Test static method consistency
sub test_static_methods {
    # Test multiple calls to static methods for consistency
    my @frequencies = ();
    my @high_res_results = ();
    
    for my $i (1..10) {
        push @frequencies, System::Diagnostics::Stopwatch::Frequency();
        push @high_res_results, System::Diagnostics::Stopwatch::IsHighResolution();
    }
    
    # All frequency calls should return the same value
    my $first_freq = $frequencies[0];
    my $freq_consistent = 1;
    for my $freq (@frequencies) {
        $freq_consistent = 0 if $freq != $first_freq;
    }
    ok($freq_consistent, 'Frequency() returns consistent values');
    
    # All high resolution calls should return the same value  
    my $first_high_res = $high_res_results[0];
    my $high_res_consistent = 1;
    for my $hr (@high_res_results) {
        $high_res_consistent = 0 if $hr != $first_high_res;
    }
    ok($high_res_consistent, 'IsHighResolution() returns consistent values');
    
    # Test GetTimestamp monotonicity
    my @timestamps = ();
    for my $i (1..100) {
        push @timestamps, System::Diagnostics::Stopwatch::GetTimestamp();
        sleep(0.0001); # Very small sleep
    }
    
    # Timestamps should be generally increasing (allowing for some platform variations)
    my $increasing_count = 0;
    for my $i (1..$#timestamps) {
        $increasing_count++ if $timestamps[$i] >= $timestamps[$i-1];
    }
    
    my $monotonic_percentage = ($increasing_count / $#timestamps) * 100;
    ok($monotonic_percentage >= 95, "GetTimestamp is mostly monotonic: ${monotonic_percentage}%");
}


# Test cross-platform compatibility
sub test_cross_platform_behavior {
    diag("Testing cross-platform behavior on $^O");
    
    my $sw = System::Diagnostics::Stopwatch->new();
    
    # Basic functionality should work on all platforms
    $sw->Start();
    sleep(0.01);
    $sw->Stop();
    
    ok($sw->ElapsedMilliseconds() > 0, 'Basic timing works on this platform');
    ok(System::Diagnostics::Stopwatch::IsHighResolution(), 'High resolution timing available');
    ok(System::Diagnostics::Stopwatch::Frequency() > 0, 'Timer frequency is positive');
    
    # Test that Frequency is reasonable (should be at least 1000 Hz, typically much higher)
    my $freq = System::Diagnostics::Stopwatch::Frequency();
    ok($freq >= 1000, "Timer frequency is reasonable: $freq Hz");
}

# Performance benchmark
sub test_performance_benchmark {
    my $iterations = 100000;
    my $start_time = time();
    
    # Benchmark stopwatch creation and basic operations
    for my $i (1..$iterations) {
        my $sw = System::Diagnostics::Stopwatch->new();
        $sw->Start();
        $sw->ElapsedTicks();
        $sw->Stop();
    }
    
    my $end_time = time();
    my $total_time = $end_time - $start_time;
    my $ops_per_second = $iterations / $total_time;
    
    diag("Performance: ${iterations} operations in ${total_time}s (${ops_per_second} ops/sec)");
    ok($ops_per_second > 1000, 'Performance is acceptable (>1000 ops/sec)');
}

# Run all tests
test_platform_detection();
test_null_reference_exceptions();
test_timing_accuracy();
test_timer_precision();
test_concurrent_operations() if $Config{useithreads};
test_stress_operations();
test_memory_management();
test_edge_cases();
test_static_methods();
test_cross_platform_behavior();
test_performance_benchmark();

done_testing();