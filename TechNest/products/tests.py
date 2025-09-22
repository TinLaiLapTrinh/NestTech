import os
from transformers import AutoConfig

# ================== PATH ==================
DIR_ROOT = r"C:\Users\Administrator\Documents\DoAnNganh\NewNestTech\NestTech\TechNest"
MODEL_DIR = os.path.join(DIR_ROOT, "transformer_model")

def check_checkpoints(model_dir):
    if not os.path.exists(model_dir):
        print("[SKIP] Không tồn tại thư mục model:", model_dir)
        return
    for task_name in os.listdir(model_dir):
        task_path = os.path.join(model_dir, task_name)
        if not os.path.isdir(task_path):
            continue

        # Lấy các checkpoint trong folder task
        ckpts = [os.path.join(task_path, d) for d in os.listdir(task_path)
                 if os.path.isdir(os.path.join(task_path, d)) and "checkpoint" in d]
        if not ckpts:
            print(f"[{task_name}] ❌ Không có checkpoint")
            continue

        ckpts.sort()
        latest = ckpts[-1]

        try:
            cfg = AutoConfig.from_pretrained(latest)
            print(f"[{task_name}] ✅ num_labels = {cfg.num_labels} (checkpoint: {os.path.basename(latest)})")
        except Exception as e:
            print(f"[{task_name}] ⚠️ Lỗi load config: {e}")

if __name__ == "__main__":
    check_checkpoints(MODEL_DIR)
