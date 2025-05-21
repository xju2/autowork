# autowork
HEP Workflow based on Snakemake

## Example usage

```bash
snakemake setup_athena --cores 1
```

```bash
snakemake workarea/tracking/ZmumuPU200/idpvm.gnn4itkTriton.tracking.ZmumuPU200.root --config max_evts=100
snakemake workarea/tracking/ZmumuPU200/idpvm.ckf.local.gnn4itkTriton.none.ZmumuPU200.root --config max_evts=100
```

Run all processes:
```bash
snakemake --config max_evts=1000
```

Build atlas with customized atlas externals.
```bash
snakemake projects/athena/athena.external.ortCUDA.default.built.json
```

Test Jupyter notebook
```bash
snakemake -c 1 --draft-notebook hello.txt --sdm conda
```

Code tracking
```bash
snakemake -R `snakemake --list-code-changes`
```

LRT tracking
```bash
snakemake --cores 6 workarea/tracking/HaaPU0/idpvm.ckfLRT.local.gnn4itkTriton.none.HaaPU0.root --config max_evts=-1
```