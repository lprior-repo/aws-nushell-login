#!/usr/bin/env nu
# Profile-Specific AWS Login Aliases - Example Implementation
# 
# This file demonstrates how to create convenient profile-specific aliases
# for your AWS environments using pure Nushell

# =============================================================================
# PROFILE-SPECIFIC LOGIN FUNCTIONS
# =============================================================================

# Development environment
export def awsl-dev []: nothing -> nothing {
    aws-login dev
    print "🚀 (ansi green)Connected to Development environment(ansi reset)"
    aws-status
}

# Staging environment with SSO
export def awsl-staging []: nothing -> nothing {
    aws-login staging --sso
    print "🚀 (ansi yellow)Connected to Staging environment(ansi reset)"
    aws-status
}

# Production environment with extra safety
export def awsl-prod []: nothing -> nothing {
    let confirm = (input "⚠️  You are connecting to PRODUCTION. Continue? (y/N): ")
    if $confirm != "y" {
        print "❌ Production access cancelled"
        return
    }
    
    aws-login production --sso
    print "🚀 (ansi red)Connected to Production environment(ansi reset)"
    print "⚠️  (ansi red)PRODUCTION ENVIRONMENT - BE CAREFUL!(ansi reset)"
    aws-status
}

# Sandbox environment
export def awsl-sandbox []: nothing -> nothing {
    aws-login sandbox
    print "🚀 (ansi cyan)Connected to Sandbox environment(ansi reset)"
    aws-status
}

# =============================================================================
# MULTI-ACCOUNT ORGANIZATION ALIASES
# =============================================================================

# Master/Root account
export def awsl-root []: nothing -> nothing {
    aws-login organization-master --sso
    print "🏢 (ansi purple)Connected to Organization Master account(ansi reset)"
    aws-status
}

# Security account
export def awsl-security []: nothing -> nothing {
    aws-login security-account --sso
    print "🔒 (ansi blue)Connected to Security account(ansi reset)"
    aws-status
}

# Logging account
export def awsl-logs []: nothing -> nothing {
    aws-login logging-account --sso
    print "📊 (ansi green)Connected to Logging account(ansi reset)"
    aws-status
}

# =============================================================================
# CLIENT-SPECIFIC ALIASES (for agencies/consultants)
# =============================================================================

# Client 1 environments
export def awsl-client1-dev []: nothing -> nothing {
    aws-login client1-development --sso
    print "🏢 (ansi cyan)Connected to Client1 Development(ansi reset)"
    aws-status
}

export def awsl-client1-prod []: nothing -> nothing {
    let confirm = (input "⚠️  Connecting to Client1 PRODUCTION. Continue? (y/N): ")
    if $confirm != "y" {
        print "❌ Cancelled"
        return
    }
    aws-login client1-production --sso
    print "🏢 (ansi red)Connected to Client1 Production(ansi reset)"
    aws-status
}

# =============================================================================
# REGION-AWARE ALIASES
# =============================================================================

# US East with profile
export def awsl-us-east [profile: string = "default"]: nothing -> nothing {
    aws-login $profile
    $env.AWS_DEFAULT_REGION = "us-east-1"
    $env.AWS_REGION = "us-east-1"
    print $"🌎 Profile: (ansi cyan)($profile)(ansi reset), Region: (ansi cyan)us-east-1(ansi reset)"
    aws-status
}

# US West with profile
export def awsl-us-west [profile: string = "default"]: nothing -> nothing {
    aws-login $profile
    $env.AWS_DEFAULT_REGION = "us-west-2"
    $env.AWS_REGION = "us-west-2"
    print $"🌎 Profile: (ansi cyan)($profile)(ansi reset), Region: (ansi cyan)us-west-2(ansi reset)"
    aws-status
}

# Europe with profile
export def awsl-eu [profile: string = "default"]: nothing -> nothing {
    aws-login $profile
    $env.AWS_DEFAULT_REGION = "eu-west-1"
    $env.AWS_REGION = "eu-west-1"
    print $"🌎 Profile: (ansi cyan)($profile)(ansi reset), Region: (ansi cyan)eu-west-1(ansi reset)"
    aws-status
}

# =============================================================================
# SERVICE-SPECIFIC WORKFLOW ALIASES
# =============================================================================

# EKS workflow: login + configure kubectl
export def awsl-eks [cluster: string, profile: string = "default", region: string = "us-west-2"]: nothing -> nothing {
    aws-login $profile
    $env.AWS_DEFAULT_REGION = $region
    $env.AWS_REGION = $region
    
    print $"⚙️  Configuring kubectl for cluster: (ansi green)($cluster)(ansi reset)"
    ^aws eks update-kubeconfig --name $cluster --region $region
    
    print "✅ EKS cluster configured"
    aws-status
    
    # Show current kubectl context
    try {
        let context = (^kubectl config current-context)
        print $"📋 Current kubectl context: (ansi yellow)($context)(ansi reset)"
    } catch {
        print "⚠️  kubectl not available or not configured"
    }
}

# ECR login workflow
export def awsl-ecr [profile: string = "default", region: string = "us-west-2"]: nothing -> nothing {
    aws-login $profile
    $env.AWS_DEFAULT_REGION = $region
    $env.AWS_REGION = $region
    
    print "🐳 Authenticating Docker with ECR..."
    let account = (^aws sts get-caller-identity --query Account --output text)
    ^aws ecr get-login-password --region $region | ^docker login --username AWS --password-stdin $"($account).dkr.ecr.($region).amazonaws.com"
    
    print "✅ Docker authenticated with ECR"
    aws-status
}

# =============================================================================
# TEMPORARY CREDENTIAL ALIASES
# =============================================================================

