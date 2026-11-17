import csv
import zipfile
import sys

NAMES_FILE = "/work_syn/references/foodme2/1.4/new_taxdump/names.dmp"
QWEN_OUTPUT_FILE = "common_names_de.txt"
GBIF_ZIP_FILE = "backbone.zip"
VERIFIED_OUTPUT_FILE = "verified_common_names_de.tsv"
SEP = "\t"

csv.field_size_limit(sys.maxsize)

def load_ncbi_scientific_names(names_path):
    """Map NCBI tax_id to its primary scientific name."""
    sci_names = {}
    with open(names_path, "r", encoding="utf-8") as handle:
        for line in handle:
            parts = [p.strip() for p in line.split("|")]
            if len(parts) >= 4:
                tax_id, name_txt, _, name_class, *_ = parts
                if name_class == "scientific name":
                    sci_names[tax_id] = name_txt
    return sci_names


def load_qwen_translations(qwen_path):
    """Load (tax_id, english_name, german_translation) rows."""
    rows = []
    with open(qwen_path, "r", encoding="utf-8") as handle:
        for line in handle:
            cols = line.rstrip("\n").split(SEP)
            if len(cols) == 3:
                tax_id, eng_name, qwen_de = cols
                rows.append((tax_id, eng_name, qwen_de))
    return rows


def normalize_name(name):
    """Lowercase and strip parenthetical notes for cleaner matching."""
    return name.strip().lower()


def load_gbif_german_names(zip_path, target_sci_names):
    """Stream Taxon.tsv and VernacularName.tsv from backbone.zip for target species."""
    sci_to_gbif_ids = {}
    target_gbif_ids = set()

    print("Reading Taxon.tsv from backbone.zip...", flush=True)
    with zipfile.ZipFile(zip_path, "r") as zf:
        with zf.open("Taxon.tsv") as raw_taxon:
            text_taxon = (line.decode("utf-8", errors="replace") for line in raw_taxon)
            reader = csv.DictReader(text_taxon, delimiter="\t", quoting=csv.QUOTE_NONE)
            for row in reader:
                gbif_id = row.get("taxonID", "").strip()
                canonical = normalize_name(row.get("canonicalName", ""))
                scientific = normalize_name(row.get("scientificName", ""))
                status = row.get("taxonomicStatus", "").strip().lower()

                matched_key = None
                if canonical in target_sci_names:
                    matched_key = canonical
                elif scientific in target_sci_names:
                    matched_key = scientific

                if matched_key and gbif_id:
                    # Prefer accepted taxa over synonyms
                    priority = 0 if status == "accepted" else 1
                    sci_to_gbif_ids.setdefault(matched_key, []).append((priority, gbif_id))
                    target_gbif_ids.add(gbif_id)

        gbif_id_to_de = {}
        print("Reading VernacularName.tsv from backbone.zip...", flush=True)
        with zf.open("VernacularName.tsv") as raw_vern:
            text_vern = (line.decode("utf-8", errors="replace") for line in raw_vern)
            reader = csv.DictReader(text_vern, delimiter="\t")
            for row in reader:
                gbif_id = row.get("taxonID", "").strip()
                if gbif_id not in target_gbif_ids:
                    continue
                lang = row.get("language", "").strip().lower()
                if lang in ("de", "deu", "ger", "german"):
                    vern_name = row.get("vernacularName", "").strip()
                    if vern_name:
                        gbif_id_to_de.setdefault(gbif_id, []).append(vern_name)

    sci_to_german = {}
    for sci_key, id_list in sci_to_gbif_ids.items():
        id_list.sort(key=lambda item: item)
        collected = []
        seen = set()
        for _, gid in id_list:
            for vname in gbif_id_to_de.get(gid, []):
                if vname.lower() not in seen:
                    seen.add(vname.lower())
                    collected.append(vname)
        if collected:
            sci_to_german[sci_key] = collected

    return sci_to_german


def main():
    print("Loading NCBI scientific names...", flush=True)
    sci_names = load_ncbi_scientific_names(NAMES_FILE)

    print("Loading Qwen translations...", flush=True)
    qwen_rows = load_qwen_translations(QWEN_OUTPUT_FILE)

    target_sci = {
        normalize_name(sci_names[tid])
        for tid, _, _ in qwen_rows
        if tid in sci_names
    }
    print(f"Found {len(target_sci)} unique scientific names to cross-check.", flush=True)

    sci_to_german = load_gbif_german_names(GBIF_ZIP_FILE, target_sci)

    stats = {"MATCH": 0, "DIFF": 0, "NO_GBIF_DE": 0}
    with open(VERIFIED_OUTPUT_FILE, "w", encoding="utf-8", newline="") as out:
        writer = csv.writer(out, delimiter="\t")
        writer.writerow([
            "tax_id",
            "scientific_name",
            "english_common_name",
            "qwen_german",
            "gbif_german",
            "status",
        ])

        for tid, eng_name, qwen_de in qwen_rows:
            sci = sci_names.get(tid, "")
            gbif_list = sci_to_german.get(normalize_name(sci), [])

            if not gbif_list:
                status = "NO_GBIF_DE"
                gbif_str = ""
            else:
                gbif_str = " | ".join(gbif_list)
                gbif_lower = {g.lower() for g in gbif_list}
                if qwen_de.strip().lower() in gbif_lower:
                    status = "MATCH"
                else:
                    status = "DIFF"

            stats[status] += 1
            writer.writerow([tid, sci, eng_name, qwen_de, gbif_str, status])

    print(f"Done! Wrote {VERIFIED_OUTPUT_FILE}", flush=True)
    print(
        f"Summary -> MATCH: {stats['MATCH']}, "
        f"DIFF (review): {stats['DIFF']}, "
        f"NO_GBIF_DE (Qwen fallback): {stats['NO_GBIF_DE']}",
        flush=True,
    )


if __name__ == "__main__":
    main()
