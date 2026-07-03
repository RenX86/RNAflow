# RNA-seq Differential Expression Pipeline

Automated, containerized RNA-seq pipeline. One command — full analysis from raw FASTQ to DE results and pathway enrichment. Runs identically on Windows and Linux via Docker.

---

## Pipeline Overview

```
Raw FASTQ
   ↓
FastQC (pre-trim QC)
   ↓
fastp (adapter trimming + quality filtering)
   ↓
FastQC (post-trim QC)
   ↓
STAR (genome alignment → BAM)
   ↓
samtools (sort + index BAM)
   ↓
featureCounts (gene-level count matrix)
   ↓
DESeq2 (differential expression)
   ↓
clusterProfiler (GO + KEGG enrichment)
   ↓
Results: volcano plot, MA plot, heatmap, enrichment plots
```

---

## Repository Structure

```
rna-seq-pipeline/
├── Dockerfile               # All tools in one image
├── docker-compose.yml       # Entry point for users
├── Snakefile                # Pipeline orchestration
├── config.yaml              # Parameters (edit this)
├── scripts/
│   ├── deseq2.R             # Differential expression
│   └── plots.R              # Visualization
├── data/
│   ├── raw/                 # Drop FASTQ files here
│   └── genome/              # Reference genome + GTF + STAR index
├── results/                 # All outputs land here
│   ├── qc/
│   ├── trimmed/
│   ├── bam/
│   ├── counts/
│   └── de/
├── .gitattributes           # Forces LF line endings (Windows compat)
└── README.md
```

---

## Requirements

| Platform | Requirement |
|----------|-------------|
| Windows  | [Docker Desktop](https://www.docker.com/products/docker-desktop/) (WSL2 backend enabled) |
| Linux    | Docker Engine + Docker Compose |
| Both     | 16GB RAM minimum, 50GB free disk (STAR genome index ~30GB) |

No other dependencies. All bioinformatics tools run inside the container.

---

## Quick Start

### 1. Clone repo

```bash
git clone https://github.com/RenX86/rna-seq-pipeline
cd rna-seq-pipeline
```

### 2. Add your data

Drop paired-end FASTQ files into `data/raw/`:

```
data/raw/
├── sample1_R1.fastq.gz
├── sample1_R2.fastq.gz
├── sample2_R1.fastq.gz
└── sample2_R2.fastq.gz
```

### 3. Edit config

```yaml
# config.yaml
samples:
  - sample1
  - sample2

conditions:
  sample1: control
  sample2: treatment

genome_dir: data/genome/star_index
gtf: data/genome/genome.gtf
threads: 8
```

### 4. Download reference genome (first time only)

```bash
docker compose run pipeline bash scripts/download_genome.sh
```

Downloads GRCh38 reference + GTF from GENCODE and builds STAR index. Takes ~45 min. Cached after first run.

### 5. Run pipeline

```bash
docker compose up
```

Results appear in `results/` as each step completes.

---

## Configuration Reference

```yaml
# config.yaml — all parameters

samples: []               # List of sample names (must match FASTQ filenames)

conditions: {}            # sample → condition mapping for DESeq2

genome_dir: ""            # Path to STAR genome index directory
gtf: ""                   # Path to genome annotation GTF

threads: 8                # CPU threads per rule
fastp_quality: 20         # Phred quality cutoff for trimming
fastp_min_length: 36      # Min read length after trimming

star_mismatch: 2          # Max mismatches per read pair
star_multimap: 10         # Max multimapped loci

fc_strand: 2              # featureCounts strandedness (0=unstranded, 1=forward, 2=reverse)
fc_feature: "gene"        # Feature type to count

deseq2_padj: 0.05         # Adjusted p-value cutoff
deseq2_lfc: 1.0           # Log2 fold change cutoff
```

---

## Output Files

```
results/
├── qc/
│   ├── pre_trim/          # FastQC reports before trimming
│   └── post_trim/         # FastQC reports after trimming
├── trimmed/               # Adapter-trimmed FASTQ
├── bam/
│   ├── *.bam              # Sorted alignments
│   └── *.bam.bai          # BAM indices
├── counts/
│   └── counts_matrix.txt  # Gene × sample count matrix
└── de/
    ├── results.csv         # Full DESeq2 results table
    ├── sig_genes.csv       # Significant DEGs only
    ├── volcano.png         # Volcano plot
    ├── ma_plot.png         # MA plot
    ├── heatmap.png         # Top 50 DEG heatmap
    ├── go_enrichment.png   # GO biological process enrichment
    └── kegg_enrichment.png # KEGG pathway enrichment
```

---

## Tools and Versions

| Tool | Version | Purpose |
|------|---------|---------|
| FastQC | 0.12.1 | Read quality assessment |
| fastp | 0.23.4 | Adapter trimming |
| STAR | 2.7.11a | Genome alignment |
| samtools | 1.19 | BAM processing |
| featureCounts (Subread) | 2.0.6 | Read counting |
| DESeq2 | 1.42.0 | Differential expression |
| clusterProfiler | 4.10.0 | Pathway enrichment |
| R | 4.3.2 | Statistical computing |
| Snakemake | 8.5.3 | Pipeline orchestration |

All pinned in `Dockerfile` — exact reproducibility guaranteed.

---

## Dataset Used (Demo)

**GSE157103** — COVID-19 vs healthy PBMC RNA-seq (Geo et al., 2021).

Download demo data:

```bash
docker compose run pipeline bash scripts/download_demo.sh
```

Downloads 6 samples (3 COVID, 3 healthy) via `fasterq-dump`. ~8GB.

---

## Snakemake DAG

Visualize full pipeline dependency graph:

```bash
docker compose run pipeline snakemake --dag | dot -Tpng > dag.png
```

---

## Troubleshooting

**Docker Desktop not starting on Windows**
→ Enable WSL2: `wsl --install` in PowerShell (Admin), then restart.

**STAR alignment fails — genome not found**
→ Run `download_genome.sh` first (Step 4). Index must exist before alignment.

**featureCounts low assignment rate (<50%)**
→ Check strandedness. Try `fc_strand: 0` in `config.yaml` for unstranded libraries.

**DESeq2 error — less than 2 replicates per condition**
→ DESeq2 requires ≥2 samples per condition. Add more samples or use `DESeq2::estimateDispersionsGeneEst()` workaround (documented in `scripts/deseq2.R`).

**Windows line ending errors in shell scripts**
→ Repo includes `.gitattributes` forcing LF. If issue persists: `git config core.autocrlf false` then re-clone.

---

## Extending the Pipeline

Add new rules to `Snakefile`:

```python
rule multiqc:
    input:
        expand("results/qc/post_trim/{sample}_fastqc.zip", sample=config["samples"])
    output:
        "results/qc/multiqc_report.html"
    container:
        "docker://ewels/multiqc:1.21"
    shell:
        "multiqc {input} -o results/qc/"
```

---

## License

MIT

---

## Citation

If used in research:

```
RNA-seq Differential Expression Pipeline. RenX86. GitHub: https://github.com/RenX86/rna-seq-pipeline
```
