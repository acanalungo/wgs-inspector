# WGS Inspector

WGS Inspector is an easy-to-use tool for extracting relevant variants from Whole Genome Sequencing (WGS) raw data files.
Under the hood, the processing pipeline relies on standard bioinformatics packages like Ensembl VEP and pysam for variant
annotation and parsing, as well as data from the gnomAD, ClinVar, and REVEL datasets for allele frequency, clinical
insights, and *in silico* pathogenicity prediction, respectively. The tool is delivered as a container image to minimize
setup time and ensure portability.

The general idea is to downsample from the approximately 5 million variants -- positions where your genotype *varies*
from the reference -- in your genome to around 1,000 variants which are most likely to be relevant to your health, ideally
something you could look through in a day or two. Of course, such a simplification will always miss something, but I think
this represents the minimal amount of time and effort invested to glean most of the interesting insights based on the best 
available data. After you've downloaded the necessary cache data (~3 hours depending on internet speed), you should be 
able to process an entire genome's worth of information in around an hour; the whole ordeal should be doable in an
afternoon.

The output of the tool is just a CSV file with different variants which meet certain criteria for relevancy, such as 
allele frequency being below a certain threshold (rarity of variant), the variant being labeled as pathogenic or 
likely pathogenic in a clinical database, or a sufficiently high-confidence prediction of pathogenicity by an *in silico*
model. Each variant will be labeled with the above information as well as its corresponding gene, and information about 
its position in the genome and variant type. A good way to explore this data more graphically and intuitively is to use
[Gene.iobio](https://gene.iobio.io/), where you can input your raw data and search for the individual genes you find in 
the CSV output.

*DISCLAIMER: I am not a doctor and the output of the tool should not be considered to be medical advice. This is for 
educational and recreational purposes only.*

### **File Formats**

This tool currently handles only genomic data from Variant Call Format (VCF) files, as that is the most efficient way to
transmit and analyze the information. It will not work with sequence data formats like SAM, BAM, CRAM, FASTQ, or FASTA.

### **Supported WGS Providers**

This tool has been tested extensively on data from the following WGS providers:
- Sequencing.com (https://sequencing.com)
- Nebula Genomics (https://nebula.org)
- Nucleus Genomics (https://mynucleus.com)

If you have a VCF file from another provider, everything **should** still work just fine, but there can be subtle differences in
how labs process their data which could lead to unexpected issues. The above three are the only ones I've tested and
confirmed to run smoothly.

### **Requirements**

- OS: Linux, macOS, or Windows (with WSL or Docker Desktop)
- Hardware: **at least 60GB** of free hard drive space for the VEP cache
- Packages:
  - Git (https://github.com/git-guides/install-git)
  - Docker (https://docs.docker.com/engine/install/)

### **Usage**

*On your host machine*
- Clone the repository: `git clone https://github.com/acanalungo/wgs-inspector.git`.
- Move your VCF file to the `user_data` directory of the repository.
- Run the container: `./run_container.sh` (this will pull the image if you haven't already).

*Inside the container*
- Download the VEP cache files to your machine by running: `./download_vep_cache.sh`. This will take a while,
  likely around 2-3 hours depending on your internet speed, as the compressed cache archive is ~25GB.
- Then run VEP on your data by running: `./run_vep.sh user_data/<vcf_filename> <sample_name>` with `<vcf_filename>`
  being the name of your file in the `user_data` directory, and `<sample_name>` being a more descriptive name of your
  choosing (e.g. your first name). On a sufficiently powerful machine -- one with 8 cores/16 threads or greater -- this
  step should finish in under an hour.
- When VEP is finished, you'll be left with an annotated VCF file called `vep_<sample_name>.vcf.gz`. To extract the
  relevant variants from this file, run the parser by running: `python3 annotation_parser.py user_data/vep_<sample_name>.vcf.gz`.
  This step should finish in under ten minutes.
- Optionally, you can use the `--gnomad` and `--revel` flags to override the default cutoffs for the parser, which
  are 0.01 and 0.5, respectively. The `--gnomad` cutoff corresponds to allele frequency as a percentage in decimal format, such
  that a cutoff of 0.01 means only variants rarer than 1% are included, 0.001 means only variants rarer than 0.1% are included,
  and so on. The `--revel` cutoff corresponds to the *in silico* pathogenicity prediction from the REVEL database, which ranges
  from 0.0 (for lowest likelihood) to 1.0 (for highest likelihood), such that a cutoff of 0.5 means only variants with a
  pathogenicity score **higher** than 0.5 are included. See the REVEL paper (linked below) and
  [website](https://sites.google.com/site/revelgenomics/about) for more information if you want to override this cutoff.
- The output of the parser will be a CSV file in the `user_data` directory containing all the variants matching the
  criteria, which you can open with any spreadsheet program and explore as you wish.

### **References**

Ensembl: https://doi.org/10.1093/nar/gkae1071

Ensembl VEP: https://doi.org/10.1186/s13059-016-0974-4

pysam: https://pysam.readthedocs.io/en/latest/index.html

gnomAD: https://gnomad.broadinstitute.org

ClinVar: https://www.ncbi.nlm.nih.gov/clinvar

REVEL: https://doi.org/10.1016/j.ajhg.2016.08.016

Gene.iobio: https://doi.org/10.1038/s41598-021-99752-5
