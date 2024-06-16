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
MULTIFASTA_ALN_OUTPUT = RESULTS_DIR+"/hsv-1/multi/" + MULTIFASTA_NAME + ".a3m"
MAX_DEPTH= ["16:32", "32:64", "64:128", "256:512", "512:1024"]
AF_MODEL= ["1","2","3","4","5"]
AF_MODEL_RANK= ["001","002","003","004","005"]
rule prepare_data:
    input:
        expand(DATA_DIR+"/{protein}.fa", protein=QUERY_PROTEINS),
        MULTIFASTA_OUTPUT,
        MULTIFASTA_ALN_OUTPUT,
        expand(RESULTS_DIR +
           "/hsv-1/multi/" + MULTIFASTA_NAME +
           "_unrelaxed_rank_{rank}_alphafold2_multimer_v3_model_{model}_seed_000_{msa_depth}.pdb", rank=AF_MODEL_RANK, model=AF_MODEL, msa_depth=MAX_DEPTH)


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
        expand(DATA_DIR+"/{protein}.fa",protein=QUERY_PROTEINS[0]) # test
        # expand(DATA_DIR+"/{protein}.fa",protein=QUERY_PROTEINS)
    output:
        MULTIFASTA_OUTPUT
    shell:
        """
        # python "{config[scripts_dir]}/create_multiseq_fasta.py" {input} {output}
        python "{config[scripts_dir]}/create_multiseq_fasta_test.py" {input} {output}
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

rule RUN_COLABFOLD_BATCH:
    input:
        MULTIFASTA_ALN_OUTPUT
    params:

        d1=MAX_DEPTH[0],
        d2=MAX_DEPTH[1],
        d3=MAX_DEPTH[2],
        d4=MAX_DEPTH[3],
        d5=MAX_DEPTH[4]
    output:
# gD_gH_gL_unrelaxed_rank_001_alphafold2_multimer_v3_model_2_seed_000.pdb
        expand(RESULTS_DIR +
               "/hsv-1/multi/" + MULTIFASTA_NAME+
               "_unrelaxed_rank_{rank}_alphafold2_multimer_v3_model_{model}_seed_000_{msa_depth}.pdb",rank=AF_MODEL_RANK,model=AF_MODEL, msa_depth=MAX_DEPTH)
    container:
        CONTAINERS_DIR+"/colabfold/colabfold_1.5.5-cuda12.2.2.sif"
    shell:
        """
        colabfold_batch {input} /predictions --max-msa {params.d1}
        colabfold_batch {input} /predictions --max-msa {params.d2}
        colabfold_batch {input} /predictions --max-msa {params.d3}
        colabfold_batch {input} /predictions --max-msa {params.d4}
        colabfold_batch {input} /predictions --max-msa {params.d5}
        """
