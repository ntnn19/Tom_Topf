# Improving the quality AlphaFold predicted protein complex structure by MSA optimization

## IMPORTANT: Other parameters also affect the quality of the resulting structures (TBD):
  - Number of recycles
  - Random seeds 
- ## The goal of this project is obtain better AlphaFold models for gH/gL/gD complex, w.r.t. the following scores:
  - ipTM score
  - pTM score
  - PAE score
  - pLDDT score

## MSA optimization strategies
### Strategies implemented thus far:
#### Default strategy
```mermaid
graph LR;
    gH/gL/gD_multi_sequence_fasta --> id1["colabfold_search
    Default params"] --> colabfold_batch --> Output;
```
#### Strategy #1 - Tom
```mermaid
graph LR;
  id1["`**DB:** Orthoherpesviridae_WGS`"]  --> jackhmmer --> a3m2multi.sh --> colabfold_batch --> Output;
  id2["`**Query:** gH/gL/gD_multi_sequence_fasta`"] --> jackhmmer
```
#### Strategy #2 - Variable MSA depth using colabfold_search
```mermaid
graph LR;
    gH/gL/gD_multi_sequence_fasta --> id1["colabfold_search
    max_msa = 16:32, 32:64, 64:128, 256:512, 512:1024"] --> colabfold_batch --> Output;
```
#### Strategy #3 - MSAs using WGS sequences at various levels of the taxonomic hierarchy
```mermaid
graph LR;
    id1["`**DB:**  Heunggongvirae(kingdom)/Herpesvirales(order)`"]  --> jackhmmer --> a3m2multi.sh --> colabfold_batch --> Output;
    id2["`**Query:** gH/gL/gD_multi_sequence_fasta`"] --> jackhmmer
```

#### Strategy #4 - MAFFT + uniref90/WGS + GUIDANCE 
```mermaid
graph LR;
  id1["`**DB:** uniref100`"]  --> jackhmmer --> a3m2multi.sh --> colabfold_batch --> Output;
  id2["`**Query:** gH/gL/gD_multi_sequence_fasta`"] --> jackhmmer
```

#### Strategy #5 - [MULTICOM3](https://www.nature.com/articles/s42004-023-00991-6#Tab3) 
```mermaid
graph LR;
  id2["`**Query:** gH/gL/gD_multi_sequence_fasta`"]  --> MULTICOM3 --> Output;
  
```

