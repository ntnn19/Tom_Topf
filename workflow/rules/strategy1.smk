import os
#configfile: "config.yaml"
configfile: "config/config.yaml"
#configfile: "workflow/config/config.yaml"

proteins = {
    "hsv-1/gD": "P57083",
    "hsv-1/gH": "P08356",
    "hsv-1/gL": "P28278",
}

DATA_DIR = config["data_dir"]
RESULTS_DIR = config["output_dir"]
CONTAINERS_DIR = config["containers_dir"]
QUERY_PROTEINS = list(proteins.keys())
MULTIFASTA_NAME = "_".join([p.split("/")[-1] for p  in QUERY_PROTEINS])
MULTIFASTA_OUTPUT = DATA_DIR+"/hsv-1/multi/"+MULTIFASTA_NAME+".fa"

rule prepare_data:
    input:
        expand(DATA_DIR+"/{protein}.fa", protein=QUERY_PROTEINS),
        MULTIFASTA_OUTPUT,

# rule CREATE_DATA_DIR:
#     output:
#         directory(DATA_DIR)
#     run:
#         os.makedirs(DATA_DIR, exist_ok=True)
#
# rule CREATE_RESULTS_DIR:
#     output:
#         directory(RESULTS_DIR)
#     run:
#         os.makedirs(RESULTS_DIR, exist_ok=True)

rule FETCH_SEQS:
    output:
        DATA_DIR+"/{protein}.fa"
    params:
        url=lambda wildcards: f"https://rest.uniprot.org/uniprotkb/{proteins[wildcards.protein]}.fasta"
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
        RESULTS_DIR+"/"+MULTIFASTA_NAME+".a3m"
    container:
        CONTAINERS_DIR+"/colabfold/colabfold_1.5.5-cuda12.2.2.sif"
    shell:
        """
        colabfold_batch {input} /predictions --msa-only 
        """
#

# rule RUN_COLABFOLD_BATCH:

