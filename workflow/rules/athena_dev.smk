
rule build_atlasexternal:
    output:
        "build_atlasexternal.out"
    params:
        source_dir = "/pscratch/sd/x/xju/athena_dev/check_ort_cuda",
        external_url = "https://gitlab.cern.ch/atlas/atlasexternals.git",
        external_ref = "origin/main",
        num_workers = 32,
    shell:
        "shifter --image={config[athean_dev_gpu_container]} --module=cvmfs workflow/scripts/build_atlasexternal.sh -u {params.external_url} -r {params.external_ref} -d {params.source_dir} -j {params.num_workers} -o {output[0]}"
