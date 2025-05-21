rule run_legacy_ckf:
    input:
        "results/athena/athena.default.{ath_dev_name}.built.json",
        "projects/tracking/rdo_files.{dataset}.txt",
    output:
        "workarea/tracking/{dataset}/aod.ckf.local.{ath_dev_name}.none.{dataset}.root",
    log:
        "logs/tracking/legacy_ckf.{ath_dev_name}.{dataset}.log",
    params:
        max_evts = config.get("max_evts", 1),
        container_name = config["athena_dev_container"],
    threads:
        6
    shell:
        """shifter --image={params.container_name} --module=cvmfs \
        workflow/scripts/run_tracking.sh -i "{input[1]}" \
        -j {threads} \
        -m {params.max_evts} \
        -c "CKF_LEGACY" \
        -s {input[0]} \
        -o "{output}" > "{log}" 2>&1 \
        """

rule run_legacy_ckf_lrt:
    input:
        "results/athena/athena.default.{ath_dev_name}.built.json",
        "projects/tracking/rdo_files.{dataset}.txt",
    output:
        "workarea/tracking/{dataset}/aod.ckfLRT.local.{ath_dev_name}.none.{dataset}.root",
    log:
        "logs/tracking/LRT-legacy_ckf.{ath_dev_name}.{dataset}.log",
    params:
        max_evts = config.get("max_evts", 1),
        container_name = config["athena_dev_container"],
    threads:
        6
    shell:
        """shifter --image={params.container_name} --module=cvmfs \
        workflow/scripts/run_tracking.sh -i "{input[1]}" \
        -j {threads} \
        -m {params.max_evts} \
        -c "CKF_LEGACY_LRT" \
        -s {input[0]} \
        -o "{output}" > "{log}" 2>&1 \
        """

datasets = ["ttbar"]
rule run_gnn4itk_local:
    input:
        "results/athena/athena.default.gnn4itkTool.built.json",
        "projects/tracking/rdo_files.{dataset}.txt",
    output:
        "workarea/tracking/{dataset}/aod.gnn4itkMLLocal.{dataset}.root",
    log:
        "logs/tracking/gnn4itk_local.{dataset}.log",
    params:
        max_evts = config.get("max_evts", 1),
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

rule run_gnn4itk_local_external:
    input:
        "results/athena/athena.{ex_dev_name}.{ath_dev_name}.built.json",
        "projects/tracking/rdo_files.{dataset}.txt",
    output:
        "workarea/tracking/{dataset}/aod.gnn4itkML.local.{ex_dev_name}.{ath_dev_name}.{dataset}.root",
    log:
        "logs/tracking/gnn4itk_local_external.{ex_dev_name}.{ath_dev_name}.{dataset}.log",
    params:
        max_evts = config.get("max_evts", 1),
        container_name = config["athena_dev_gpu_container"],
        chain_name = "GNN4ITk_ML_LOCAL",
        mpi = "srun",
        atime = "4:00:00",
        nodes = 1,
        gpu = 1,
        account = "m3443",
        partition = "gpu&hbm80g",
        queue = "interactive",
        workers = 1,
    shell:
        """{params.mpi} -N {params.nodes} -A {params.account} \
        -t "{params.atime}" \
        -q {params.queue} \
        -C "{params.partition}" -c 32 -n 1  -G 1 \
        shifter --image={params.container_name} --module=cvmfs,gpu \
        workflow/scripts/run_tracking.sh -i "{input[1]}" \
        -j {params.workers} \
        -m {params.max_evts} \
        -c {params.chain_name} \
        -s {input[0]} \
        -o "{output}" > "{log}" 2>&1 \
        """

rule run_gnn4itk_triton:
    input:
        "results/athena/athena.default.{ath_dev_name}.built.json",
        "projects/tracking/rdo_files.{dataset}.txt",
        "results/triton/triton_server.{triton_dev_name}.ready.txt"
    output:
        "workarea/tracking/{dataset}/aod.gnn4itkML.triton.{ath_dev_name}.{triton_dev_name}.{dataset}.root"
    log:
        "logs/tracking/gnn4itkML.triton.{ath_dev_name}.{triton_dev_name}.{dataset}.log"
    params:
        max_evts = config.get("max_evts", 1),
        container_name = config["athena_dev_gpu_container"],
        model_name = "MetricLearning",
    threads:
        1
    shell:
        """shifter --image={params.container_name} --module=cvmfs,gpu \
        workflow/scripts/run_tracking.sh -i "{input[1]}" \
        -j {threads} \
        -m {params.max_evts} \
        -c "GNN4ITk_ML_TRITON" \
        -s {input[0]} \
        -u `cat {input[2]}` \
        -p {params.model_name} \
        -o "{output}" > "{log}" 2>&1 \
        """

rule run_idpvm:
    input:
        "results/athena/athena.default.{ath_dev_name}.built.json",
        "workarea/tracking/{dataset}/aod.{chain_name}.{ath_mode}.{ath_dev_name}.{triton_dev_name}.{dataset}.root"
    output:
        "workarea/tracking/{dataset}/idpvm.{chain_name}.{ath_mode}.{ath_dev_name}.{triton_dev_name}.{dataset}.root",
    log:
        "logs/tracking/idpvm.{chain_name}.{ath_mode}.{ath_dev_name}.{triton_dev_name}.{dataset}.log",
    params:
        max_evts = -1,
        container_name = config["athena_dev_gpu_container"],
    threads:
        6
    shell:
        """shifter --image={params.container_name} --module=cvmfs,gpu \
        workflow/scripts/run_idpvm.sh -i "{input[1]}" \
        -s {input[0]} \
        -j {threads} \
        -m {params.max_evts} \
        -o "{output}" > "{log}" 2>&1 \
        """
