rule all:
    input:
        "/pscratch/sd/x/xju/ITk/run_athena/aod.ckf.ttbar.root"

rule run_ttbar:
    input:
        "/pscratch/sd/x/xju/ITk/run_athena/aod.ckf.ttbar.root"
    output:
        "dummy_ttbar.out"
    log:
        "dummy_ttbar.log"
    shell:
        """echo "Hello World" > {output[0]} 2> {log[0]}"""


rule run_legacy_ckf:
    input:
        "projects/gnn4itk/rdo_files.{dataset}.txt"
    output:
        "/pscratch/sd/x/xju/ITk/run_athena/aod.ckf.{dataset}.root",
    log:
        "projects/gnn4itk/run_legacy_ckf.{dataset}.log"
    threads:
        6
    shell:
        """shifter --image={config[athena_dev_container]} --module=cvmfs \
        workflow/scripts/run_tracking.sh -i "{input[0]}" \
        -d "{params.work_dir}" \
        -j {threads} \
        -o "{output[0]} 2> {log[0]}" \
        """


