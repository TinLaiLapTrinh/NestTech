import os
import re
import pickle
import shutil
import torch
import pandas as pd
import numpy as np
import seaborn as sns
import matplotlib.pyplot as plt
from vncorenlp import VnCoreNLP
from sklearn.metrics import f1_score, confusion_matrix, accuracy_score
from transformers import AutoTokenizer, AutoModelForSequenceClassification, Trainer, TrainingArguments, BertTokenizer

# ================== PATH ==================
DIR_ROOT = r"C:\Users\Administrator\Documents\DoAnNganh\NewNestTech\NestTech\TechNest"
DIR_DATASET = os.path.join(DIR_ROOT, "dataset")
MODEL_DIR = os.path.join(DIR_ROOT, "transformer_model")
CACHE_DIR = os.path.join(DIR_ROOT, "cache")
os.makedirs(MODEL_DIR, exist_ok=True)
os.makedirs(CACHE_DIR, exist_ok=True)

PATH_TRAIN = os.path.join(DIR_DATASET, "train.csv")
PATH_DEV   = os.path.join(DIR_DATASET, "dev.csv")
PATH_TEST  = os.path.join(DIR_DATASET, "test.csv")
STOPWORDS_PATH = os.path.join(DIR_ROOT, "vietnamese-stopwords-dash.txt")
VNCORP_JAR = os.path.join(DIR_ROOT, "vncorenlp", "VnCoreNLP-1.1.1.jar")

# ================== LABEL ==================
label_map_task1 = {"no-spam":0, "spam":1}
label_map_task2 = {"no-spam":0, "spam-1":1, "spam-2":2, "spam-3":3}
labels_task_1 = ["no-spam", "spam"]
labels_task_2 = ["no-spam", "spam-1", "spam-2", "spam-3"]

# ================== VnCoreNLP ==================
vncorenlp = VnCoreNLP(VNCORP_JAR, annotators="wseg", max_heap_size='-Xmx500m', port=2960)

# ================== STOPWORDS ==================
with open(STOPWORDS_PATH, "r", encoding="utf-8") as f:
    stopwords = set(line.strip() for line in f)

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

def preprocess_dataset(X, cache_file):
    """ Preprocess dataset and cache result """
    if os.path.exists(cache_file):
        with open(cache_file, "rb") as f:
            X_processed = pickle.load(f)
    else:
        X_processed = [preprocess(str(x)) for x in X]
        with open(cache_file, "wb") as f:
            pickle.dump(X_processed, f)
    return X_processed

# ================== LOAD DATA ==================
train_data = pd.read_csv(PATH_TRAIN)
dev_data = pd.read_csv(PATH_DEV)
test_data = pd.read_csv(PATH_TEST)

train_X = preprocess_dataset(train_data['Comment'], os.path.join(CACHE_DIR, "train_X.pkl"))
dev_X   = preprocess_dataset(dev_data['Comment'], os.path.join(CACHE_DIR, "dev_X.pkl"))
test_X  = preprocess_dataset(test_data['Comment'], os.path.join(CACHE_DIR, "test_X.pkl"))

train_y_task1 = train_data['Label'].values
train_y_task2 = train_data['SpamLabel'].values
dev_y_task1   = dev_data['Label'].values
dev_y_task2   = dev_data['SpamLabel'].values
test_y_task1  = test_data['Label'].values
test_y_task2  = test_data['SpamLabel'].values

# ================== DATASET CLASS ==================
class BuildDataset(torch.utils.data.Dataset):
    def __init__(self, encodings, labels):
        self.encodings = encodings
        self.labels = torch.tensor(labels, dtype=torch.long)
    def __getitem__(self, idx):
        item = {key: torch.tensor(val[idx]) for key, val in self.encodings.items()}
        item['labels'] = self.labels[idx]
        return item
    def __len__(self):
        return len(self.labels)

# ================== SHOW RESULT ==================
def show_predict_result(trainer, test_dataset, y_test, labels):
    y_pred_classify = trainer.predict(test_dataset)
    y_pred = np.argmax(y_pred_classify.predictions, axis=-1)
    cf = confusion_matrix(y_test, y_pred)
    df_cm = pd.DataFrame(cf, index=labels, columns=labels)
    sns.heatmap(df_cm, annot=True, cmap="Greys", fmt='g', cbar=True, annot_kws={"size": 15})
    plt.show()
    print("F1 - micro:", f1_score(y_test, y_pred, average='micro'))
    print("F1 - macro:", f1_score(y_test, y_pred, average='macro'))
    print("Accuracy:", accuracy_score(y_test, y_pred))

