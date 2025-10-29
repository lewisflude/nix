# Conventional Comments

This document outlines the standard for using conventional comments in code reviews and codebase annotations.

## What are Conventional Comments?

Conventional Comments is a standard for formatting comments in code reviews to make them more actionable and easier to parse. Each comment is prefixed with a label and an optional decoration.

**Format:** `<label> [decorations]: <subject>`

## Labels

### Required Action Labels

- **blocking:** This comment requires immediate action before the PR can be merged. The author must address it.

  ```
  blocking: This function needs error handling before we can merge.
  ```

- **nitpick:** Minor suggestions that don't block the PR. Author can choose to address or ignore.

  ```
  nitpick: Consider renaming this variable to `userCount` for clarity.
  ```

### Informational Labels

- **suggestion:** Propose an improvement or alternative approach.

  ```
  suggestion: We could use `fold` here for better functional style.
  ```

- **issue:** Highlight a specific problem that needs discussion or fixing.

  ```
  issue: This will cause a race condition when multiple users access simultaneously.
  ```

- **question:** Ask for clarification or more information.

  ```
  question: Why did we choose to use a HashMap here instead of a BTreeMap?
  ```

### Positive Labels

- **praise:** Acknowledge good work or clever solutions.

  ```
  praise: Excellent use of pattern matching here!
  ```

- **polish:** Suggest minor improvements for code quality.

  ```
  polish: Consider extracting this into a helper function.
  ```

### Context Labels

- **thought:** Share thinking without requiring action.

  ```
  thought: This reminds me of a similar pattern we used in the auth module.
  ```

- **chore:** Suggest maintenance or housekeeping tasks.

  ```
  chore: We should update the documentation for this API endpoint.
  ```

- **note:** Point out something important without requiring changes.

  ```
  note: This optimization is important for our performance requirements.
  ```

## Decorations (Optional)

Decorations provide additional context about the comment:

- **(non-blocking):** This comment doesn't prevent merging.

  ```
  suggestion (non-blocking): Consider adding more comments here.
  ```

- **(if-minor):** Only needs addressing if it's a quick fix.

  ```
  issue (if-minor): Small typo in the error message.
  ```

## Examples in Practice

### Code Review Comments

```
blocking: This function panics on empty input. We need error handling.
```

```
suggestion (non-blocking): Consider using the `anyhow` crate for better error messages.
```

```
question: Is this optimization necessary? Have we benchmarked it?
```

```
praise: Love how you structured this module! Very clean.
```

```
nitpick: Extra blank line here.
```

### Inline Code Comments

You can also use conventional comments in your code:

```nix
# TODO(blocking): Implement proper error handling for network failures
# FIXME(blocking): This creates a memory leak with large files
# NOTE: This optimization is critical for production performance
# QUESTION: Should we cache these results?
# REFACTOR(if-minor): Extract this logic into a separate function
```

## Benefits

1. **Clarity:** Reviewers and authors immediately understand the comment's intent
2. **Prioritization:** Easy to identify blocking vs. non-blocking issues
3. **Actionability:** Clear what needs to be done (or not done)
4. **Tone:** Helps maintain positive, constructive code review culture
5. **Searchability:** Easy to filter and find specific types of comments

## Best Practices

1. **Be Specific:** Make the subject clear and actionable
2. **Be Kind:** Use `praise` liberally, use `nitpick` sparingly
3. **Be Reasonable:** Not everything needs to be `blocking`
4. **Be Consistent:** Use the same labels across your team
5. **Be Empathetic:** Remember there's a human reading your comment

## Tool Integration

- **GitHub/GitLab:** Use these in PR comments
- **Code Comments:** Use in TODO, FIXME, NOTE annotations
- **Documentation:** Reference in design docs and RFCs

## Further Reading

- [Conventional Comments Specification](https://conventionalcomments.org/)
- [Code Review Best Practices](https://google.github.io/eng-practices/review/)

## Team Guidelines

When reviewing code in this repository:

1. Use conventional comment labels consistently
2. Mark truly blocking issues as `blocking` - be conservative
3. Use `praise` to acknowledge good work
4. Use `question` to start discussions
5. Use `suggestion` for architectural or design feedback
6. Use `nitpick` only for truly minor style issues

Remember: Code reviews are about maintaining quality while respecting each other's time and effort.
