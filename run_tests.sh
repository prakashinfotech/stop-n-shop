#!/bin/bash

# Test Automation Runner for Stop-N-Shop
# Runs all unit, integration, and frontend tests
# Usage: ./run_tests.sh [backend|frontend|all] [--coverage]

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
TEST_TYPE="${1:-all}"
COVERAGE_FLAG="${2}"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
RESULTS_DIR="test-results-$TIMESTAMP"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "=================================================="
echo "       Stop-N-Shop Test Automation Runner"
echo "=================================================="
echo "Test Type: $TEST_TYPE"
echo "Results Directory: $RESULTS_DIR"
echo ""

mkdir -p "$RESULTS_DIR"

# Backend Tests
run_backend_tests() {
    echo -e "${YELLOW}[1/3] Running Backend Tests...${NC}"
    echo "========================================"

    cd "$SCRIPT_DIR/api"

    if ! command -v dotnet &> /dev/null; then
        echo -e "${RED}❌ dotnet CLI not found. Please install .NET SDK.${NC}"
        return 1
    fi

    # Run unit tests
    echo "Running Unit Tests..."
    dotnet test \
        --logger "trx;LogFileName=$SCRIPT_DIR/$RESULTS_DIR/backend-unit-tests.trx" \
        --logger "console;verbosity=normal" \
        --configuration Release \
        2>&1 | tee "$SCRIPT_DIR/$RESULTS_DIR/backend-unit.log"

    local unit_exit=$?

    if [ $unit_exit -eq 0 ]; then
        echo -e "${GREEN}✅ Backend Unit Tests Passed${NC}"
    else
        echo -e "${RED}❌ Backend Unit Tests Failed${NC}"
        return 1
    fi

    cd "$SCRIPT_DIR"
}

# Frontend Tests
run_frontend_tests() {
    echo -e "${YELLOW}[2/3] Running Frontend Tests...${NC}"
    echo "========================================"

    cd "$SCRIPT_DIR/stopnshop-ui"

    if ! command -v npm &> /dev/null; then
        echo -e "${RED}❌ npm not found. Please install Node.js.${NC}"
        return 1
    fi

    # Install dependencies if needed
    if [ ! -d "node_modules" ]; then
        echo "Installing dependencies..."
        npm install
    fi

    # Run tests
    if [ "$COVERAGE_FLAG" == "--coverage" ]; then
        echo "Running Frontend Tests with Coverage..."
        npm run test:coverage 2>&1 | tee "$SCRIPT_DIR/$RESULTS_DIR/frontend-tests.log"
    else
        echo "Running Frontend Tests..."
        npm test 2>&1 | tee "$SCRIPT_DIR/$RESULTS_DIR/frontend-tests.log"
    fi

    local frontend_exit=$?

    if [ $frontend_exit -eq 0 ]; then
        echo -e "${GREEN}✅ Frontend Tests Passed${NC}"
    else
        echo -e "${RED}❌ Frontend Tests Failed${NC}"
        return 1
    fi

    cd "$SCRIPT_DIR"
}

# Integration Tests
run_integration_tests() {
    echo -e "${YELLOW}[3/3] Running Integration Tests...${NC}"
    echo "========================================"

    # Check if API is running
    if ! curl -s http://localhost:5000/api/health > /dev/null 2>&1; then
        echo -e "${YELLOW}⚠️  API not running. Integration tests require running API.${NC}"
        echo "Start API with: cd api && dotnet run"
        return 0 # Don't fail, just skip
    fi

    cd "$SCRIPT_DIR/api"

    echo "Running Integration Tests..."
    dotnet test \
        --filter "Category=Integration" \
        --logger "trx;LogFileName=$SCRIPT_DIR/$RESULTS_DIR/backend-integration-tests.trx" \
        --logger "console;verbosity=normal" \
        --configuration Release \
        2>&1 | tee "$SCRIPT_DIR/$RESULTS_DIR/backend-integration.log"

    local integration_exit=$?

    if [ $integration_exit -eq 0 ]; then
        echo -e "${GREEN}✅ Integration Tests Passed${NC}"
    else
        echo -e "${RED}❌ Integration Tests Failed${NC}"
        return 1
    fi

    cd "$SCRIPT_DIR"
}

# Generate Report
generate_report() {
    echo ""
    echo "=================================================="
    echo "           Test Execution Summary"
    echo "=================================================="

    local report_file="$RESULTS_DIR/TEST_REPORT.md"

    cat > "$report_file" << EOF
# Test Execution Report
Generated: $(date)

## Test Statistics
- Test Type: $TEST_TYPE
- Results Directory: $RESULTS_DIR

## Backend Tests
EOF

    if [ "$TEST_TYPE" == "backend" ] || [ "$TEST_TYPE" == "all" ]; then
        if [ -f "$RESULTS_DIR/backend-unit.log" ]; then
            local unit_count=$(grep -c "PASSED\|FAILED" "$RESULTS_DIR/backend-unit.log" || echo "N/A")
            echo "- Unit Tests: $unit_count" >> "$report_file"
        fi
    fi

    cat >> "$report_file" << EOF

## Frontend Tests
- Status: Check $RESULTS_DIR/frontend-tests.log

## Integration Tests
- Status: Check $RESULTS_DIR/backend-integration.log

## Logs Location
All test logs available in: $RESULTS_DIR/

## Next Steps
1. Review logs for any failures
2. Fix failing tests
3. Re-run specific test suites as needed
4. Commit passing tests to git

---
Report generated at: $(date)
EOF

    echo "📊 Report saved to: $report_file"
}

# Main execution
main() {
    case $TEST_TYPE in
        backend)
            run_backend_tests
            ;;
        frontend)
            run_frontend_tests
            ;;
        all)
            run_backend_tests && run_frontend_tests && run_integration_tests
            ;;
        *)
            echo -e "${RED}Unknown test type: $TEST_TYPE${NC}"
            echo "Usage: ./run_tests.sh [backend|frontend|all] [--coverage]"
            exit 1
            ;;
    esac

    local exit_code=$?

    if [ $exit_code -eq 0 ]; then
        echo ""
        echo -e "${GREEN}=================================================="
        echo "✅ All Tests Passed!"
        echo "==================================================${NC}"
    else
        echo ""
        echo -e "${RED}=================================================="
        echo "❌ Some Tests Failed"
        echo "==================================================${NC}"
    fi

    generate_report

    exit $exit_code
}

main
