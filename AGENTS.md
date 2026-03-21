# AGENTS.md - Guidelines for Building an Agentic Workflow in autoEnsmblDockMD
This project aim to create an agentic workflow to perform ensemble docking using GROMACS and gnina, with a suite of bash and python scriprs, slash commands, and agent skills, compatible with opencode and ideally also other coding agwnts. The workflow takes the following provided by the user: receptor structure PDB, reference ligand for pocket definition and velidatiom (coordinates and topology), ligands to be evaluated (coordinates

## Detailed requirements
Success of this project depends on the following elements
1. workflow: the full workflow should be automated via calling of slash commands or agent skills. Slash commands and agent skill use the scripts to do the work. Agents orchestrate the workflow, execute commands or call scripts, preoare input files, inspect results and make decisions based on results.
3. agent
checkpoints should be provided fir human verification and starting new session to @void overflow of context window of LLM.
2. slash command:
3. agent skill:
4. scripts: python and bash scripts of the current manual workflow is provided in the respective directory in `./expected`, usage and execution order under the `## Workflow` session. Success criteria of this element is that a generalized version of related script is provided in the `./scripts` directory under repo root, which can be used vua command lines, with options input via cli flag or input conf file.

## prere
env
preinstall gnina gmx

## Repository structure

file paths

user provided templates

workspace

expected output

## Workflow

checks


## Notes for Agents
- **Environment sourcing**: Source `setenv.sh` before using the script and commands in this project.
- **Professional tone**: Be clear, concise, and professional in responses. Check output for errors.
- **Conda environment only**: Do not modify system-wide Python installations
- **Test directory**: Primary location for validation and testing
- **Maintain backward compatibility**: When modifying core workflows
- **Configuration-driven approach**: Preferred over hardcoded values
- **Multi-job manager support**: Must be preserved in shell scripts
- **Consistency**: Ensure input/output file formats and code style consistency across different conversations of this project
- **No rm command except in the test directory**: the `rm` command is prohibited except in the test directory for handling temporary test files. In any case you use the rm command, report it in a file.
- **Report summary of the tasks done and to-be-done**: After planning, the plan should write to a md file before proceed. After executing tasks, the working being done should be summarized abd append into a md file, and the to-do tasks summarized in another md file
