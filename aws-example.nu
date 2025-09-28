#!/usr/bin/env nu
# Example: AWS Multi-Environment Deployment Script
# 
# This script demonstrates how to use the aws-login.nu script
# for managing AWS credentials across different environments

# Load the AWS login utilities
use ~/bin/aws-login.nu [clear_aws_env, list_aws_profiles]

# Configuration for different environments
const ENVIRONMENTS = {
    dev: {
        profile: "dev"
        region: "us-west-2"  
        cluster: "dev-cluster"
        use_sso: false
    }
    staging: {
        profile: "staging"
        region: "us-west-2"
        cluster: "staging-cluster" 
        use_sso: true
    }
    production: {
        profile: "production"
        region: "us-east-1"
        cluster: "prod-cluster"
        use_sso: true
    }
}

# Deploy to a specific environment
def "main deploy" [
    environment: string  # Environment to deploy to (dev, staging, production)
    --dry-run           # Show what would be deployed without actually doing it
    --force             # Skip confirmation prompts
]: nothing -> nothing {
    
    # Validate environment
    if not ($environment in ($ENVIRONMENTS | columns)) {
        let available_envs = ($ENVIRONMENTS | columns | str join ", ")
        error make {
            msg: $"Invalid environment: ($environment)"
            help: $"Available environments: ($available_envs)"
        }
    }
    
    let env_config = ($ENVIRONMENTS | get $environment)
    
    print $"🚀 Starting deployment to (ansi cyan)($environment)(ansi reset) environment"
    print $"   Profile: ($env_config.profile)"
    print $"   Region: ($env_config.region)"
    print $"   Cluster: ($env_config.cluster)"
    
    if $dry_run {
        print "\n📋 DRY RUN - Would perform the following actions:"
    }
    
    # Login to AWS for the target environment
    print "\n🔐 Authenticating with AWS..."
    try {
        if $env_config.use_sso {
            ^nu ~/bin/aws-login.nu $env_config.profile --sso
        } else {
            ^nu ~/bin/aws-login.nu $env_config.profile
        }
    } catch { |e|
        error make {
            msg: $"AWS login failed: ($e.msg)"
            help: "Check your AWS configuration and try again"
        }
    }
    
    # Confirmation for production
    if $environment == "production" and not $force and not $dry_run {
        let confirm = (input $"⚠️  You are about to deploy to PRODUCTION. Continue? (y/N): ")
        if $confirm != "y" {
            print "Deployment cancelled"
            return
        }
    }
    
    # Simulate deployment steps
    let steps = [
        "Validating AWS credentials"
        "Checking EKS cluster access"  
        "Building Docker images"
        "Pushing to ECR"
        "Updating Kubernetes manifests"
        "Rolling out deployment"
        "Verifying deployment health"
    ]
    
    print "\n📦 Deployment steps:"
    for step in $steps {
        if $dry_run {
            print $"   ✓ Would execute: ($step)"
        } else {
            print $"   🔄 ($step)..."
            # Simulate work
            sleep 500ms
            print $"   ✅ ($step) completed"
        }
    }
    
    if $dry_run {
        print $"\n🎭 DRY RUN completed - no actual changes made"
    } else {
        print $"\n🎉 (ansi green)Deployment to ($environment) completed successfully!(ansi reset)"
    }
    
    # Show final AWS status
    print "\n📊 Final AWS Status:"
    ^nu ~/bin/aws-login.nu --status
}

# List available environments and their status
def "main environments" []: nothing -> table {
    print "🌍 Available deployment environments:\n"
    
    $ENVIRONMENTS 
    | transpose environment config
    | each { |row|
        let env_name = $row.environment
        let config = $row.config
        
        # Check if profile exists and credentials are valid
        let profile_status = try {
            ^nu ~/bin/aws-login.nu $config.profile --export-only
            "✅ Ready"
        } catch {
            "❌ Needs Setup"
        }
        
        {
            environment: $env_name
            profile: $config.profile
            region: $config.region
            sso: $config.use_sso
            status: $profile_status
        }
    }
}

# Switch between environments quickly
def "main switch" [
    environment: string  # Environment to switch to
    --show-status       # Show detailed status after switch
]: nothing -> nothing {
    
    if not ($environment in ($ENVIRONMENTS | columns)) {
        let available_envs = ($ENVIRONMENTS | columns | str join ", ")
        error make {
            msg: $"Invalid environment: ($environment)"
            help: $"Available environments: ($available_envs)"
        }
    }
    
    let env_config = ($ENVIRONMENTS | get $environment)
    
    print $"🔄 Switching to (ansi cyan)($environment)(ansi reset) environment..."
    
    try {
        if $env_config.use_sso {
            ^nu ~/bin/aws-login.nu $env_config.profile --sso
        } else {
            ^nu ~/bin/aws-login.nu $env_config.profile
        }
        
        if $show_status {
            print "\n📊 Environment details:"
            ^nu ~/bin/aws-login.nu --status
            
            # Show some AWS resources if available
            print "\n🗂️  Quick resource check:"
            try {
                let s3_buckets = (^aws s3 ls | lines | length)
                print $"   S3 buckets: ($s3_buckets)"
            } catch {
                print "   S3 buckets: Unable to list"
            }
            
            try {
                let ec2_instances = (^aws ec2 describe-instances --query 'Reservations[].Instances[].InstanceId' --output text | lines | length)
                print $"   EC2 instances: ($ec2_instances)"
            } catch {
                print "   EC2 instances: Unable to list" 
            }
        }
        
    } catch { |e|
        error make {
            msg: $"Failed to switch to ($environment): ($e.msg)"
        }
    }
}

# Clean up AWS credentials
def "main cleanup" []: nothing -> nothing {
    print "🧹 Cleaning up AWS credentials..."
    clear_aws_env
    print "✅ AWS credentials cleared from environment"
}

# Show help and available commands
def main []: nothing -> nothing {
    print "🔧 AWS Multi-Environment Management Tool"
    print ""
    print "Available commands:"
    print "  deploy <env> [--dry-run] [--force] - Deploy to environment"  
    print "  environments                       - List available environments"
    print "  switch <env> [--show-status]       - Switch to environment"
    print "  cleanup                            - Clear AWS credentials"
    print ""
    print "Examples:"
    print "  ./aws-example.nu deploy dev --dry-run"
    print "  ./aws-example.nu switch production --show-status"
    print "  ./aws-example.nu environments"
    print ""
    print "Available environments:"
    let envs = ($ENVIRONMENTS | columns | str join ", ")
    print $"  ($envs)"
}