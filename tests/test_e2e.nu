#!/usr/bin/env nu  
# End-to-End Tests (10% of test suite)
# Tests complete user scenarios with real external dependencies (controlled)

use std assert
source ../aws-login.nu

# =============================================================================
# SETUP AND TEARDOWN
# =============================================================================

#[before-each]
def setup [] {
    {
        temp_dir: (mktemp -d),
        backup_aws_dir: ($env.AWS_CONFIG_DIR? | default "~/.aws"),
        original_env: ($env | select -o AWS_PROFILE AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_DEFAULT_REGION AWS_SESSION_TOKEN)
    }
}

#[after-each]
def cleanup [] {
    let context = $in
    try { rm -rf $context.temp_dir } catch { }
    clear_aws_env
    
    # Restore original environment
    for key in ($context.original_env | columns) {
        if ($context.original_env | get $key) != null {
            load-env {($key): ($context.original_env | get $key)}
        }
    }
}

# =============================================================================
# ALIAS PATTERN SIMULATION TESTS  
# =============================================================================

#[test]
def "alias pattern - should simulate awsl-dev workflow" [] {
    let context = $in
    mkdir $context.temp_dir
    
    # Create realistic dev environment configuration
    let credentials_content = "[development]
aws_access_key_id = AKIADEVKEY1234567890
aws_secret_access_key = DevSecretKey123456789012345678901234"
    
    let config_content = "[profile development] 
region = us-east-1
output = json"
    
    $credentials_content | save $"($context.temp_dir)/credentials"  
    $config_content | save $"($context.temp_dir)/config"
    
    with-env {AWS_CONFIG_DIR: $context.temp_dir} {
        # Simulate alias: def awsl-dev [] { aws-login development }
        def awsl-dev []: nothing -> nothing {
            main "development" --export-only  # Use export-only to avoid AWS API
            print "🚀 Connected to Development"
        }
        
        try {
            awsl-dev
            
            # Verify the alias worked  
            assert ($env.AWS_PROFILE == "development") "Alias should set development profile"
            assert ($env.AWS_ACCESS_KEY_ID == "AKIADEVKEY1234567890") "Should export dev credentials"
            assert ($env.AWS_DEFAULT_REGION == "us-east-1") "Should set dev region"
            
        } catch { |e|
            assert false $"Development alias workflow should succeed: ($e.msg)"
        }
    }
}

#[test]
def "alias pattern - should simulate awsl-prod with safety check" [] {
    let context = $in
    mkdir $context.temp_dir
    
    # Create production configuration
    let credentials_content = "[production]
aws_access_key_id = AKIAPRODKEY123456789
aws_secret_access_key = ProdSecretKey12345678901234567890123"
    
    let config_content = "[profile production]
region = us-west-2  
output = json"
    
    $credentials_content | save $"($context.temp_dir)/credentials"
    $config_content | save $"($context.temp_dir)/config"
    
    with-env {AWS_CONFIG_DIR: $context.temp_dir} {
        # Simulate production alias with safety (auto-confirm for test)
        def awsl-prod-test []: nothing -> nothing {
            # Skip confirmation for automated test
            main "production" --export-only
            print "🚨 PRODUCTION ENVIRONMENT - BE CAREFUL!"
        }
        
        try {
            awsl-prod-test
            
            # Verify production environment setup
            assert ($env.AWS_PROFILE == "production") "Should set production profile"
            assert ($env.AWS_ACCESS_KEY_ID == "AKIAPRODKEY123456789") "Should export prod credentials"
            assert ($env.AWS_DEFAULT_REGION == "us-west-2") "Should set prod region"
            
        } catch { |e|
            assert false $"Production alias workflow should succeed: ($e.msg)"
        }
    }
}

