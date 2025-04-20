# Pipeline API Tests

# Test 1: Start a new pipeline job
POST http://localhost:8000/run-pipeline
Content-Type: application/json

{
    "match_id": "999",
    "device": "cpu"
}

# Validate response
HTTP 200
[Asserts]
jsonpath "$.job_id" exists
jsonpath "$.status" == "queued"
jsonpath "$.message" exists
[Captures]
job_id: jsonpath "$.job_id"

# Test 2: Check job status
GET http://localhost:8000/job-status/{{job_id}}
HTTP 200
[Asserts]
jsonpath "$.job_id" == "{{job_id}}"
jsonpath "$.match_id" == "999"
jsonpath "$.status" exists
jsonpath "$.details" exists

# Test 3: List all jobs
GET http://localhost:8000/jobs
HTTP 200
[Asserts]
header "Content-Type" == "application/json"
