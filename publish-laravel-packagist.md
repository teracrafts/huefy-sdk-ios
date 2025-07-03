# Publish Laravel SDK to Packagist

## Manual Packagist Submission

Since the Laravel SDK is not yet on Packagist, you need to submit it manually:

### Step 1: Submit to Packagist

1. **Go to Packagist**: https://packagist.org/packages/submit
2. **Enter Repository URL**: `https://github.com/teracrafts/huefy-sdk-laravel`
3. **Click "Check"** - Packagist will validate the composer.json
4. **Click "Submit"** - This will create the package on Packagist

### Step 2: Verify Package Information

The package should appear as:
- **Name**: `teracrafts/huefy-laravel`
- **Version**: `v1.0.0` 
- **Repository**: `https://github.com/teracrafts/huefy-sdk-laravel`

### Step 3: Set Up Auto-Update Webhook (Recommended)

1. **Go to GitHub Repository**: https://github.com/teracrafts/huefy-sdk-laravel
2. **Settings → Webhooks → Add webhook**
3. **Payload URL**: `https://packagist.org/api/github?username=USERNAME&apiToken=API_TOKEN`
   - Replace `USERNAME` with your Packagist username
   - Replace `API_TOKEN` with your Packagist API token
4. **Content type**: `application/json`
5. **Events**: Select "Just the push event"
6. **Active**: ✅ Checked

### Alternative: Manual Update

If you prefer manual updates instead of webhook:
1. Go to https://packagist.org/packages/teracrafts/huefy-laravel
2. Click "Update" button whenever you push new versions

## Testing Installation

Once published, test the installation:

```bash
# Create a new Laravel project
laravel new test-huefy

# Install the package
cd test-huefy
composer require teracrafts/huefy-laravel

# Publish config
php artisan vendor:publish --tag=huefy-config

# Test commands
php artisan huefy:health
```

## Expected Composer.json Validation

Packagist should validate these fields from our composer.json:

✅ **Required Fields:**
- `name`: "teracrafts/huefy-laravel"
- `description`: "Laravel package for Huefy..."
- `type`: "library"
- `license`: "MIT"

✅ **PSR-4 Autoloading:**
- `TeraCrafts\\HuefyLaravel\\`: "src/"

✅ **Laravel Auto-Discovery:**
- Service provider registration
- Facade alias registration

✅ **Dependencies:**
- PHP 8.1+
- Laravel 9.x|10.x|11.x
- Guzzle HTTP client

## Troubleshooting

**If submission fails:**
1. Check composer.json syntax: `composer validate`
2. Ensure repository is public
3. Verify all required fields are present

**If auto-update doesn't work:**
1. Check webhook configuration
2. Verify API token permissions
3. Check webhook delivery logs in GitHub