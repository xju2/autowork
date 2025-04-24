rule run_legacy_ckf:
    input:
        "projects/tracking/rdo_files.{dataset}.txt",
    output:
        "workarea/tracking/{dataset}/aod.ckf.{dataset}.root",
    log:
        "projects/tracking/run_legacy_ckf.{dataset}.log",
    params:
        max_evts = 1,
        container_name = config["athena_dev_container"],
        chain_name = "CKF_LEGACY",
    threads:
        6
    shell:
        """shifter --image={params.container_name} --module=cvmfs \
        workflow/scripts/run_tracking.sh -i "{input}" \
        -j {threads} \
        -m {params.max_evts} \
        -c {params.chain_name} \
        -o "{output}" > "{log}" 2>&1 \
        """

datasets = ["ttbar"]
rule run_gnn4itk_ml_local:
    input:
        "projects/athena/athena.default.gnn4itkTool.built",
        "projects/tracking/rdo_files.{dataset}.txt",
    output:
        "workarea/tracking/{dataset}/aod.gnn4itkMLLocal.{dataset}.root",
    log:
        "projects/tracking/run_gnn4itk_ml_local.{dataset}.log",
    params:
        max_evts = 1,
        container_name = config["athena_dev_gpu_container"],
        chain_name = "GNN4ITk_ML_LOCAL",
    threads:
        1
    shell:
        """shifter --image={params.container_name} --module=cvmfs,gpu \
        workflow/scripts/run_tracking.sh -i "{input[1]}" \
        -j {threads} \
        -m {params.max_evts} \
        -c {params.chain_name} \
        -s {input[0]} \
        -o "{output}" > "{log}" 2>&1 \
        """

rule run_gnn4itk_ml_local_external:
    input:
        "projects/athena/athena.ortCUDA.{ath_dev_name}.built",
        "projects/tracking/rdo_files.{dataset}.txt",
    output:
        "workarea/tracking/{dataset}/aod.ortCUDA.gnn4itkTool.{dataset}.root",
    log:
        "projects/tracking/log.run_gnn4itk_ml_local_external.{dataset}.txt",
    params:
        max_evts = 1,
        container_name = config["athena_dev_gpu_container"],
        chain_name = "GNN4ITk_ML_LOCAL_EXTERNAL",
    threads:
        1
    shell:
        """shifter --image={params.container_name} --module=cvmfs,gpu \
        workflow/scripts/run_tracking.sh -i "{input[1]}" \
        -j {threads} \
        -m {params.max_evts} \
        -c {params.chain_name} \
        -s {input[0]} \
        -o "{output}" > "{log}" 2>&1 \
        """