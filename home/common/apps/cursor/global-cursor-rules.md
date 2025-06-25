# Global Cursor Rules
# Copy these rules to Cursor Settings → Rules for consistent AI behavior across all projects

## Code Quality & Style

- Always write clean, readable, and maintainable code
- Use meaningful variable and function names that clearly describe their purpose
- Follow established language conventions and idiomatic patterns
- Prefer explicit over implicit when it improves code clarity
- Write self-documenting code but add comments for complex business logic

## Error Handling & Safety

- Always handle errors gracefully and provide meaningful error messages
- Use proper error types and avoid generic exceptions
- Validate inputs and handle edge cases
- Never ignore errors or use empty catch blocks
- Prefer early returns to reduce nesting

## Performance & Efficiency

- Write efficient code but prioritize readability over premature optimization
- Avoid unnecessary complexity and over-engineering
- Use appropriate data structures for the task
- Consider memory usage and avoid memory leaks
- Profile before optimizing

## Security Best Practices

- Never hardcode secrets, API keys, or sensitive data
- Always validate and sanitize user inputs
- Use secure defaults and principle of least privilege
- Follow security best practices for the specific language/framework
- Be aware of common vulnerabilities (OWASP Top 10)

## Testing & Documentation

- Write testable code with clear separation of concerns
- Include unit tests for critical business logic
- Write clear, concise documentation for public APIs
- Use descriptive commit messages following conventional commits
- Keep README files up to date with setup instructions

## Language-Specific Guidelines

### TypeScript/JavaScript
- Use TypeScript when possible for better type safety
- Prefer const over let, avoid var
- Use modern ES6+ features appropriately
- Follow functional programming principles when beneficial
- Use proper async/await patterns

### Python
- Follow PEP 8 style guidelines
- Use type hints for function signatures
- Prefer list/dict comprehensions for simple transformations
- Use context managers for resource management
- Write docstrings for modules, classes, and functions

### Rust
- Embrace Rust's ownership system and borrow checker
- Use Result types for error handling
- Prefer explicit error handling over panicking
- Follow Rust naming conventions (snake_case, etc.)
- Use Clippy suggestions to improve code quality

### Nix
- Use consistent indentation (2 spaces)
- Organize attributes logically and use proper formatting
- Add comments for complex expressions
- Use meaningful attribute names
- Follow nixpkgs conventions for packaging

## Development Workflow

- Make small, focused commits with clear messages
- Use feature branches for new development
- Keep the main branch stable and deployable
- Review code before merging
- Update dependencies regularly but carefully

## Communication & Collaboration

- Write clear, professional code reviews
- Ask clarifying questions when requirements are unclear
- Suggest improvements constructively
- Share knowledge and document decisions
- Be responsive to feedback and iterate quickly

---

**Note**: These are general guidelines. Always defer to project-specific rules and team conventions when they exist.