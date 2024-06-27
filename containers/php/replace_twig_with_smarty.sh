#!/bin/bash

# Check if composer.json exists and create a backup
if [ -f "composer.json" ]; then
    backup_file="composer.json.bak.$(date +%Y%m%d%H%M%S)"
    cp composer.json "$backup_file"
    echo "Backup of existing composer.json created as $backup_file"
else
    echo "No existing composer.json found. Please ensure you have a composer.json file."
    exit 1
fi

# Check if composer.lock exists and create a backup
if [ -f "composer.lock" ]; then
    backup_file="composer.lock.bak.$(date +%Y%m%d%H%M%S)"
    cp composer.lock "$backup_file"
    echo "Backup of existing composer.lock created as $backup_file"
fi

# Run composer show --locked and capture the output
output=$(composer show --locked)

# Initialize an empty JSON structure for the new require block
new_require='{}'

# Function to add a package to the new require block
add_package_to_require() {
  local package=$1
  local version=$2
  new_require=$(echo "$new_require" | jq --arg package "$package" --arg version "$version" '.[$package] = $version')
}

# Read the output line by line
while IFS= read -r line; do
  # Extract package name and version using regex
  if [[ $line =~ ^([a-z0-9/.-]+)\ +([0-9a-zA-Z.-]+) ]]; then
    package="${BASH_REMATCH[1]}"
    version="${BASH_REMATCH[2]}"
    add_package_to_require "$package" "$version"
  fi
done <<< "$output"

# Update the require block in the existing composer.json
updated_json=$(jq --argjson new_require "$new_require" '.require = $new_require' composer.json)

# Write the updated JSON back to composer.json
echo "$updated_json" > composer.json

# Remove lines containing "oxideshop-metapackage" and save the result
sed '/oxideshop-metapackage/d' composer.json > "composer.json.tmp" && mv "composer.json.tmp" "composer.json"

echo "composer.json has been updated with the new require block and oxideshop-metapackage packages removed."
echo "Please run 'composer update' to apply the changes."

# Optionally, remove composer.lock
if [ -f "composer.lock" ]; then
    rm composer.lock
    echo "composer.lock has been removed. It will be regenerated when you run 'composer update'."
fi

# do a composer update
#composer update
#echo "Changes applied with 'composer update'"

# -----------

# Remove Twig components
composer remove --no-update oxid-esales/apex-theme
composer remove --no-update oxid-esales/twig-admin-theme
composer remove --no-update oxid-esales/twig-component-ee
composer remove --no-update oxid-esales/twig-component-pe
composer remove --no-update oxid-esales/twig-component
composer remove --no-update twig/twig

# Remove demodata
composer remove --no-update oxid-esales/oxideshop-demodata-ee
composer remove --no-update oxid-esales/oxideshop-demodata-pe
composer remove --no-update oxid-esales/oxideshop-demodata-ce

# do a composer update
#composer update

# Require demodata
composer require --no-update oxid-esales/oxideshop-demodata-ce v7.1.0
composer require --no-update oxid-esales/oxideshop-demodata-pe v7.1.0
composer require --no-update oxid-esales/oxideshop-demodata-ee v7.1.0

# Require Smarty component
composer require --no-update oxid-esales/smarty-component v1.0.0
composer require --no-update oxid-esales/smarty-component-pe v1.0.0
composer require --no-update oxid-esales/smarty-component-ee v1.0.0

# Require Smarty-Themes
composer require --no-update oxid-esales/smarty-admin-theme v1.0.0
composer require --no-update oxid-esales/wave-theme v3.0.0

# do a composer update
composer update
echo "Twig has been replaced with Smarty and Wave theme installed"

./vendor/bin/oe-console oe:cache:clear

./vendor/bin/oe-console oe:theme:activate wave
echo "Wave theme activated"

rm -rf source/Application/views/admin_twig source/Application/views/apex source/out/admin_twig source/out/apex

echo "DONE"
