
rule build_atlasexternal:
    input:
        "projects/athena/external.config.{ex_dev_name}.json"
    output:
        "results/athena/external.{ex_dev_name}.built.json"
    log:
        "logs/athena/external.{ex_dev_name}.built.log"
    params:
        container_name = config["athena_dev_gpu_container"],
        mpi = "srun",
        atime = "4:00:00",
        nodes = 1,
        account = config.get("nersc_project_name", "m3443"),
        partition = "cpu",
        queue = "interactive",
        workers = 32
    shell:
        """{params.mpi} -N {params.nodes} -A {params.account} \
        -t {params.atime} \
        -q {params.queue} \
        -C {params.partition} -c 128 -n 1 \
        shifter --image={params.container_name} --module=cvmfs,gpu \
          workflow/scripts/local_athena.sh -m build_external \
            -i "{input}" \
            -t {params.workers} \
            -o "{output}" \
            > "{log}" 2>&1
        """

rule build_athena_with_external:
    input:
        "results/athena/external.{ex_dev_name}.built.json"
    output:
        "results/athena/athena.external.{ex_dev_name}.default.built.json"
    log:
        "logs/athena/athena.external.{ex_dev_name}.default.built.log"
    params:
        container_name = config["athena_dev_gpu_container"],
        mpi = "srun",
        nodes = 1,
        account = config.get("nersc_project_name", "m3443"),
        atime = "4:00:00",
        queue = "interactive",
        partition = "cpu",
        workers = 32
    resources:
        tasks = 1
    shell:
        """{params.mpi} -N {params.nodes} -A {params.account} \
        -t {params.atime} \
        -q {params.queue} \
        -C {params.partition} -c 128 -n 1 \
        shifter --image={params.container_name} --module=cvmfs,gpu \
        workflow/scripts/local_athena.sh -m build_external_athena \
          -i "{input}" -o "{output}" \
          -t {params.workers} > "{log}" 2>&1
        """

ath_dev_names = ["gnn4itkTool", "mr_tritontool"]

rule build_custom_athena:
    input:
        "projects/athena/athena.config.{ath_dev_name}.json"
    output:
        "results/athena/athena.default.{ath_dev_name}.built.json"
    params:
        container_name = config["athena_dev_gpu_container"],
    log:
        "logs/athena/athena.default.{ath_dev_name}.built.log"
    threads:
        16
    shell:
        """shifter --image={params.container_name} --module=cvmfs,gpu \
        workflow/scripts/local_athena.sh -m build_athena \
        -i "{input}" -o "{output}" -t {threads} \
        > "{log}" 2>&1
        """

rule build_custom_athena_with_external:
    input:
        "projects/athena/athena.config.{ath_dev_name}.json",
        "results/athena/athena.external.{ex_dev_name}.default.built.json",
    output:
        "results/athena/athena.external.{ex_dev_name}.{ath_dev_name}.built.json"
    params:
        container_name = config["athena_dev_gpu_container"],
    log:
        "logs/athena/athena.{ex_dev_name}.{ath_dev_name}.built.log"
    threads:
        16
    shell:
        """shifter --image={params.container_name} --module=cvmfs,gpu \
        workflow/scripts/local_athena.sh -m build_athena \
        -i "{input[0]}" -o "{output}" -t {threads} \
        -s "{input[1]}" \
        > "{log}" 2>&1
        """

rule validate_custom_athena:
    input:
        "projects/athena/athena.config.{ath_dev_name}.json",
        "results/athena/athena.default.{ath_dev_name}.built.json"
    output:
        "results/athena/athena.default.{ath_dev_name}.validated.txt"
    params:
        container_name = config["athena_dev_gpu_container"]
    log:
        "logs/athena/athena.default.{ath_dev_name}.validated.log"
    threads:
        4
    shell:
        """shifter --image={params.container_name} --module=cvmfs,gpu \
        workflow/scripts/local_athena.sh -m run_athena \
        -i {input[0]} -o "{output}" -t {threads} \
        > "{log}" 2>&1
        """
