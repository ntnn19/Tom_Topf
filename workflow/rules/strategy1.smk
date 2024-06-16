configfile: "config/config.yaml"

PROTEINS = {
    "hsv-1/gD": "P57083",
    "hsv-1/gH": "P08356",
    "hsv-1/gL": "P28278",
}

DATA_DIR = config["data_dir"]
RESULTS_DIR = config["output_dir"]
CONTAINERS_DIR = config["containers_dir"]
QUERY_PROTEINS = list(PROTEINS.keys())
MULTIFASTA_NAME = "_".join([p.split("/")[-1] for p in QUERY_PROTEINS])
MAX_DEPTH_FILENAME = ["16_32", "32_64", "64_128", "256_512", "512_1024"]
AF_MODEL = ["1", "2", "3", "4", "5"]
AF_MODEL_RANK = ["001", "002", "003", "004", "005"]
MULTIFASTA_OUTPUT = DATA_DIR + "/hsv-1/multi/" + MULTIFASTA_NAME + ".fa"
MULTIFASTA_ALN_OUTPUT = RESULTS_DIR + "/" + MULTIFASTA_NAME + ".a3m"
MULTIFASTA_ALN_DECOY_OUTPUT = [RESULTS_DIR + "/" + MULTIFASTA_NAME + "_" + max_depth + ".a3m" for max_depth in
                               MAX_DEPTH_FILENAME]

rule prepare_data:
    input:
        expand(DATA_DIR + "/{protein}.fa",protein=QUERY_PROTEINS),
        MULTIFASTA_OUTPUT,
        MULTIFASTA_ALN_OUTPUT,
        expand(RESULTS_DIR +
               "/hsv-1/multi/" + MULTIFASTA_NAME +
               "_{msa_depth}_unrelaxed_rank_{rank}_alphafold2_multimer_v3_model_{model}_seed_000.pdb",rank=AF_MODEL_RANK,model=AF_MODEL,msa_depth=MAX_DEPTH_FILENAME)


rule FETCH_SEQS:
    output:
        DATA_DIR + "/{protein}.fa"
    params:
        url=lambda wildcards: f"https://rest.uniprot.org/uniprotkb/{PROTEINS[wildcards.protein]}.fasta"
    shell:
        """
        mkdir -p $(dirname {output})
        curl -o {output} {params.url}
        """


rule CREATE_MULTISEQ_FASTA:
    input:
        expand(DATA_DIR + "/{protein}.fa",protein=QUERY_PROTEINS[0])  # test
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
        CONTAINERS_DIR + "/colabfold/colabfold_1.5.5-cuda12.2.2.sif"
    shell:
        """
        colabfold_batch {input} /predictions --msa-only
        """

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
        MULTIFASTA_ALN_DECOY_OUTPUT,
    output:
        expand(RESULTS_DIR +
               "/hsv-1/multi/" + MULTIFASTA_NAME +
               "_{msa_depth}_unrelaxed_rank_{rank}_alphafold2_multimer_v3_model_{model}_seed_000.pdb",rank=AF_MODEL_RANK,model=AF_MODEL,msa_depth=MAX_DEPTH_FILENAME)
    container:
        CONTAINERS_DIR + "/colabfold/colabfold_1.5.5-cuda12.2.2.sif"
    shell:
        """
        input_files=({input})
        for idx in "${{!input_files[@]}}"; do
            input_a3m="${{input_files[$idx]}}"
            max_msa_as_path=$input_a3m
            max_msa_basename=`basename "${{max_msa_as_path%.*}}"`
            max_msa_param=`echo "${{max_msa_basename}}" | cut -d"_" -f4,5 | tr '_' ':'`
            echo "max_msa_param=$max_msa_param"
            echo "input_aln=$input_a3m"
            colabfold_batch $input_a3m /predictions --max-msa $max_msa_param
        done
        """





