# AWS Nushell Quick Reference Card

## 🚀 Quick Commands

```nu
# Basic login
aws-login                    # Use default profile
awsl production             # Login to production profile
aws-login dev --sso         # Login with SSO

# Status and management  
aws-status                  # Check current credentials
aws-profiles               # List available profiles
aws-clear                  # Clear credentials

# Advanced usage
aws-login prod --temp      # Get temporary credentials
aws-login staging --export-only --verbose  # Export with logging
```

## 🔧 Common Workflows

### Daily Development
```nu
# Start of day
awsl dev
aws-status

# Check what's available
aws s3 ls
aws ec2 describe-instances --query 'Reservations[].Instances[].{Name:Tags[?Key==`Name`]|[0].Value,State:State.Name}' --output table

# End of day  
aws-clear
```

### Multi-Environment Deployment
```nu
# Development testing
awsl dev
kubectl get pods

# Staging deployment  
awsl staging --sso
helm upgrade myapp ./chart --dry-run

# Production deployment
awsl production --sso  
# Deployment commands...
```

### Troubleshooting
```nu
# Check configuration
aws-profiles
aws configure list-profiles

# Verbose logging
aws-login profile --verbose

# Reset credentials
aws-clear
rm ~/.aws/sso/cache/*
aws sso login --profile profile_name
```

## 📋 Environment Variables Set

After `aws-login`:
- `$env.AWS_PROFILE` - Active profile
- `$env.AWS_ACCESS_KEY_ID` - Access key
- `$env.AWS_SECRET_ACCESS_KEY` - Secret key  
- `$env.AWS_SESSION_TOKEN` - Session token (if temp creds)
- `$env.AWS_DEFAULT_REGION` - Default region
- `$env.AWS_CREDENTIAL_EXPIRY` - When credentials expire

## 🛠️ Configuration Files

```nu
# Check AWS config
open ~/.aws/config | to yaml

# Check credentials (be careful!)
open ~/.aws/credentials | lines | where $it !~ "aws_secret_access_key"

# List SSO sessions
ls ~/.aws/sso/cache/
```

## 🎯 Integration Examples

### With Kubernetes
```nu
awsl production --sso
aws eks update-kubeconfig --name my-cluster --region us-west-2
kubectl config current-context
```

### With Terraform  
```nu
awsl dev
cd terraform/
terraform plan
terraform apply
```

### With Docker/ECR
```nu
awsl production
aws ecr get-login-password --region us-west-2 | docker login --username AWS --password-stdin 123456789012.dkr.ecr.us-west-2.amazonaws.com
docker push my-app:latest
```

## 🔍 Debugging

```nu
# Check AWS CLI installation
which aws

# Test basic connectivity
aws sts get-caller-identity

# Check SSO status
aws sso list-accounts

# Validate profile configuration
aws configure list --profile profile_name
```

## ⚡ Power User Tips

```nu
# Quick profile switching function
def awsp [profile: string] {
    aws-login $profile
    aws-status
}

# Batch profile validation
def check_all_profiles [] {
    aws-profiles | each { |p| 
        print $"Checking ($p.profile)..."
        try {
            aws-login $p.profile --export-only
            {profile: $p.profile, status: "✅ Valid"}
        } catch {
            {profile: $p.profile, status: "❌ Invalid"}
        }
    }
}

# Regional resource check
def aws_resources [region: string] {
    $env.AWS_DEFAULT_REGION = $region
    print $"Resources in ($region):"
    print $"  EC2: (aws ec2 describe-instances --region $region --query 'Reservations[].Instances[].InstanceId' --output text | lines | length)"
    print $"  S3: (aws s3 ls | lines | length) buckets"  
    print $"  EKS: (aws eks list-clusters --region $region --query 'clusters' --output text | lines | length)"
}
```

## 🚨 Security Reminders

- Always use `aws-clear` when switching between sensitive environments
- Check `aws-status` before running sensitive commands
- Use `--dry-run` flags when available
- Never commit credentials to version control
- Regularly rotate access keys
- Use SSO when possible for better security

## 📚 Files Created

- `~/bin/aws-login.nu` - Main login script
- `~/bin/aws-example.nu` - Example multi-environment script  
- `~/bin/AWS_LOGIN_README.md` - Comprehensive documentation
- `~/.config/nushell/config.nu` - Updated with aliases