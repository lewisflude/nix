#!/usr/bin/env bash
# Generate a test report in Markdown format

set -euo pipefail

OUTPUT_FILE="${1:-TEST_REPORT.md}"
SYSTEM="${2:-x86_64-linux}"

echo "Generating test report for system: $SYSTEM"
echo "Output file: $OUTPUT_FILE"

cat > "$OUTPUT_FILE" << 'EOF'
# Signal-Nix Test Report

**Generated**: $(date +"%Y-%m-%d %H:%M:%S")  
**System**: SYSTEM_PLACEHOLDER

## Executive Summary

This report provides a comprehensive overview of the Signal-Nix test suite execution.

EOF

# Replace placeholder
sed -i "s/SYSTEM_PLACEHOLDER/$SYSTEM/g" "$OUTPUT_FILE"

# Function to test a category
test_category() {
    local category=$1
    local tests=()
    
    case $category in
        happy)
            tests=(happy-basic-dark-mode happy-basic-light-mode happy-auto-mode-defaults-dark happy-color-structure happy-syntax-colors-complete happy-brand-governance-functional-override)
            ;;
        edge)
            tests=(edge-empty-brand-colors edge-lightness-boundaries edge-chroma-boundaries edge-contrast-extreme-values edge-all-modules-disabled edge-ironbar-profiles)
            ;;
        error)
            tests=(error-invalid-theme-mode error-brand-governance-invalid-policy error-color-manipulation-throws)
            ;;
        integration)
            tests=(integration-module-lib-interaction integration-colors-and-syntax integration-brand-with-colors integration-theme-resolution-consistency integration-auto-enable-logic)
            ;;
        performance)
            tests=(performance-color-lookups performance-theme-resolution-cached performance-large-brand-colors performance-module-evaluation)
            ;;
        security)
            tests=(security-color-hex-validation security-no-code-injection security-mode-enum-validation security-brand-policy-enum-validation security-no-path-traversal)
            ;;
        unit)
            tests=(unit-lib-resolveThemeMode unit-lib-isValidResolvedMode unit-lib-getThemeName unit-lib-getColors unit-lib-getSyntaxColors)
            ;;
        module)
            tests=(module-common-evaluates module-helix-dark module-ghostty-evaluates module-bat-evaluates module-fzf-evaluates module-gtk-evaluates)
            ;;
        validation)
            tests=(validation-theme-names validation-no-auto-theme-names accessibility-contrast-estimation)
            ;;
        documentation)
            tests=(documentation-examples-valid-nix documentation-readme-references)
            ;;
    esac
    
    local passed=0
    local failed=0
    local category_title=$(echo "$category" | sed 's/.*/\u&/')
    
    echo "" >> "$OUTPUT_FILE"
    echo "### $category_title Tests" >> "$OUTPUT_FILE"
    echo "" >> "$OUTPUT_FILE"
    echo "| Test | Status |" >> "$OUTPUT_FILE"
    echo "|------|--------|" >> "$OUTPUT_FILE"
    
    for test in "${tests[@]}"; do
        if nix build ".#checks.$SYSTEM.$test" --no-link 2>/dev/null; then
            echo "| $test | ✅ Pass |" >> "$OUTPUT_FILE"
            ((passed++))
        else
            echo "| $test | ❌ Fail |" >> "$OUTPUT_FILE"
            ((failed++))
        fi
    done
    
    echo "" >> "$OUTPUT_FILE"
    echo "**Summary**: $passed passed, $failed failed" >> "$OUTPUT_FILE"
    
    return $failed
}

# Add overview section
cat >> "$OUTPUT_FILE" << 'EOF'

## Test Results by Category

EOF

# Track overall stats
total_passed=0
total_failed=0

# Test each category
categories=(happy edge error integration performance security unit module validation documentation)

for category in "${categories[@]}"; do
    echo "Testing category: $category..."
    if test_category "$category"; then
        echo "  ✓ $category tests passed"
    else
        echo "  ✗ Some $category tests failed"
    fi
done

# Add summary
cat >> "$OUTPUT_FILE" << 'EOF'

## Overall Summary

EOF

# Count actual results
total_tests=$(grep -c "| ✅ Pass |\\|| ❌ Fail |" "$OUTPUT_FILE" || echo 0)
passed_tests=$(grep -c "| ✅ Pass |" "$OUTPUT_FILE" || echo 0)
failed_tests=$(grep -c "| ❌ Fail |" "$OUTPUT_FILE" || echo 0)

cat >> "$OUTPUT_FILE" << EOF

- **Total Tests**: $total_tests
- **Passed**: $passed_tests ($(awk "BEGIN {printf \"%.1f\", ($passed_tests/$total_tests)*100}")%)
- **Failed**: $failed_tests ($(awk "BEGIN {printf \"%.1f\", ($failed_tests/$total_tests)*100}")%)

EOF

if [ "$failed_tests" -eq 0 ]; then
    cat >> "$OUTPUT_FILE" << 'EOF'

## Status: ✅ ALL TESTS PASSED

All test categories completed successfully. The Signal-Nix codebase is stable and ready for use.

EOF
else
    cat >> "$OUTPUT_FILE" << 'EOF'

## Status: ❌ SOME TESTS FAILED

Some tests failed. Please review the failures above and address the issues before releasing.

EOF
fi

# Add test categories legend
cat >> "$OUTPUT_FILE" << 'EOF'

## Test Categories

### Happy Path Tests
Test normal, expected usage patterns. These verify that the most common use cases work correctly.

### Edge Case Tests
Test boundary conditions and unusual but valid inputs. These ensure the system handles edge cases gracefully.

### Error Handling Tests
Test that invalid inputs are properly rejected with clear error messages.

### Integration Tests
Test interactions between different components to ensure they work together correctly.

### Performance Tests
Test speed and resource usage to ensure acceptable performance.

### Security Tests
Test input validation and security to prevent vulnerabilities.

### Unit Tests
Test individual library functions in isolation.

### Module Tests
Test individual module structure and evaluation.

### Validation Tests
Test consistency and correctness across the codebase.

### Documentation Tests
Test that documentation and examples are accurate and up-to-date.

---

**Report generated by**: `generate-test-report.sh`  
**For more information**: See [TESTING_GUIDE.md](./TESTING_GUIDE.md)
EOF

echo ""
echo "Test report generated: $OUTPUT_FILE"

if [ "$failed_tests" -eq 0 ]; then
    echo "✅ All tests passed!"
    exit 0
else
    echo "❌ $failed_tests test(s) failed"
    exit 1
fi
