import os
import csv
import requests
import datetime
from argparse import ArgumentParser

import pysam

class GeneInfoRequestError(Exception): pass

HIGH_IMPACT_VARIANT_TYPES = [
    'missense_variant',
    'inframe_insertion',
    'inframe_deletion',
    'frameshift_variant',
    'stop_gained',
    'stop_lost',
    'start_lost',
    'protein_altering_variant'
]

class AnnotationParser:
    def __init__(self, input_vcf_path: str,
                    gene_info_path: str,
                    gnomad_cutoff: float,
                    revel_cutoff: float) -> None:
        
        self.input_vcf_path = input_vcf_path
        self.gene_info_path = gene_info_path
        self.gnomad_cutoff = gnomad_cutoff
        self.revel_cutoff = revel_cutoff

        self.user_data_dir = 'user_data'

        self.csv_columns = ['chrom', 'pos', 'gene_id','gene_symbol',
                            'consequence', 'af', 'max_af', 'clinsig',
                            'revel', 'description']

        self.cached_gene_info = self.load_gene_info()

        self.vcf = pysam.VariantFile(self.input_vcf_path)

    def build_output_filepath(self) -> str:
        vcf_filename = os.path.basename(self.input_vcf_path)
        vcf_filename_prefix = vcf_filename.split('.')[0]

        dt = datetime.datetime.now()
        dt_strf = dt.strftime('%Y%m%d_%H%M%S')

        output_fn = f'{vcf_filename_prefix}_{dt_strf}.csv'
        output_fp = os.path.join(self.user_data_dir, output_fn)
        return output_fp
    
    def build_output_header(self) -> str:
        return ','.join(self.csv_columns) + '\n'

    def load_gene_info(self) -> dict:
        with open(self.gene_info_path, "r") as tsv:
            reader = csv.reader(tsv, delimiter="\t")

            return {line[0]: {'symbol': line[1], 'description': line[2]}
                            for line in reader}

    def request_gene_info(self, gene_id: str) -> tuple:
        url = f'https://rest.ensembl.org/lookup/id/{gene_id}?'

        r = None
        while not r:
            try:
                r = requests.get(url,
                                headers={ "Content-Type" : "application/json"},
                                timeout=10)
            except requests.exceptions.ReadTimeout:
                continue

        if not r.status_code == 200:
            print(r.content)
            raise GeneInfoRequestError(
                    f"Ensembl API request unsuccessful for ID {gene_id}.")

        res_body = r.json()

        symbol = res_body['display_name']
        description = ''.join(res_body['description'].split(','))
        return symbol, description
    
    def get_gene_info(self, gene_id: str) -> tuple:
        try:
            symbol, description = self.cached_gene_info.get(gene_id).values()
        except AttributeError:
            try:
                symbol, description = self.request_gene_info(gene_id)
            except (GeneInfoRequestError, KeyError, TypeError) as e:
                print(e)
                symbol = 'none'
                description = 'none'
        return symbol, description

    def parse_annotations(self) -> None:
        output_fp = self.build_output_filepath()
        output_csv_header = self.build_output_header()

        with open(output_fp, 'w') as f:
            f.write(output_csv_header)
        
        for variant in self.vcf.fetch():
            vep_csq = variant.info['CSQ']
            print(vep_csq)

            for transcript in vep_csq:
                ts_split = transcript.split('|')

                gene_id, consequence, gnomad_af, gnomad_af_max, clinsig, \
                    revel_score = ts_split

                print(variant.chrom, variant.pos, ts_split)

                revel_cond = (
                    revel_score != '' 
                    and float(revel_score) > self.revel_cutoff
                )

                rare_variant_cond = (
                    any([vtype in consequence for vtype 
                        in HIGH_IMPACT_VARIANT_TYPES]) 
                    and gnomad_af != ''
                    and float(gnomad_af) <= self.gnomad_cutoff
                    and gnomad_af_max != ''
                    and float(gnomad_af_max) <= self.gnomad_cutoff
                )

                clinvar_cond = (
                    any([vtype in consequence for vtype 
                        in HIGH_IMPACT_VARIANT_TYPES])
                    and 'pathogenic' in clinsig
                )
                
                af_absent_cond = (
                    any([vtype in consequence for vtype 
                        in HIGH_IMPACT_VARIANT_TYPES]) 
                    and gnomad_af == ''
                    and gnomad_af_max != ''
                    and float(gnomad_af_max) <= self.gnomad_cutoff
                )
                
                both_af_absent_cond = (
                    any([vtype in consequence for vtype 
                        in HIGH_IMPACT_VARIANT_TYPES]) 
                    and gnomad_af == ''
                    and gnomad_af_max == ''
                )

                criteria = [revel_cond, rare_variant_cond, 
                            clinvar_cond, af_absent_cond, 
                            both_af_absent_cond]

                if any(criteria):
                    if not gene_id == '':
                        symbol, description = self.get_gene_info(gene_id)
                        print(symbol, description)

                    with open(output_fp, 'a') as f:
                        f.write(','.join([variant.chrom, str(variant.pos), 
                                          gene_id, symbol, consequence, 
                                          gnomad_af, gnomad_af_max,
                                          clinsig, revel_score, description]))
                        f.write('\n')
                    break

if __name__ == "__main__":
    parser = ArgumentParser()
    parser.add_argument('input_vcf_path', type=str,
                        help='The path to the input VCF file.')
    parser.add_argument('--geneinfo', '-i', type=str, default='gene_info.tsv',
                        help='The path to cached gene info from ensembl.')
    parser.add_argument('--gnomad', '-g', type=float, default=0.01,
                        help='The threshold for gnomAD allele frequency.')
    parser.add_argument('--revel', '-r', type=float, default=0.5,
                        help='The threshold for REVEL score.')

    args = parser.parse_args()

    ap = AnnotationParser(input_vcf_path=args.input_vcf_path, 
                          gene_info_path=args.geneinfo,
                          gnomad_cutoff=args.gnomad,
                          revel_cutoff=args.revel)

    ap.parse_annotations()