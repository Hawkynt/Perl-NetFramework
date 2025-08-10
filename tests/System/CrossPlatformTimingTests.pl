#!/usr/bin/perl
use strict;
use warnings;
use lib '../../';
use Test::More;
use Time::HiRes qw(time sleep gettimeofday tv_interval);
use Config;
use POSIX qw(strftime);

# Define constants
use constant true => 1;
use constant false => 0;
use constant TIMING_SAMPLES => 20;
use constant MIN_RESOLUTION_US => 1; # 1 microsecond minimum resolution
use constant MAX_TIMING_VARIANCE => 0.3; # 30% variance allowed

# Import timing classes
use System::Diagnostics::Stopwatch;
use System::TimeSpan;
use System::DateTime;

BEGIN {
    use_ok('System::Diagnostics::Stopwatch');
    use_ok('System::TimeSpan');
    
    # Check Time::HiRes availability
    my $hires_available = eval { require Time::HiRes; 1 };
    if (!$hires_available) {
        plan skip_all => 'Time::HiRes not available for high-resolution timing tests';
    }
}

sub get_platform_info {
    my %info = (
        os => $^O,
        perl_version => $],
        architecture => $Config{archname},
        use_64bit => $Config{use64bitint} || $Config{use64bitall},
        threading => $Config{useithreads},
        time_hires_version => eval { Time::HiRes->VERSION } || 'unknown'
    );
    return \%info;
}

sub test_platform_timing_capabilities {
    diag("Testing platform timing capabilities");
    
    my $info = get_platform_info();
    diag("Platform: $info->{os}");
    diag("Architecture: $info->{architecture}");
    diag("Perl version: $info->{perl_version}");
    diag("64-bit support: " . ($info->{use_64bit} ? "Yes" : "No"));
    diag("Threading support: " . ($info->{threading} ? "Yes" : "No"));
    diag("Time::HiRes version: $info->{time_hires_version}");
    
    # Test basic timing functions availability
    my @timing_functions = qw(time gettimeofday);
    
    for my $func (@timing_functions) {
        my $available = eval { 
            no strict 'refs';
            &{"Time::HiRes::$func"}();
            1;
        };
        ok($available, "Time::HiRes::$func is available") or diag("Error: $@");
    }
    
    # Test timer resolution
    my @timestamps;
    for (1..100) {
        push @timestamps, Time::HiRes::time();
    }
    
    my @differences;
    for my $i (1..$#timestamps) {
        my $diff = $timestamps[$i] - $timestamps[$i-1];
        push @differences, $diff if $diff > 0;
    }
    
    if (@differences) {
        my $min_diff = (sort { $a <=> $b } @differences)[0];
        my $resolution_us = $min_diff * 1_000_000;
        
        diag(sprintf("Estimated timer resolution: %.3f microseconds", $resolution_us));
        
        # High-resolution timers should have sub-millisecond resolution
        ok($resolution_us < 1000, "Timer has sub-millisecond resolution");
        
        if ($info->{os} eq 'MSWin32') {
            # Windows should have very high resolution
            ok($resolution_us < 100, "Windows timer has high resolution (<100μs)");
        }
    }
}

