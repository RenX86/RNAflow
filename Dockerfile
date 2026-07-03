FROM mambaorg/micromamba:1.5.8-bookworm-slim

WORKDIR /app

COPY . /app

RUN micromamba install -y -n base -c conda-forge -c bioconda \
    snakemake=8.5.3 \
    fastp=0.23.4 \
    && micromamba clean --all --yes

ENV PATH="/opt/conda/bin:$PATH"