
FROM ubuntu:22.04

WORKDIR /opt

RUN apt-get update && apt-get upgrade -y

# Apt dependencies
RUN apt-get install -y git gcc g++ make curl unzip wget libbz2-dev \
	liblzma-dev cpanminus libmysqlclient-dev libcurl4-openssl-dev tabix

# Perl dependencies
RUN cpanm Archive::Zip DBI DBD::mysql LWP::Simple

# Python dependencies
RUN apt-get install -y python3.10 python3-pip

RUN pip3 install pysam requests

# v0.0.0 STOPS HERE

# Build bcftools
RUN git clone --recurse-submodules https://github.com/samtools/htslib.git

RUN git clone https://github.com/samtools/bcftools.git

RUN cd bcftools && make && make install

# v0.0.1 STOPS HERE

# Build VEP with REVEL plugin
RUN git clone https://github.com/Ensembl/ensembl-vep.git

RUN cd ensembl-vep && perl INSTALL.pl --ASSEMBLY GRCh38 --AUTO ap --SPECIES homo_sapiens --PLUGINS REVEL

# v0.0.2 STOPS HERE

# Download REVEL data and process for VEP
ARG REVEL_ARCHIVE_NAME="revel-v1.3_all_chromosomes.zip"
ARG REVEL_ARCHIVE_URL="https://www.google.com/url?q=https://rothsj06.dmz.hpc.mssm.edu/revel-v1.3_all_chromosomes.zip&sa=D&sntz=1&usg=AOvVaw2DS2TWUYl__0vqijzzxp5M"

ARG PROCESSING_DIR=/opt/revel_processing

ARG PROCESSED_DATA_FN=new_tabbed_revel_grch38.tsv.gz
ARG PROCESSED_DATA_INDEX=$PROCESSED_DATA_FN.tbi

ARG PROCESSED_DATA_NEWDIR=/opt/revel

RUN wget --execute=robots=off --recursive --span-hosts --accept=zip --no-directories $REVEL_ARCHIVE_URL \
	&& unzip -d $PROCESSING_DIR $REVEL_ARCHIVE_NAME \
	&& cat $PROCESSING_DIR/revel_with_transcript_ids | tr "," "\t" > $PROCESSING_DIR/tabbed_revel.tsv \
	&& sed '1s/.*/#&/' $PROCESSING_DIR/tabbed_revel.tsv > $PROCESSING_DIR/new_tabbed_revel.tsv \
	&& bgzip $PROCESSING_DIR/new_tabbed_revel.tsv \
	&& zcat $PROCESSING_DIR/new_tabbed_revel.tsv.gz | head -n1 > $PROCESSING_DIR/h \
	&& zgrep -h -v ^#chr $PROCESSING_DIR/new_tabbed_revel.tsv.gz | awk '$3 != "." ' | sort -k1,1 -k3,3n - | cat $PROCESSING_DIR/h - | bgzip -c > $PROCESSING_DIR/$PROCESSED_DATA_FN \
	&& tabix -f -s 1 -b 3 -e 3 $PROCESSING_DIR/$PROCESSED_DATA_FN \
	&& mkdir $PROCESSED_DATA_NEWDIR \
	&& mv $PROCESSING_DIR/$PROCESSED_DATA_FN $PROCESSED_DATA_NEWDIR \
	&& mv $PROCESSING_DIR/$PROCESSED_DATA_INDEX $PROCESSED_DATA_NEWDIR \
	&& rm -r $PROCESSING_DIR && rm $REVEL_ARCHIVE_NAME

# v0.0.4 STOPS HERE

ARG APP_DIR=/opt/wgs-inspector-dev
ARG USER_DATA_DIR=$APP_DIR/user_data
ARG CONTAINER_VEP_CACHE_DIR=/opt/vep_cache

RUN mkdir $CONTAINER_VEP_CACHE_DIR && mkdir $APP_DIR && mkdir $USER_DATA_DIR

COPY scripts src ensembl_data $APP_DIR

# v0.0.5 STOPS HERE

WORKDIR	$APP_DIR

# 0.0.6-9 STOPS HERE
