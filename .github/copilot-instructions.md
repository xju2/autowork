# Autowork - HEP Workflow Instructions

Autowork is a HEP (High Energy Physics) workflow based on Snakemake for ATLAS/Athena software development and GNN4ITk particle tracking analysis.

Always reference these instructions first and fallback to search or bash commands only when you encounter unexpected information that does not match the info here.

## Working Effectively

### Bootstrap and Setup
- Install Snakemake: `pip install snakemake`
- Install conda for environment management (required for notebook execution)
- Basic workflow validation: `snakemake --dry-run --cores 1` -- takes <1 second
- Simple test: `snakemake hello --cores 1 --sdm conda` -- takes 45-60 seconds (conda environment creation)

### Understanding the Environment Requirements
**CRITICAL**: This workflow is designed for HEP computing infrastructure (NERSC, CVMFS, specialized containers).

**What works in standard environments:**
- Basic Snakemake commands and dry-runs
- Workflow linting: `snakemake --lint`
- Rule listing: `snakemake --list`
- Code change tracking: `snakemake --list-changes code`
- Simple notebook execution (hello rule)

**What requires specialized HEP infrastructure:**
- All Athena builds and external dependency compilation
- Particle tracking workflows
- Container-based execution (shifter/apptainer)
- CVMFS filesystem access
- GPU-accelerated tracking jobs

### Build Commands and Timing

**NEVER CANCEL builds or long-running commands. Builds may take up to 4+ hours.**

#### Athena External Dependencies
```bash
snakemake projects/athena/athena.external.ortCUDA.default.built.json
```
- **TIMEOUT: Set 5+ hours (300+ minutes). NEVER CANCEL.**
- Uses 32 workers by default (-j32)
- Runs on specialized HEP infrastructure only
- Requires CVMFS and Atlas software stack

#### Basic Tracking Workflows
```bash
# Setup Athena development environment
snakemake setup_athena --cores 1

# Run tracking analysis (requires built Athena)
snakemake workarea/tracking/ZmumuPU200/idpvm.gnn4itkTriton.tracking.ZmumuPU200.root --config max_evts=100

# Run all tracking processes
snakemake --config max_evts=1000
```
- **TIMEOUT: Set 4+ hours (240+ minutes) for each command. NEVER CANCEL.**
- Tracking jobs allocate 4:00:00 on NERSC
- GPU jobs require specialized partition access

#### Triton Server Operations
```bash
# Start Triton inference server
snakemake --cores 6 results/triton/triton_server.tracking.ready.txt

# Triton client validation
snakemake --cores 2 workarea/tracking/MuonPU0/aod.gnn4itkML.triton.gnn4itkTriton.tracking.MuonPU0.root --dry-run --config max_evts=10
```
- **TIMEOUT: Set 2+ hours (120+ minutes). NEVER CANCEL.**
- Requires GPU resources and specialized containers

### Testing and Validation

#### Basic Workflow Validation (works everywhere)
```bash
# Test workflow syntax
snakemake --lint

# Test basic notebook execution
snakemake hello --cores 1 --sdm conda

# Dry run of main workflow
snakemake --dry-run --cores 1
```
- All commands complete in <2 minutes
- No specialized infrastructure required

#### Full HEP Validation (requires NERSC/CVMFS)
```bash
# Validate Athena installation
snakemake --cores 6 results/athena/athena.default.debugTriton11.validated.txt

# Test complete tracking pipeline
snakemake --cores 6 --config samples='["MuonPU0","PionPU0"]' max_evts=-1 -p --set-threads run_idpvm=4 run_gnn4itk_triton=1
```
- **TIMEOUT: Set 4+ hours (240+ minutes). NEVER CANCEL.**
- Requires NERSC account and specialized containers

### Linting and Code Quality

**Limited linting available without external dependencies:**
```bash
# Workflow linting (works everywhere)
snakemake --lint

# YAML validation via pre-commit (if available)
pre-commit run check-yaml --all-files
```

**Note**: Standard Python linting tools (ruff, black) are not applicable as this is primarily a Snakemake workflow repository.

