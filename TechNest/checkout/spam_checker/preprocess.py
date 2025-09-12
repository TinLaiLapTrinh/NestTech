import re
from .configs import vncorenlp, stopwords

def filter_stop_words(text: str) -> str:
    return ' '.join([w for w in text.split() if w not in stopwords])

def deEmojify(text: str) -> str:
    pattern = re.compile("[" 
                         u"\U0001F600-\U0001F64F"
                         u"\U0001F300-\U0001F5FF"
                         u"\U0001F680-\U0001F6FF"
                         u"\U0001F1E0-\U0001F1FF"
                         "]+", flags=re.UNICODE)
    return pattern.sub(r'', text)

def preprocess(text: str, tokenized: bool = True, lowercased: bool = True) -> str:
    text = filter_stop_words(text)
    text = deEmojify(text)
    text = text.lower() if lowercased else text
    if tokenized:
        pre_text = ""
        for sentence in vncorenlp.tokenize(text):
            pre_text += " ".join(sentence) + " "
        text = pre_text.strip()
    return text
