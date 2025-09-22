import os
import re
import torch
from transformers import AutoTokenizer, AutoModelForSequenceClassification, BertTokenizer
from .configs import MODEL_DIR, labels_task_1, labels_task_2
from .preprocess import preprocess

# ================== HELPER ==================
def get_latest_checkpoint(output_dir):
    if not os.path.exists(output_dir):
        return None
    checkpoints = [os.path.join(output_dir, d) for d in os.listdir(output_dir)
                   if os.path.isdir(os.path.join(output_dir, d)) and "checkpoint" in d]
    if not checkpoints:
        return None
    checkpoints.sort(key=lambda x: int(re.findall(r"checkpoint-(\d+)", x)[0]), reverse=True)
    return checkpoints[0]

# ================== PREDICT ==================
def predict_comments(comments, model_name, tokenizer_class, num_labels, labels, model_dir_name):
    output_dir = os.path.join(MODEL_DIR, model_dir_name)
    latest_ckpt = get_latest_checkpoint(output_dir)

    if latest_ckpt:
        model = AutoModelForSequenceClassification.from_pretrained(latest_ckpt, num_labels=num_labels)
    else:
        model = AutoModelForSequenceClassification.from_pretrained(output_dir, num_labels=num_labels)
    
    tokenizer = tokenizer_class.from_pretrained(model_name, use_fast=False)
    
    # Tiền xử lý comment
    comments_processed = [preprocess(c) for c in comments]
    
    encodings = tokenizer(comments_processed, truncation=True, padding=True, max_length=100, return_tensors='pt')
    
    model.eval()
    with torch.no_grad():
        outputs = model(**encodings)
        preds = torch.argmax(outputs.logits, dim=-1).cpu().numpy()
    
    return [labels[i] for i in preds]

# ================== HÀM CHECK SPAM ==================
def check_spam(comments):
    """Trả về dict {comment: nhãn}"""
    results = {}
    
    preds_task1 = predict_comments(
        comments,
        model_name="vinai/phobert-base",
        tokenizer_class=AutoTokenizer,
        num_labels=2,
        labels=labels_task_1,
        model_dir_name="phobert_task_1"
    )

    preds_task2 = predict_comments(
        comments,
        model_name="vinai/phobert-base",
        tokenizer_class=AutoTokenizer,
        num_labels=4,
        labels=labels_task_2,
        model_dir_name="phobert_task_2"
    )

    for i, c in enumerate(comments):
        results[c] = {
            "task1": preds_task1[i],
            "task2": preds_task2[i]
        }

    return results