# MFA-enabled temporary credentials
export def awsl-mfa [profile: string = "default"]: nothing -> nothing {
    aws-login $profile --temp
    print $"🔐 (ansi green)Temporary credentials obtained for ($profile)(ansi reset)"
    print "⏰ These credentials will expire in 1 hour"
    aws-status
}

# =============================================================================
# INTERACTIVE AND UTILITY ALIASES
# =============================================================================

# Interactive profile selector with fuzzy matching
export def awsi []: nothing -> nothing {
    let profiles = (aws-profiles)
    
    if ($profiles | length) == 0 {
        print "❌ No AWS profiles found"
        print "💡 Run 'aws configure' to set up profiles"
        return
    }
    
    print "🔍 Available AWS profiles:"
    $profiles | enumerate | each { |item| 
        print $"  ($item.index + 1). ($item.item.profile) (($item.item.type))" 
    }
    
    let selection = (input "Enter profile number or name: ")
    
    # Try to parse as number first
    let profile_name = try {
        let index = ($selection | into int) - 1
        if $index >= 0 and $index < ($profiles | length) {
            $profiles | get $index | get profile
        } else {
            $selection
        }
    } catch {
        $selection
    }
    
    if $profile_name in ($profiles | get profile) {
        print $"🚀 Connecting to: (ansi cyan)($profile_name)(ansi reset)"
        aws-login $profile_name
        aws-status
    } else {
        print $"❌ Invalid selection: ($selection)"
    }
}

# Quick status check for all profiles
export def aws-check-all []: nothing -> table {
    print "🔍 Checking all AWS profiles..."
    
    aws-profiles | each { |profile_info|
        let profile = $profile_info.profile
        print $"  Checking ($profile)..."
        
        let status = try {
            aws-login $profile --export-only --verbose false
            "✅ Valid"
        } catch { |e|
            $"❌ ($e.msg | str substring 0..50)..."
        }
        
        {
            profile: $profile
            type: $profile_info.type
            status: $status
            checked_at: (date now | format date "%H:%M:%S")
        }
    }
}

# Profile switching with automatic region detection
export def awsp [profile: string, --region (-r): string]: nothing -> nothing {
    aws-login $profile
    
    if $region != null {
        $env.AWS_DEFAULT_REGION = $region
        $env.AWS_REGION = $region
        print $"🌎 Region set to: (ansi cyan)($region)(ansi reset)"
    }
    
    # Try to detect region from AWS config if not specified
    if $region == null {
        try {
            let detected_region = (^aws configure get region --profile $profile)
            if ($detected_region | str length) > 0 {
                $env.AWS_DEFAULT_REGION = $detected_region
                $env.AWS_REGION = $detected_region
                print $"🌎 Using configured region: (ansi cyan)($detected_region)(ansi reset)"
            }
        } catch {
            # Ignore errors, use default region
        }
    }
    
    aws-status
}

# =============================================================================
# BULK OPERATIONS
# =============================================================================

# Clear all AWS credentials and reset
export def aws-reset []: nothing -> nothing {
    print "🧹 Clearing all AWS credentials and environment..."
    aws-clear
    
    # Clear additional environment variables that might be set
    hide-env AWS_PROFILE?
    hide-env AWS_ACCESS_KEY_ID?
    hide-env AWS_SECRET_ACCESS_KEY?
    hide-env AWS_SESSION_TOKEN?
    hide-env AWS_DEFAULT_REGION?
    hide-env AWS_REGION?
    hide-env AWS_CREDENTIAL_EXPIRY?
    
    print "✅ AWS environment reset complete"
}

# Backup current AWS configuration
export def aws-backup-config []: nothing -> nothing {
    let backup_dir = $"~/.aws-backup-(date now | format date '%Y%m%d_%H%M%S')" | path expand
    
    print $"💾 Backing up AWS config to: (ansi cyan)($backup_dir)(ansi reset)"
    
    mkdir $backup_dir
    
    let aws_dir = "~/.aws" | path expand
    if ($aws_dir | path exists) {
        cp -r $aws_dir/* $backup_dir
        print "✅ AWS configuration backed up successfully"
    } else {
        print "⚠️  No AWS configuration found to backup"
    }
}

# =============================================================================
# VALIDATION AND TESTING
# =============================================================================

# Test AWS connectivity for a profile
export def aws-test [profile: string]: nothing -> nothing {
    print $"🧪 Testing AWS connectivity for profile: (ansi cyan)($profile)(ansi reset)"
    
    try {
        aws-login $profile --export-only
        
        # Test basic AWS operations
        print "  📋 Getting caller identity..."
        let identity = (^aws sts get-caller-identity | from json)
        print $"     Account: (ansi green)($identity.Account)(ansi reset)"
        print $"     User/Role: (ansi green)($identity.Arn | split row '/' | last)(ansi reset)"
        
        print "  📦 Testing S3 access..."
        try {
            let buckets = (^aws s3 ls | lines | length)
            print $"     Found ($buckets) S3 buckets"
        } catch {
            print "     S3 access not available or no buckets"
        }
        
        print "  💻 Testing EC2 access..."
        try {
            let instances = (^aws ec2 describe-instances --query 'Reservations[].Instances[].InstanceId' --output json | from json | length)
            print $"     Found ($instances) EC2 instances"
        } catch {
            print "     EC2 access not available or no instances"
        }
        
        print $"✅ (ansi green)Profile ($profile) is working correctly(ansi reset)"
        
    } catch { |e|
        print $"❌ (ansi red)Profile ($profile) test failed: ($e.msg)(ansi reset)"
    }
}