#[test]
def "alias pattern - should simulate region override" [] {
    let context = $in
    mkdir $context.temp_dir
    
    let credentials_content = "[us-prod]
aws_access_key_id = AKIAUSKEY1234567890123
aws_secret_access_key = USSecretKey123456789012345678901234"
    
    let config_content = "[profile us-prod]
region = us-west-2"
    
    $credentials_content | save $"($context.temp_dir)/credentials"
    $config_content | save $"($context.temp_dir)/config"
    
    with-env {AWS_CONFIG_DIR: $context.temp_dir} {
        # Simulate region-specific alias
        def awsl-prod-us-east []: nothing -> nothing {
            main "us-prod" --export-only
            # Override region after login
            if ("AWS_PROFILE" in ($env | columns)) {
                $env.AWS_DEFAULT_REGION = "us-east-1"  
                $env.AWS_REGION = "us-east-1"
            }
        }
        
        try {
            awsl-prod-us-east
            
            # Verify region override worked
            assert ($env.AWS_PROFILE == "us-prod") "Should set profile"
            assert ($env.AWS_DEFAULT_REGION == "us-east-1") "Should override to us-east-1"
            assert ($env.AWS_REGION == "us-east-1") "Should override both region vars"
            
        } catch { |e|
            assert false $"Region override workflow should succeed: ($e.msg)"
        }
    }
}

# =============================================================================
# MULTI-PROFILE SCENARIOS
# =============================================================================

#[test]  
def "multi-profile scenario - should handle profile switching" [] {
    let context = $in
    mkdir $context.temp_dir
    
    # Create multiple profiles
    let credentials_content = "[dev]
aws_access_key_id = AKIADEVKEY1234567890123
aws_secret_access_key = DevSecret12345678901234567890123456

[staging]  
aws_access_key_id = AKIASTAGEKEY12345678901
aws_secret_access_key = StageSecret123456789012345678901234

[production]
aws_access_key_id = AKIAPRODKEY123456789012
aws_secret_access_key = ProdSecret1234567890123456789012"
    
    let config_content = "[profile dev]
region = us-east-1

[profile staging]
region = us-east-2  

[profile production]
region = us-west-1"
    
    $credentials_content | save $"($context.temp_dir)/credentials"
    $config_content | save $"($context.temp_dir)/config"
    
    with-env {AWS_CONFIG_DIR: $context.temp_dir} {
        # Test switching between profiles
        main "dev" --export-only
        assert ($env.AWS_PROFILE == "dev") "Should switch to dev"
        assert ($env.AWS_DEFAULT_REGION == "us-east-1") "Should use dev region"
        
        main "staging" --export-only  
        assert ($env.AWS_PROFILE == "staging") "Should switch to staging"
        assert ($env.AWS_DEFAULT_REGION == "us-east-2") "Should use staging region"
        assert ($env.AWS_ACCESS_KEY_ID == "AKIASTAGEKEY12345678901") "Should use staging credentials"
        
        main "production" --export-only
        assert ($env.AWS_PROFILE == "production") "Should switch to production"
        assert ($env.AWS_DEFAULT_REGION == "us-west-1") "Should use production region"
        assert ($env.AWS_ACCESS_KEY_ID == "AKIAPRODKEY123456789012") "Should use production credentials"
    }
}

# =============================================================================
# COMPREHENSIVE USER SCENARIOS
# =============================================================================

