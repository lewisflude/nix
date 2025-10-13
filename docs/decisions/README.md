# Architecture Decision Records (ADRs)

This directory contains Architecture Decision Records for the Nix configuration.

## What is an ADR?

An Architecture Decision Record (ADR) is a document that captures an important architectural decision made along with its context and consequences.

## Format

Each ADR follows this structure:

```markdown
# ADR-XXXX: Title

**Date:** YYYY-MM-DD  
**Status:** Proposed | Accepted | Deprecated | Superseded  
**Deciders:** Names  
**Technical Story:** Link/Description

## Context

What is the issue we're seeing that is motivating this decision?

## Decision

What is the change we're proposing or have agreed to implement?

## Consequences

### Positive
- Benefits of this decision

### Negative
- Drawbacks of this decision

### Neutral
- Other impacts

## Alternatives Considered

- Alternative 1: Description and why it wasn't chosen
- Alternative 2: Description and why it wasn't chosen

## References

- Links to relevant documentation
- Related ADRs
- Discussion threads
```

## Index of ADRs

| ADR | Title | Status | Date |
|-----|-------|--------|------|
| [0001](0001-overlay-consolidation.md) | Consolidate Overlay Management | Accepted | 2025-01-14 |
| [0002](0002-separate-mcp-configs.md) | Keep Separate MCP Platform Configs | Accepted | 2025-01-14 |
| [0003](0003-import-patterns.md) | Standardize Import Patterns | Accepted | 2025-01-14 |
| [0004](0004-feature-flags.md) | Feature Flag System | Accepted | 2025-01-14 |

## Creating a New ADR

1. Copy the template above
2. Number it sequentially (next available number)
3. Fill in all sections
4. Submit for review (if applicable)
5. Update this index

## ADR Lifecycle

```
Proposed → Accepted → [Deprecated] → [Superseded by ADR-XXXX]
           ↓
         Rejected
```

- **Proposed**: Under discussion
- **Accepted**: Approved and implemented
- **Deprecated**: No longer recommended but not replaced
- **Superseded**: Replaced by another ADR
- **Rejected**: Decided against

## Guidelines

### When to Create an ADR

Create an ADR for:
- Significant architectural choices
- Technology or pattern selections
- Changes to core standards
- Major refactorings
- Breaking changes

### When NOT to Create an ADR

Don't create an ADR for:
- Simple bug fixes
- Documentation updates
- Minor refactorings
- Individual module implementations

### Writing Good ADRs

- **Be concise**: 1-2 pages maximum
- **Be specific**: Clear decision, not vague
- **Include context**: Why this matters
- **List alternatives**: What else was considered
- **State consequences**: Both pros and cons
- **Date it**: When was this decided

---

**Last Updated:** 2025-01-14
