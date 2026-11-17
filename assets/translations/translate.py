import os
import re
import requests
import json

NODES_FILE = "nodes.dmp"
NAMES_FILE = "names.dmp"
OUTPUT_FILE = "common_names_de.txt"
API_URL = "http://localhost:11434/v1/chat/completions"
MODEL_NAME = "qwen3-coder:30b"  # Replace with your exact Ollama model name
BATCH_SIZE = 50
EUKARYOTA_TAX_ID = "2759"
SEP = "\t"

print("Loading nodes.dmp...", flush=True)
parent_map = {}
with open(NODES_FILE, "r", encoding="utf-8") as f:
    for line in f:
        parts = [p.strip() for p in line.split("|")]
        if len(parts) >= 2:
            tax_id, parent_id, *_ = parts
            parent_map[tax_id] = parent_id

is_euk_cache = {EUKARYOTA_TAX_ID: True, "1": False, "0": False}

def is_eukaryote(tax_id):
    path = []
    curr = tax_id
    while curr not in is_euk_cache:
        path.append(curr)
        parent = parent_map.get(curr)
        if not parent or parent == curr:
            is_euk_cache[curr] = False
            break
        curr = parent
    result = is_euk_cache[curr]
    for node in path:
        is_euk_cache[node] = result
    return result

print("Reading names.dmp...", flush=True)
entries = set()
with open(NAMES_FILE, "r", encoding="utf-8") as f:
    for line in f:
        parts = [p.strip() for p in line.split("|")]
        if len(parts) >= 4:
            tax_id, name_txt, _, name_class, *_ = parts
            if name_class in ("common name", "genbank common name") and is_eukaryote(tax_id):
                entries.add((tax_id, name_txt))

already_done = set()
cached_translations = {}
if os.path.exists(OUTPUT_FILE):
    with open(OUTPUT_FILE, "r", encoding="utf-8") as f:
        for line in f:
            cols = line.rstrip("\n").split(SEP)
            if len(cols) == 3:
                saved_id, saved_eng, saved_ger = cols
                already_done.add((saved_id, saved_eng))
                cached_translations[saved_eng] = saved_ger

def sort_key(pair):
    tid, name = pair
    return (int(tid), name)

remaining_entries = sorted(entries - already_done, key=sort_key)
name_to_taxids = {}
for tax_id, eng in remaining_entries:
    name_to_taxids.setdefault(eng, []).append(tax_id)

print(f"Found {len(entries)} eukaryote entries ({len(name_to_taxids)} unique names remaining).", flush=True)

def translate_batch(batch):
    numbered = {str(idx): name for idx, name in enumerate(batch, 1)}
    prompt = (
        "Translate each English biological common name in this JSON object into its standard German common name. "
        "Return ONLY a valid JSON object using the exact same numeric keys.\n\n"
        f"{json.dumps(numbered, ensure_ascii=False)}"
    )
    response = requests.post(
        API_URL,
        json={
            "model": MODEL_NAME,
            "messages": [{"role": "user", "content": prompt}],
            "temperature": 0.1,
            "response_format": {"type": "json_object"},
        },
        timeout=120,
    )
    data = response.json()
    choices = data.get("choices")
    if not choices:
        raise RuntimeError(f"API Error (HTTP {response.status_code}): {data}")
    first_choice, *_ = choices
    content = first_choice.get("message", {}).get("content", "")
    content = re.sub(r"<think>.*?</think>", "", content, flags=re.DOTALL).strip()
    parsed = json.loads(content)
    return [str(parsed.get(str(idx), name)).strip() for idx, name in enumerate(batch, 1)]


with open(OUTPUT_FILE, "a", encoding="utf-8") as out:
    for eng, tax_ids in list(name_to_taxids.items()):
        if eng in cached_translations:
            for tid in tax_ids:
                out.write(f"{tid}{SEP}{eng}{SEP}{cached_translations[eng]}\n")
            del name_to_taxids[eng]
    out.flush()

    pending_names = sorted(name_to_taxids.keys())
    for i in range(0, len(pending_names), BATCH_SIZE):
        batch = pending_names[i : i + BATCH_SIZE]
        translations = translate_batch(batch)

        if len(translations) != len(batch):
            print(f"Batch mismatch ({len(translations)} vs {len(batch)}), falling back 1-by-1...", flush=True)
            translations = []
            for name in batch:
                single = translate_batch([name])
                first_trans, *_ = single if single else [name]
                translations.append(first_trans)

        for eng, ger in zip(batch, translations):
            for tid in name_to_taxids[eng]:
                out.write(f"{tid}{SEP}{eng}{SEP}{ger}\n")
        out.flush()
        print(f"Saved {min(i + BATCH_SIZE, len(pending_names))}/{len(pending_names)} unique names", flush=True)

print("Done!", flush=True)
