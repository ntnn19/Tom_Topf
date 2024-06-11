# Improving the quality AlphaFold predicted protein complex structure by MSA optimization

- ## The goal of this project is obtain better AlphaFold models for XYZ complex, in terms of the following scores:
  - ipTM score
  - pTM score
  - PAE score
  - pLDDT score

## MSA optimization strategies
### Strategies implemented thus far:
#### Default strategy
```mermaid
graph LR;
    multi_sequence_fasta --> colabfold_search --> a3m2multi.sh --> colabfold_batch --> Output;
```
#### Strategy #1 (Tom)
```mermaid
graph LR;
  id1["`**DB:** Orthoherpesviridae_protein_seqs_fasta`"]  --> jackhmmer --> a3m2multi.sh --> colabfold_batch --> Output;
  id2["`**Query:** multi_sequence_fasta`"] --> jackhmmer
%%  id1[DB: Orthoherpesviridae_protein_seqs_fasta\nQuery: multi_sequence_fasta]  --> jackhmmer --> a3m2multi.sh --> colabfold_batch --> Output;
```






