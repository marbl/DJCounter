# Resources

Download or unzip relevant resources here.

## GRCh38 reference
* [GRCh38_full_analysis_set_plus_decoy_hla.fa](ftp://ftp.1000genomes.ebi.ac.uk/vol1/ftp/technical/reference/GRCh38_reference_genome/GRCh38_full_analysis_set_plus_decoy_hla.fa)

## DJ k-mer target db
```sh
pigz -cd DJtarget.meryl.tar.gz > DJtarget.meryl.tar
tar -xf DJtarget.meryl.tar
```

Check `DJtarget.meryl` matches the following stats:
```sh
meryl statistics DJtarget.meryl | head -n5

Found 1 command tree.
Number of 31-mers that are:
  unique                      0  (exactly one instance of the kmer is in the input)
  distinct                52227  (non-redundant kmer sequences in the input)
  present              26140589  (...)
  missing   4611686018427335677  (non-redundant kmer sequences not in the input)
```
