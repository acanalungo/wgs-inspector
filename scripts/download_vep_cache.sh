
CONTAINER_VEP_CACHE_DIR=/opt/vep_cache

VEP_RELEASE=114
ASSEMBLY=GRCh38

CACHE_FILE="homo_sapiens_vep_${VEP_RELEASE}_${ASSEMBLY}.tar.gz"
FASTA_FILE="Homo_sapiens.${ASSEMBLY}.dna.toplevel.fa.gz"

CACHE_URL="https://ftp.ensembl.org/pub/release-${VEP_RELEASE}/variation/indexed_vep_cache/${CACHE_FILE}"
FASTA_URL="https://ftp.ensembl.org/pub/release-${VEP_RELEASE}/fasta/homo_sapiens/dna/${FASTA_FILE}"

SPECIES_DIR=homo_sapiens

# Download VEP cache file

echo "Downloading VEP cache..."

wget -P $CONTAINER_VEP_CACHE_DIR $CACHE_URL

echo "Cache download finished, extracting files..."

tar xzvf $CONTAINER_VEP_CACHE_DIR/$CACHE_FILE -C $CONTAINER_VEP_CACHE_DIR

echo "Cache extracted to ${CONTAINER_VEP_CACHE_DIR}"

# Download FASTA files

echo "Downloading VEP FASTA files..."

wget -P $CONTAINER_VEP_CACHE_DIR/$SPECIES_DIR $FASTA_URL

echo "FASTA download finished, extracting files..."

gzip -d $CONTAINER_VEP_CACHE_DIR/$SPECIES_DIR/$FASTA_FILE

bgzip $CONTAINER_VEP_CACHE_DIR/$SPECIES_DIR/${FASTA_FILE%.*}

echo "Cache download completed successfully."
