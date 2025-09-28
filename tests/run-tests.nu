#!/usr/bin/env nu
# Test Runner - Following Martin Fowler's Testing Pyramid
# 70% Unit Tests, 20% Integration Tests, 10% E2E Tests

use std log

def print_banner [text: string]: nothing -> nothing {
    print "============================================================"
    print $"                    ($text)"
    print "============================================================"
}

def run_test_suite [suite_name: string, test_file: string]: nothing -> record {
    print $"\n🧪 Running ($suite_name)..."
    print $"   File: ($test_file)"
    
    let start_time = (date now)
    
    let result = try {
        chmod +x $test_file
        let output = (nu $test_file | complete)
        
        {
            suite: $suite_name
            status: (if $output.exit_code == 0 { "PASSED" } else { "FAILED" })
            exit_code: $output.exit_code
            output: $output.stdout
            error: $output.stderr
            duration: ((date now) - $start_time)
        }
    } catch { |e|
        {
            suite: $suite_name
            status: "ERROR"
            exit_code: -1
            output: ""
            error: $e.msg
            duration: ((date now) - $start_time)
        }
    }
    
    match $result.status {
        "PASSED" => { print $"   ✅ ($suite_name) PASSED" }
        "FAILED" => { print $"   ❌ ($suite_name) FAILED" }
        "ERROR" => { print $"   💥 ($suite_name) ERROR" }
        _ => { print $"   ❓ ($suite_name) UNKNOWN" }
    }
    
    $result
}

def print_test_summary [results: list]: nothing -> nothing {
    print_banner "TEST SUMMARY"
    
    let passed = ($results | where status == "PASSED" | length)
    let failed = ($results | where status == "FAILED" | length)
    let errors = ($results | where status == "ERROR" | length)
    let total = ($results | length)
    
    print $"Total Test Suites: ($total)"
    print $"✅ Passed: ($passed)"
    print $"❌ Failed: ($failed)"
    print $"💥 Errors: ($errors)"
    
    # Calculate total duration
    let total_duration = ($results | get duration | reduce { |it, acc| $acc + $it })
    print $"⏱️  Total Duration: ($total_duration)"
    
    print ""
    
    # Show details for each suite
    for result in $results {
        let status_icon = match $result.status {
            "PASSED" => "✅"
            "FAILED" => "❌"  
            "ERROR" => "💥"
            _ => "❓"
        }
        
        print $"($status_icon) ($result.suite): ($result.status) (($result.duration))"
        
        # Show errors for failed tests
        if $result.status in ["FAILED", "ERROR"] and ($result.error | str length) > 0 {
            print $"    Error: ($result.error)"
        }
    }
    
    print ""
    
    # Overall result
    if $failed == 0 and $errors == 0 {
        print "🎉 ALL TESTS PASSED! 🎉"
    } else {
        print "❌ SOME TESTS FAILED"
        print ""
        print "Failed/Error Test Output:"
        for result in ($results | where status in ["FAILED", "ERROR"]) {
            print $"--- ($result.suite) ---"
            if ($result.output | str length) > 0 {
                print $result.output
            }
            if ($result.error | str length) > 0 {
                print $"ERROR: ($result.error)"
            }
            print ""
        }
    }
}

def main [
    --unit-only      # Run only unit tests
    --integration-only  # Run only integration tests  
    --e2e-only       # Run only e2e tests
    --verbose (-v)   # Verbose output
    --parallel (-p)  # Run tests in parallel (if supported)
]: nothing -> nothing {
    
    if $verbose {
        $env.LOG_LEVEL = "DEBUG"
    }
    
    print_banner "AWS NUSHELL LOGIN - TEST SUITE"
    print "Following Martin Fowler's Testing Pyramid:"
    print "📊 70% Unit Tests - Fast, isolated, deterministic"
    print "🔗 20% Integration Tests - Component interactions"  
    print "🎯 10% End-to-End Tests - Complete user workflows"
    print ""
    
    mut results = []
    
    # Unit Tests (70% - should be fast and comprehensive)
    if not $integration_only and not $e2e_only {
        print_banner "UNIT TESTS (70%)"
        print "Testing individual functions in isolation..."
        
        let unit_tests = [
            {name: "Core Functions", file: "tests/unit/test-core-functions.nu"}
        ]
        
        for test in $unit_tests {
            if ($test.file | path exists) {
                let result = (run_test_suite $test.name $test.file)
                $results = ($results | append $result)
            } else {
                print $"⚠️  Test file not found: ($test.file)"
                let missing_result = {
                    suite: $test.name
                    status: "ERROR"
                    exit_code: -1
                    output: ""
                    error: $"File not found: ($test.file)"
                    duration: 0ms
                }
                $results = ($results | append $missing_result)
            }
        }
    }
    
    # Integration Tests (20% - test component interactions)
    if not $unit_only and not $e2e_only {
        print_banner "INTEGRATION TESTS (20%)"
        print "Testing component interactions and workflows..."
        
        let integration_tests = [
            {name: "Workflow Integration", file: "tests/integration/test-workflows.nu"}
        ]
        
        for test in $integration_tests {
            if ($test.file | path exists) {
                let result = (run_test_suite $test.name $test.file)
                $results = ($results | append $result)
            } else {
                print $"⚠️  Test file not found: ($test.file)"
                let missing_result = {
                    suite: $test.name
                    status: "ERROR"
                    exit_code: -1
                    output: ""
                    error: $"File not found: ($test.file)"
                    duration: 0ms
                }
                $results = ($results | append $missing_result)
            }
        }
    }
    
    # E2E Tests (10% - complete user workflows)
    if not $unit_only and not $integration_only {
        print_banner "END-TO-END TESTS (10%)"
        print "Testing complete user workflows..."
        
        let e2e_tests = [
            {name: "Complete Workflows", file: "tests/e2e/test-complete-workflows.nu"}
        ]
        
        for test in $e2e_tests {
            if ($test.file | path exists) {
                let result = (run_test_suite $test.name $test.file)
                $results = ($results | append $result)
            } else {
                print $"⚠️  Test file not found: ($test.file)"
                let missing_result = {
                    suite: $test.name
                    status: "ERROR"
                    exit_code: -1
                    output: ""
                    error: $"File not found: ($test.file)"
                    duration: 0ms
                }
                $results = ($results | append $missing_result)
            }
        }
    }
    
    # Print summary
    print_test_summary $results
    
    # Exit with appropriate code
    let failed_count = ($results | where status in ["FAILED", "ERROR"] | length)
    if $failed_count > 0 {
        exit 1
    }
}

# Quick test runner for CI
export def quick []: nothing -> nothing {
    print "🔥 Running quick test suite..."
    main --unit-only
}

# Full test suite for comprehensive validation
export def full []: nothing -> nothing {
    print "🚀 Running full test suite..."
    main
}

# Development test runner (unit + integration, no e2e)
export def dev []: nothing -> nothing {
    print "👨‍💻 Running development test suite..."
    main --verbose
}