import os
#configfile: "config.yaml"
configfile: "config/config.yaml"
#configfile: "workflow/config/config.yaml"

PROTEINS = {
    "hsv-1/gD": "P57083",
    "hsv-1/gH": "P08356",
    "hsv-1/gL": "P28278",
}

DATA_DIR = config["data_dir"]
RESULTS_DIR = config["output_dir"]
CONTAINERS_DIR = config["containers_dir"]
QUERY_PROTEINS = list(PROTEINS.keys())
MULTIFASTA_NAME = "_".join([p.split("/")[-1] for p  in QUERY_PROTEINS])
MULTIFASTA_OUTPUT = DATA_DIR+"/hsv-1/multi/"+MULTIFASTA_NAME+".fa"
MULTIFASTA_ALN_OUTPUT = RESULTS_DIR+"/" + MULTIFASTA_NAME + ".a3m"
rule prepare_data:
    input:
        expand(DATA_DIR+"/{protein}.fa", protein=QUERY_PROTEINS),
        MULTIFASTA_OUTPUT,
        MULTIFASTA_ALN_OUTPUT


rule FETCH_SEQS:
    output:
        DATA_DIR+"/{protein}.fa"
    params:
        url=lambda wildcards: f"https://rest.uniprot.org/uniprotkb/{PROTEINS[wildcards.protein]}.fasta"
    shell:
        """
        mkdir -p $(dirname {output})
        curl -o {output} {params.url}
        """


rule CREATE_MULTISEQ_FASTA:
    input:
        expand(DATA_DIR+"/{protein}.fa",protein=QUERY_PROTEINS)
    output:
        MULTIFASTA_OUTPUT
    shell:
        """
        python "{config[scripts_dir]}/create_multiseq_fasta.py" {input} {output}
        """

rule RUN_COLABFOLD_SEARCH:
    input:
        MULTIFASTA_OUTPUT
    output:
        MULTIFASTA_ALN_OUTPUT
    container:
        CONTAINERS_DIR+"/colabfold/colabfold_1.5.5-cuda12.2.2.sif"
    shell:
        """
        colabfold_batch {input} /predictions --msa-only 
        """
#

# rule RUN_COLABFOLD_BATCH:

