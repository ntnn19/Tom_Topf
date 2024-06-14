import click
@click.command()
@click.argument('input', type=click.Path(exists=True), args=-1, required=True)
@click.argument('out', type=click.Path(), required=True)
def main(input, out):
