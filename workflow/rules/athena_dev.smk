
rule build_atlasexternal:
    output:
        "projects/atlasexternal/build_atlasexternal.out"
    params:
        source_dir = config["atlas_external_source_dir"],
        external_url = "https://gitlab.cern.ch/xju/atlasexternals.git",
        external_ref = "origin/triton_disable_typeinfo",
        extra_cmake_config_args = "-DATLAS_ONNXRUNTIME_USE_CUDA=True -DCUDNN_INCLUDE_DIR=/usr/include -G Ninja -DCMAKE_EXPORT_COMPILE_COMMANDS=TRUE",
        container_name = config["athena_dev_gpu_container"],
    threads:
        16
    shell:
        """shifter --image={params.container_name} --module=cvmfs,gpu \
          workflow/scripts/build_athena.sh \
            -u {params.external_url} \
            -r {params.external_ref} \
            -d "{params.source_dir}" \
            -j {threads} \
            -o "{output}" \
            -x "{params.extra_cmake_config_args}"
        """

rule build_athena_with_external:
    input:
        "build_atlasexternal.out"
    output:
        "build_athena_with_external.out"
    params:
        source_dir = config["atlas_external_source_dir"],
        container_name = config["athena_dev_gpu_container"],
    threads:
        16
    shell:
        """shifter --image={params.container_name} --module=cvmfs,gpu \
        workflow/scripts/build_athena.sh -a -d {params.source_dir} \
          -j {threads} -o "{output}"
        """

rule test_athena_with_external:
    input:
        "build_athena_with_external.out"
    output:
        "test_athena_with_external.out"
    params:
        source_dir = config["atlas_external_source_dir"],
        release = "25.0.30",
        container_name = config["athena_dev_gpu_container"],
    shell:
        """shifter --image={params.container_name} --module=cvmfs,gpu \
        workflow/scripts/test_athena.sh -d {params.source_dir} -o "{output}"
        """

build_runs = ["gnn4itkTool", "mr_tritontool"]

rule build_custom_athena:
    input:
        "projects/athena/custom_config.mr_tritontool.json"
    output:
        "projects/athena/custom_config.mr_tritontool.built"
    params:
        container_name = config["athena_dev_gpu_container"],
    log:
        "projects/athena/custom_config.mr_tritontool.built.log"
    threads:
        16
    shell:
        """shifter --image={params.container_name} --module=cvmfs,gpu \
        workflow/scripts/local_athena.sh -i "{input}" -o "{output}" -t {threads} \
        > "{log}" 2>&1
        """

rule validate_custom_athena:
    input:
        "projects/athena/custom_config.mr_tritontool.json",
        "projects/athena/custom_config.mr_tritontool.built"
    output:
        "projects/athena/custom_config.mr_tritontool.validated"
    params:
        container_name = config["athena_dev_gpu_container"]
    log:
        "projects/athena/custom_config.mr_tritontool.validated.log"
    threads:
        4
    shell:
        """shifter --image={params.container_name} --module=cvmfs,gpu \
        workflow/scripts/local_athena.sh -i {input[0]} -o "{output}" -m run -t {threads} \
        > "{log}" 2>&1
        """
