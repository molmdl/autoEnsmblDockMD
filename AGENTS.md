# AGENTS.md - Guidelines for Building an Agentic Workflow in autoEnsmblDockMD
This project aim to create a set of scripts, with an experimental but SAFE AND EFFICIENT agentic workflow to perform ensemble docking using GROMACS and gnina, with a suite of bash and python scriprs, slash commands, and agent skills, compatible with opencode and ideally also other coding agents. 

---

## Detailed requirements
Success of this project depends on the elements I, II, III, IV, V, and VI.

### I. Workflow
1. The full workflow should be automated via calling of slash commands or agent skills. 
2. Slash commands and agent skill use the scripts to do the work. 
3. Agents orchestrate the workflow, execute commands or call scripts, preoare input files, inspect results and make decisions based on results.
4. checkpoints should be provided for human verification and starting new session to avoid overflow of context window of LLM.
5. When scripts can be used, prepare scripts for the protocol instead of letting the agent generate new commands every time.

### II. Agent(s)
Agents are aware of how and when to use related commands and skills, and where to obtain relevant documentations. 
1. orchestrator manage all agents, knows the workflow, knows when to spawn which agent, knows the agent-targeted documentation.
2. runner run specific steps of the workflow, loads the workflow of a stage or a slash command, and knows how to use the scripts.
3. analyzer run standard analysis and create custom analysis scripts if necessary, following a consistent coding style and i/o format
4. checker investigate results to evaluate/judge/warn/suggest/comment on it
5. debugger follow the gsd-debugger workflow to fix major issues awaring of the manual of the versions of gromacs, gnina, gmx_MMPBSA, and other python libraries.


### III. Slash command: 
For the user to run specific major stage in the workflow.

### IV. Agent skill
Formated, to be loaded by agents, minimal but sufficient. 

### V. Scripts
- Python and bash scripts of the current manual workflow is provided in the respective (sub-)directory in `./expected`, usage and execution order under the `## Workflow` session. 
- Identify missing scripts (gaps) in the protocol. Ask the user to provide first, otherwise generate one.
- Success criteria of this element is that a generalized version of related script is provided in the `./scripts` directory under repo root, which can be used vua command lines; and 'gaps' scripts generated, with options input via cli flag or input conf file.
- All the scripts should be revised, refactored for consistency and generalizability.

### VI. Documentation
1. Minimal, sufficient, professional, clear and concise documentation in README.md for human
2. Detailed documentation in a format optimized for agents to check whenever necessary (to avoid loading too much context every time)

---

## Prerequisite
For other users
- **Environment setup**: Conda environment in `env.yml` should be installed and activated.
- **Software installation**: Gromacs version > 2022, gnina, gmx_MMPBSA (already in conda environment via pip)
- **files to be provided by user**: see work/input for the files of each stage. copy them to new workspace to start

For the CURRENT user (developer) or agents on this cluster
- **Loading the environment**: `source ./scripts/setenv.sh`
- **Input files for testing**: see ./work/input for the files of each stage, copy them to new workspace to start. this directory has the same structure as expected output.
- **Expected output (selected) from a manual trial by human**: Selected output from a manual trial by human will be provided in the ./expected directory, which has the same structure as the work/input directory, and the new workspace created by agent for testing in work/ should also have the same structure.
- **Other examples**: Other examples files for reference, e.g. the gmxMMPBSA pred example from the developers github, are provided, that the user will provie the path to this exmple when working on that stage.

---

## Workflow

Workflow will be provided in the `WORKFLOW.md` file to reduce the filesize of this AGENTS.md.
**CURRENT STATUS: workflow and related script to be finalized, do not proceed to plan stages related to workflow yet until the user manually remove this statement and the `TO BE FINALIZED` banner in WORKFLOW.md**

## Future
- Automate the ligand preparation procedures and ffnonbond.itp edits


## Notes for Agents
- **No rm command except in the test directory**: the `rm` command is prohibited except in the test directory of the workspace created for the test, for handling temporary test files. In any case you use the rm command, report it in a file. and seek explicit approval
- **Never require sudo permission**
- **Environment sourcing**: Source `./scripts/setenv.sh` before using the script and commands in this project.
- **Professional tone**: Be clear, concise, and professional in responses. Check output for errors.
- **Conda environment only**: Do not modify system-wide Python installations
- **work/test directory of the protocol/agent**: Primary location for validation and testing. User-provided inputs are in `./work/input`.
- **Maintain backward compatibility**: When modifying core workflows
- **Configuration-driven approach**: Preferred over hardcoded values
- **Multi-job manager support**: Must be preserved in shell scripts
- **Consistency**: Ensure input/output file formats and code style consistency across different conversations of this project
- **Report summary of the tasks done and to-be-done**: After planning, the plan should write to a md file before proceed. After executing tasks, the working being done should be summarized abd append into a md file, and the to-do tasks summarized in another md file

