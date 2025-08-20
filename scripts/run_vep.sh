#!/bin/bash

set -euo pipefail

VCF_FILE=$1
SAMPLE_NAME=$2

USER_DATA_DIR=user_data

FILTERED_VCF_COMPRESSED=$USER_DATA_DIR/filtered_$SAMPLE_NAME.vcf.gz

OUTPUT_VCF=$USER_DATA_DIR/vep_$SAMPLE_NAME.vcf
OUTPUT_VCF_COMPRESSED=$OUTPUT_VCF.gz

VEP_PATH=/opt/ensembl-vep
CONTAINER_VEP_CACHE_DIR=/opt/vep_cache
REVEL_PLUGIN_DATA_PATH=/opt/revel/new_tabbed_revel_grch38.tsv.gz

echo "Indexing and filtering ${VCF_FILE}..."

bcftools index -t $VCF_FILE

# Remove monomorphic references (where ALT == .)
bcftools filter --output-type z --output $FILTERED_VCF_COMPRESSED --exclude 'ALT="."' $VCF_FILE

echo "Re-indexing filtered VCF: ${FILTERED_VCF_COMPRESSED}..."

bcftools index -t $FILTERED_VCF_COMPRESSED


echo "Running VEP on ${FILTERED_VCF_COMPRESSED}. Please wait..."

$VEP_PATH/vep -i $FILTERED_VCF_COMPRESSED \
              --species homo_sapiens \
              --assembly GRCh38 \
              --vcf --fields "Gene,Consequence,gnomADe_AF,MAX_AF,CLIN_SIG,REVEL" \
              -o $OUTPUT_VCF \
              --cache --offline \
              --dir_cache $CONTAINER_VEP_CACHE_DIR \
              --no_stats --check_existing \
              --af_gnomad --max_af \
              --canonical --mane \
              --plugin REVEL,file=$REVEL_PLUGIN_DATA_PATH \
              --fork 8

echo "Compressing ${OUTPUT_VCF}..."

bgzip $OUTPUT_VCF

echo "Indexing ${OUTPUT_VCF_COMPRESSED}..."

bcftools index -t $OUTPUT_VCF_COMPRESSED

echo "VEP annotation complete. Output file: ${OUTPUT_VCF_COMPRESSED}"
