{
  lib,
  host,
  pkgs,
  inputs,
  ...
}: let
  cfg = host.features.productivity;
in {
  config = lib.mkIf cfg.resume {
    home = {
      packages = with pkgs; [
        # jsonresume-nix provides resume generation tools
        inputs.jsonresume-nix.packages.${pkgs.system}.default
      ];

      # Resume data configuration
      # This will be your resume data in JSON format
      file.".config/resume/resume.json" = {
        text = builtins.toJSON {
          basics = {
            name = "Lewis Flude";
            label = "Senior Full-stack Engineer";
            email = "lewis@lewisflude.com";
            phone = "07375 751794";
            url = "";
            summary = "Passionate web developer with 15 years of experience building robust, user-friendly web applications. Proven track record in startups and product-focused environments. Expertise in TypeScript, React, and Next.js. Seeking to leverage my skills in user experience, accessibility, and mentoring to contribute to an innovative, fast-paced team.";
            location = {
              address = "20 Belmont Road";
              postalCode = "CT11 7QG";
              city = "Ramsgate";
              countryCode = "GB";
              region = "Kent";
            };
            profiles = [];
          };
          work = [
            {
              name = "MoonPay";
              position = "Senior Full-stack Engineer";
              url = "https://moonpay.com";
              startDate = "2024-06-01";
              endDate = "2025-02-01";
              summary = "Contributed to the engineering and architecture of the core product, a mobile crypto wallet available on Android, iOS and the web. Led product engineering initiatives, taking features from design through to implementation and deployment.";
              highlights = [
                "Contributed to the engineering and architecture of the core product, a mobile crypto wallet available on Android, iOS and the web"
                "Led product engineering initiatives, taking features from design through to implementation and deployment"
              ];
            }
            {
              name = "Freelance";
              position = "Senior Full-stack Engineer";
              url = "";
              startDate = "2024-02-01";
              endDate = "2024-06-01";
              summary = "Worked on a greenfield project for a large UK-based meal delivery kit company. Delivered a web app with a high level of performance, accessibility, and user experience using TypeScript, React, and xState.";
              highlights = [
                "Worked on a greenfield project for a large UK-based meal delivery kit company"
                "Delivered a web app with a high level of performance, accessibility, and user experience using TypeScript, React, and xState"
              ];
            }
            {
              name = "Translucent";
              position = "Senior Front-end Engineer";
              url = "";
              startDate = "2023-01-01";
              endDate = "2024-01-01";
              summary = "Developed a robust web app capable of dealing with precise multi-entity accounting data using TypeScript, React, and tRPC. Led initiatives to enhance user experience, reduce technical debt, and streamline feature development.";
              highlights = [
                "Developed a robust web app capable of dealing with precise multi-entity accounting data using TypeScript, React, and tRPC"
                "Led initiatives to enhance user experience, reduce technical debt, and streamline feature development"
              ];
            }
            {
              name = "Decipad";
              position = "Software Engineer";
              url = "";
              startDate = "2022-05-01";
              endDate = "2023-01-01";
              summary = "Collaborated with a small product-oriented team to deliver features within a dynamic, collaborative low-code notebook using TypeScript, React, and Slate. Developed components focused on adding spreadsheet functionality and data processing/display.";
              highlights = [
                "Collaborated with a small product-oriented team to deliver features within a dynamic, collaborative low-code notebook using TypeScript, React, and Slate"
                "Developed components focused on adding spreadsheet functionality and data processing/display"
                "Refactored large parts of the front-end codebase and reduced technical debt"
              ];
            }
            {
              name = "Dojo";
              position = "Software Engineer";
              url = "";
              startDate = "2021-08-01";
              endDate = "2022-05-01";
              summary = "Helped develop a greenfield reimplementation of the web platform using TypeScript, React, and GraphQL. Bootstrapped an internal component library and worked on redeveloping key components of the customer-facing marketing site, customer onboarding, and the core product.";
              highlights = [
                "Helped develop a greenfield reimplementation of the web platform using TypeScript, React, and GraphQL"
                "Bootstrapped an internal component library"
                "Worked on redeveloping key components of the customer-facing marketing site, customer onboarding, and the core product using TypeScript, React, and GraphQL"
                "Led an internal component library initiative and helped roll out across front-end teams"
              ];
            }
            {
              name = "Trussle";
              position = "Product Engineer";
              url = "";
              startDate = "2019-11-01";
              endDate = "2021-03-01";
              summary = "Served as the principal front-end engineer on several client projects for Ralph Lauren, New Balance, Rapha and others. Mentored and trained a team of junior front-end developers.";
              highlights = [
                "Served as the principal front-end engineer on several client projects for Ralph Lauren, New Balance, Rapha and others"
                "Mentored and trained a team of junior front-end developers"
              ];
            }
            {
              name = "Unmade";
              position = "Senior Front-end Engineer";
              url = "";
              startDate = "2018-10-01";
              endDate = "2019-10-01";
              summary = "Led a front-end team working on a crypto wallet/exchange for iOS and Android using TypeScript, React, React Native, and Redux. Developed a design system/component library across iOS and Android.";
              highlights = [
                "Led a front-end team working on a crypto wallet/exchange for iOS and Android using TypeScript, React, React Native, and Redux"
                "Developed a design system/component library across iOS and Android"
              ];
            }
            {
              name = "Pillar";
              position = "Lead Front-end Developer";
              url = "";
              startDate = "2017-10-01";
              endDate = "2018-10-01";
              summary = "Hired to help develop HireMyFriend, a recruitment platform for developers. Refactored and improved front-end JS/CSS. Used Ruby/Rails to implement new features.";
              highlights = [
                "Hired to help develop HireMyFriend, a recruitment platform for developers"
                "Refactored and improved front-end JS/CSS"
                "Used Ruby/Rails to implement new features"
              ];
            }
            {
              name = "Makeshift";
              position = "Front-end Developer";
              url = "";
              startDate = "2014-09-01";
              endDate = "2015-02-01";
              summary = "Front-end development role focusing on web applications and user interfaces.";
              highlights = [];
            }
            {
              name = "Magnific";
              position = "Co Founder and CTO";
              url = "";
              startDate = "2014-01-01";
              endDate = "2016-10-01";
              summary = "Co-founded the company and made strategic decisions around design, engineering, and product. Scaled the business using Ruby, Rails, PHP, WordPress, and Amazon AWS. Took the company through the TechStars accelerator program and raised over £250k in seed funding.";
              highlights = [
                "Co-founded the company and made strategic decisions around design, engineering, and product"
                "Scaled the business using Ruby, Rails, PHP, WordPress, and Amazon AWS"
                "Took the company through the TechStars accelerator program"
                "Raised over £250k in seed funding"
                "Launched 7 online magazines, with over 2m unique visits/month"
              ];
            }
            {
              name = "enthuse.me";
              position = "Front-end Developer";
              url = "";
              startDate = "2012-10-01";
              endDate = "2014-01-01";
              summary = "Served as the lead front-end developer and designer. Led front-end development of the platform using Ruby, Rails, JavaScript, and Ember.js. Designed and implemented the overall UX/UI and developed a styleguide-driven front-end using Ember.js.";
              highlights = [
                "Served as the lead front-end developer and designer"
                "Led front-end development of the platform using Ruby, Rails, JavaScript, and Ember.js"
                "Designed and implemented the overall UX/UI"
                "Developed a styleguide-driven front-end using Ember.js"
              ];
            }
          ];
          skills = [
            {
              name = "Programming Languages";
              level = "Expert";
              keywords = [
                "JavaScript"
                "TypeScript"
                "Ruby"
                "PHP"
              ];
            }
            {
              name = "Frontend Frameworks";
              level = "Expert";
              keywords = [
                "React"
                "Next.js"
                "Ember.js"
                "React Native"
                "Redux"
              ];
            }
            {
              name = "Backend Technologies";
              level = "Advanced";
              keywords = [
                "Node.js"
                "Ruby on Rails"
                "GraphQL"
                "tRPC"
                "xState"
              ];
            }
            {
              name = "Tools & Technologies";
              level = "Advanced";
              keywords = [
                "Git"
                "AWS"
                "WordPress"
                "Slate"
                "Docker"
              ];
            }
            {
              name = "Design & UX";
              level = "Expert";
              keywords = [
                "UI/UX Design"
                "Component Libraries"
                "Design Systems"
                "Accessibility"
                "Styleguides"
              ];
            }
          ];
          languages = [
            {
              language = "English";
              fluency = "Native speaker";
            }
          ];
        };
      };

      # Create a script to generate the resume
      file.".local/bin/generate-resume" = {
        text = ''
          #!/usr/bin/env bash
          set -euo pipefail

          RESUME_DIR="$HOME/.config/resume"
          OUTPUT_DIR="$HOME/Documents/resume"

          # Create output directory if it doesn't exist
          mkdir -p "$OUTPUT_DIR"

          # Generate different formats
          echo "Generating resume in various formats..."

          # Generate PDF
          ${inputs.jsonresume-nix.packages.${pkgs.system}.default}/bin/resume-pdf "$RESUME_DIR/resume.json" "$OUTPUT_DIR/resume.pdf"
          echo "✓ PDF generated: $OUTPUT_DIR/resume.pdf"

          # Generate HTML
          ${inputs.jsonresume-nix.packages.${pkgs.system}.default}/bin/resume-html "$RESUME_DIR/resume.json" "$OUTPUT_DIR/resume.html"
          echo "✓ HTML generated: $OUTPUT_DIR/resume.html"

          # Generate JSON (copy the source)
          cp "$RESUME_DIR/resume.json" "$OUTPUT_DIR/resume.json"
          echo "✓ JSON copied: $OUTPUT_DIR/resume.json"

          echo "Resume generation complete!"
          echo "Files available in: $OUTPUT_DIR"
        '';
        executable = true;
      };
    };
  };
}
