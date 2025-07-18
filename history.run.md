## 2025-07-17
Debug the MuonSelection Tool
```bash
snakemake --cores 6 results/athena/athena.default.debugMuonSel.built.json
snakemake --cores 6 results/athena/athena.default.debugMuonSel.validated.txt
```

## 2025-07-12
```bash
snakemake --cores 6 --config samples='["MuonPU0","PionPU0"]' max_evts=-1 -p --set-threads run_idpvm=4 run_gnn4itk_triton=1 --force --dry-run

snakemake --cores 6 --config samples='["ttbar"]' max_evts=400 -p --set-threads run_idpvm=4 run_gnn4itk_triton=1 --force --dry-run
```
