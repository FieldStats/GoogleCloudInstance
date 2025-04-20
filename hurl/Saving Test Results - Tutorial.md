# Saving Hurl Test Results: A Complete Guide

This tutorial explains how to save and export Hurl test results, including HTTP responses, test reports, and detailed logs.

## Available Output Options

Hurl provides several options for saving test results:

| Option                  | Description                                          |
| ----------------------- | ---------------------------------------------------- |
| `--output <file>`       | Save response body of last request to a file         |
| `--output-dir <dir>`    | Save response body of each request in separate files |
| `--report-html <dir>`   | Generate HTML test report in specified directory     |
| `--report-junit <file>` | Generate JUnit XML report for CI/CD integration      |
| `--json`                | Output test results in JSON format                   |
| `--verbose`             | Detailed logs of requests and responses              |
| `--very-verbose`        | Even more detailed logs (headers, cookies, etc.)     |

## Basic Examples

### 1. Save Response Body to File

```bash
# Save last response to a file
hurl --output response.json pipeline-api-tests.hurl
```

### 2. Save Each Response to Separate Files

```bash
# Create directory for responses
mkdir -p responses

# Save each response with auto-naming
hurl --output-dir responses pipeline-api-tests.hurl
```

### 3. Generate HTML Report

```bash
# Create report directory
mkdir -p html-report

# Generate HTML report
hurl --report-html html-report pipeline-api-tests.hurl
```

### 4. Generate JUnit XML Report

```bash
# Generate JUnit report for CI/CD integration
hurl --report-junit junit-report.xml pipeline-api-tests.hurl
```

### 5. Output JSON Results

```bash
# Save structured test results as JSON
hurl --json pipeline-api-tests.hurl > test-results.json
```

### 6. Save Detailed Logs

```bash
# Save verbose output with request/response details
hurl --verbose pipeline-api-tests.hurl > verbose-output.txt 2>&1
```

## Advanced Techniques

### Custom Naming of Response Files

You can use variables to create custom filenames for responses:

1. Create a variable file (e.g., `response-names.vars`):

```
test1=run-pipeline-response
test2=job-status-response
test3=list-jobs-response
```

2. Use the variable file with `--variable-file`:

```bash
hurl --output-dir responses --variable-file response-names.vars pipeline-api-tests.hurl
```

### Adding Timestamps to Filenames

```bash
# Generate timestamp variable
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

# Use timestamp in output
hurl --variable timestamp=$TIMESTAMP --output "response-$TIMESTAMP.json" pipeline-api-tests.hurl
```

### Combining Multiple Output Options

You can combine several output options in a single command:

```bash
hurl --report-html ./html-report \
     --report-junit junit-report.xml \
     --output-dir ./responses \
     --json \
     pipeline-api-tests.hurl > results.json
```

## Automated Testing Script

For a complete solution, use the provided `run-tests-with-output.sh` script:

```bash
# Make script executable
chmod +x run-tests-with-output.sh

# Run tests and save all outputs
./run-tests-with-output.sh
```

This script:

- Creates organized directories for all test artifacts
- Saves responses with custom names
- Generates HTML and JUnit reports
- Saves JSON test results
- Records detailed logs
- Creates an HTML index for browsing all results

## Viewing Test Results

After running tests with the `--report-html` option:

1. Navigate to the report directory
2. Open `index.html` in your browser
3. Browse through all test requests, responses, and assertions

The HTML report provides:

- Summary of all tests
- Request details (method, URL, headers, body)
- Response details (status, headers, body)
- Assertion results
- Timing information

## Integration with CI/CD

The JUnit XML reports generated with `--report-junit` can be used in CI/CD pipelines:

- **GitHub Actions**: Use with `actions/upload-artifact` to publish reports
- **Jenkins**: Configure to read JUnit XML reports
- **GitLab CI**: Use with the JUnit report artifact feature

## Troubleshooting Output Issues

If you encounter problems with saving outputs:

1. **Permission denied**: Ensure write permissions to output directories
2. **Invalid filenames**: Avoid special characters in variable names
3. **Missing outputs**: Check if tests actually ran (could be connection issues)
4. **Corrupt HTML reports**: Ensure tests completed successfully

## Conclusion

With these techniques, you can:

- Keep a record of all test runs
- Share test results with your team
- Integrate testing into your CI/CD workflow
- Debug API responses when tests fail

The `run-tests-with-output.sh` script provides a complete solution for capturing and organizing all test outputs in a browser-friendly format.
