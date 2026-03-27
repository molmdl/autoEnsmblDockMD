#!/bin/bash
cd rec
cp ../scripts/rec/*.mdp .
ln -s ../charmm36.ff .
gmx pdb2gmx -f BRD4.pdb -ignh -o prot.gro --ff charmm36 -water tip3p
gmx editconf -f prot.gro -o box.gro -d 1 -c -bt dodecahedron #-bt cubic
gmx solvate -cp box.gro -cs spc216 -p topol.top -o solv.gro
gmx grompp -f em.mdp -c solv.gro -p topol.top -o ion.tpr -maxwarn 1
echo SOL | gmx genion -s ion.tpr  -p topol.top  -neutral -conc 0.15 -nname CL -pname NA -o ion.gro
