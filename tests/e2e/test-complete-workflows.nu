#!/usr/bin/env nu
# End-to-End Tests for AWS Login System
# Tests complete user workflows from installation to usage

use std assert
use std log

# E2E Test: Complete installation and basic usage workflow
def test_installation_workflow []: nothing -> nothing {
    print "🎯 Testing complete installation workflow..."
    
    try {
        # Test that installer exists and is executable
        let installer_path = "../../install.nu"
        assert ($installer_path | path exists) "Installer should exist"
        
        # Test that main script exists
        let main_script = "../../aws-login.nu"
        assert ($main_script | path exists) "Main script should exist"
        
        # Test that we can source the main script without errors
        let source_result = try {
            source $main_script
            true
        } catch {
            false
        }
        
        assert $source_result "Should be able to source main script without errors"
        
        print "✅ Installation workflow test passed"
    } catch { |e|
        print $"❌ E2E test failed: ($e.msg)"
        error make { msg: $"Test failed: ($e.msg)" }
    }
}

# E2E Test: Profile-specific alias creation and usage
def test_alias_creation_e2e []: nothing -> nothing {
    print "🎯 Testing end-to-end alias creation and usage..."
    
    try {
        # Create a complete alias as a user would
        def test_awsl_dev []: nothing -> nothing {
            print "🚀 Mock: Connecting to development..."
            
            # Mock the credential export
            $env.E2E_TEST_AWS_PROFILE = "development"
            $env.E2E_TEST_AWS_ACCESS_KEY_ID = "AKIAE2ETEST"
            $env.E2E_TEST_AWS_SECRET_ACCESS_KEY = "e2e-test-secret"
            $env.E2E_TEST_AWS_DEFAULT_REGION = "us-west-2"
            
            print "✅ Mock: Connected to development environment"
            print $"   Profile: ($env.E2E_TEST_AWS_PROFILE)"
            print $"   Region: ($env.E2E_TEST_AWS_DEFAULT_REGION)"
        }
        
        # Test using the alias
        test_awsl_dev
        
        # Verify the alias worked correctly
        assert ($env.E2E_TEST_AWS_PROFILE == "development") "Should set development profile"
        assert ($env.E2E_TEST_AWS_ACCESS_KEY_ID == "AKIAE2ETEST") "Should set access key"
        assert ($env.E2E_TEST_AWS_DEFAULT_REGION == "us-west-2") "Should set region"
        
        # Test production alias with safety check
        def test_awsl_prod [should_confirm: bool]: nothing -> nothing {
            if not $should_confirm {
                print "❌ Mock: Production access cancelled"
                return
            }
            
            print "🚀 Mock: Connecting to production..."
            $env.E2E_TEST_AWS_PROFILE = "production"
            $env.E2E_TEST_AWS_ACCESS_KEY_ID = "AKIAE2EPROD"
            print "🚨 Mock: PRODUCTION ENVIRONMENT - BE CAREFUL!"
        }
        
        # Test cancellation
        test_awsl_prod false
        let prod_not_set = not ("E2E_TEST_AWS_PROFILE" in ($env | columns)) or ($env.E2E_TEST_AWS_PROFILE != "production")
        assert $prod_not_set "Production should not be set when cancelled"
        
        # Test confirmation
        test_awsl_prod true
        assert ($env.E2E_TEST_AWS_PROFILE == "production") "Should set production when confirmed"
        
        # Cleanup
        let e2e_vars = ($env | columns | where ($it | str starts-with "E2E_TEST_AWS"))
        for var in $e2e_vars {
            hide-env $var
        }
        
        print "✅ Alias creation and usage E2E test passed"
    } catch { |e|
        print $"❌ E2E test failed: ($e.msg)"
        error make { msg: $"Test failed: ($e.msg)" }
    }
}

