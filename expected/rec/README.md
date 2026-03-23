# Directory with symbolic link to data and scripts for receptor preparation

## rec_md 
- protonated pdb
- gmx processeing and simulation scripts and output
- slurm submission scripts
- clustering scriots and output

## ensemble
- top 10 represenrative structures from clustering, copied from md trajectory
- pdb format for docking, gro format for later alignment then combine with lig after docking
- **note: yet to align to reference**

## amber19SB_OL21_OL3_lipid17.ff
- note that pdb2gmx was run with ff dir sym link to rec_md than removed, then I manually edited path in topol.top
- in practical case find a way to avoid these complication in paths
