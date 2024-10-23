#!/usr/bin/env python
import plotly.express as px
from jinja2 import Template
import pandas as pd
import os,json,re
import argparse


parser = argparse.ArgumentParser(description="Script options")
parser.add_argument("--template", help="A JINJA2 template")
parser.add_argument("--output")
args = parser.parse_args()

status = {
    "pass": "pass",
    "warn": "warn",
    "fail": "fail",
    "missing": "missing"
}


def main(template, output):

    json_files = [pos_json for pos_json in os.listdir('.') if pos_json.endswith('.json')]

    data = {}
    data["summary"] = [ ]

    taxon_data = []

    samples = []

    insert_size_list = {}

    for idx, json_file in enumerate(json_files):

        rtable = {}

        with open(json_file) as f:
            jdata = json.load(f)
            f.close

            sample = jdata["sample"]
            samples.append(sample)

            composition = jdata["composition"]

            # Track the sample status
            this_status = status["pass"]

            reads_passing = jdata["cutadapt"]["Reads passing filters"]
            reads_filtered = jdata["cutadapt"]["Filtered reads (uncategorized)"]

            reads_after_clustering = jdata["clustering"]["passing"]
            reads_chimera = jdata["clustering"]["chimeras"]

            if ("fastp" in jdata):
                fastp = jdata["fastp"]
                insert_size = fastp["insert_size"]["peak"]
                reads_total = int(int(fastp["summary"]["before_filtering"]["total_reads"])/2)
                q30 = round(float(fastp["summary"]["before_filtering"]["q30_rate"]),2)*100

                insert_size_list[sample] = fastp["insert_size"]["histogram"]

            # sample-level dictionary
            rtable = { 
                "sample": sample,
                "status": this_status,
                "reads_passing": reads_passing,
                "reads_filtered": reads_filtered,
                "reads_after_clustering": reads_after_clustering,
                "reads_chimera": reads_chimera,
                "insert_size": insert_size,
                "reads_total": reads_total,
                "reads_q30": q30
            }

            this_taxon_data = {}

            for taxon in composition:
                perc = float(taxon["proportion"])*100
                if (perc >= 1.0):
                    this_taxon_data[taxon["name"]] = perc

            taxon_data.append(this_taxon_data)
        
        data["summary"].append(rtable)    

    # The taxonomic composition as stacked bar plot
    tdata = pd.DataFrame(data=taxon_data,index=samples)
    plot_labels = { "index": "Samples", "value": "Percentage"}
    h = len(samples)*20 if len(samples) > 10 else 400
    fig = px.bar(tdata,orientation='h',labels=plot_labels, height=h)
    data["Taxa"] = fig.to_html(full_html=False)

    # The insert size distribution
    plot_labels = { "index": "Basepairs", "values": "Count"}
    hdata = pd.DataFrame(insert_size_list)
    hfig = px.line(hdata, labels=plot_labels)
    data["Insertsizes"] = hfig.to_html(full_html=False)

    with open(output, "w", encoding="utf-8") as output_file:
        with open(template) as template_file:
            j2_template = Template(template_file.read())
            output_file.write(j2_template.render(data))


if __name__ == '__main__':
    main( args.template, args.output)

