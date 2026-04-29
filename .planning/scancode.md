/gsd-map-codebase
after codebase scanning, spawn additional subagents for the additional tasks of read-only analysis, output each report into timestamped file in .planning/code_analysis. do not fix yet, I will start new debug session or urgent phase insertion or quick task for the fix.
A. for all the codes in this repo, critically scan the code and trace the logic of different options to identift vunlability, suspecious code, or issues leading to safety concerns or performance lost. do not run anything.
pay specific attention to any nested for-loops, unit mismatch and atom number mismatch, and any bugs you can identify.
B. For the skills, identify conflict with standard opencode commands, e.g. I identified the /status skill conflicts with internal opencode commands. suggest if its better to e.g. add a prefix aedmd/aed/admd (you decide, tell me reason) to all skills and update related docs
C. For the documentation facing both human and agent, cross-check for consistency with the code, and suggest possible citation to add.
D. For the plugins (hooks), investigate for any vunlability and issues, and analyze if they could serve the purpose in the agent skill and workflow.
