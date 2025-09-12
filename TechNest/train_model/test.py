import os
import re
import pickle
import torch
from vncorenlp import VnCoreNLP
from transformers import AutoTokenizer, AutoModelForSequenceClassification, BertTokenizer
import numpy as np

# ================== PATH ==================
DIR_ROOT = r"C:\Users\Administrator\Documents\DoAnNganh\NewNestTech\NestTech\TechNest"

MODEL_DIR = os.path.join(DIR_ROOT, "transformer_model")
VNCORP_JAR = os.path.join(DIR_ROOT, "vncorenlp", "VnCoreNLP-1.1.1.jar")
STOPWORDS_PATH = os.path.join(DIR_ROOT, "vietnamese-stopwords-dash.txt")

# ================== VnCoreNLP ==================
vncorenlp = VnCoreNLP(VNCORP_JAR, annotators="wseg", max_heap_size='-Xmx500m', port=2930)

# ================== STOPWORDS ==================
with open(STOPWORDS_PATH, "r", encoding="utf-8") as f:
    stopwords = set(line.strip() for line in f)

# ================== LABELS ==================
labels_task_1 = ["no-spam", "spam"]
labels_task_2 = ["no-spam", "spam-1", "spam-2", "spam-3"]

# ================== PREPROCESS ==================
def filter_stop_words(text, stop_words):
    return ' '.join([w for w in text.split() if w not in stop_words])

def deEmojify(text):
    pattern = re.compile("[" 
                         u"\U0001F600-\U0001F64F"
                         u"\U0001F300-\U0001F5FF"
                         u"\U0001F680-\U0001F6FF"
                         u"\U0001F1E0-\U0001F1FF"
                         "]+", flags=re.UNICODE)
    return pattern.sub(r'', text)

def preprocess(text, tokenized=True, lowercased=True):
    text = filter_stop_words(text, stopwords)
    text = deEmojify(text)
    text = text.lower() if lowercased else text
    if tokenized:
        pre_text = ""
        for sentence in vncorenlp.tokenize(text):
            pre_text += " ".join(sentence) + " "
        text = pre_text.strip()
    return text

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

# ================== PREDICT FUNCTION ==================
def predict_comments(comments, model_name, tokenizer_class, num_labels, labels, model_dir_name):
    output_dir = os.path.join(MODEL_DIR, model_dir_name)
    latest_ckpt = get_latest_checkpoint(output_dir)
    if latest_ckpt:
        print(f"Load model từ checkpoint: {latest_ckpt}")
        model = AutoModelForSequenceClassification.from_pretrained(latest_ckpt, num_labels=num_labels)
    else:
        print(f"Load model từ thư mục: {output_dir}")
        model = AutoModelForSequenceClassification.from_pretrained(output_dir, num_labels=num_labels)
    
    tokenizer = tokenizer_class.from_pretrained(model_name, use_fast=False)
    
    # Tiền xử lý comment
    comments_processed = [preprocess(c) for c in comments]
    
    encodings = tokenizer(comments_processed, truncation=True, padding=True, max_length=100, return_tensors='pt')
    
    model.eval()
    with torch.no_grad():
        outputs = model(**encodings)
        preds = torch.argmax(outputs.logits, dim=-1).cpu().numpy()
    
    # Chuyển thành nhãn
    pred_labels = [labels[i] for i in preds]
    return pred_labels

# ================== EXAMPLE ==================
if __name__ == "__main__":
    # Comment mẫu để dự đoán
    new_comments = [
        "Bút xinhhh cực Màu ok, đúng ý mình Cho shop 5 saoooooooooooooooooooooooooooooooooooooooo😍😍😍",
        "giao hàng nhanh, uy tín lắm luôn. shop phục vụ tận tình ❤❤❤ sẽ ủng hộ shoppppppp",
        "Giá cả phải chăng, tiết kiệm, tiki giao hàng đúng hẹn, chưa giặt nên chưa biết chất lượng nhưng rất ưng",
        "tệ",
        "Giao hàng nhanh, đóng gói cẩn thận",
        "Shop đóng gói đẹp, giao hàng sớm, mình mới nhận đc hàng nên cũng ko biết chất lượng thế nào, vote cho shop 5 sao trước đã",
        "[QC] Lo lắng khi hết data? MobiFone tặng bạn 1GB data TỐC ĐỘ CAO và 30 phút gọi nội mạng MIỄN PHÍ mỗi ngày qua tổng đài 1079. Soạn KMB gửi 1079 đăng ký dv MobiRadio. Miễn phí ngày đầu, duy trì dv 48h tiếp theo để nhận Data. Sau KM: 3.000đ/ngày. LH 9090. Từ chối QC, soạn TC VOICE gửi 9241.",
        "Sản phẩm quá tuyệt vời! Mua ngay kẻo hết nhé!!! 😍😍😍 Link đặt hàng: http://"
    ]

    # Ví dụ dự đoán Task 1 PhoBERT
    preds_task1_phobert = predict_comments(
        new_comments,
        model_name="vinai/phobert-base",
        tokenizer_class=AutoTokenizer,
        num_labels=2,
        labels=labels_task_1,
        model_dir_name="phobert_task_1"
    )
    print("Task 1 PhoBERT:", preds_task1_phobert)

    # Ví dụ dự đoán Task 2 BERT4News
    preds_task2_bert4news = predict_comments(
        new_comments,
        model_name="NlpHUST/vibert4news-base-cased",
        tokenizer_class=BertTokenizer,
        num_labels=4,
        labels=labels_task_2,
        model_dir_name="bert4news_task_2"
    )
    print("Task 2 BERT4News:", preds_task2_bert4news)

# ================== CLOSE VnCoreNLP ==================
vncorenlp.close()
