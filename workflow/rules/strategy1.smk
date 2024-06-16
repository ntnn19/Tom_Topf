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
MAX_DEPTH_FILENAME= ["16_32", "32_64", "64_128", "256_512", "512_1024"]
MAX_DEPTH_PARAM= [i.replace("_",":") for i in MAX_DEPTH_FILENAME]
AF_MODEL= ["1","2","3","4","5"]
AF_MODEL_RANK= ["001","002","003","004","005"]
MULTIFASTA_OUTPUT = DATA_DIR+"/hsv-1/multi/"+MULTIFASTA_NAME+".fa"
MULTIFASTA_ALN_OUTPUT = RESULTS_DIR+"/hsv-1/multi/" + MULTIFASTA_NAME + ".a3m"
MULTIFASTA_ALN_DECOY_OUTPUT = [RESULTS_DIR+"/hsv-1/multi/" + MULTIFASTA_NAME+"_"+max_depth + ".a3m" for max_depth in MAX_DEPTH_FILENAME]
rule prepare_data:
    input:
        expand(DATA_DIR+"/{protein}.fa", protein=QUERY_PROTEINS),
        MULTIFASTA_OUTPUT,
        MULTIFASTA_ALN_OUTPUT,
        expand(RESULTS_DIR +
           "/hsv-1/multi/" + MULTIFASTA_NAME +
           "_{msa_depth}_unrelaxed_rank_{rank}_alphafold2_multimer_v3_model_{model}_seed_000.pdb", rank=AF_MODEL_RANK, model=AF_MODEL, msa_depth=MAX_DEPTH_FILENAME)


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
        python "{config[scripts_dir]}/create_multiseq_fasta_test.py" {input} {output}
        """
        # python "{config[scripts_dir]}/create_multiseq_fasta.py" {input} {output}

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
rule CREATE_DECOY_A3M:
    input:
        MULTIFASTA_ALN_OUTPUT
    output:
        MULTIFASTA_ALN_DECOY_OUTPUT
    shell:
        """
        for dest in {output}; do cp {input} "$dest"; done
        """



rule RUN_COLABFOLD_BATCH:
    input:
        MULTIFASTA_ALN_DECOY_OUTPUT
        # a3m_1 =  MULTIFASTA_ALN_DECOY_OUTPUT[0],
        # a3m_2 =  MULTIFASTA_ALN_DECOY_OUTPUT[1],
        # a3m_3 =  MULTIFASTA_ALN_DECOY_OUTPUT[2],
        # a3m_4 =  MULTIFASTA_ALN_DECOY_OUTPUT[3],
        # a3m_5 =  MULTIFASTA_ALN_DECOY_OUTPUT[4]
    params:
        MAX_DEPTH_PARAM
        # d1=MAX_DEPTH[0].replace("_",":"),
        # d2=MAX_DEPTH[1].replace("_",":"),
        # d3=MAX_DEPTH[2].replace("_",":"),
        # d4=MAX_DEPTH[3].replace("_",":"),
        # d5=MAX_DEPTH[4].replace("_",":")
    output:
        expand(RESULTS_DIR +
               "/hsv-1/multi/" + MULTIFASTA_NAME+
               "_{msa_depth}_unrelaxed_rank_{rank}_alphafold2_multimer_v3_model_{model}_seed_000.pdb",rank=AF_MODEL_RANK,model=AF_MODEL, msa_depth=MAX_DEPTH_FILENAME)
    container:
        CONTAINERS_DIR+"/colabfold/colabfold_1.5.5-cuda12.2.2.sif"
    shell:
        """
        for i in !{input}; do
          input_a3m="${{input[$i]}}"
          max_msa="${{params[$i]}}"
          colabfold_batch {input_a3m} /predictions --max-msa {max_msa}
        """
        # done
        # # colabfold_batch {a3m_1} /predictions --max-msa {params.d1}
        # # colabfold_batch {a3m_2} /predictions --max-msa {params.d2}
        # # colabfold_batch {a3m_3} /predictions --max-msa {params.d3}
        # # colabfold_batch {a3m_4} /predictions --max-msa {params.d4}
        # # colabfold_batch {a3m_5} /predictions --max-msa {params.d5}
        # """