sub test_stopwatch_cross_platform_accuracy {
    diag("Testing Stopwatch cross-platform timing accuracy");
    
    my @test_durations = (0.001, 0.01, 0.1, 0.5); # 1ms, 10ms, 100ms, 500ms
    
    for my $target_duration (@test_durations) {
        my @measurements;
        my @hires_measurements;
        
        # Take multiple measurements
        for (1..TIMING_SAMPLES) {
            # Measure with Stopwatch
            my $sw = System::Diagnostics::Stopwatch->new();
            
            # Measure with Time::HiRes for comparison
            my $hires_start = Time::HiRes::time();
            
            $sw->Start();
            sleep($target_duration);
            $sw->Stop();
            
            my $hires_end = Time::HiRes::time();
            
            push @measurements, $sw->ElapsedMilliseconds() / 1000; # Convert to seconds
            push @hires_measurements, $hires_end - $hires_start;
        }
        
        # Calculate statistics
        my $sw_avg = (List::Util::sum(@measurements)) / @measurements;
        my $sw_min = (sort { $a <=> $b } @measurements)[0];
        my $sw_max = (sort { $b <=> $a } @measurements)[0];
        my $sw_variance = ($sw_max - $sw_min) / $sw_avg;
        
        my $hr_avg = (List::Util::sum(@hires_measurements)) / @hires_measurements;
        my $hr_min = (sort { $a <=> $b } @hires_measurements)[0];
        my $hr_max = (sort { $b <=> $a } @hires_measurements)[0];
        my $hr_variance = ($hr_max - $hr_min) / $hr_avg;
        
        diag(sprintf("Target: %.3fs, Stopwatch: %.3fs±%.3fs (var %.1f%%), Time::HiRes: %.3fs±%.3fs (var %.1f%%)",
                     $target_duration, $sw_avg, ($sw_max - $sw_min), $sw_variance * 100,
                     $hr_avg, ($hr_max - $hr_min), $hr_variance * 100));
        
        # Test accuracy - should be within reasonable range of target
        my $sw_accuracy = abs($sw_avg - $target_duration) / $target_duration;
        my $hr_accuracy = abs($hr_avg - $target_duration) / $target_duration;
        
        ok($sw_accuracy < 0.2, sprintf("Stopwatch accuracy within 20%% for %.3fs (actual: %.1f%%)", 
                                       $target_duration, $sw_accuracy * 100));
        
        ok($hr_accuracy < 0.2, sprintf("Time::HiRes accuracy within 20%% for %.3fs (actual: %.1f%%)", 
                                       $target_duration, $hr_accuracy * 100));
        
        # Test precision consistency
        ok($sw_variance < MAX_TIMING_VARIANCE, 
           sprintf("Stopwatch variance within %.1f%% for %.3fs (actual: %.1f%%)", 
                   MAX_TIMING_VARIANCE * 100, $target_duration, $sw_variance * 100));
        
        # Test that Stopwatch and Time::HiRes give similar results
        my $relative_diff = abs($sw_avg - $hr_avg) / $hr_avg;
        ok($relative_diff < 0.1, 
           sprintf("Stopwatch and Time::HiRes agree within 10%% for %.3fs (diff: %.1f%%)", 
                   $target_duration, $relative_diff * 100));
    }
}

sub test_timespan_cross_platform_consistency {
    diag("Testing TimeSpan cross-platform consistency");
    
    # Test various TimeSpan creation methods
    my @test_cases = (
        { method => 'FromMilliseconds', value => 1500, expected_ms => 1500 },
        { method => 'FromSeconds', value => 2.5, expected_ms => 2500 },
        { method => 'FromMinutes', value => 1, expected_ms => 60000 },
        { method => 'FromHours', value => 1, expected_ms => 3600000 },
        { method => 'FromDays', value => 1, expected_ms => 86400000 }
    );
    
    for my $test (@test_cases) {
        my $method = $test->{method};
        my $ts = eval "System::TimeSpan->$method($test->{value})";
        
        ok(!$@, "$method($test->{value}) creates TimeSpan without error") or diag("Error: $@");
        
        if ($ts) {
            isa_ok($ts, 'System::TimeSpan', "$method returns TimeSpan object");
            
            my $actual_ms = $ts->TotalMilliseconds();
            my $expected_ms = $test->{expected_ms};
            
            # Allow small floating point differences
            my $diff = abs($actual_ms - $expected_ms);
            my $tolerance = $expected_ms * 0.001; # 0.1% tolerance
            
            ok($diff <= $tolerance, 
               sprintf("%s gives correct milliseconds: %.3f (expected %.3f)", 
                       $method, $actual_ms, $expected_ms));
        }
    }
    
    # Test TimeSpan arithmetic consistency
    my $ts1 = System::TimeSpan->FromSeconds(1.5);
    my $ts2 = System::TimeSpan->FromSeconds(2.5);
    
    eval {
        my $sum = $ts1 + $ts2;
        my $diff = $ts2 - $ts1;
        
        isa_ok($sum, 'System::TimeSpan', 'TimeSpan addition returns TimeSpan');
        isa_ok($diff, 'System::TimeSpan', 'TimeSpan subtraction returns TimeSpan');
        
        is($sum->TotalSeconds(), 4.0, 'TimeSpan addition gives correct result');
        is($diff->TotalSeconds(), 1.0, 'TimeSpan subtraction gives correct result');
    };
    ok(!$@, 'TimeSpan arithmetic operations work without error') or diag("Error: $@");
}