#[test]
def "user scenario - should handle complete day-in-the-life workflow" [] {
    let context = $in
    mkdir $context.temp_dir
    
    # Set up realistic multi-environment configuration
    let credentials_content = "[personal]
aws_access_key_id = AKIAPERSONAL1234567890
aws_secret_access_key = PersonalSecret123456789012345678901

[work-dev]
aws_access_key_id = AKIAWORKDEV123456789012
aws_secret_access_key = WorkDevSecret12345678901234567890

[work-prod]  
aws_access_key_id = AKIAWORKPROD12345678901
aws_secret_access_key = WorkProdSecret123456789012345678"
    
    let config_content = "[profile personal]
region = us-west-2

[profile work-dev]
region = us-east-1

[profile work-prod] 
region = us-east-1"
    
    $credentials_content | save $"($context.temp_dir)/credentials"
    $config_content | save $"($context.temp_dir)/config"
    
    with-env {AWS_CONFIG_DIR: $context.temp_dir} {
        # Simulate user's daily workflow
        
        # 1. Start with personal projects
        main "personal" --export-only
        assert ($env.AWS_PROFILE == "personal") "Should start with personal"
        
        # 2. Check current status
        try {
            main "personal" --status
            # Status should work
        } catch {
            # Status might fail without real AWS, but shouldn't crash
        }
        
        # 3. Switch to work development
        main "work-dev" --export-only  
        assert ($env.AWS_PROFILE == "work-dev") "Should switch to work-dev"
        assert ($env.AWS_DEFAULT_REGION == "us-east-1") "Should use work region"
        
        # 4. Clear credentials for security
        clear_aws_env
        assert not ("AWS_PROFILE" in ($env | columns)) "Should clear all AWS vars"
        
        # 5. Later, switch to production with safety
        main "work-prod" --export-only
        assert ($env.AWS_PROFILE == "work-prod") "Should switch to production"
        
        # 6. Final cleanup
        clear_aws_env
        assert not ("AWS_ACCESS_KEY_ID" in ($env | columns)) "Should end clean"
    }
}

# =============================================================================
# ERROR RECOVERY SCENARIOS
# =============================================================================

#[test]
def "error recovery - should handle missing profile gracefully" [] {
    let context = $in
    mkdir $context.temp_dir
    
    # Create minimal config with one profile
    let credentials_content = "[existing-profile]
aws_access_key_id = AKIAEXISTING123456789012
aws_secret_access_key = ExistingSecret12345678901234567890"
    
    $credentials_content | save $"($context.temp_dir)/credentials"
    
    with-env {AWS_CONFIG_DIR: $context.temp_dir} {
        # Try to use non-existent profile
        let error_caught = try {
            main "nonexistent-profile" --export-only
            false
        } catch { |e|
            assert ($e.msg | str contains "not found") "Should give helpful error"
            assert ($e.help | str contains "Available profiles") "Should suggest available profiles"
            true
        }
        assert $error_caught "Should catch missing profile error"
        
        # Verify environment wasn't corrupted
        assert not ("AWS_PROFILE" in ($env | columns)) "Should not set invalid profile"
    }
}

#[test]
def "error recovery - should handle corrupted config gracefully" [] {
    let context = $in
    mkdir $context.temp_dir
    
    # Create corrupted credentials file
    "This is not valid INI format
[incomplete-section
missing = closing bracket" | save $"($context.temp_dir)/credentials"
    
    with-env {AWS_CONFIG_DIR: $context.temp_dir} {
        let error_caught = try {
            main "any-profile" --export-only
            false
        } catch {
            true
        }
        assert $error_caught "Should handle corrupted config gracefully"
        
        # Environment should remain clean after error
        clear_aws_env  # Ensure clean state
        assert not ("AWS_PROFILE" in ($env | columns)) "Should not leave corrupt state"
    }
}

# =============================================================================
# PERFORMANCE AND RELIABILITY  
# =============================================================================

#[test]
def "performance - should handle large profile lists efficiently" [] {
    let context = $in
    mkdir $context.temp_dir
    
    # Create configuration with many profiles
    mut credentials_content = ""
    mut config_content = ""
    
    for i in 1..50 {
        $credentials_content = $credentials_content + $"
[profile($i)]
aws_access_key_id = AKIAPROFILE($i)1234567890
aws_secret_access_key = ProfileSecret($i)12345678901234567"
        
        $config_content = $config_content + $"  
[profile profile($i)]
region = us-east-1"
    }
    
    $credentials_content | save $"($context.temp_dir)/credentials"
    $config_content | save $"($context.temp_dir)/config"
    
    with-env {AWS_CONFIG_DIR: $context.temp_dir} {
        # Test that profile listing is still performant
        let start_time = date now
        let profiles = list_aws_profiles  
        let end_time = date now
        let duration = $end_time - $start_time
        
        assert (($profiles | length) == 50) "Should find all 50 profiles"
        # Duration should be reasonable (less than 5 seconds for 50 profiles)
        assert ($duration < 5sec) "Profile listing should be performant"
    }
}