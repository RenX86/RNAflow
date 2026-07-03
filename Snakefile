#rule name_of_steps:
#    input: "what_goes_in.txt"
#   output: "what_comes_out.txt"
#   shell: "command_to_run {input} > {output}"
configfile: "config.yaml"

rule all:
    input:
        "results/trimmed/sample1_R1.fastq.gz",
        "results/trimmed/sample1_R2.fastq.gz"

rule fastp_trimming:
    input:
        r1 = "data/raw/{sample}_R1.fastq.gz",
        r2 = "data/raw/{sample}_R2.fastq.gz"
    output:
        r1 = "results/trimmed/{sample}_R1.fastq.gz",
        r2 = "results/trimmed/{sample}_R2.fastq.gz",
        html = "results/qc/pre_trim/{sample}_fastp.html"
    threads:
        config["threads"]
    shell:
        """
        fastp -i {input.r1} -I {input.r2} \
            -o {output.r1} -O {output.r2} \
            --html {output.html} \
            --thread {threads} \
            --qualified_quality_phred {config[fastp_quality]} \
            --length_required {config[fastp_min_length]}
        """
