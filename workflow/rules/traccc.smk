rule build_traccc:
    output:
        "build_traccc.out"
    params:
        source_dir = config["traccc_source_dir"],
        num_workers = 32,
        container_name = config["athena_dev_gpu_container"],
    shell:
        """shifter --image={params.container_name} --module=cvmfs,gpu \
        workflow/scripts/build_traccc.sh -d "{params.source_dir}" \
        -j {params.num_workers} -o "{output}"
        """

rule run_traccc:
    input:
        "build_traccc.out"
    output:
        "run_traccc.out"
    params:
        source_dir = config["traccc_source_dir"],
        num_workers = 32,
        do_G300 = "true",
        container_name = config["athena_dev_gpu_container"],
    shell:
        """shifter --image={params.container_name} --module=cvmfs,gpu \
         workflow/scripts/run_traccc.sh -d "{params.source_dir}" \
         -j {params.num_workers} -o "{output}" \
         -g {params.do_G300}
         """
