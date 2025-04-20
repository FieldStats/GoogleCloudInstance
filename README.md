# YOLO Detection Pipeline API

This project provides a FastAPI wrapper around the YOLO detection pipeline with Docker support.

## Setup

1. Clone this repository
2. Copy `.env.template` to `.env` and fill in your Backblaze credentials
3. Make sure Docker and Docker Compose are installed

## Building and Running

```bash
# Build and start the API service
docker-compose up --build

# Or run in detached mode
docker-compose up --build -d
```

The API will be available at http://localhost:8000

## API Endpoints

### Run Pipeline

- **URL**: `/run-pipeline`
- **Method**: `POST`
- **Body**:

```json
{
  "match_id": "your_match_id",
  "device": "gpu" // or "cpu"
}
```

- **Response**: Job ID and status information

### Check Job Status

- **URL**: `/job-status/{job_id}`
- **Method**: `GET`
- **Response**: Detailed job status

### List All Jobs

- **URL**: `/jobs`
- **Method**: `GET`
- **Response**: List of all jobs and their statuses

## GPU Support

The Docker setup includes NVIDIA GPU support. Make sure you have:

1. NVIDIA drivers installed on your host
2. NVIDIA Container Toolkit installed (docker-nvidia2)

If you don't need GPU support, you can:

1. Remove the GPU-related section from docker-compose.yml
2. Set "device": "cpu" when submitting jobs

## File Storage

The processed videos and results are stored in the `./data` directory, which is mounted as a volume in the container.
