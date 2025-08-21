
FROM ubuntu:22.04

WORKDIR /opt

# Apt, Perl and Python dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
	git gcc g++ make curl unzip wget libbz2-dev liblzma-dev \
	cpanminus libmysqlclient-dev libcurl4-openssl-dev tabix \
	python3.10 python3-pip \
    && cpanm Archive::Zip DBI DBD::mysql LWP::Simple List::MoreUtils \
    && pip3 install --no-cache-dir pysam requests \
    && rm -rf /var/cache/apt/archives /var/lib/apt/lists/* \
    && rm -rf /root/.cpanm

# Build bcftools
RUN git clone --recurse-submodules https://github.com/samtools/htslib.git \
    && git clone https://github.com/samtools/bcftools.git \
    && cd bcftools && make && make install && cd .. \
    && rm -rf bcftools/ htslib/

# Build VEP with REVEL plugin
RUN git clone https://github.com/Ensembl/ensembl-vep.git \
    && cd ensembl-vep && perl INSTALL.pl --ASSEMBLY GRCh38 \
                                         --AUTO ap \
                                         --NO_HTSLIB \
                                         --SPECIES homo_sapiens \
                                         --PLUGINS REVEL \
    && rm -rf t/ .git/ biodbhts/t/data/

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

# Copy everything into the container
ARG APP_DIR=/opt/wgs-inspector
ARG USER_DATA_DIR=$APP_DIR/user_data
ARG CONTAINER_VEP_CACHE_DIR=/opt/vep_cache

RUN mkdir $CONTAINER_VEP_CACHE_DIR && mkdir $APP_DIR && mkdir $USER_DATA_DIR

COPY scripts src ensembl_data $APP_DIR

WORKDIR	$APP_DIR
