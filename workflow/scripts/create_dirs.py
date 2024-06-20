import os.path

import click
@click.command()
@click.argument('config_file', type=click.Path(exists=True), required=True)
@click.argument('colabfold_weights_dir', type=click.Path(), required=True)
def main(config_file,colabfold_weights_dir):
    conf = yaml.safe_load(Path(config_file).read_text())
    DATA_DIR = conf["data_dir"]
    RESULTS_DIR = conf["output_dir"].split(",")
    os.makedirs(DATA_DIR, exist_ok=True)
    os.makedirs(colabfold_weights_dir, exist_ok=True)
    for d in RESULTS_DIR:
        os.makedirs(d, exist_ok=True)

if __name__ == '__main__':
    import yaml
    from pathlib import Path
    main()