sub test_timing_precision_limits {
    diag("Testing timing precision limits and edge cases");
    
    # Test very short durations
    my @short_durations = (0.0001, 0.0005, 0.001, 0.005); # 0.1ms to 5ms
    
    for my $duration (@short_durations) {
        my $sw = System::Diagnostics::Stopwatch->new();
        
        $sw->Start();
        sleep($duration);
        $sw->Stop();
        
        my $measured = $sw->ElapsedMilliseconds() / 1000;
        
        # For very short durations, just check that we get a reasonable result
        ok($measured >= 0, "Short duration ${duration}s measurement is non-negative: ${measured}s");
        ok($measured < ($duration * 10), "Short duration ${duration}s measurement is reasonable: ${measured}s");
        
        # Test microsecond precision
        my $microseconds = $sw->ElapsedMicroseconds();
        ok($microseconds > 0, "Microsecond measurement is positive for ${duration}s duration");
        ok($microseconds > $measured * 1000, "Microseconds > milliseconds * 1000");
    }
    
    # Test timer frequency consistency
    my $freq1 = System::Diagnostics::Stopwatch::Frequency();
    sleep(0.001);
    my $freq2 = System::Diagnostics::Stopwatch::Frequency();
    
    is($freq1, $freq2, 'Timer frequency is consistent across calls');
    ok($freq1 > 0, 'Timer frequency is positive');
    
    # Test GetTimestamp consistency
    my @timestamps;
    for (1..10) {
        push @timestamps, System::Diagnostics::Stopwatch::GetTimestamp();
    }
    
    # Check that timestamps are increasing
    for my $i (1..$#timestamps) {
        ok($timestamps[$i] >= $timestamps[$i-1], 
           "Timestamp $i is >= previous timestamp");
    }
    
    # Check that timestamps are reasonable (not too large or small)
    for my $ts (@timestamps) {
        ok($ts > 0, "Timestamp is positive: $ts");
        ok($ts < 1e20, "Timestamp is not unreasonably large: $ts"); # Sanity check
    }
}

sub test_concurrent_timing_reliability {
    diag("Testing concurrent timing reliability");
    
    # Skip if threads not available
    unless ($Config{useithreads}) {
        diag("Threads not available, skipping concurrent timing tests");
        return;
    }
    
    use threads;
    use threads::shared;
    
    my @results :shared;
    my @errors :shared;
    my $num_threads = 3;
    my $measurements_per_thread = 10;
    
    my @threads;
    for my $thread_id (1..$num_threads) {
        my $thread = threads->create(sub {
            my $id = shift;
            
            for my $i (1..$measurements_per_thread) {
                eval {
                    my $sw = System::Diagnostics::Stopwatch->new();
                    
                    $sw->Start();
                    sleep(0.01); # 10ms
                    $sw->Stop();
                    
                    my $elapsed = $sw->ElapsedMilliseconds();
                    push @results, "Thread${id}:${elapsed}";
                    
                    # Test static methods in concurrent context
                    my $freq = System::Diagnostics::Stopwatch::Frequency();
                    my $ts = System::Diagnostics::Stopwatch::GetTimestamp();
                    
                    if ($freq <= 0 || $ts <= 0) {
                        push @errors, "Thread${id}: Invalid static method result";
                    }
                };
                if ($@) {
                    push @errors, "Thread${id}: $@";
                }
            }
        }, $thread_id);
        
        push @threads, $thread;
    }
    
    # Wait for completion
    for my $thread (@threads) {
        $thread->join();
    }
    
    my $total_results = scalar(@results);
    my $total_errors = scalar(@errors);
    my $expected_results = $num_threads * $measurements_per_thread;
    
    diag("Concurrent timing test: $total_results/$expected_results results, $total_errors errors");
    
    ok($total_results == $expected_results, "All concurrent measurements completed");
    ok($total_errors == 0, "No errors in concurrent timing");
    
    if ($total_errors > 0) {
        diag("Concurrent errors: " . join(", ", @errors));
    }
    
    # Analyze timing consistency across threads
    my %thread_measurements;
    for my $result (@results) {
        my ($thread, $measurement) = split /:/, $result;
        push @{$thread_measurements{$thread}}, $measurement;
    }
    
    for my $thread (keys %thread_measurements) {
        my @measurements = @{$thread_measurements{$thread}};
        my $avg = (List::Util::sum(@measurements)) / @measurements;
        my $min = (sort { $a <=> $b } @measurements)[0];
        my $max = (sort { $b <=> $a } @measurements)[0];
        
        diag(sprintf("%s: avg=%.1fms, min=%.1fms, max=%.1fms", $thread, $avg, $min, $max));
        
        # Each measurement should be reasonable (around 10ms ± tolerance)
        ok($avg >= 5 && $avg <= 25, "$thread average timing is reasonable");
        
        my $variance = ($max - $min) / $avg;
        ok($variance < 0.5, "$thread timing variance is acceptable");
    }
}

