#!/bin/bash
# Simple script to run all Hurl tests for the YOLO Detection Pipeline API

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Starting API tests with Hurl...${NC}"

# Create tests directory if it doesn't exist
mkdir -p tests
cd tests

# Check if test files exist, if not copy them
if [ ! -f "pipeline-api-tests.hurl" ]; then
  echo -e "${YELLOW}Test files not found, copying from project root...${NC}"
  cp ../*.hurl ./
fi

# Make sure the API is running
echo -e "${YELLOW}Checking if API is available...${NC}"
if ! curl -s http://localhost:8000/docs > /dev/null; then
  echo -e "${RED}API is not running at http://localhost:8000${NC}"
  echo -e "${YELLOW}Starting API with Docker Compose...${NC}"
  cd ..
  docker-compose up -d
  cd tests
  
  # Wait for API to become available
  echo -e "${YELLOW}Waiting for API to start...${NC}"
  for i in {1..30}; do
    if curl -s http://localhost:8000/docs > /dev/null; then
      echo -e "${GREEN}API is now available!${NC}"
      break
    fi
    echo -n "."
    sleep 1
    if [ $i -eq 30 ]; then
      echo -e "\n${RED}API did not start in time. Please check Docker logs.${NC}"
      exit 1
    fi
  done
else
  echo -e "${GREEN}API is running at http://localhost:8000${NC}"
fi

# Run the main API tests
echo -e "\n${YELLOW}Running main pipeline tests...${NC}"
hurl --test pipeline-api-tests.hurl
MAIN_RESULT=$?

# Run error scenario tests
echo -e "\n${YELLOW}Running error scenario tests...${NC}"
hurl --test error-tests.hurl
ERROR_RESULT=$?

# Generate HTML report if requested
if [ "$1" == "--report" ]; then
  echo -e "\n${YELLOW}Generating HTML test report...${NC}"
  mkdir -p ../test-reports
  hurl --test *.hurl --report-html ../test-reports
  echo -e "${GREEN}Report generated in test-reports directory${NC}"
fi

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

# Final result
if [ $MAIN_RESULT -eq 0 ] && [ $ERROR_RESULT -eq 0 ]; then
  echo -e "\n${GREEN}All tests passed successfully!${NC}"
  exit 0
else
  echo -e "\n${RED}Some tests failed. Please check the output above.${NC}"
  exit 1
fi
