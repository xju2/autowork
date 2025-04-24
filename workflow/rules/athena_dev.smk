
rule build_atlasexternal:
    input:
        "projects/athena/external.config.{ath_dev_name}.json"
    output:
        "projects/athena/external.{ath_dev_name}.built"
    log:
        "projects/athena/external.{ath_dev_name}.built.log"
    params:
        container_name = config["athena_dev_gpu_container"],
    threads:
        16
    shell:
        """shifter --image={params.container_name} --module=cvmfs,gpu \
          workflow/scripts/local_athena.sh -m build_external \
            -i "{input}" \
            -t {threads} \
            -o "{output}" \
            > "{log}" 2>&1
        """

rule build_athena_with_external:
    input:
        "projects/athena/external.{ath_dev_name}.built"
    output:
        "projects/athena/athena_external.{ath_dev_name}.built"
    log:
        "projects/athena/athena_external.{ath_dev_name}.built.log"
    params:
        container_name = config["athena_dev_gpu_container"],
    threads:
        16
    shell:
        """shifter --image={params.container_name} --module=cvmfs,gpu \
        workflow/scripts/build_athena_with_external.sh -i "{input}" -o "{output}" \
          -t {threads} > "{log}" 2>&1
        """

rule test_athena_with_external:
    input:
        "projects/athena/config.{ath_dev_name}.json",
        "projects/athena/athena_external.{ath_dev_name}.built"
    output:
        "projects/athena/test_athena_with_external.{ath_dev_name}.tested"
    log:
        "projects/athena/test_athena_with_external.{ath_dev_name}.tested.log"
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
        "projects/athena/config.{ath_dev_name}.json"
    output:
        "projects/athena/athena.{ath_dev_name}.built"
    params:
        container_name = config["athena_dev_gpu_container"],
    log:
        "projects/athena/athena.{ath_dev_name}.built.log"
    threads:
        16
    shell:
        """shifter --image={params.container_name} --module=cvmfs,gpu \
        workflow/scripts/local_athena.sh -i "{input}" -o "{output}" -t {threads} \
        > "{log}" 2>&1
        """

rule validate_custom_athena:
    input:
        "projects/athena/config.{ath_dev_name}.json",
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