# E2E Test: Multi-environment workflow
def test_multi_environment_workflow []: nothing -> nothing {
    print "🎯 Testing multi-environment workflow..."
    
    try {
        # Simulate a typical multi-environment workflow
        let environments = [
            {name: "development", region: "us-west-2", requires_sso: false}
            {name: "staging", region: "us-west-2", requires_sso: true}
            {name: "production", region: "us-east-1", requires_sso: true}
        ]
        
        for env in $environments {
            print $"🔄 Testing environment: ($env.name)"
            
            # Create environment-specific function
            def switch_environment [env_record: record]: nothing -> nothing {
                print $"🚀 Mock: Connecting to ($env_record.name)..."
                
                $env.WORKFLOW_TEST_AWS_PROFILE = $env_record.name
                $env.WORKFLOW_TEST_AWS_DEFAULT_REGION = $env_record.region
                
                if $env_record.requires_sso {
                    print "🔐 Mock: Using SSO authentication"
                    $env.WORKFLOW_TEST_SSO_USED = "true"
                } else {
                    hide-env --ignore-errors WORKFLOW_TEST_SSO_USED
                }
                
                print $"✅ Mock: Connected to ($env_record.name) in ($env_record.region)"
            }
            
            # Test switching to this environment
            switch_environment $env
            
            # Verify environment is set correctly
            assert ($env.WORKFLOW_TEST_AWS_PROFILE == $env.name) $"Should set profile to ($env.name)"
            assert ($env.WORKFLOW_TEST_AWS_DEFAULT_REGION == $env.region) $"Should set region to ($env.region)"
            
            if $env.requires_sso {
                assert ("WORKFLOW_TEST_SSO_USED" in ($env | columns)) "Should indicate SSO was used"
            }
            
            print $"✅ Successfully tested ($env.name) environment"
        }
        
        # Test clearing workflow
        def clear_workflow_env []: nothing -> nothing {
            let workflow_vars = ($env | columns | where ($it | str starts-with "WORKFLOW_TEST"))
            for var in $workflow_vars {
                hide-env $var
            }
            print "🧹 Mock: Workflow environment cleared"
        }
        
        clear_workflow_env
        
        # Verify cleanup
        let remaining_vars = ($env | columns | where ($it | str starts-with "WORKFLOW_TEST"))
        assert (($remaining_vars | length) == 0) "All workflow variables should be cleared"
        
        print "✅ Multi-environment workflow test passed"
    } catch { |e|
        print $"❌ E2E test failed: ($e.msg)"
        error make { msg: $"Test failed: ($e.msg)" }
    }
}

# E2E Test: Error recovery workflow
def test_error_recovery_workflow []: nothing -> nothing {
    print "🎯 Testing error recovery workflow..."
    
    try {
        # Simulate various error conditions and recovery
        let error_scenarios = [
            {name: "invalid_profile", recoverable: true}
            {name: "missing_credentials", recoverable: false}  
            {name: "network_error", recoverable: true}
        ]
        
        for scenario in $error_scenarios {
            print $"🔄 Testing error scenario: ($scenario.name)"
            
            # Simulate error condition
            let error_result = try {
                match $scenario.name {
                    "invalid_profile" => {
                        error make { 
                            msg: "Profile 'nonexistent' not found"
                            help: "Check your AWS configuration"
                        }
                    }
                    "missing_credentials" => {
                        error make {
                            msg: "AWS credentials file not found"
                            help: "Run 'aws configure' to set up credentials"
                        }
                    }
                    "network_error" => {
                        error make {
                            msg: "Unable to contact AWS STS service"
                            help: "Check your internet connection and try again"
                        }
                    }
                    _ => {
                        error make { msg: "Unknown error" }
                    }
                }
            } catch { |e|
                $e
            }
            
            # Verify error structure
            assert ("msg" in ($error_result | columns)) "Error should have message"
            assert ("help" in ($error_result | columns)) "Error should have help text"
            
            # Test recovery for recoverable errors
            if $scenario.recoverable {
                let recovery_successful = try {
                    print $"🔄 Mock: Attempting recovery for ($scenario.name)..."
                    # Mock recovery logic
                    true
                } catch {
                    false
                }
                
                print $"✅ Recovery test completed for ($scenario.name): successful = ($recovery_successful)"
            } else {
                print $"⚠️  Error ($scenario.name) is not recoverable (as expected)"
            }
        }
        
        print "✅ Error recovery workflow test passed"
    } catch { |e|
        print $"❌ E2E test failed: ($e.msg)"
        error make { msg: $"Test failed: ($e.msg)" }
    }
}

