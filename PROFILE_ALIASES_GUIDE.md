# Creating Profile-Specific AWS Login Aliases in Nushell

This guide shows you how to create convenient, profile-specific aliases for your AWS environments using pure Nushell. These aliases make switching between AWS accounts and environments as simple as typing `awsl-prod` or `awsl-dev`.

## 🎯 Quick Setup

### 1. Basic Profile Aliases

Add these to your `~/.config/nushell/config.nu`:

```nu
# Basic profile aliases - customize names for your environments
alias awsl-dev = aws-login development
alias awsl-staging = aws-login staging --sso
alias awsl-prod = aws-login production --sso
alias awsl-sandbox = aws-login sandbox
```

### 2. Safe Production Access

For production environments, add confirmation prompts:

```nu
# Production with safety prompt
def awsl-prod []: nothing -> nothing {
    let confirm = (input "⚠️  Connecting to PRODUCTION. Continue? (y/N): ")
    if $confirm != "y" {
        print "❌ Production access cancelled"
        return
    }
    aws-login production --sso
    print "🚀 (ansi red)Connected to Production - BE CAREFUL!(ansi reset)"
    aws-status
}
```

### 3. Auto-Generated Aliases

The installer can automatically generate aliases based on your existing AWS profiles:

```nu
# Run the installer to auto-generate aliases
./install.nu

# Or manually generate them
use profile-specific-examples.nu
```

## 🏢 Organization-Specific Examples

### Startup (Dev/Staging/Prod)

```nu
alias awsl-dev = aws-login dev
alias awsl-staging = aws-login staging --sso
alias awsl-prod = aws-login production --sso

# With regions
def awsl-prod-us []: nothing -> nothing {
    awsl-prod
    $env.AWS_DEFAULT_REGION = "us-east-1"
    $env.AWS_REGION = "us-east-1"
}
```

### Enterprise (Multi-Account)

```nu
# Organization accounts
alias awsl-master = aws-login org-master --sso
alias awsl-security = aws-login security-account --sso
alias awsl-logs = aws-login logging-account --sso

# Business unit accounts
alias awsl-finance = aws-login finance-prod --sso
alias awsl-hr = aws-login hr-systems --sso
```

### Agency/Consulting (Multi-Client)

```nu
# Client-specific environments
alias awsl-client1-dev = aws-login client1-development --sso
alias awsl-client1-prod = aws-login client1-production --sso
alias awsl-client2-dev = aws-login client2-development --sso
alias awsl-client2-prod = aws-login client2-production --sso

# Internal company accounts
alias awsl-internal = aws-login company-internal
```

## 🌍 Region-Aware Aliases

Create aliases that set both profile and region:

```nu
# Profile + Region combinations
def awsl-us-prod []: nothing -> nothing {
    aws-login production --sso
    $env.AWS_DEFAULT_REGION = "us-east-1"
    $env.AWS_REGION = "us-east-1"
    print "🌎 Production US-East-1"
    aws-status
}

def awsl-eu-prod []: nothing -> nothing {
    aws-login production-eu --sso
    $env.AWS_DEFAULT_REGION = "eu-west-1" 
    $env.AWS_REGION = "eu-west-1"
    print "🌎 Production EU-West-1"
    aws-status
}
```

## 🔧 Service-Specific Workflows

### EKS (Kubernetes) Integration

```nu
# Login + configure kubectl for EKS
def awsl-k8s [cluster: string, profile: string = "default"]: nothing -> nothing {
    aws-login $profile
    aws eks update-kubeconfig --name $cluster
    print $"⚙️  Configured kubectl for: (ansi green)($cluster)(ansi reset)"
    kubectl config current-context
}

# Shortcuts for specific clusters
alias awsl-k8s-dev = awsl-k8s dev-cluster development
alias awsl-k8s-prod = awsl-k8s prod-cluster production
```

### ECR (Docker Registry) Integration

```nu
# Login + authenticate Docker with ECR
def awsl-docker [profile: string = "default", region: string = "us-west-2"]: nothing -> nothing {
    aws-login $profile
    let account = (aws sts get-caller-identity --query Account --output text)
    aws ecr get-login-password --region $region | docker login --username AWS --password-stdin $"($account).dkr.ecr.($region).amazonaws.com"
    print "🐳 Docker authenticated with ECR"
}
```

