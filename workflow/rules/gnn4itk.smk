rule run_legacy_ckf:
    input:
        "projects/gnn4itk/rdo_files.{dataset}.txt",
    output:
        "workarea/gnn4itk/{dataset}/aod.ckf.{dataset}.root",
    log:
        "projects/gnn4itk/run_legacy_ckf.{dataset}.log",
    params:
        max_evts = 1,
    threads:
        6
    shell:
        """shifter --image={config[athena_dev_container]} --module=cvmfs \
        workflow/scripts/run_tracking.sh -i "{input}" \
        -j {threads} \
        -m {params.max_evts} \
        -o "{output}" > "{log}" 2>&1 \
        """
