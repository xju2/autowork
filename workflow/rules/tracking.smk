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

rule run_gnn4itk_ml_local:
    input:
        "projects/tracking/rdo_files.{dataset}.txt",
    output:
        "workarea/tracking/{dataset}/aod.gnn4itkMLLocal.{dataset}.root",
    log:
        "projects/tracking/run_gnn4itk_ml_local.{dataset}.log",
    params:
        max_evts = 1,
        container_name = config["athena_dev_container"],
        chain_name = "GNN4ITk_ML_LOCAL",
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