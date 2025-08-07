# Git Worktree Support for Athena Development

This enhancement adds support for using git worktrees for Athena development, which provides significant space efficiency compared to the traditional approach of separate repository clones.

## Overview

### Traditional Approach (Still Supported)
Each Athena development uses a separate directory with its own full repository clone:

```json
{
    "source_dir": "/pscratch/sd/x/xju/athena_dev/20250725_debugTriton",
    "athena_repository": "ssh://git@gitlab.cern.ch:7999/xju/athena.git", 
    "athena_tag": "changeTritonInterface",
    "release": "Athena,main,latest,here",
    "packages": [
        "Control/AthTriton/AthTritonComps",
        "InnerDetector/InDetGNNTracking"
    ]
}
```

### New Worktree Approach
Multiple Athena developments share a single repository's git history but have separate working directories:

```json
{
    "worktree_base_dir": "/pscratch/sd/x/xju/athena_worktrees",
    "worktree_name": "triton_debug_dev", 
    "athena_repository": "ssh://git@gitlab.cern.ch:7999/xju/athena.git",
    "athena_tag": "changeTritonInterface",
    "release": "Athena,main,latest,here",
    "packages": [
        "Control/AthTriton/AthTritonComps",
        "InnerDetector/InDetGNNTracking"
    ]
}
```

## Benefits of Worktree Approach

1. **Space Efficiency**: The `.git` directory is shared between all worktrees, saving significant disk space
2. **Faster Setup**: New worktrees are created faster than full clones
3. **Centralized Management**: All developments share the same git history and references
4. **Isolation**: Each development still has its own working directory and can check out different branches/tags

## Configuration Fields

### Required for Worktree Mode
- `worktree_base_dir`: Base directory where the main repository and all worktrees will be created
- `worktree_name`: Unique name for this specific worktree (used as subdirectory name)
- `athena_repository`: Git repository URL (required for initial clone)
- `athena_tag`: Branch or tag to checkout in this worktree

### Traditional Mode (Backward Compatible)
- `source_dir`: Full path to the development directory
- `athena_repository`: Git repository URL (optional, only used if directory needs to be created)
- `athena_tag`: Branch or tag to checkout (optional)

## Directory Structure

### Worktree Mode
```
/pscratch/sd/x/xju/athena_worktrees/
├── athena-main/          # Main repository (shared .git)
├── triton_debug_dev/     # Worktree 1
├── gnn4itk_tool_dev/     # Worktree 2
└── feature_branch_dev/   # Worktree 3
```

### Traditional Mode  
```
/pscratch/sd/x/xju/athena_dev/
├── 20250725_debugTriton/ # Full clone 1
├── gnn4itk_20250423/     # Full clone 2
└── feature_branch/       # Full clone 3
```

## Examples

### Example 1: GNN4ITK Development with Worktree
```json
{
    "worktree_base_dir": "/pscratch/sd/x/xju/athena_worktrees",
    "worktree_name": "gnn4itk_tool_dev",
    "athena_repository": "ssh://git@gitlab.cern.ch:7999/atlas/athena.git",
    "athena_tag": "main",
    "release": "Athena,main,latest,here",
    "packages": [
        "InnerDetector/InDetGNNTracking"
    ]
}
```

### Example 2: Triton Debug Development with Worktree
```json
{
    "worktree_base_dir": "/pscratch/sd/x/xju/athena_worktrees", 
    "worktree_name": "triton_debug_dev",
    "athena_repository": "ssh://git@gitlab.cern.ch:7999/xju/athena.git",
    "athena_tag": "changeTritonInterface",
    "release": "Athena,main,latest,here",
    "packages": [
        "Control/AthTriton/AthTritonComps",
        "InnerDetector/InDetGNNTracking",
        "Control/AthenaExamples/AthExTriton"
    ]
}
```

## Implementation Notes

- The system automatically detects whether to use worktree or traditional mode based on the presence of `worktree_base_dir` and `worktree_name` fields
- Backward compatibility is maintained - existing configurations continue to work unchanged
- The main repository is created at `{worktree_base_dir}/athena-main`
- Individual worktrees are created at `{worktree_base_dir}/{worktree_name}`
- Submodules are automatically updated in both main repository and worktrees
- The build system adapts the source path automatically based on the mode being used