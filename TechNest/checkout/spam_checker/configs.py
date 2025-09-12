import os
from vncorenlp import VnCoreNLP

# ================== PATH ==================
DIR_ROOT = r"C:\Users\Administrator\Documents\DoAnNganh\NewNestTech\NestTech\TechNest"

MODEL_DIR = os.path.join(DIR_ROOT, "transformer_model")
VNCORP_JAR = os.path.join(DIR_ROOT, "vncorenlp", "VnCoreNLP-1.1.1.jar")
STOPWORDS_PATH = os.path.join(DIR_ROOT, "vietnamese-stopwords-dash.txt")

# ================== VnCoreNLP ==================
vncorenlp = VnCoreNLP(
    VNCORP_JAR,
    annotators="wseg",
    max_heap_size='-Xmx500m',
    port=2930
)

# ================== STOPWORDS ==================
with open(STOPWORDS_PATH, "r", encoding="utf-8") as f:
    stopwords = set(line.strip() for line in f)

# ================== LABELS ==================
labels_task_1 = ["no-spam", "spam"]
labels_task_2 = ["no-spam", "spam-1", "spam-2", "spam-3"]
