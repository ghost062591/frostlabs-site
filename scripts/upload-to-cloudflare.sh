#!/bin/bash
#
# Cloudflare Images Bulk Upload Script
#
# This script uploads images from your static/photos directory to Cloudflare Images
# and generates a mapping file for migration.
#
# Prerequisites:
# 1. Get your Cloudflare Account ID from: https://dash.cloudflare.com/ (in the URL or right sidebar)
# 2. Create an API token at: https://dash.cloudflare.com/profile/api-tokens
#    - Template: "Edit Cloudflare Images"
#    - Or custom token with "Account > Cloudflare Images > Edit" permission
#
# Usage:
#   export CF_ACCOUNT_ID="your-account-id"
#   export CF_API_TOKEN="your-api-token"
#   ./scripts/upload-to-cloudflare.sh [directory]
#
# Example:
#   ./scripts/upload-to-cloudflare.sh static/photos/house-project/delivery
#

set -e

# Configuration
CF_ACCOUNT_ID="${CF_ACCOUNT_ID:-}"
CF_API_TOKEN="${CF_API_TOKEN:-}"
UPLOAD_DIR="${1:-static/photos}"
MAPPING_FILE="cloudflare-image-mapping.csv"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check prerequisites
if [ -z "$CF_ACCOUNT_ID" ]; then
    echo -e "${RED}Error: CF_ACCOUNT_ID not set${NC}"
    echo "Get your Account ID from: https://dash.cloudflare.com/"
    echo "Then run: export CF_ACCOUNT_ID=\"your-account-id\""
    exit 1
fi

if [ -z "$CF_API_TOKEN" ]; then
    echo -e "${RED}Error: CF_API_TOKEN not set${NC}"
    echo "Create an API token at: https://dash.cloudflare.com/profile/api-tokens"
    echo "Then run: export CF_API_TOKEN=\"your-api-token\""
    exit 1
fi

if [ ! -d "$UPLOAD_DIR" ]; then
    echo -e "${RED}Error: Directory $UPLOAD_DIR does not exist${NC}"
    exit 1
fi

# API endpoint
API_ENDPOINT="https://api.cloudflare.com/client/v4/accounts/${CF_ACCOUNT_ID}/images/v1"

# Create or append to mapping file
if [ ! -f "$MAPPING_FILE" ]; then
    echo "original_path,cloudflare_id,cloudflare_url,upload_date" > "$MAPPING_FILE"
    echo -e "${GREEN}Created mapping file: $MAPPING_FILE${NC}"
fi

# Counter for progress
total_files=$(find "$UPLOAD_DIR" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" -o -iname "*.gif" \) | wc -l)
current=0
success=0
skipped=0
failed=0

echo -e "${GREEN}Starting upload of $total_files images from $UPLOAD_DIR${NC}"
echo "----------------------------------------"

# Find and upload all images
find "$UPLOAD_DIR" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" -o -iname "*.gif" \) | while read -r filepath; do
    current=$((current + 1))

    # Generate a meaningful ID from the file path
    # Example: static/photos/house-project/delivery/Delivery_001.jpg -> house-project-delivery-Delivery_001
    relative_path="${filepath#static/photos/}"
    cf_id=$(echo "$relative_path" | sed 's/\//-/g' | sed 's/\.[^.]*$//')

    # Check if already uploaded
    if grep -q "^${filepath}," "$MAPPING_FILE" 2>/dev/null; then
        echo -e "${YELLOW}[$current/$total_files] Skipped (already uploaded): $filepath${NC}"
        skipped=$((skipped + 1))
        continue
    fi

    echo -e "${YELLOW}[$current/$total_files] Uploading: $filepath${NC}"
    echo "  ID: $cf_id"

    # Upload to Cloudflare Images
    response=$(curl -s -X POST "$API_ENDPOINT" \
        -H "Authorization: Bearer $CF_API_TOKEN" \
        -F "id=$cf_id" \
        -F "file=@$filepath" \
        -F "requireSignedURLs=false")

    # Check if upload was successful
    if echo "$response" | grep -q '"success":true'; then
        # Extract the image ID and variants URL
        image_id=$(echo "$response" | grep -o '"id":"[^"]*"' | head -1 | cut -d'"' -f4)

        # Cloudflare Images URL format: https://imagedelivery.net/<account-hash>/<image-id>/<variant>
        # We'll need to get the delivery URL from the response
        delivery_url=$(echo "$response" | grep -o '"variants":\["[^"]*"' | cut -d'"' -f4 | sed 's/\/public$//')

        if [ -z "$delivery_url" ]; then
            # Fallback: construct URL if we can't extract it
            echo -e "${YELLOW}  Warning: Could not extract delivery URL from response${NC}"
            delivery_url="CHECK_CLOUDFLARE_DASHBOARD"
        fi

        # Save mapping
        echo "${filepath},${cf_id},${delivery_url},$(date -u +%Y-%m-%dT%H:%M:%SZ)" >> "$MAPPING_FILE"
        echo -e "${GREEN}  ✓ Success: $delivery_url${NC}"
        success=$((success + 1))
    else
        error_msg=$(echo "$response" | grep -o '"message":"[^"]*"' | cut -d'"' -f4)
        echo -e "${RED}  ✗ Failed: ${error_msg:-Unknown error}${NC}"
        echo "  Response: $response"
        failed=$((failed + 1))
    fi

    # Rate limiting: sleep briefly between uploads
    sleep 0.5
done

echo "----------------------------------------"
echo -e "${GREEN}Upload Complete!${NC}"
echo "  Successful: $success"
echo "  Skipped: $skipped"
echo "  Failed: $failed"
echo ""
echo "Mapping saved to: $MAPPING_FILE"
echo ""
echo "Next steps:"
echo "1. Review the mapping file to verify URLs"
echo "2. Update your Hugo content files to use Cloudflare URLs"
echo "3. Test your site locally before deploying"
