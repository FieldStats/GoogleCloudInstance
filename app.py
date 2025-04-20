import os
import asyncio
from typing import Optional, Dict, Any
from fastapi import FastAPI, BackgroundTasks, HTTPException
from pydantic import BaseModel
from run_pipeline import run_pipeline

app = FastAPI(title="YOLO Detection Pipeline API")

# Store job status
jobs = {}

class PipelineRequest(BaseModel):
    match_id: str

class PipelineResponse(BaseModel):
    job_id: str
    status: str
    message: str

class JobStatusResponse(BaseModel):
    job_id: str
    match_id: str
    status: str
    details: Optional[Dict[str, Any]] = None

@app.post("/run-pipeline", response_model=PipelineResponse)
async def start_pipeline(request: PipelineRequest, background_tasks: BackgroundTasks):
    """Start a new pipeline job for processing video files."""
    
    # Create a unique job ID based on match ID and timestamp
    import time
    job_id = f"{request.match_id}_{int(time.time())}"
    
    # Initialize job status
    jobs[job_id] = {
        "match_id": request.match_id,
        "status": "queued",
        "details": {
            "device": "gpu",  # Using default device
            "start_time": time.time(),
            "steps_completed": []
        }
    }
    
    # Add the job to background tasks
    background_tasks.add_task(
        run_pipeline_job,
        job_id, 
        request.match_id, 
        "gpu"  # Using default device
    )
    
    return PipelineResponse(
        job_id=job_id,
        status="queued",
        message=f"Pipeline job queued for match_id: {request.match_id}"
    )

@app.get("/job-status/{job_id}", response_model=JobStatusResponse)
async def get_job_status(job_id: str):
    """Get the status of a specific job."""
    if job_id not in jobs:
        raise HTTPException(status_code=404, detail=f"Job ID {job_id} not found")
    
    job_info = jobs[job_id]
    return JobStatusResponse(
        job_id=job_id,
        match_id=job_info["match_id"],
        status=job_info["status"],
        details=job_info["details"]
    )

@app.get("/jobs", response_model=Dict[str, JobStatusResponse])
async def list_jobs():
    """List all jobs and their statuses."""
    return {
        job_id: JobStatusResponse(
            job_id=job_id,
            match_id=info["match_id"],
            status=info["status"],
            details=info["details"]
        ) for job_id, info in jobs.items()
    }

async def run_pipeline_job(job_id: str, match_id: str, device: str):
    """Run the pipeline in the background and update job status."""
    try:
        # Update status to running
        jobs[job_id]["status"] = "running"
        
        # Create a class to capture the steps
        class StepTracker:
            def __init__(self, job_id):
                self.job_id = job_id
            
            def update_step(self, step_name, status="completed"):
                jobs[self.job_id]["details"]["steps_completed"].append({
                    "step": step_name,
                    "status": status,
                    "time": time.time()
                })
                
        # We need to monkeypatch the print function to track progress
        import builtins
        original_print = builtins.print
        
        def custom_print(*args, **kwargs):
            message = " ".join(str(arg) for arg in args)
            original_print(message, **kwargs)
            
            # Update job details based on message
            if "Running YOLO detections" in message:
                jobs[job_id]["details"]["steps_completed"].append({
                    "step": "start_yolo_detection",
                    "time": time.time()
                })
            elif "Running homography transformation" in message:
                jobs[job_id]["details"]["steps_completed"].append({
                    "step": "start_homography",
                    "time": time.time()
                })
            elif "Uploading final JSONs" in message:
                jobs[job_id]["details"]["steps_completed"].append({
                    "step": "start_upload",
                    "time": time.time()
                })
            elif "Pipeline complete" in message:
                jobs[job_id]["details"]["steps_completed"].append({
                    "step": "complete",
                    "time": time.time()
                })
        
        # Override print for this function execution
        builtins.print = custom_print
        
        # Import time here to avoid circular import
        import time
        
        # Execute the pipeline
        run_pipeline(match_id, device)
        
        # Restore original print function
        builtins.print = original_print
        
        # Update job status to completed
        jobs[job_id]["status"] = "completed"
        jobs[job_id]["details"]["end_time"] = time.time()
        
    except Exception as e:
        # Restore original print function
        import builtins
        builtins.print = original_print
        
        # Update job status to failed
        jobs[job_id]["status"] = "failed"
        jobs[job_id]["details"]["error"] = str(e)
        jobs[job_id]["details"]["end_time"] = time.time()

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
