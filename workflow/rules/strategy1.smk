configfile: "config/config.yaml"

PROTEINS = {
    "hsv-1/gD": "P57083",
    "hsv-1/gH": "P08356",
    "hsv-1/gL": "P28278",
}

DATA_DIR = config["data_dir"]
STG_1_RESULTS_DIR = config["output_dir"].split(",")[0]
QUERY_PROTEINS = list(PROTEINS.keys())
MULTIFASTA_NAME = "_".join([p.split("/")[-1] for p in QUERY_PROTEINS])
MAX_DEPTH_FILENAME = ["16_32", "32_64", "64_128", "256_512", "512_1024"]
MULTIFASTA_OUTPUT = DATA_DIR + "/hsv-1/multi/" + MULTIFASTA_NAME + ".fa"
MULTIFASTA_ALN_OUTPUT = STG_1_RESULTS_DIR + "/" + MULTIFASTA_NAME + ".a3m"
MULTIFASTA_ALN_DECOY_OUTPUT = [STG_1_RESULTS_DIR + "/" + MULTIFASTA_NAME + "_" + max_depth + ".a3m" for max_depth in
                               MAX_DEPTH_FILENAME]

colabfold_weights_dir= config["colabfold_weights_dir"]

rule prepare_data:
    input:
        expand(DATA_DIR + "/{protein}.fa",protein=QUERY_PROTEINS),
        MULTIFASTA_OUTPUT,
        MULTIFASTA_ALN_OUTPUT,
        'strategy_1.done.txt',


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
        expand(DATA_DIR+"/{protein}.fa",protein=QUERY_PROTEINS)
        # expand(DATA_DIR + "/{protein}.fa",protein=QUERY_PROTEINS[0])  # test - passed
    output:
        MULTIFASTA_OUTPUT
    shell:
        """
        python "{config[scripts_dir]}/create_multiseq_fasta.py" {input} {output}
        # python "{config[scripts_dir]}/create_multiseq_fasta_test.py" {input} {output} # test - passed
        """


rule RUN_COLABFOLD_SEARCH:
    input:
        MULTIFASTA_OUTPUT
    output:
        MULTIFASTA_ALN_OUTPUT
    container:
        "docker://ghcr.io/sokrypton/colabfold:1.5.5-cuda12.2.2"
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
rule DOWNLOAD_COLABFOLD_WEIGHTS:
    output:
        directory(colabfold_weights_dir+"/colabfold/params")
    container:
        "docker://ghcr.io/sokrypton/colabfold:1.5.5-cuda12.2.2"
    shell:
        """
        python -m colabfold.download
        """

rule RUN_COLABFOLD_BATCH:
    input:
        MULTIFASTA_ALN_DECOY_OUTPUT,
    output:
        "strategy_1.done.txt"
    container:
        "docker://ghcr.io/sokrypton/colabfold:1.5.5-cuda12.2.2"
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
        touch {output}
        """





