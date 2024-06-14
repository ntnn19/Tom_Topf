import os.path

import click
@click.command()
@click.argument('input', type=click.Path(exists=True), nargs=-1, required=True)
@click.argument('out', type=click.Path(), required=True)
def main(input, out):
    list_of_seq_dicts = [SeqIO.to_dict(SeqIO.parse(f,'fasta')) for f in input]
    outdir = os.path.dirname(out)
    if not os.path.exists(out):
        os.makedirs(outdir, exist_ok=True)

    if len(list_of_seq_dicts) < 2:
        raise ValueError("At least two input sequences are required.")
    else:
        header_list = []
        seq_list = []
        for seq_dict in list_of_seq_dicts:
            if len(seq_dict.keys()) > 1:
                raise ValueError("Only single sequence fasta files are supported.")
            else:
                seq_list.append(str(seq_dict[list(seq_dict.keys())[0]].seq))
                header_list.append(list(seq_dict.keys())[0])
        with open(out, 'w') as outfile:
            outfile.write(">"+'_'.join(header_list)+'\n'+":".join(seq_list))




if __name__ == '__main__':
    from Bio import SeqIO
    main()
