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

For triton jobs, you need to add `--cores 6 --latency-wait 30 --wait-for-files`


History:
```bash
snakemake --cores 6 workarea/tracking/MuonPU0/idpvm.gnn4itkML.triton.gnn4itkTriton.tracking.MuonPU0.root --config max_evts=-1
snakemake --cores 6 workarea/tracking/MuonPU0/idpvm.ckf.local.gnn4itkTriton.none.MuonPU0.root --config max_evts=-1

snakemake --cores 12 workarea/tracking/ttbar/idpvm.ckf.primary.local.gnn4itkTriton.none.ttbar.root -p

# in a Perlmutter CPU node, I run 4 samples in parallel to get IDPVM results.
snakemake --cores 128 --config max_evts=-1 --set-threads run_legacy_ckf=16 run_idpvm=16 run_gnn4itk_triton=1

snakemake --cores 16 --config max_evts=1000 -p --set-threads run_idpvm=4 run_gnn4itk_triton=1

snakemake --cores 6 results/tracking/idpvm.comparison.primary.ttbarPU0.txt -p --rerun-triggers mtime --sdm conda --force
```
I can set threads for the rule.
```bash
snakemake --cores 12 --set-threads run_idpvm=12 workarea/tracking/ttbar/idpvm.ckf.primary.local.gnn4itkTriton.none.ttbar.root -p
```