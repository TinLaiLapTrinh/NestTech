import os
import re
import pickle
import numpy as np
import pandas as pd
import seaborn as sns
import matplotlib.pyplot as plt
import torch

from sklearn.metrics import f1_score, accuracy_score, classification_report, confusion_matrix
from transformers import AutoTokenizer, AutoModelForSequenceClassification, Trainer, TrainingArguments, BertTokenizer, RobertaTokenizer
from datasets import Dataset

# ================== PATH ==================
DIR_ROOT = r"C:\Users\Administrator\Documents\DoAnNganh\NewNestTech\NestTech\TechNest"
MODEL_DIR = os.path.join(DIR_ROOT, "transformer_model")
CACHE_DIR = os.path.join(DIR_ROOT, "cache")
DATASET_PATH = os.path.join(DIR_ROOT, "dataset", "test.csv")

# ================== LABELS ==================
labels_task_1 = ["no-spam", "spam"]
labels_task_2 = ["no-spam", "spam-1", "spam-2", "spam-3"]

TASKS = [
    {
        "name": "phobert_task_1",
        "model_name": "vinai/phobert-base",
        "tokenizer": AutoTokenizer,
        "labels": labels_task_1,
        "label_col": "Label"
    },
    {
        "name": "phobert_task_2",
        "model_name": "vinai/phobert-base",
        "tokenizer": AutoTokenizer,
        "labels": labels_task_2,
        "label_col": "SpamLabel"
    },
    {
        "name": "bert4news_task_1",
        "model_name": "NlpHUST/vibert4news-base-cased",
        "tokenizer": BertTokenizer,
        "labels": labels_task_1,
        "label_col": "Label"
    },
    {
        "name": "bert4news_task_2",
        "model_name": "NlpHUST/vibert4news-base-cased",
        "tokenizer": BertTokenizer,
        "labels": labels_task_2,
        "label_col": "SpamLabel"
    }
]

# ================== Utils ==================
def get_latest_checkpoint(output_dir):
    """Lấy checkpoint mới nhất"""
    if not os.path.exists(output_dir):
        return None
    checkpoints = [os.path.join(output_dir, d) for d in os.listdir(output_dir)
                   if os.path.isdir(os.path.join(output_dir, d)) and "checkpoint" in d]
    if not checkpoints:
        return None
    checkpoints.sort(key=lambda x: int(re.findall(r"checkpoint-(\d+)", x)[0]), reverse=True)
    return checkpoints[0]

# ================== Evaluate ==================
def evaluate_model(task_name, model_name, tokenizer_class, task_labels, label_col, model_path):
    print(f"\n========== Evaluate {task_name} ==========")

    # Load tokenizer
    tokenizer = tokenizer_class.from_pretrained(model_name, use_fast=False)

    # Load model
    model = AutoModelForSequenceClassification.from_pretrained(
        model_path,
        num_labels=len(task_labels)
    )

    # Load test dataset
    df_test = pd.read_csv(DATASET_PATH)
    df_test = df_test[df_test["Comment"].notna() & (df_test["Comment"].str.strip() != "")]
    test_texts = df_test["Comment"].astype(str).tolist()
    y_test = df_test[label_col].astype(int).values

    # Encode
    encodings = tokenizer(test_texts, truncation=True, padding=True, max_length=256)
    test_dataset = Dataset.from_dict(encodings)

    args = TrainingArguments(
        output_dir="./tmp_eval",
        per_device_eval_batch_size=8,
        report_to="none"
    )
    trainer = Trainer(model=model, args=args)

    preds = trainer.predict(test_dataset)
    y_pred = np.argmax(preds.predictions, axis=-1)

    # Confusion matrix
    cf = confusion_matrix(y_test[:len(y_pred)], y_pred, labels=range(len(task_labels)))
    df_cm = pd.DataFrame(cf, index=task_labels, columns=task_labels)

    plt.figure(figsize=(6, 5))
    sns.heatmap(df_cm, annot=True, cmap="Blues", fmt='g', cbar=True, annot_kws={"size": 12})
    plt.title(f"Confusion Matrix - {task_name}")
    plt.ylabel("True")
    plt.xlabel("Predicted")
    plt.tight_layout()
    plt.show()

    # Metrics
    print("F1 - micro:", f1_score(y_test[:len(y_pred)], y_pred, average='micro'))
    print("F1 - macro:", f1_score(y_test[:len(y_pred)], y_pred, average='macro'))
    print("Accuracy:", accuracy_score(y_test[:len(y_pred)], y_pred))

    print("\nClassification Report:")
    print(classification_report(
        y_test[:len(y_pred)],
        y_pred,
        labels=range(len(task_labels)),
        target_names=task_labels,
        zero_division=0
    ))

    # Xuất file kết quả
    results_df = pd.DataFrame({
        "Comment": test_texts,
        "y_true": [task_labels[i] for i in y_test[:len(y_pred)]],
        "y_pred": [task_labels[i] for i in y_pred]
    })
    out_file = f"{task_name}_results.csv"
    results_df.to_csv(out_file, index=False, encoding="utf-8")
    print(f"✅ Saved results to {out_file}")


# ================== Run ==================
if __name__ == "__main__":
    for task in TASKS:
        model_dir = os.path.join(MODEL_DIR, task["name"])
        latest_ckpt = get_latest_checkpoint(model_dir)
        if latest_ckpt:
            print(f"[LOAD] {task['name']} from {latest_ckpt}")
            evaluate_model(
                task["name"], task["model_name"], task["tokenizer"],
                task["labels"], task["label_col"], latest_ckpt
            )
        else:
            print(f"[SKIP] No checkpoint found for {task['name']}")
