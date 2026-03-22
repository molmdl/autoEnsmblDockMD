> TO BE FINALIZED, do not proceed to plan or work of related stages with this banner

# WORKFLOW.md contains information on the full workflow of autoEnsmblDockMD

The workflow takes the following provided by the user: receptor structure PDB, reference ligand for pocket definition and velidatiom (coordinates and topology), ligands to be evaluated (coordinates and topology), and the customised forcefield that include ligand parameters, gromacs run input mdp; optionally configuration parameters for docking.

which dir to enter, which file to detect, which script to execute, which analysis to do

## Major stages
remind or help user to place the required input

---

## On-demand stages
checker agent
debugger agent


---

## Complete Workflow

reference redock
interested lig dock
gen ensemble, cluster, select, align
intermediate analysis step
multiple parallel agent for multiple ligands, max parallel up to N agents
using slurm for hpc, and run local option

checker agent
debugger agent

