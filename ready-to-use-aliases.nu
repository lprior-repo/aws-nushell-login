#!/usr/bin/env nu
# Ready-to-Use Profile-Specific Aliases
# Copy these examples to your ~/.config/nushell/config.nu and customize

# =============================================================================
# BASIC PROFILE ALIASES - CUSTOMIZE THESE FOR YOUR ENVIRONMENT
# =============================================================================

# Quick login to different environments
# Replace 'development', 'staging', 'production' with your actual profile names
def awsl-dev []: nothing -> nothing {
    aws-login development  # or whatever your dev profile is named
    print "🚀 (ansi green)Connected to Development environment(ansi reset)"
    aws-status
}

def awsl-staging []: nothing -> nothing {
    aws-login staging --sso  # using SSO for staging
    print "🚀 (ansi yellow)Connected to Staging environment(ansi reset)"
    aws-status
}

# Production with safety confirmation
def awsl-prod []: nothing -> nothing {
    let confirm = (input "⚠️  You are connecting to PRODUCTION. Continue? (y/N): ")
    if $confirm != "y" {
        print "❌ Production access cancelled"
        return
    }
    
    aws-login production --sso
    print "🚨 (ansi red)PRODUCTION ENVIRONMENT - BE CAREFUL!(ansi reset)"
    aws-status
}

# Sandbox/testing environment
def awsl-sandbox []: nothing -> nothing {
    aws-login sandbox
    print "🚀 (ansi cyan)Connected to Sandbox environment(ansi reset)"
    aws-status
}

# =============================================================================
# REGION-SPECIFIC ALIASES
# =============================================================================

# Production in US East
def awsl-prod-us []: nothing -> nothing {
    awsl-prod
    if ("AWS_PROFILE" in ($env | columns)) {  # Only set region if login succeeded
        $env.AWS_DEFAULT_REGION = "us-east-1"
        $env.AWS_REGION = "us-east-1"
        print "🌎 Region set to US-East-1"
    }
}

# Production in Europe
def awsl-prod-eu []: nothing -> nothing {
    awsl-prod
    if ("AWS_PROFILE" in ($env | columns)) {  # Only set region if login succeeded
        $env.AWS_DEFAULT_REGION = "eu-west-1"
        $env.AWS_REGION = "eu-west-1"
        print "🌎 Region set to EU-West-1"
    }
}

# =============================================================================
# CLIENT-SPECIFIC ALIASES (for agencies/consultants)
# =============================================================================

# Replace 'client1', 'client2' with actual client names
def awsl-client1-dev []: nothing -> nothing {
    aws-login client1-development --sso
    print "🏢 (ansi cyan)Connected to Client1 Development(ansi reset)"
    aws-status
}

def awsl-client1-prod []: nothing -> nothing {
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
# SERVICE-SPECIFIC WORKFLOW ALIASES
# =============================================================================

# EKS/Kubernetes workflow - replace cluster names with yours
def awsl-k8s-dev []: nothing -> nothing {
    awsl-dev
    if ("AWS_PROFILE" in ($env | columns)) {
        print "⚙️  Configuring kubectl for dev cluster..."
        ^aws eks update-kubeconfig --name dev-cluster --region us-west-2
        print "✅ kubectl configured for development"
    }
}

def awsl-k8s-prod []: nothing -> nothing {
    awsl-prod
    if ("AWS_PROFILE" in ($env | columns)) {
        print "⚙️  Configuring kubectl for prod cluster..."
        ^aws eks update-kubeconfig --name production-cluster --region us-east-1
        print "✅ kubectl configured for production"
    }
}

# ECR/Docker workflow
def awsl-docker-dev []: nothing -> nothing {
    awsl-dev
    if ("AWS_PROFILE" in ($env | columns)) {
        print "🐳 Authenticating Docker with ECR..."
        let account = (^aws sts get-caller-identity --query Account --output text)
        let region = ($env.AWS_DEFAULT_REGION | default "us-west-2")
        ^aws ecr get-login-password --region $region | ^docker login --username AWS --password-stdin $"($account).dkr.ecr.($region).amazonaws.com"
        print "✅ Docker authenticated with ECR"
    }
}

# =============================================================================
# UTILITY ALIASES
# =============================================================================

# Interactive profile selector (when you can't remember profile names)
def awsi []: nothing -> nothing {
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

# Quick status check with current time
def awss []: nothing -> nothing {
    print $"🕐 Current time: (date now | format date '%Y-%m-%d %H:%M:%S')"
    aws-status
}

# Quick profile switch (no confirmation, use with caution)
def awsp [profile: string]: nothing -> nothing {
    aws-login $profile
    aws-status
}

# =============================================================================
# ORGANIZATION-SPECIFIC EXAMPLES
# =============================================================================

# Example 1: AWS Organizations setup
# def awsl-master []: nothing -> nothing {
#     aws-login organization-master --sso
#     print "🏢 Connected to Organization Master Account"
#     aws-status
# }

# def awsl-security []: nothing -> nothing {
#     aws-login security-account --sso
#     print "🔒 Connected to Security Account"
#     aws-status
# }

# Example 2: Multi-tenant SaaS setup
# def awsl-tenant1 []: nothing -> nothing {
#     aws-login tenant1-prod --sso
#     print "🏠 Connected to Tenant1 Production"
#     aws-status
# }

# =============================================================================
# TESTING AND VALIDATION
# =============================================================================

# Test all your profiles to make sure they work
def aws-test-all []: nothing -> nothing {
    print "🧪 Testing all AWS profiles..."
    
    aws-profiles | each { |profile_info|
        let profile = $profile_info.profile
        print $"  Testing ($profile)..."
        
        try {
            aws-login $profile --export-only
            let identity = (^aws sts get-caller-identity | complete)
            if $identity.exit_code == 0 {
                let info = ($identity.stdout | from json)
                print $"    ✅ ($profile): Account ($info.Account)"
            } else {
                print $"    ❌ ($profile): Cannot authenticate"
            }
        } catch { |e|
            print $"    ❌ ($profile): ($e.msg)"
        }
    }
    
    aws-clear
    print "🏁 Profile testing complete"
}

# =============================================================================
# CUSTOMIZATION INSTRUCTIONS
# =============================================================================

# To customize these aliases:
# 1. Replace profile names (development, staging, production) with your actual AWS profile names
# 2. Update cluster names in the EKS functions
# 3. Adjust regions to match your setup
# 4. Add/remove functions based on your workflow
# 5. Update client names if you're managing multiple clients

# To add these to your config:
# 1. Copy the functions you want to ~/.config/nushell/config.nu
# 2. Customize the profile names and settings
# 3. Restart your shell or run: source ~/.config/nushell/config.nu
# 4. Test with: awsl-dev, awsl-prod, etc.

print "📋 Profile-specific AWS aliases loaded!"
print "💡 Available shortcuts:"
print "   awsl-dev, awsl-staging, awsl-prod, awsl-sandbox"
print "   awsl-k8s-dev, awsl-k8s-prod, awsl-docker-dev"
print "   awsi (interactive), awss (quick status), awsp <profile>"
print ""
print "🔧 Customize the profile names in this file for your environment"
print "📖 See PROFILE_ALIASES_GUIDE.md for more examples"