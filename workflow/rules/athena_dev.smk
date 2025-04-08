
rule setup_athena:
    output:
        "setup_athena.out"
    container: "docker://{config[athena_dev_container]}"
    shell:
        "echo 'Setting up Athena environment' && pwd > {output}"
        # "shifter --image={config[athena_dev_container]}, --module=cvmfs bash -c \"echo 'Hello, world!'\""