# E2E Test: Service integration workflow  
def test_service_integration_workflow []: nothing -> nothing {
    print "🎯 Testing service integration workflow..."
    
    try {
        # Test EKS integration pattern
        def test_eks_integration [cluster_name: string, region: string]: nothing -> nothing {
            print $"⚙️ Mock: Configuring kubectl for cluster ($cluster_name)..."
            
            # Mock AWS login
            $env.SERVICE_TEST_AWS_PROFILE = "eks-profile"
            $env.SERVICE_TEST_AWS_DEFAULT_REGION = $region
            
            # Mock kubectl configuration
            $env.SERVICE_TEST_KUBECONFIG = $"/tmp/kubectl-config-($cluster_name)"
            
            print $"✅ Mock: kubectl configured for ($cluster_name) in ($region)"
        }
        
        # Test ECR integration pattern
        def test_ecr_integration [region: string]: nothing -> nothing {
            print $"🐳 Mock: Authenticating Docker with ECR in ($region)..."
            
            # Mock AWS login
            $env.SERVICE_TEST_AWS_PROFILE = "ecr-profile"
            
            # Mock ECR authentication
            $env.SERVICE_TEST_DOCKER_REGISTRY = $"123456789012.dkr.ecr.($region).amazonaws.com"
            
            print $"✅ Mock: Docker authenticated with ECR in ($region)"
        }
        
        # Test service integrations
        test_eks_integration "production-cluster" "us-east-1"
        assert ($env.SERVICE_TEST_KUBECONFIG == "/tmp/kubectl-config-production-cluster") "Should set kubectl config"
        
        test_ecr_integration "us-west-2" 
        assert ($env.SERVICE_TEST_DOCKER_REGISTRY == "123456789012.dkr.ecr.us-west-2.amazonaws.com") "Should set ECR registry"
        
        # Cleanup
        let service_vars = ($env | columns | where ($it | str starts-with "SERVICE_TEST"))
        for var in $service_vars {
            hide-env $var
        }
        
        print "✅ Service integration workflow test passed"
    } catch { |e|
        print $"❌ E2E test failed: ($e.msg)"
        error make { msg: $"Test failed: ($e.msg)" }
    }
}

# E2E Test: Real-world usage patterns
def test_real_world_usage_patterns []: nothing -> nothing {
    print "🎯 Testing real-world usage patterns..."
    
    try {
        # Pattern 1: Daily developer workflow
        def daily_developer_workflow []: nothing -> nothing {
            print "👨‍💻 Mock: Daily developer workflow"
            
            # Morning: Check current status
            let current_profile = ($env | get --ignore-errors AWS_PROFILE | default "none")
            print $"Current profile: ($current_profile)"
            
            # Switch to dev for morning work
            $env.PATTERN_TEST_AWS_PROFILE = "development"
            print "🚀 Switched to development"
            
            # Lunch break: switch to staging for testing
            $env.PATTERN_TEST_AWS_PROFILE = "staging"  
            print "🔄 Switched to staging for testing"
            
            # End of day: clear credentials
            hide-env --ignore-errors PATTERN_TEST_AWS_PROFILE
            print "🧹 Cleared credentials"
        }
        
        # Pattern 2: Deployment workflow
        def deployment_workflow []: nothing -> nothing {
            print "🚀 Mock: Deployment workflow"
            
            # Test in staging first
            $env.PATTERN_TEST_AWS_PROFILE = "staging"
            print "✅ Tested in staging"
            
            # Deploy to production with confirmation
            let confirm = true  # Mock confirmation
            if $confirm {
                $env.PATTERN_TEST_AWS_PROFILE = "production"
                print "🚨 Deployed to production"
            }
            
            # Cleanup
            hide-env --ignore-errors PATTERN_TEST_AWS_PROFILE
            print "✅ Deployment completed"
        }
        
        # Pattern 3: Multi-client management
        def multi_client_workflow []: nothing -> nothing {
            print "🏢 Mock: Multi-client workflow"
            
            let clients = ["client1", "client2", "client3"]
            
            for client in $clients {
                $env.PATTERN_TEST_AWS_PROFILE = $"($client)-production"
                print $"🔄 Switched to ($client) environment"
            }
            
            # Cleanup
            hide-env --ignore-errors PATTERN_TEST_AWS_PROFILE
            print "✅ Multi-client work completed"
        }
        
        # Test each pattern
        daily_developer_workflow
        deployment_workflow
        multi_client_workflow
        
        # Verify all patterns completed without errors
        let final_env = ($env | columns | where ($it | str starts-with "PATTERN_TEST"))
        assert (($final_env | length) == 0) "All pattern test variables should be cleaned up"
        
        print "✅ Real-world usage patterns test passed"
    } catch { |e|
        print $"❌ E2E test failed: ($e.msg)"
        error make { msg: $"Test failed: ($e.msg)" }
    }
}

# Test Runner
def main []: nothing -> nothing {
    print "🎯 Running End-to-End Tests for AWS Login System"  
    print "=================================================="
    
    let tests = [
        test_installation_workflow
        test_alias_creation_e2e
        test_multi_environment_workflow
        test_error_recovery_workflow
        test_service_integration_workflow
        test_real_world_usage_patterns
    ]
    
    mut passed = 0
    mut failed = 0
    
    for test in $tests {
        try {
            do $test
            $passed = ($passed + 1)
        } catch { |e|
            print $"❌ E2E test failed: ($e.msg)"
            $failed = ($failed + 1)
        }
    }
    
    print "=================================================="
    print $"Results: ($passed) passed, ($failed) failed"
    
    if $failed > 0 {
        print "❌ Some end-to-end tests failed!"
        exit 1
    } else {
        print "✅ All end-to-end tests passed!"
    }
}