def get_latest_checkpoint(output_dir):
    """
    Trả về đường dẫn checkpoint mới nhất trong thư mục output_dir, hoặc None nếu không có.
    """
    if not os.path.exists(output_dir):
        return None
    checkpoints = [os.path.join(output_dir, d) for d in os.listdir(output_dir)
                   if os.path.isdir(os.path.join(output_dir, d)) and "checkpoint" in d]
    if not checkpoints:
        return None
    
    checkpoints.sort(key=lambda x: int(re.findall(r"checkpoint-(\d+)", x)[0]), reverse=True)
    return checkpoints[0]


# ================== TRAIN MODEL ==================
def train_model(model_name, tokenizer_class, num_labels, train_texts, train_labels,
                dev_texts, dev_labels, test_texts, test_labels, labels, output_dir,
                resume_checkpoint=None, remove_old_checkpoints=False):
    
    
    if remove_old_checkpoints and os.path.exists(output_dir):
        shutil.rmtree(output_dir)
        os.makedirs(output_dir, exist_ok=True)
        print(f"Removed old checkpoints at {output_dir}")


    if resume_checkpoint and os.path.exists(resume_checkpoint):
        print(f"Resuming training from checkpoint: {resume_checkpoint}")
        model = AutoModelForSequenceClassification.from_pretrained(resume_checkpoint, num_labels=num_labels)
    else:
        model = AutoModelForSequenceClassification.from_pretrained(model_name, num_labels=num_labels)

    tokenizer = tokenizer_class.from_pretrained(model_name, use_fast=False)

    train_encodings = tokenizer(train_texts, truncation=True, padding=True, max_length=100)
    dev_encodings   = tokenizer(dev_texts, truncation=True, padding=True, max_length=100)
    test_encodings  = tokenizer(test_texts, truncation=True, padding=True, max_length=100)

    train_dataset = BuildDataset(train_encodings, train_labels)
    dev_dataset   = BuildDataset(dev_encodings, dev_labels)
    test_dataset  = BuildDataset(test_encodings, test_labels)

    training_args = TrainingArguments(
        output_dir=output_dir,
        per_device_train_batch_size=16,
        per_device_eval_batch_size=16,
        num_train_epochs=3,
        eval_strategy="epoch",
        save_strategy="epoch",
        logging_dir=os.path.join(output_dir, "logs"),
        report_to="none",
        no_cuda=False,
        save_safetensors=False,
        save_steps=2000,
        save_total_limit=2,
    )

    trainer = Trainer(
        model=model,
        args=training_args,
        train_dataset=train_dataset,
        eval_dataset=dev_dataset
    )

    trainer.train(resume_from_checkpoint=resume_checkpoint)
    trainer.save_model(output_dir)
    show_predict_result(trainer, test_dataset, test_labels, labels)


TASKS = [
    {
        "name": "phobert_task_1",
        "model_name": "vinai/phobert-base",
        "tokenizer": AutoTokenizer,
        "num_labels": 2,
        "train_labels": train_y_task1,
        "dev_labels": dev_y_task1,
        "test_labels": test_y_task1,
        "labels": labels_task_1
    },
    {
        "name": "phobert_task_2",
        "model_name": "vinai/phobert-base",
        "tokenizer": AutoTokenizer,
        "num_labels": 4,
        "train_labels": train_y_task2,
        "dev_labels": dev_y_task2,
        "test_labels": test_y_task2,
        "labels": labels_task_2
    },
    {
        "name": "bert4news_task_1",
        "model_name": "NlpHUST/vibert4news-base-cased",
        "tokenizer": BertTokenizer,
        "num_labels": 2,
        "train_labels": train_y_task1,
        "dev_labels": dev_y_task1,
        "test_labels": test_y_task1,
        "labels": labels_task_1
    },
    {
        "name": "bert4news_task_2",
        "model_name": "NlpHUST/vibert4news-base-cased",
        "tokenizer": BertTokenizer,
        "num_labels": 4,
        "train_labels": train_y_task2,
        "dev_labels": dev_y_task2,
        "test_labels": test_y_task2,
        "labels": labels_task_2
    }
]

for task in TASKS:
    output_dir = os.path.join(MODEL_DIR, task["name"])
    latest_ckpt = get_latest_checkpoint(output_dir)
    if latest_ckpt:
        print(f"[RESUME] Task {task['name']} từ checkpoint: {latest_ckpt}")
    else:
        print(f"[RUN] Task {task['name']} chưa có checkpoint, bắt đầu train từ đầu")

    train_model(
        task["model_name"], task["tokenizer"], task["num_labels"],
        train_X, task["train_labels"],
        dev_X, task["dev_labels"],
        test_X, task["test_labels"],
        task["labels"],
        output_dir,
        resume_checkpoint=latest_ckpt,
        remove_old_checkpoints=False 
    )


# ================== CLOSE VnCoreNLP ==================
vncorenlp.close()
