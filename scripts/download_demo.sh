#!/bin/bash

# Create the data/raw directory if it doesn't exist
mkdir -p data/raw

echo "Creating dummy FASTQ data for sample1..."

# A FASTQ file is just text. Every DNA read takes exactly 4 lines:
# Line 1: @Read_ID
# Line 2: The actual A,C,T,G sequence
# Line 3: A plus sign (+) separator
# Line 4: The quality score of each letter (ASCII characters where ! is bad and I is perfect)

cat <<EOF > data/raw/sample1_R1.fastq
@Read_1_Forward
GATCGGAAGAGCACACGTCTGAACTCCAGTCAC
+
IIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIII
@Read_2_Forward
CGATCGATCGATCGATCGATCGATCGATCGATC
+
IIIIIIIIIII!!!!!!!!!!!IIIIIIIIIII
EOF

cat <<EOF > data/raw/sample1_R2.fastq
@Read_1_Reverse
GTGACTGGAGTTCAGACGTGTGCTCTTCCGATC
+
IIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIII
@Read_2_Reverse
GATCGATCGATCGATCGATCGATCGATCGATCG
+
IIIIIIIIIII!!!!!!!!!!!IIIIIIIIIII
EOF

# Zip them up because fastp expects .fastq.gz files
gzip -f data/raw/sample1_R1.fastq
gzip -f data/raw/sample1_R2.fastq

echo "Done! Dummy files created in data/raw/"
