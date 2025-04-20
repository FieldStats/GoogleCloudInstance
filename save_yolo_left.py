import os
import json
from ultralytics import YOLO

def save_yolo_left(device="gpu"):
    model_path = os.path.join(os.getcwd(), "model.pt")
    video_path = os.path.join(os.getcwd(), "left.mp4")
    output_json = os.path.join(os.getcwd(), "left5shifted.json")

    model = YOLO(model_path)
    device_option = 0 if device == "gpu" else "cpu"
    results = model.predict(video_path, verbose=True, stream=True, device=device_option)

    detection_data = []
    for frame_idx, result in enumerate(results):
        frame = {"frame_index": frame_idx, "objects": []}
        for box, conf, cls_id in zip(result.boxes.xyxy, result.boxes.conf, result.boxes.cls):
            bbox = box.tolist()
            cx = (bbox[0] + bbox[2]) / 2
            cy = (bbox[1] + bbox[3]) / 2
            frame["objects"].append({
                "class_id": int(cls_id),
                "confidence": float(conf),
                "bbox": list(map(float, bbox)),
                "center": [float(cx), float(cy)]
            })
        detection_data.append(frame)

    with open(output_json, 'w') as f:
        json.dump(detection_data, f, indent=4)
    print("left5shifted.json written")
