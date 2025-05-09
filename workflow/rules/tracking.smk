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
rule run_gnn4itk_local:
    input:
        ath_cfg="projects/athena/athena.default.gnn4itkTool.built.json",
        data_cfg="projects/tracking/rdo_files.{dataset}.txt",
    output:
        "workarea/tracking/{dataset}/aod.gnn4itkMLLocal.{dataset}.root",
    log:
        "projects/tracking/gnn4itk_local.{dataset}.log",
    params:
        max_evts = 1,
        container_name = config["athena_dev_gpu_container"],
        chain_name = "GNN4ITk_ML_LOCAL",
    threads:
        1
    shell:
        """shifter --image={params.container_name} --module=cvmfs,gpu \
        workflow/scripts/run_tracking.sh -i "{input.data_cfg}" \
        -j {threads} \
        -m {params.max_evts} \
        -c {params.chain_name} \
        -s {input.ath_cfg} \
        -o "{output}" > "{log}" 2>&1 \
        """

rule run_gnn4itk_local_external:
    input:
        ath_config="projects/athena/athena.{ex_dev_name}.{ath_dev_name}.built.json",
        data_cfg="projects/tracking/rdo_files.{dataset}.txt",
    output:
        "workarea/tracking/{dataset}/aod.gnn4itkML.local.{ex_dev_name}.{ath_dev_name}.{dataset}.root",
    log:
        "projects/tracking/gnn4itk_local_external.{ex_dev_name}.{ath_dev_name}.{dataset}.log",
    params:
        max_evts = 1,
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
        workflow/scripts/run_tracking.sh -i "{input.data_cfg}" \
        -j {params.workers} \
        -m {params.max_evts} \
        -c {params.chain_name} \
        -s {input.ath_config} \
        -o "{output}" > "{log}" 2>&1 \
        """

rule run_gnn4itk_triton:
    input:
        ath_cfg="projects/athena/athena.default.{ath_dev_name}.built.json",
        data_cfg="projects/tracking/rdo_files.{dataset}.txt",
        server_cfg="projects/triton/triton_server.{triton_dev_name}.ready.txt",
    output:
        "workarea/tracking/{dataset}/aod.gnn4itkML.triton.{ath_dev_name}.{triton_dev_name}.{dataset}.root",
    log:
        "projects/tracking/gnn4itkML.triton.{ath_dev_name}.{triton_dev_name}.{dataset}.log",
    params:
        max_evts = -1,
        container_name = config["athena_dev_gpu_container"],
        model_name = "MetricLearning",
    threads:
        1
    shell:
        """shifter --image={params.container_name} --module=cvmfs,gpu \
        workflow/scripts/run_tracking.sh -i "{input.data_cfg}" \
        -j {threads} \
        -m {params.max_evts} \
        -c "GNN4ITk_ML_TRITON" \
        -s {input.ath_cfg} \
        -u `cat {input.server_cfg}` \
        -p {params.model_name} \
        -o "{output}" > "{log}" 2>&1 \
        """

rule run_idpvm:
    input:
        ath_cfg="projects/athena/athena.default.{ath_dev_name}.built.json",
        aod_file="workarea/tracking/{dataset}/aod.gnn4itkML.triton.{ath_dev_name}.{dev_conf_name}.{dataset}.root",
    output:
        "workarea/tracking/{dataset}/idpvm.{ath_dev_name}.{dev_conf_name}.{dataset}.root",
    log:
        "projects/tracking/idpvm.{ath_dev_name}.{dev_conf_name}.{dataset}.log",
    params:
        max_evts = -1,
        container_name = config["athena_dev_gpu_container"],
    threads:
        6
    shell:
        """shifter --image={params.container_name} --module=cvmfs,gpu \
        workflow/scripts/run_idpvm.sh -i "{input.aod_file}" \
        -s {input.ath_cfg} \
        -j {threads} \
        -m {params.max_evts} \
        -o "{output}" > "{log}" 2>&1 \
        """