### Common Workflow Patterns

#### Thread Control
```bash
# Set specific thread allocation for rules
snakemake --cores 12 --set-threads run_idpvm=12 workarea/tracking/ttbar/idpvm.ckf.primary.local.gnn4itkTriton.none.ttbar.root -p
```

#### Configuration Overrides
```bash
# Override samples and event counts
snakemake --cores 6 --config samples='["ttbar"]' max_evts=400 -p --set-threads run_idpvm=4 run_gnn4itk_triton=1
```

#### Code Change Tracking
```bash
# List code changes (for rerun triggers)
snakemake --list-changes code

# Rerun based on code changes
snakemake -R `snakemake --list-changes code`
```

## Repository Structure

### Key Directories
```
workflow/
├── Snakefile          # Main workflow entry point
├── rules/             # Snakemake rule definitions
│   ├── athena_dev.smk # Athena build rules
│   ├── tracking.smk   # Particle tracking workflows
│   ├── triton.smk     # ML inference server rules
│   └── test.smk       # Test and validation rules
├── scripts/           # Build and execution scripts
├── envs/              # Conda environment definitions
└── notebooks/         # Jupyter notebooks

config/
└── config.yaml        # Main configuration

projects/              # Project-specific configurations
results/               # Build artifacts and outputs
workarea/              # Analysis working directories
```

### Critical Files to Monitor
- `config/config.yaml` - Main workflow configuration
- `pyproject.toml` - Python project metadata
- `.pre-commit-config.yaml` - Code quality hooks
- `workflow/scripts/build_athena.sh` - Main Athena build script
- `workflow/scripts/local_athena.sh` - Local development build script

### Configuration Overview
- Default samples: `["MuonPU0", "ElectronPU0", "PionPU0"]`
- NERSC project: `m3443`
- Container images: Atlas OS containers for CPU/GPU workloads
- Default max events: 1 (for testing)

## Infrastructure Requirements

### Required for Full Functionality
- NERSC/Perlmutter access with account allocation
- CVMFS filesystem (/cvmfs/atlas.cern.ch, /cvmfs/sft.cern.ch)
- Container runtime (shifter/apptainer)
- GPU access for ML inference
- Atlas collaboration member access

### Available in Standard Environments
- Basic Snakemake workflow validation
- Configuration file editing
- Rule syntax checking
- Dry-run execution
- Simple notebook processing

## Common Issues and Solutions

### Build Failures
- **Always check CVMFS availability first**: `ls /cvmfs/atlas.cern.ch`
- **Verify container access**: Check shifter/apptainer availability
- **Check disk space**: Builds require substantial disk space (100+ GB)
- **Validate networking**: Atlas externals require network access

### Timeout Issues
- **NEVER reduce build timeouts below 4 hours**
- **Use appropriate thread counts**: Default 32 for builds, adjust based on available cores
- **Monitor resource allocation**: NERSC jobs have strict time/memory limits

### Development Workflow
- **Always test with dry-run first**: `snakemake --dry-run`
- **Use small event counts for testing**: `--config max_evts=10`
- **Validate individual rules**: `snakemake rule_name --dry-run`
- **Check logs for failures**: Logs are in `logs/` directory with detailed error information

## Performance Expectations

### Command Timing (Standard Environment)
- `snakemake --version`: <1 second
- `snakemake --list`: <1 second  
- `snakemake --dry-run --cores 1`: <1 second
- `snakemake hello --cores 1 --sdm conda`: 45-60 seconds (first time, conda setup)
- `snakemake --lint`: <1 second

### Build Timing (HEP Infrastructure)
- **Atlas external build**: 2-4 hours - **NEVER CANCEL**
- **Athena compilation**: 1-2 hours - **NEVER CANCEL** 
- **Tracking analysis**: 30 minutes - 2 hours depending on event count
- **Triton server startup**: 5-15 minutes
- **Full workflow**: 4+ hours - **NEVER CANCEL**

**CRITICAL**: Always set timeouts to 300+ minutes (5+ hours) for any build commands. Do not cancel long-running builds as they are expected to take several hours.