# Resume Management with jsonresume-nix

This module provides resume generation capabilities using the [jsonresume-nix](https://github.com/TaserudConsulting/jsonresume-nix) flake.

## Features

- **JSON-based resume data**: Define your resume in a structured JSON format
- **Multiple output formats**: Generate PDF, HTML, and JSON versions
- **Automated generation**: Simple script to generate all formats at once
- **Version controlled**: Resume data is part of your Nix configuration

## Usage

### 1. Enable the resume feature

In your host configuration (e.g., `hosts/jupiter/default.nix`), enable the resume feature:

```nix
host.features.productivity.resume = true;
```

### 2. Customize your resume data

Edit the resume data in `home/common/features/productivity/resume.nix`. The file contains a comprehensive JSON structure with all standard resume sections:

- **basics**: Personal information, contact details, summary
- **work**: Work experience
- **education**: Educational background
- **skills**: Technical and soft skills
- **projects**: Personal and professional projects
- **volunteer**: Volunteer experience
- **awards**: Awards and recognition
- **certificates**: Professional certifications
- **publications**: Articles, papers, blog posts
- **languages**: Language proficiencies
- **interests**: Personal interests and hobbies
- **references**: Professional references

### 3. Generate your resume

After rebuilding your Nix configuration, you can generate your resume using:

```bash
generate-resume
```

This will create:

- `~/Documents/resume/resume.pdf` - PDF version
- `~/Documents/resume/resume.html` - HTML version
- `~/Documents/resume/resume.json` - JSON source

### 4. Customize the generation script

The generation script is located at `~/.local/bin/generate-resume`. You can modify it to:

- Change output directory
- Add custom themes
- Generate additional formats
- Add post-processing steps

## Resume Data Structure

The resume follows the [JSON Resume](https://jsonresume.org/) schema. Key sections include:

```json
{
  "basics": {
    "name": "Your Name",
    "label": "Job Title",
    "email": "your@email.com",
    "phone": "+1-555-123-4567",
    "url": "https://yourwebsite.com",
    "summary": "Professional summary...",
    "location": {
      "address": "123 Main St",
      "postalCode": "12345",
      "city": "City",
      "countryCode": "US",
      "region": "State"
    },
    "profiles": [
      {
        "network": "GitHub",
        "username": "yourusername",
        "url": "https://github.com/yourusername"
      }
    ]
  },
  "work": [
    {
      "name": "Company Name",
      "position": "Job Title",
      "url": "https://company.com",
      "startDate": "2023-01-01",
      "endDate": "",
      "summary": "Job description...",
      "highlights": [
        "Achievement 1",
        "Achievement 2"
      ]
    }
  ]
  // ... other sections
}
```

## Customization

### Themes

You can customize the appearance by modifying the generation script to use different themes:

```bash
# Use a different theme
resume-pdf --theme=modern "$RESUME_DIR/resume.json" "$OUTPUT_DIR/resume.pdf"
```

### Multiple Resumes

To create multiple resume versions (e.g., for different job types), you can:

1. Create additional JSON files in `~/.config/resume/`
2. Modify the generation script to handle multiple files
3. Use different themes or customizations for each version

### Integration with CI/CD

The JSON format makes it easy to integrate resume generation into CI/CD pipelines:

```yaml
# GitHub Actions example
- name: Generate Resume
  run: |
    nix run nixpkgs#nix -- build .#homeConfigurations.youruser.activationPackage
    ~/.local/bin/generate-resume
```

## Troubleshooting

### Common Issues

1. **Missing packages**: Ensure `jsonresume-nix` is properly added to your flake inputs
2. **Permission errors**: Check that the output directory is writable
3. **JSON validation**: Validate your JSON structure using online tools

### Debugging

Enable verbose output in the generation script:

```bash
set -x  # Add this to the script for debug output
```

## Resources

- [JSON Resume Schema](https://jsonresume.org/schema/)
- [jsonresume-nix Documentation](https://github.com/TaserudConsulting/jsonresume-nix)
- [Resume Themes](https://jsonresume.org/themes/)
