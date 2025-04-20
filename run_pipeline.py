import os
import argparse
from backblaze_sdk import download_file, upload_json
from save_yolo_left import save_yolo_left
from save_yolo_right import save_yolo_right
import ENTRY_YOLO_merge as merge_module


def safe_download(match_id, fname):
    if os.path.exists(fname):
        print(f"📂 Found local file: {fname}, skipping download.")
        return {"status": "local"}
    print(f"📥 Attempting to download {fname} from Backblaze...")
    result = download_file(match_id, fname, fname)
    if "error" in result:
        print(f"❌ Failed to download {fname}: {result['error']}")
    return result


def run_pipeline(match_id: str, device: str = "gpu"):
    print("📥 Ensuring video files are available...")

    result_left = safe_download(match_id, "left.mp4")
    if "error" in result_left:
        print("❌ Pipeline aborted: left.mp4 not available.")
        return

    result_right = safe_download(match_id, "right.mp4")
    if "error" in result_right:
        print("❌ Pipeline aborted: right.mp4 not available.")
        return

    print("🔍 Running YOLO detections...")
    save_yolo_left(device=device)
    save_yolo_right(device=device)

    print("🔁 Running homography transformation + merge...")
    merge_module.main()  # ENTRY_YOLO_merge.main() handles everything else

    print("📤 Uploading final JSONs to Backblaze...")
    for fname in [
        "right_intersections.json",
        "right_non_intersections.json",
        "left_intersections.json",
        "left_non_intersections.json"
    ]:
        result = upload_json(match_id, fname, fname)
        if "error" in result:
            print(f"⚠️ Upload failed for {fname}: {result['error']}")
        else:
            print(f"✅ Uploaded {fname}")

    print("✅ Pipeline complete.")


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--match-id", required=True)
    parser.add_argument("--device", choices=["cpu", "gpu"], default="gpu")
    args = parser.parse_args()
    run_pipeline(args.match_id, args.device)
