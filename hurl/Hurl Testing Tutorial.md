# Tutorial: Testing Your Pipeline API with Hurl

This tutorial will guide you through testing your YOLO Detection Pipeline API using Hurl, a command-line tool for running HTTP requests.

## What is Hurl?

Hurl is a lightweight command-line tool that can send HTTP requests and validate their responses. It uses a simple plain text format to define requests, expected responses, and assertions, making it perfect for API testing.

## Installation

### macOS

```bash
brew install hurl
```

### Linux

```bash
curl -LO https://github.com/Orange-OpenSource/hurl/releases/download/2.0.1/hurl_2.0.1_amd64.deb
sudo dpkg -i hurl_2.0.1_amd64.deb
```

Or use snap:

```bash
sudo snap install hurl
```

### Windows

```bash
scoop install hurl
```

Or download the Windows installer from the [official GitHub repository](https://github.com/Orange-OpenSource/hurl/releases).

## Testing Your API

### 1. Start the API Server

Before running tests, make sure your Docker container is running:

```bash
docker-compose up -d
```

### 2. Create a Test Directory

```bash
mkdir -p tests
cd tests
```

### 3. Save the Test Files

Save the provided test files (`pipeline-api-tests.hurl` and `error-tests.hurl`) to your test directory.

### 4. Run the Tests

```bash
# Run the main pipeline tests
hurl --test pipeline-api-tests.hurl

# Run the error scenario tests
hurl --test error-tests.hurl
```

You can also run multiple test files at once:

```bash
hurl --test *.hurl
```

### 5. Understanding Test Results

Hurl will display the results of each request, showing:

- HTTP status code
- Response headers and body
- Results of assertions
- Any captured variables

A successful test will show something like:

```
pipeline-api-tests.hurl: Success (3 requests in 235 ms)
```

## Test File Structure

Each Hurl test file consists of one or more entries with this format:

```
# Comment describing the test
METHOD URL
[Headers]

[Body]

# Expected response
HTTP status_code
[Asserts]
[Captures]
```

### Example Explained

Let's break down the first test in `pipeline-api-tests.hurl`:

```
# Test 1: Start a new pipeline job
POST http://localhost:8000/run-pipeline
Content-Type: application/json

{
    "match_id": "test_match_123",
    "device": "cpu"
}

HTTP 200
[Asserts]
jsonpath "$.job_id" exists
jsonpath "$.status" == "queued"
jsonpath "$.message" exists
[Captures]
job_id: jsonpath "$.job_id"
```

This test:

1. Sends a POST request to `/run-pipeline` with JSON data
2. Expects HTTP status code 200
3. Asserts that the response contains fields `job_id`, `status`, and `message`
4. Verifies that `status` equals "queued"
5. Captures the `job_id` value for use in subsequent tests

## Advanced Testing

### Using Variables

You can use variables to make your tests more flexible:

```bash
hurl --variable match_id=real_match_123 --variable device=gpu pipeline-api-tests.hurl
```

Then in your test file:

```
POST http://localhost:8000/run-pipeline
Content-Type: application/json

{
    "match_id": "{{match_id}}",
    "device": "{{device}}"
}
```

### Testing with Real Data

When testing with real data, you might want to create a separate test file that includes your actual match IDs:

```
# real-data-test.hurl
POST http://localhost:8000/run-pipeline
Content-Type: application/json

{
    "match_id": "actual_production_match_id",
    "device": "gpu"
}

HTTP 200
```

### Creating a Test Suite

For comprehensive testing, create a script that runs all your tests:

```bash
#!/bin/bash
# run-tests.sh

echo "Running basic API tests..."
hurl --test pipeline-api-tests.hurl

echo "Running error scenario tests..."
hurl --test error-tests.hurl

echo "Running tests with timeouts..."
hurl --connect-timeout 5000 --max-time 30000 --test long-running-tests.hurl
```

Make it executable with:

```bash
chmod +x run-tests.sh
```

## Continuous Integration

You can integrate these Hurl tests into your CI/CD pipeline:

### GitHub Actions Example

```yaml
name: API Tests

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Set up Docker Compose
        run: docker-compose up -d

      - name: Install Hurl
        run: |
          curl -LO https://github.com/Orange-OpenSource/hurl/releases/download/2.0.1/hurl_2.0.1_amd64.deb
          sudo dpkg -i hurl_2.0.1_amd64.deb

      - name: Run tests
        run: hurl --test tests/*.hurl --report-html test-report

      - name: Upload test results
        uses: actions/upload-artifact@v3
        with:
          name: test-report
          path: test-report
```

## Troubleshooting

### Common Issues

1. **Connection refused**: Make sure your API is running and accessible at the specified URL.

   ```
   Error: Failed to connect to localhost port 8000: Connection refused
   ```

2. **Assertion failures**: Check if your API response matches the expected format.

   ```
   Assert failure: jsonpath $.status == "completed"
   ```

3. **Timing issues**: For long-running processes, you might need to increase timeouts.
   ```bash
   hurl --connect-timeout 5000 --max-time 30000 --test your-test.hurl
   ```

## Further Resources

- [Hurl Documentation](https://hurl.dev/)
- [JSON Path Reference](https://goessner.net/articles/JsonPath/)
- [Hurl GitHub Repository](https://github.com/Orange-OpenSource/hurl)

With these Hurl tests, you can ensure your Pipeline API works correctly and catch issues early in your development process.
