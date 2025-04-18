rule validate_triton:
    input:
        "projects/triton/triton_server.json"
    output:
        "projects/triton/validate_triton.out"
    params:
        source_dir = config["triton_source_dir"],
        triton_common_version = "a6b410343234f9acaa5d615c19f5b38690b45dff",
        triton_core_version = "ce46b95dcaa860a524f91324c146877c018dcf13",
        client_version = "r24.12",
        container_name = config["athena_dev_gpu_container"],
    log:
        "projects/triton/validate_triton.log"
    shell:
        """shifter --image={params.container_name} --module=cvmfs,gpu \
        workflow/scripts/validate_triton.sh \
        -c {params.triton_common_version} \
        -k {params.triton_core_version} \
        -t {params.client_version} \
        -d {params.source_dir} \
        -o "{output}"
        """
