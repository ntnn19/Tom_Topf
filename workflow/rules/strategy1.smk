proteins = {
    "hsv-1/gD": "P57083",
    "hsv-1/gH": "P08356",
    "hsv-1/gL": "P28278",
}
QUERY_PROTEINS = list(proteins.keys())
MULTIFASTA_NAME = "_".join([p.split("/")[-1] for p  in QUERY_PROTEINS])
MULTIFASTA_OUTPUT = "data/hsv-1/"+MULTIFASTA_NAME+".fa"
rule all:
    input:
        expand("data/{protein}.fa", protein=QUERY_PROTEINS),
        MULTIFASTA_OUTPUT,

rule fetch_seqs:
    output:
        "data/{protein}.fa"
    params:
        url=lambda wildcards: f"https://rest.uniprot.org/uniprotkb/{proteins[wildcards.protein]}.fasta"
    shell:
        """
        mkdir -p $(dirname {output})
        curl -o {output} {params.url}
        """


rule create_multiseq_fasta:
    input:
        "data/{protein}.fa"
    output:
        MULTIFASTA_OUTPUT
    shell:
        """
        echo >{MULTIFASTA_NAME} > {output}
        cat {input} > {output}
        """

# rule colabfold_search:
# rule colabfold_batch:
