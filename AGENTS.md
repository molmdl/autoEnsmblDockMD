# AGENTS.md - Guidelines for Agentic Workflow in autoEnsmblDockMD

Agent skill to 

## Aim


## Detailed requirements
- workflow
- command
- skill

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
- **Ignore backup directory**: Unless explicitly requested
- **Maintain backward compatibility**: When modifying core workflows
- **Configuration-driven approach**: Preferred over hardcoded values
- **Multi-job manager support**: Must be preserved in shell scripts
- **Documentation updates**: Should accompany functional changes
- **Consistency**: Ensure input/output file formats and code style consistency across different conversations of this project
- **No rm command except in the test directory**: the `rm` command is prohibited except in the test directory for handling temporary test files. In any case you use the rm command, report it in a file.
- **Report summary of the tasks done and to-be-done**: After planning, the plan should write to a md file before proceed. After executing tasks, the working being done should be summarized abd append into a md file, and the to-do tasks summarized in another md file
