import os
import argparse
from backblaze_sdk import download_file, upload_json
from save_yolo_left import save_yolo_left
from save_yolo_right import save_yolo_right
import ENTRY_YOLO_merge as merge_module

def safe_download(match_id, fname):
    """Download a file from Backblaze if it doesn't exist locally"""
    # Create data directory if it doesn't exist
    os.makedirs("data", exist_ok=True)
    file_path = os.path.join("data", fname)
    
    if os.path.exists(file_path):
        print(f"📂 Found local file: {file_path}, skipping download.")
        return {"status": "local"}
    
    print(f"📥 Attempting to download {fname} from Backblaze...")
    result = download_file(match_id, fname, file_path)
    if "error" in result:
        print(f"❌ Failed to download {fname}: {result['error']}")
    return result

def run_pipeline(match_id: str, device: str = "gpu"):
    """Run the YOLO detection pipeline with the given match ID and device"""
    # Store original working directory
    original_dir = os.getcwd()
    data_dir = os.path.join(original_dir, "data")
    os.makedirs(data_dir, exist_ok=True)
    
    try:
        # Change to data directory for processing
        os.chdir(data_dir)
        
        print("📥 Ensuring video files are available...")
        result_left = safe_download(match_id, "left.mp4")
        if "error" in result_left:
            print("❌ Pipeline aborted: left.mp4 not available.")
            return {"status": "error", "message": "left.mp4 not available"}
            
        result_right = safe_download(match_id, "right.mp4")
        if "error" in result_right:
            print("❌ Pipeline aborted: right.mp4 not available.")
            return {"status": "error", "message": "right.mp4 not available"}
        
        print("🔍 Running YOLO detections...")
        save_yolo_left(device=device)
        save_yolo_right(device=device)
        
        print("🔁 Running homography transformation + merge...")
        merge_module.main()  # ENTRY_YOLO_merge.main() handles everything else
        
        print("📤 Uploading final JSONs to Backblaze...")
        upload_results = {}
        
        for fname in [
            "right_intersections.json",
            "right_non_intersections.json",
            "left_intersections.json",
            "left_non_intersections.json"
        ]:
            result = upload_json(match_id, fname, fname)
            upload_results[fname] = result
            
            if "error" in result:
                print(f"⚠️ Upload failed for {fname}: {result['error']}")
            else:
                print(f"✅ Uploaded {fname}")
        
        print("✅ Pipeline complete.")
        return {
            "status": "success",
            "match_id": match_id,
            "upload_results": upload_results
        }
    
    finally:
        # Always return to the original directory
        os.chdir(original_dir)

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--match-id", required=True)
    parser.add_argument("--device", choices=["cpu", "gpu"], default="gpu")
    args = parser.parse_args()
    
    run_pipeline(args.match_id, args.device)
