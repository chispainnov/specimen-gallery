# Specimen Gallery

An open-source collection of high-quality, transparent-background specimen images for scientific illustration, education, and creative projects. All images are moderated for quality and freely licensed under CC0 or CC-BY.

## Run Locally

```bash
# Install dependencies
bundle install

# Set up database
bin/rails db:setup

# Set admin password
export ADMIN_PASSWORD="your-secret-password"

# Start development server
bin/dev
```

Visit `http://localhost:3000`. Admin queue at `/admin/specimen_assets`.

## Contribution Rules

**Image requirements:**
- Transparent background (alpha channel required)
- Single specimen per image
- Minimum 512×512 pixels
- PNG or WebP format only
- No heavy filters, watermarks, or composites

**Quality standards:**
- Clean specimen isolation
- Accurate colors (minimal post-processing)
- Sharp focus on subject
- No visible artifacts or halos

## Licensing

- **CC0 (preferred):** Public domain. No attribution required.
- **CC-BY (allowed):** Attribution required. Must provide name and URL.

By uploading, you confirm you hold rights to the image and agree to release it under your selected license.

## Moderation

All uploads enter a pending queue and are reviewed before appearing in the public gallery. Submissions may be rejected for:
- Not meeting image requirements
- Incorrect or missing metadata
- Copyright concerns
- Low quality or duplicate content

## Format Specification

See [docs/format-v0.1.md](docs/format-v0.1.md) for the Specimen Gallery Format specification.
