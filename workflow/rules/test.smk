rule hello:
    output:
        "hello.txt"
    log:
        notebook="logs/notebooks/processed_notebook.ipynb"
    conda:
        "../envs/test.yaml"
    notebook:
        "../notebooks/hello.py.ipynb"
