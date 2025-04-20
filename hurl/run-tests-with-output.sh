#!/bin/bash
# Enhanced test runner script that saves all test outputs to files

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# Create output directories
OUTPUT_DIR="test-results"
mkdir -p $OUTPUT_DIR
mkdir -p $OUTPUT_DIR/responses
mkdir -p $OUTPUT_DIR/reports/html
mkdir -p $OUTPUT_DIR/reports/junit
mkdir -p $OUTPUT_DIR/logs

echo -e "${YELLOW}Starting API tests with Hurl...${NC}"
echo -e "${YELLOW}All test results will be saved to: $OUTPUT_DIR${NC}"

# Check if test files exist
if [ ! -f "pipeline-api-tests.hurl" ] || [ ! -f "error-tests.hurl" ]; then
  echo -e "${RED}Test files not found!${NC}"
  exit 1
fi

# Make sure the API is running
echo -e "${YELLOW}Checking if API is available...${NC}"
if ! curl -s http://localhost:8000/docs > /dev/null; then
  echo -e "${RED}API is not running at http://localhost:8000${NC}"
  echo -e "${YELLOW}Please start the API before running tests.${NC}"
  exit 1
else
  echo -e "${GREEN}API is running at http://localhost:8000${NC}"
fi

# Timestamp for filenames
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

# Run the main API tests with various output formats
echo -e "\n${YELLOW}Running main pipeline tests...${NC}"

# Run tests and save each response individually
hurl --variable timestamp=$TIMESTAMP \
     --output-dir $OUTPUT_DIR/responses \
     --variable-file response-names.vars \
     pipeline-api-tests.hurl

# Save test results as JSON
hurl --json pipeline-api-tests.hurl > $OUTPUT_DIR/logs/pipeline-results-$TIMESTAMP.json

# Generate HTML report
hurl --report-html $OUTPUT_DIR/reports/html/pipeline-$TIMESTAMP \
     pipeline-api-tests.hurl

# Generate JUnit report
hurl --report-junit $OUTPUT_DIR/reports/junit/pipeline-$TIMESTAMP.xml \
     pipeline-api-tests.hurl

# Save verbose output
hurl --very-verbose pipeline-api-tests.hurl > $OUTPUT_DIR/logs/pipeline-verbose-$TIMESTAMP.log 2>&1
MAIN_RESULT=$?

# Run error scenario tests with various output formats
echo -e "\n${YELLOW}Running error scenario tests...${NC}"

# Save each response
hurl --variable timestamp=$TIMESTAMP \
     --output-dir $OUTPUT_DIR/responses \
     --variable-file error-response-names.vars \
     error-tests.hurl

# Save test results as JSON
hurl --json error-tests.hurl > $OUTPUT_DIR/logs/error-results-$TIMESTAMP.json

# Generate HTML report
hurl --report-html $OUTPUT_DIR/reports/html/error-$TIMESTAMP \
     error-tests.hurl

# Generate JUnit report
hurl --report-junit $OUTPUT_DIR/reports/junit/error-$TIMESTAMP.xml \
     error-tests.hurl

# Save verbose output
hurl --very-verbose error-tests.hurl > $OUTPUT_DIR/logs/error-verbose-$TIMESTAMP.log 2>&1
ERROR_RESULT=$?

# Show summary
echo -e "\n${YELLOW}Test Summary:${NC}"
if [ $MAIN_RESULT -eq 0 ]; then
  echo -e "${GREEN}✓ Main pipeline tests: PASSED${NC}"
else
  echo -e "${RED}✗ Main pipeline tests: FAILED${NC}"
fi

if [ $ERROR_RESULT -eq 0 ]; then
  echo -e "${GREEN}✓ Error scenario tests: PASSED${NC}"
else
  echo -e "${RED}✗ Error scenario tests: FAILED${NC}"
fi

# Create an index HTML file for easy browsing of results
cat > $OUTPUT_DIR/index.html << EOF
<!DOCTYPE html>
<html>
<head>
    <title>Hurl Test Results - $TIMESTAMP</title>
    <style>
        body { font-family: Arial, sans-serif; max-width: 800px; margin: 0 auto; padding: 20px; }
        h1, h2 { color: #333; }
        .success { color: #0a0; }
        .failure { color: #d00; }
        ul { list-style-type: square; }
        a { color: #07b; text-decoration: none; }
        a:hover { text-decoration: underline; }
        .section { margin: 20px 0; padding: 10px; border: 1px solid #ddd; border-radius: 5px; }
    </style>
</head>
<body>
    <h1>Hurl Test Results - $(date)</h1>
    
    <div class="section">
        <h2>Test Summary</h2>
        <p class="$([ $MAIN_RESULT -eq 0 ] && echo 'success' || echo 'failure')">
            Main pipeline tests: $([ $MAIN_RESULT -eq 0 ] && echo 'PASSED' || echo 'FAILED')
        </p>
        <p class="$([ $ERROR_RESULT -eq 0 ] && echo 'success' || echo 'failure')">
            Error scenario tests: $([ $ERROR_RESULT -eq 0 ] && echo 'PASSED' || echo 'FAILED')
        </p>
    </div>
    
    <div class="section">
        <h2>HTML Reports</h2>
        <ul>
            <li><a href="reports/html/pipeline-$TIMESTAMP/index.html">Pipeline Tests Report</a></li>
            <li><a href="reports/html/error-$TIMESTAMP/index.html">Error Tests Report</a></li>
        </ul>
    </div>
    
    <div class="section">
        <h2>Log Files</h2>
        <ul>
            <li><a href="logs/pipeline-verbose-$TIMESTAMP.log">Pipeline Tests Log</a></li>
            <li><a href="logs/error-verbose-$TIMESTAMP.log">Error Tests Log</a></li>
            <li><a href="logs/pipeline-results-$TIMESTAMP.json">Pipeline Results (JSON)</a></li>
            <li><a href="logs/error-results-$TIMESTAMP.json">Error Results (JSON)</a></li>
        </ul>
    </div>
    
    <div class="section">
        <h2>JUnit Reports</h2>
        <ul>
            <li><a href="reports/junit/pipeline-$TIMESTAMP.xml">Pipeline Tests JUnit Report</a></li>
            <li><a href="reports/junit/error-$TIMESTAMP.xml">Error Tests JUnit Report</a></li>
        </ul>
    </div>
</body>
</html>
EOF

echo -e "\n${GREEN}All test results have been saved to: $OUTPUT_DIR${NC}"
echo -e "${GREEN}Open $OUTPUT_DIR/index.html in your browser to view the results${NC}"

# Final result
if [ $MAIN_RESULT -eq 0 ] && [ $ERROR_RESULT -eq 0 ]; then
  echo -e "\n${GREEN}All tests passed successfully!${NC}"
  exit 0
else
  echo -e "\n${RED}Some tests failed. Please check the reports for details.${NC}"
  exit 1
fi