## 🚀 Advanced Patterns

### Interactive Profile Selection

```nu
# Fuzzy profile selection
def awsi []: nothing -> nothing {
    let profiles = (aws-profiles)
    print "Available profiles:"
    $profiles | enumerate | each { |item| 
        print $"  ($item.index + 1). ($item.item.profile)" 
    }
    let selection = (input "Enter number or name: ")
    
    # Handle numeric or name selection
    let profile = try {
        let idx = ($selection | into int) - 1
        $profiles | get $idx | get profile
    } catch {
        $selection
    }
    
    aws-login $profile
    aws-status
}
```

### Temporary Credentials with MFA

```nu
# MFA-enabled temporary credentials
def awsl-mfa [profile: string]: nothing -> nothing {
    aws-login $profile --temp
    print "🔐 Temporary credentials (1 hour expiry)"
    aws-status
}

alias awsl-prod-mfa = awsl-mfa production
```

### Bulk Operations

```nu
# Check status of all profiles
def aws-check-all []: nothing -> table {
    aws-profiles | each { |p|
        let status = try {
            aws-login $p.profile --export-only
            "✅ Valid"
        } catch {
            "❌ Invalid"
        }
        {profile: $p.profile, status: $status}
    }
}
```

## 📋 Template for Your Organization

Copy this template and customize for your needs:

```nu
# =============================================================================
# YOUR ORGANIZATION AWS ALIASES
# =============================================================================

# Development environments
alias awsl-dev = aws-login YOUR_DEV_PROFILE
alias awsl-test = aws-login YOUR_TEST_PROFILE

# Staging environments  
alias awsl-staging = aws-login YOUR_STAGING_PROFILE --sso
alias awsl-uat = aws-login YOUR_UAT_PROFILE --sso

# Production environments (with safety)
def awsl-prod []: nothing -> nothing {
    let confirm = (input "⚠️  PRODUCTION access. Continue? (y/N): ")
    if $confirm != "y" { return }
    aws-login YOUR_PROD_PROFILE --sso
    print "🚨 PRODUCTION ENVIRONMENT"
    aws-status
}

# Multi-region production
def awsl-prod-us []: nothing -> nothing {
    awsl-prod
    $env.AWS_DEFAULT_REGION = "us-east-1"
    $env.AWS_REGION = "us-east-1" 
}

def awsl-prod-eu []: nothing -> nothing {
    awsl-prod  
    $env.AWS_DEFAULT_REGION = "eu-west-1"
    $env.AWS_REGION = "eu-west-1"
}

# Service-specific
def awsl-k8s-prod []: nothing -> nothing {
    awsl-prod
    aws eks update-kubeconfig --name YOUR_PROD_CLUSTER
}
```

## 🎨 Customization Tips

1. **Use descriptive names** that match your team's terminology
2. **Add confirmation prompts** for sensitive environments
3. **Include region setting** for multi-region setups
4. **Group related aliases** with comments
5. **Use consistent naming patterns** (e.g., `awsl-{env}`, `awsl-{client}-{env}`)
6. **Add visual indicators** with colors and emojis for different environment types

## 🔄 Dynamic Profile Management

For organizations with many profiles, create dynamic management:

```nu
# Generate aliases from AWS config
def generate_profile_aliases []: nothing -> nothing {
    aws-profiles | each { |p|
        let safe_name = ($p.profile | str replace -a "-" "_")
        let alias_cmd = if ($p.profile | str contains "prod") {
            $"def awsl_($safe_name) [] { awsl-prod-confirm ($p.profile) }"
        } else {
            $"alias awsl_($safe_name) = aws-login ($p.profile)"
        }
        print $alias_cmd
    }
}

# Helper for production confirmation
def awsl-prod-confirm [profile: string]: nothing -> nothing {
    let confirm = (input $"⚠️  Access ($profile) production? (y/N): ")
    if $confirm == "y" {
        aws-login $profile --sso
        aws-status
    }
}
```

This approach gives you maximum flexibility while maintaining safety and convenience! 🚀