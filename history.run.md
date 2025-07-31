## 2025-07-25
Validate the AthenaTriton with GNN4ITk as a Service.
```bash
snakemake --cores 6 results/athena/athena.default.mainValidateAthenaTritonWithGNN4ITk.release_validated.txt
snakemake --cores 6 results/athena/athena.default.debugTriton11.validated.txt
```

## 2025-07-18
Make the GNN4ITk ready. The NERSC Triton server is running on the port 443.
```bash
snakemake --cores 6 results/athena/athena.default.gnn4itkMoreOpt.built.json

snakemake --cores 2 workarea/tracking/MuonPU0/aod.gnn4itkML.triton.gnn4itkMoreOpt.tracking.MuonPU0.root --config max_evts=2 --set-threads run_gnn4itk_triton=1 -p
```

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
