
rule build_atlasexternal:
    output:
        "build_atlasexternal.out"
    params:
        source_dir = "/pscratch/sd/x/xju/athena_dev/check_ort_cuda",
        external_url = "https://gitlab.cern.ch/atlas/atlasexternals.git",
        external_ref = "origin/main",
        num_workers = 32,
        extra_cmake_args = "-DATLAS_ONNXRUNTIME_USE_CUDA=True -DCUDNN_INCLUDE_DIR=/usr/include",
    shell:
        """shifter --image={config[athena_dev_gpu_container]} --module=cvmfs,gpu \
          workflow/scripts/build_athena.sh \
            -u {params.external_url} \
            -r {params.external_ref} \
            -d "{params.source_dir}" \
            -j {params.num_workers} \
            -o "{output[0]}" \
            -x "{params.extra_cmake_args}"
        """


rule build_athena_with_external:
    input:
        "build_atlasexternal.out"
    output:
        "build_athena_with_external.out"
    params:
        source_dir = "/pscratch/sd/x/xju/athena_dev/check_ort_cuda",
        num_workers = 32,
    shell:
        """shifter --image={config[athena_dev_gpu_container]} --module=cvmfs,gpu \
        workflow/scripts/build_athena.sh -a -d {params.source_dir} \
          -j {params.num_workers} -o "{output[0]}"
        """

rule test_athena_with_external:
    input:
        "build_athena_with_external.out"
    output:
        "test_athena_with_external.out"
    params:
        source_dir = "/pscratch/sd/x/xju/athena_dev/check_ort_cuda",
        release = "25.0.30",
    shell:
        """shifter --image={config[athena_dev_gpu_container]} --module=cvmfs,gpu \
        workflow/scripts/test_athena.sh -d {params.source_dir} -o "{output[0]}"
        """

rule build_traccc:
    output:
        "build_traccc.out"
    params:
        source_dir = "/pscratch/sd/x/xju/code/G-200",
        num_workers = 32,
    shell:
        "shifter --image={config[athean_dev_gpu_container]} --module=cvmfs,gpu workflow/scripts/build_traccc.sh -d {params.source_dir} -j {params.num_workers} -o {output[0]}"

rule run_traccc:
    input:
        "build_traccc.out"
    output:
        "run_traccc.out"
    params:
        source_dir = "/pscratch/sd/x/xju/code/G-200",
        num_workers = 32,
    shell:
        "shifter --image={config[athean_dev_gpu_container]} --module=cvmfs,gpu workflow/scripts/run_traccc.sh -d {params.source_dir} -j {params.num_workers} -o {output[0]}"
