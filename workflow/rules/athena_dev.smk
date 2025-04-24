
rule build_atlasexternal:
    input:
        "projects/athena/external.config.{ex_dev_name}.json"
    output:
        "projects/athena/external.{ex_dev_name}.built"
    log:
        "projects/athena/external.{ex_dev_name}.built.log"
    params:
        container_name = config["athena_dev_gpu_container"],
    threads:
        32
    resources:
        mpi="srun",
        atime = "4:00:00",
        nodes = 1,
        account = "m3443",
        tasks = 32,
        partition = "gpu",
        gpu = 1,
        queue = "interactive"
    shell:
        """{resources.mpi} -N {resources.nodes} -G {resources.gpu} -A {resources.account} \
        -t {resources.atime} \
        -q {resources.queue} \
        -C {resources.partition} -c 32 \
        shifter --image={params.container_name} --module=cvmfs,gpu \
          workflow/scripts/local_athena.sh -m build_external \
            -i "{input}" \
            -t {threads} \
            -o "{output}" \
            > "{log}" 2>&1
        """

rule build_athena_with_external:
    input:
        "projects/athena/external.{ex_dev_name}.built"
    output:
        "projects/athena/athena.{ex_dev_name}.default.built"
    log:
        "projects/athena/athena.{ex_dev_name}.default.built.log"
    params:
        container_name = config["athena_dev_gpu_container"],
    threads:
        8
    shell:
        """shifter --image={params.container_name} --module=cvmfs,gpu \
        workflow/scripts/build_athena_with_external.sh -i "{input}" -o "{output}" \
          -t {threads} > "{log}" 2>&1
        """

rule ctest_athena_with_external:
    input:
        "projects/athena/athena.config.{ex_dev_name}.json",
        "projects/athena/athena.{ex_dev_name}.default.built"
    output:
        "projects/athena/test_athena_with_external.{ex_dev_name}.tested"
    log:
        "projects/athena/test_athena_with_external.{ex_dev_name}.tested.log"
    params:
        source_dir = config["atlas_external_source_dir"],
        release = "25.0.30",
        container_name = config["athena_dev_gpu_container"],
    shell:
        """shifter --image={params.container_name} --module=cvmfs,gpu \
        workflow/scripts/test_athena.sh -d {params.source_dir} -o "{output}"
        """

ath_dev_names = ["gnn4itkTool", "mr_tritontool"]

rule build_custom_athena:
    input:
        "projects/athena/athena.config.{ath_dev_name}.json"
    output:
        "projects/athena/athena.default.{ath_dev_name}.built"
    params:
        container_name = config["athena_dev_gpu_container"],
    log:
        "projects/athena/athena.default.{ath_dev_name}.built.log"
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
        "projects/athena/athena.{ex_dev_name}.default.built",
    output:
        "projects/athena/athena.{ex_dev_name}.{ath_dev_name}.built"
    params:
        container_name = config["athena_dev_gpu_container"],
    log:
        "projects/athena/athena.{ex_dev_name}.{ath_dev_name}.built.log"
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
        "projects/athena/athena.{ath_dev_name}.built"
    output:
        "projects/athena/athena.{ath_dev_name}.validated"
    params:
        container_name = config["athena_dev_gpu_container"]
    log:
        "projects/athena/athena.{ath_dev_name}.validated.log"
    threads:
        4
    shell:
        """shifter --image={params.container_name} --module=cvmfs,gpu \
        workflow/scripts/local_athena.sh -i {input[0]} -o "{output}" -m run -t {threads} \
        > "{log}" 2>&1
        """
