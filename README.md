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