rule start_triton_server_for_validation:
    output:
        "projects/triton/triton_server_for_validation.out"
    params:
        source_dir = "",
    threads: 2
    log:
        "projects/triton/start_triton_server_for_validation.log"
    shell:
        """workflow/scripts/start_triton_server_for_validation.sh \
        -d {params.source_dir} \
        -o "{output}" > "{log}" 2>&1
        """

rule validate_triton_client:
    input:
        "projects/triton/triton_server_for_validation.out"
    output:
        "projects/triton/validate_triton_client.out"
    params:
        source_dir = "",
        triton_common_version = "a6b410343234f9acaa5d615c19f5b38690b45dff",
        triton_core_version = "ce46b95dcaa860a524f91324c146877c018dcf13",
        client_version = "r24.12",
        container_name = config["athena_dev_gpu_container"],
    log:
        "projects/triton/validate_triton_client.log"
    threads: 4
    shell:
        """shifter --image={params.container_name} --module=cvmfs,gpu \
        workflow/scripts/validate_triton_client.sh \
        -c {params.triton_common_version} \
        -k {params.triton_core_version} \
        -t {params.client_version} \
        -d {params.source_dir} \
        -o "{output}" -i "{input}" > "{log}" 2>&1
        """
