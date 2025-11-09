# Signal Theme Refactoring Checklist

Quick reference checklist for tracking progress. See `SIGNAL_THEME_REFACTOR_PLAN.md` for detailed implementation instructions.

## Phase 1: Foundation (17 tasks)

### Unified Options Module

- [x] 1.1 Create base options module (`modules/shared/features/theming/options.nix`)
- [x] 1.2 Extract brand governance options
- [x] 1.3 Extract overrides option (deprecated)
- [x] 1.4 Update NixOS module to use shared options
- [x] 1.5 Update Home Manager module to use shared options
- [x] 1.6 Add option definition tests

### Mode Resolution System

- [x] 1.7 Create mode resolution module (`mode.nix`)
- [x] 1.8 Implement system preference detection
- [x] 1.9 Add mode validation functions
- [x] 1.10 Update platform modules to use mode resolution
- [x] 1.11 Add mode resolution tests

### Theme Context System

- [x] 1.12 Create theme context type (`context.nix`)
- [x] 1.13 Implement context provider
- [x] 1.14 Add context validation
- [x] 1.15 Update NixOS module to use context
- [x] 1.16 Update Home Manager module to use context
- [x] 1.17 Update all application modules
- [x] 1.18 Add backward compatibility shim

## Phase 2: Application Organization (22 tasks)

### Application Registry

- [x] 2.1 Create registry structure (`registry.nix`)
- [x] 2.2 Define registry entry type
- [x] 2.3 Register all applications
- [x] 2.4 Create registry query functions

### Standard Application Interface

- [x] 2.5 Create interface definition (`interface.nix`)
- [x] 2.6 Define interface type
- [x] 2.7 Create interface validation

### Application Reorganization

- [x] 2.8 Create `editors/` directory
- [x] 2.9 Move cursor.nix, helix.nix, zed.nix to `editors/`
- [x] 2.10 Create `terminals/` directory
- [x] 2.11 Move ghostty.nix, zellij.nix to `terminals/`
- [x] 2.12 Create `desktop/` directory
- [x] 2.13 Move desktop apps to `desktop/`
- [x] 2.14 Create `cli/` directory
- [x] 2.15 Move CLI apps to `cli/`
- [x] 2.16 Update application modules to use interface
- [x] 2.17 Update platform module imports
- [x] 2.18 Add migration guide

## Phase 3: Validation & Testing (18 tasks)

### Validation Layer

- [x] 3.1 Create validation framework (`validation.nix`)
- [x] 3.2 Implement WCAG contrast calculation
- [x] 3.3 Implement APCA contrast calculation
- [x] 3.4 Create contrast validation function
- [x] 3.5 Create theme completeness validation
- [x] 3.6 Create accessibility validation
- [x] 3.7 Integrate validation into theme generation
- [x] 3.8 Add validation options
- [x] 3.9 Create validation report generator

### Testing Infrastructure

- [x] 3.10 Create test directory structure
- [x] 3.11 Create `tests/palette.nix`
- [x] 3.12 Create `tests/semantic.nix`
- [x] 3.13 Create `tests/mode.nix`
- [x] 3.14 Create `tests/validation.nix`
- [x] 3.15 Create `tests/applications.nix`
- [x] 3.16 Create `tests/snapshots.nix`
- [x] 3.17 Add test runner integration
- [ ] 3.18 Add CI integration (optional - depends on CI setup)

## Phase 4: Advanced Features (11 tasks)

### Theme Factory Enhancements

- [ ] 4.1 Create theme factory pattern
- [ ] 4.2 Implement override composition
- [ ] 4.3 Add extension points system
- [ ] 4.4 Implement theme variant support
- [ ] 4.5 Add variant generation functions
- [ ] 4.6 Integrate validation hooks
- [ ] 4.7 Add theme caching

### Brand Governance Enhancements

- [ ] 4.8 Enhance brand governance with validation
- [ ] 4.9 Add brand color transformation utilities
- [ ] 4.10 Implement multiple brand layers
- [ ] 4.11 Add brand color accessibility validation

### Documentation Generation

- [ ] 4.12 Create documentation generator
- [ ] 4.13 Auto-generate application list
- [ ] 4.14 Auto-generate color palette documentation
- [ ] 4.15 Create architecture diagram
- [ ] 4.16 Update main documentation

## Phase 5: Cleanup & Polish (8 tasks)

- [ ] 5.1 Remove deprecated patterns
- [ ] 5.2 Remove old application locations
- [ ] 5.3 Clean up duplicate code
- [ ] 5.4 Add deprecation warnings
- [ ] 5.5 Update all documentation
- [ ] 5.6 Run full test suite
- [ ] 5.7 Update examples
- [ ] 5.8 Create user migration guide

## Progress Tracking

**Total Tasks**: 68
**Completed**: 57
**In Progress**: 0
**Remaining**: 11

### Phase Completion

- Phase 1: 17/17 (100%) ?
- Phase 2: 22/22 (100%) ?
- Phase 3: 17/18 (94%) ? (CI integration optional)
- Phase 4: 0/11 (0%)
- Phase 5: 0/8 (0%)

## Notes

- Mark tasks as complete by checking the box
- Update progress tracking after each task
- Refer to detailed plan for implementation guidance
- Test after each phase completion