sub test_timing_under_system_load {
    diag("Testing timing accuracy under system load");
    
    # Create some CPU load
    my $load_duration = 2; # seconds
    my $end_time = time() + $load_duration;
    
    my @load_measurements;
    my @normal_measurements;
    
    # Take normal measurements first
    for (1..5) {
        my $sw = System::Diagnostics::Stopwatch->new();
        $sw->Start();
        sleep(0.05); # 50ms
        $sw->Stop();
        push @normal_measurements, $sw->ElapsedMilliseconds();
    }
    
    # Create CPU load and take measurements during it
    my $pid = fork();
    if (defined $pid && $pid == 0) {
        # Child process - create CPU load
        while (time() < $end_time) {
            my $x = 0;
            $x++ for (1..1000); # Busy loop
        }
        exit(0);
    }
    
    if (defined $pid) {
        # Parent process - take measurements under load
        sleep(0.1); # Let load process start
        
        for (1..5) {
            my $sw = System::Diagnostics::Stopwatch->new();
            $sw->Start();
            sleep(0.05); # 50ms
            $sw->Stop();
            push @load_measurements, $sw->ElapsedMilliseconds();
        }
        
        # Clean up load process
        waitpid($pid, 0);
    } else {
        diag("Could not fork for load testing, skipping load tests");
        return;
    }
    
    # Analyze results
    my $normal_avg = (List::Util::sum(@normal_measurements)) / @normal_measurements;
    my $load_avg = (List::Util::sum(@load_measurements)) / @load_measurements;
    
    diag(sprintf("Normal load: %.1fms average, Under load: %.1fms average", $normal_avg, $load_avg));
    
    # Timing should still be reasonably accurate under load
    ok($normal_avg >= 40 && $normal_avg <= 70, "Normal timing is accurate");
    ok($load_avg >= 35 && $load_avg <= 100, "Timing under load is still reasonable");
    
    # The difference shouldn't be too large
    my $load_impact = abs($load_avg - $normal_avg) / $normal_avg;
    ok($load_impact < 0.5, sprintf("System load impact is acceptable: %.1f%%", $load_impact * 100));
}

sub test_long_duration_accuracy {
    diag("Testing long duration timing accuracy");
    
    # Test progressively longer durations to check for drift
    my @long_durations = (1.0, 2.0, 5.0); # 1s, 2s, 5s
    
    for my $duration (@long_durations) {
        diag("Testing ${duration}s duration...");
        
        my $sw = System::Diagnostics::Stopwatch->new();
        my $hires_start = Time::HiRes::time();
        
        $sw->Start();
        sleep($duration);
        $sw->Stop();
        
        my $hires_end = Time::HiRes::time();
        
        my $sw_elapsed = $sw->ElapsedMilliseconds() / 1000;
        my $hires_elapsed = $hires_end - $hires_start;
        
        diag(sprintf("Stopwatch: %.3fs, Time::HiRes: %.3fs", $sw_elapsed, $hires_elapsed));
        
        # Check accuracy
        my $sw_error = abs($sw_elapsed - $duration) / $duration;
        my $hr_error = abs($hires_elapsed - $duration) / $duration;
        
        ok($sw_error < 0.05, sprintf("Stopwatch accuracy for ${duration}s within 5%% (actual: %.2f%%)", $sw_error * 100));
        ok($hr_error < 0.05, sprintf("Time::HiRes accuracy for ${duration}s within 5%% (actual: %.2f%%)", $hr_error * 100));
        
        # Check consistency between methods
        my $method_diff = abs($sw_elapsed - $hires_elapsed) / $hires_elapsed;
        ok($method_diff < 0.02, sprintf("Stopwatch and Time::HiRes agree for ${duration}s within 2%% (diff: %.2f%%)", $method_diff * 100));
    }
}

# List::Util may not be available, provide fallback
BEGIN {
    eval { require List::Util; List::Util->import('sum'); 1 } or do {
        *List::Util::sum = sub { 
            my $sum = 0; 
            $sum += $_ for @_; 
            return $sum; 
        };
    };
}

# Run all tests
diag("=== Cross-Platform Timing Reliability Tests ===");

test_platform_timing_capabilities();
test_stopwatch_cross_platform_accuracy();
test_timespan_cross_platform_consistency();
test_timing_precision_limits();
test_concurrent_timing_reliability();
test_timing_under_system_load();
test_long_duration_accuracy();

done_testing();