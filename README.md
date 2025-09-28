# AWS Nushell Login

A comprehensive Nushell script for AWS CLI authentication and credential management with support for multiple profiles, SSO, temporary credentials, and environment variable export.

![Nushell](https://img.shields.io/badge/shell-nushell-green)
![AWS CLI](https://img.shields.io/badge/aws-cli-orange)
![License](https://img.shields.io/badge/license-MIT-blue)

## Features

- ✅ **Multi-Profile Support**: Switch between different AWS profiles easily
- ✅ **SSO Integration**: Full AWS Single Sign-On support
- ✅ **Credential Validation**: Automatic validation of AWS credentials
- ✅ **Environment Export**: Export credentials as environment variables
- ✅ **Temporary Credentials**: Support for session tokens and MFA
- ✅ **Status Monitoring**: Check current credential status and expiration
- ✅ **Profile Management**: List and manage AWS profiles
- ✅ **Security Features**: Input validation and secure credential handling
- ✅ **Functional Programming**: Built with Nushell's functional paradigms
- ✅ **Error Handling**: Comprehensive error handling with helpful messages
- ✅ **Logging**: Structured logging with configurable levels

## Installation

The script is installed at `~/bin/aws-login.nu` with the following aliases configured in your Nushell config:

```nu
alias aws-login = ~/bin/aws-login.nu        # Main command
alias awsl = ~/bin/aws-login.nu             # Short version
alias aws-clear = ~/bin/aws-login.nu clear_aws_env    # Clear credentials
alias aws-profiles = ~/bin/aws-login.nu list_aws_profiles  # List profiles
alias aws-status = ~/bin/aws-login.nu --status        # Check status
```

## Usage

### Basic Login
```nu
# Login with default profile
aws-login

# Login with specific profile
aws-login production

# Short form
awsl dev
```

### SSO Login
```nu
# Login with SSO
aws-login production --sso

# SSO with verbose output
awsl prod --sso --verbose
```

### Temporary Credentials
```nu
# Get temporary credentials (useful for MFA)
aws-login dev --temp

# Export only (don't validate)
aws-login staging --export-only
```

### Status and Management
```nu
# Check current credential status
aws-status

# List available profiles
aws-profiles

# Clear credentials from environment
aws-clear
```

## Command Options

| Option | Description |
|--------|-------------|
| `[profile]` | AWS profile name (default: "default") |
| `--sso` | Use AWS SSO login |
| `--export-only` | Only export existing credentials, don't validate |
| `--temp` | Get temporary credentials (useful for MFA) |
| `--status` | Show current credential status |
| `--verbose` | Enable verbose logging |

## Examples

### Daily Workflow
```nu
# Morning: Login to development
awsl dev

# Check what's currently active
aws-status

# Switch to production for deployment
awsl production --sso

# After work: clear credentials
aws-clear
```

### CI/CD Pipeline
```nu
# Validate credentials before deployment
aws-login $env.AWS_PROFILE --export-only
if $env.LAST_EXIT_CODE == 0 {
    print "✅ AWS credentials are valid"
    # Continue with deployment...
} else {
    print "❌ AWS credentials are invalid"
    exit 1
}
```

### Multiple Environments
```nu
# Development work
awsl dev --verbose
aws s3 ls

# Quick switch to staging
awsl staging
aws eks list-clusters

# Production deployment (with SSO)
awsl prod --sso
aws ecs update-service --service my-app
```

## Configuration

The script expects standard AWS CLI configuration files:
- `~/.aws/config` - AWS profiles and SSO configuration
- `~/.aws/credentials` - Access keys and secrets

### Example ~/.aws/config
```ini
[default]
region = us-west-2

[profile dev]
region = us-west-2
output = json

[profile production]
sso_start_url = https://my-company.awsapps.com/start
sso_region = us-east-1
sso_account_id = 123456789012
sso_role_name = AdministratorAccess
region = us-west-2
```

### Example ~/.aws/credentials
```ini
[default]
aws_access_key_id = AKIA...
aws_secret_access_key = ...

[dev]
aws_access_key_id = AKIA...
aws_secret_access_key = ...
```

## Environment Variables

After successful login, the following environment variables are set:

| Variable | Description |
|----------|-------------|
| `AWS_PROFILE` | Active AWS profile name |
| `AWS_ACCESS_KEY_ID` | AWS access key |
| `AWS_SECRET_ACCESS_KEY` | AWS secret key |
| `AWS_SESSION_TOKEN` | Session token (if applicable) |
| `AWS_DEFAULT_REGION` | Default AWS region |
| `AWS_REGION` | AWS region (duplicate for compatibility) |
| `AWS_CREDENTIAL_EXPIRY` | Credential expiration time |

## Security Features

- **Input Validation**: All inputs are validated and sanitized
- **Secure File Handling**: Credentials file permissions are checked
- **Error Masking**: Sensitive information is masked in logs
- **Fail Fast**: Script fails immediately on security issues
- **Least Privilege**: Only requests necessary permissions

## Functional Programming Features

This script demonstrates Nushell's functional programming capabilities:

- **Pure Functions**: All functions are side-effect free where possible
- **Immutable Data**: No variable mutation, data flows through transformations
- **Function Composition**: Complex operations built from simple functions
- **Type Safety**: All functions have explicit type signatures
- **Error Monads**: Error handling through try/catch chains
- **Streaming**: Efficient processing of configuration files

## Troubleshooting

### Common Issues

1. **"AWS CLI not found"**
   ```nu
   # Install AWS CLI
   curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
   unzip awscliv2.zip
   sudo ./aws/install
   ```

2. **"AWS credentials file not found"**
   ```nu
   # Initialize AWS configuration
   aws configure
   ```

3. **SSO Login Issues**
   ```nu
   # Check SSO configuration
   aws configure sso
   
   # Clear SSO cache if needed
   rm -rf ~/.aws/sso/cache
   ```

4. **Permission Errors**
   ```nu
   # Fix credentials file permissions
   chmod 600 ~/.aws/credentials
   chmod 600 ~/.aws/config
   ```

### Debug Mode

Enable verbose logging for troubleshooting:
```nu
aws-login profile --verbose
```

### Log Files

Logs are written to standard output with structured format:
```nu
# Check recent AWS login attempts
aws-login --status | to json
```

## Advanced Usage

### Custom Profile Validation
```nu
# Validate specific profile without switching
def validate_aws_profile [profile: string]: nothing -> bool {
    try {
        aws-login $profile --export-only
        true
    } catch {
        false
    }
}
```

### Batch Profile Processing
```nu
# Check all profiles
aws-profiles | each { |p|
    {
        profile: $p.profile
        valid: (validate_aws_profile $p.profile)
    }
}
```

### Integration with Other Tools
```nu
# Use with kubectl for EKS
awsl production --sso
aws eks update-kubeconfig --name my-cluster
kubectl get pods
```

## Contributing

This script follows Nushell best practices:
- Functional programming paradigms
- Comprehensive error handling
- Type-safe interfaces
- Structured logging
- Production-ready patterns

Feel free to extend the script with additional features or improvements!

## License

This script is provided as-is for educational and practical use.