
rule build_atlasexternal:
    output:
        "build_atlasexternal.out"
    params:
        source_dir = "/pscratch/sd/x/xju/athena_dev/triton_20240923"
    shell:
        "shifter --image={config[athena_dev_container]} --module=cvmfs workflow/scripts/build_atlasexternal.sh {output} {params.source_dir} "
        # "echo 'Setting up Athena environment' > {output} && uname -a >> {output}"
