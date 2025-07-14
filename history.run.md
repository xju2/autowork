2025-07-12
```bash
snakemake --cores 6 --config samples='["MuonPU0","PionPU0"]' max_evts=-1 -p --set-threads run_idpvm=4 run_gnn4itk_triton=1 --force --dry-run

snakemake --cores 6 --config samples='["ttbar"]' max_evts=400 -p --set-threads run_idpvm=4 run_gnn4itk_triton=1 --force --dry-run
```
