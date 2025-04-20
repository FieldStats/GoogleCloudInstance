# Error Scenario Tests
# Test 1: Missing match_id (required field)
POST http://localhost:8000/run-pipeline
Content-Type: application/json
{
}
# Should return validation error
HTTP 422
[Asserts]
jsonpath "$.detail[0].loc[1]" == "match_id"
jsonpath "$.detail[0].type" == "missing"

# Test 2: Check non-existent job status
GET http://localhost:8000/job-status/non_existent_job_id
HTTP 404
[Asserts]
jsonpath "$.detail" exists

# Test 3: Invalid HTTP method
PUT http://localhost:8000/run-pipeline
Content-Type: application/json
{
    "match_id": "999"
}
# Should return method not allowed
HTTP 405

# Test 5: Invalid endpoint
GET http://localhost:8000/invalid-endpoint
HTTP 404
