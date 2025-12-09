#!/usr/bin/env bash
# Test YubiKey authentication configuration
# Safe pre-flight checks before testing login

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_header() {
    echo -e "\n${BLUE}=== $1 ===${NC}\n"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

# Track test results
TESTS_PASSED=0
TESTS_FAILED=0
TESTS_WARNING=0

test_pass() {
    print_success "$1"
    ((TESTS_PASSED++))
}

test_fail() {
    print_error "$1"
    ((TESTS_FAILED++))
}

test_warn() {
    print_warning "$1"
    ((TESTS_WARNING++))
}

print_header "YubiKey Authentication Pre-Flight Checks"

# Test 1: Check YubiKey is connected
print_info "Checking for YubiKey device..."
if lsusb | grep -qi yubico; then
    YUBIKEY_INFO=$(lsusb | grep -i yubico)
    test_pass "YubiKey detected: $YUBIKEY_INFO"
else
    test_fail "YubiKey not detected - please insert YubiKey"
fi

# Test 2: Check pcscd service
print_info "Checking pcscd service status..."
if systemctl is-active --quiet pcscd; then
    test_pass "pcscd service is running"
else
    test_fail "pcscd service is not running"
    print_info "Try: sudo systemctl start pcscd"
fi

# Test 3: Check u2f_mappings file
print_info "Checking u2f_mappings file..."
if [ -f /etc/u2f_mappings ]; then
    PERMS=$(stat -c "%a" /etc/u2f_mappings)
    if [ "$PERMS" = "644" ]; then
        test_pass "u2f_mappings exists with correct permissions (644)"
    else
        test_warn "u2f_mappings exists but has permissions: $PERMS (expected: 644)"
    fi

    # Check if current user is in the file
    if grep -q "^$USER:" /etc/u2f_mappings; then
        test_pass "Current user ($USER) found in u2f_mappings"
    else
        test_fail "Current user ($USER) NOT found in u2f_mappings"
        print_info "Run: pamu2fcfg -u $USER -o pam://yubi -i pam://yubi"
    fi
else
    test_fail "u2f_mappings file not found at /etc/u2f_mappings"
fi

# Test 4: Check greetd PAM configuration
print_info "Checking greetd PAM configuration..."
if [ -f /etc/pam.d/greetd ]; then
    test_pass "greetd PAM config exists"

    # Check for correct configuration
    if grep -q "auth sufficient.*pam_u2f.so" /etc/pam.d/greetd; then
        test_pass "greetd has 'auth sufficient' for pam_u2f (allows password fallback)"
    elif grep -q "auth required.*pam_u2f.so" /etc/pam.d/greetd; then
        test_warn "greetd has 'auth required' for pam_u2f (no fallback - this may be intentional for 2FA)"
    else
        test_fail "greetd PAM config doesn't contain pam_u2f.so"
    fi

    # Check for password fallback
    if grep -q "auth required.*pam_unix.so" /etc/pam.d/greetd; then
        test_pass "greetd has password fallback (pam_unix.so)"
    else
        test_fail "greetd missing password fallback"
    fi

    # Check for keyring integration
    if grep -q "pam_gnome_keyring.so" /etc/pam.d/greetd; then
        test_pass "greetd has GNOME Keyring integration"
    else
        test_warn "greetd doesn't have GNOME Keyring integration"
    fi
else
    test_fail "greetd PAM config not found"
fi

# Test 5: Check global u2f settings
print_info "Checking global PAM u2f settings..."
if [ -f /etc/pam.d/sudo ]; then
    if grep -q "pam_u2f.so" /etc/pam.d/sudo; then
        test_pass "sudo has u2f authentication enabled"
    else
        test_warn "sudo doesn't have u2f authentication"
    fi
fi

# Test 6: Test YubiKey with pamu2fcfg
print_info "Testing YubiKey registration format..."
if command -v pamu2fcfg &> /dev/null; then
    test_pass "pamu2fcfg command available"
    print_info "You can test YubiKey detection with:"
    print_info "  pamu2fcfg -u $USER -o pam://yubi -i pam://yubi"
else
    test_warn "pamu2fcfg not found - install pam-u2f package"
fi

# Test 7: Check YubiKey manager
print_info "Checking YubiKey management tools..."
if command -v ykman &> /dev/null; then
    test_pass "ykman (YubiKey Manager) available"
    if ykman info &> /dev/null; then
        test_pass "ykman can communicate with YubiKey"
        print_info "YubiKey info:"
        ykman info | head -5
    else
        test_warn "ykman installed but can't communicate with YubiKey"
    fi
else
    test_warn "ykman not installed - consider installing yubikey-manager"
fi

# Print summary
print_header "Test Summary"
echo -e "Passed:   ${GREEN}$TESTS_PASSED${NC}"
echo -e "Failed:   ${RED}$TESTS_FAILED${NC}"
echo -e "Warnings: ${YELLOW}$TESTS_WARNING${NC}"
echo ""

# Final assessment
if [ $TESTS_FAILED -eq 0 ]; then
    print_success "All critical checks passed!"
    echo ""
    print_info "Next steps:"
    echo "  1. Test sudo: sudo -k && sudo ls"
    echo "  2. Test TTY: Ctrl+Alt+F2, login, then Ctrl+Alt+F1 to return"
    echo "  3. Test greeter: Log out and test login"
    echo ""
    print_info "See docs/TESTING_YUBIKEY_AUTH.md for detailed testing procedures"
else
    print_error "Some critical checks failed - review errors above"
    echo ""
    print_info "Fix issues before testing login to avoid lockout"
    echo ""
    exit 1
fi

# Offer to test sudo
echo ""
read -p "Test sudo with YubiKey now? (y/N) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    print_info "Testing sudo with YubiKey..."
    print_info "You should see 'Please touch the device' message"
    print_info "(Touch YubiKey to proceed, or wait for password prompt)"
    echo ""

    # Clear sudo cache and test
    sudo -k
    if sudo -v; then
        print_success "sudo authentication successful!"
    else
        print_error "sudo authentication failed"
    fi
fi

print_header "PAM Configuration Details"
echo "greetd PAM config (/etc/pam.d/greetd):"
echo "----------------------------------------"
if [ -f /etc/pam.d/greetd ]; then
    grep -E "(auth|session).*pam_(u2f|unix|gnome_keyring)" /etc/pam.d/greetd | sed 's/^/  /'
else
    echo "  File not found"
fi
