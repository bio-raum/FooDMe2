# Translating taxon names

For some users it may be desirable to use common species names, and even translated species names, in their reporting. 
However, such translations are not generally something that we as developers can realistically provide as it would involve substantial manual
curation to achieve robust results (and create a lot of support requests...). Howevever, below we outline a few suggestions on how this task could be approached and how FooDMe2
already supports it. 

## The data format

In principle, providing FooDMe2 with a list of translations is already possible using the `--common_names` command line flag. In short, all you need to do is provide a
TSV file with the following format:

| tax_id | scientific_name | common_name | translation |
| ------ | --------------- | ----------- | ----------- |
| 1234   | Equus unicornis | Unicorn | Einhorn |

The translation can by in any language, as long as it is compatible with UTF-8 encoding. 

## The hard way

You can obviously start putting together a list of relevant taxa and manually curate your list over time. Depending on your use case, this may be a quick or a very slow process. 

## Using LLMs (translate.py)

One way to produce translations is via LLMs - some of which have fairly extensive translation capabilities. We have written a small script (translate.py) that accepts dump files from the NCBI taxonomy and uses a local (or remote) Ollama instance to generate translations. Note that this script needs to be adapted to your local setting.

```Python
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

...
```
Specifically, the NODES_FILE and NAMES_FILE need to point to the locally available dump files (part of the local FooDMe2 references) and the MODEL_NAME needs 
to match whatever model you want to use. Also, please check the LLM prompt to switch the translation from German to your language of choice. 

```python
prompt = (
    "Translate each English biological common name in this JSON object into its standard German common name. "
    "Return ONLY a valid JSON object using the exact same numeric keys.\n\n"
    f"{json.dumps(numbered, ensure_ascii=False)}"
)
```

Please note that this takes a long time (1.5-2 hours at 130 tokens/s) so isn't exactly suited for your Claude subscription perhaps. We ran this on a local Ollama instance.

## GBIF (check_gbif.py)

The Global Biodiversity Information Facility [GBIF](https://www.gbif.org/) is a global database of biodiversity information. It contains a wealth of information on species, habitats, 
and ecosystems. GBIF provides a wide range of data formats, including CSV, JSON, and XML, which can be used to analyze and visualize biodiversity data.

It also happens to come with a database of venacular species names as part of its backbone [data dump](https://www.gbif.org/dataset/d7dddbf4-2cf0-4f39-9b2a-bb099caae36c). We have thus
created a second script that takes the output from the LLM translations, the NCBI dump files and the the GBIF backbone data (backbone.zip) to add all the translations from GBIF to our translation table. This is under the assumption that GBIF has much fewer but higher-quality translations. From this you can then easily produce the format mentioned above as a lookup file. However, you will need to adjust which language you want to translate to, similar as for the LLM script. 

The code section of relevance is this bit:

```Python
lang = row.get("language", "").strip().lower()
if lang in ("de", "deu", "ger", "german"):
...
```

