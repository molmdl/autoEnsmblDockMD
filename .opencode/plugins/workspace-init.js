import { definePlugin } from '@opencode-ai/plugin';
import { execFile } from 'child_process';
import { promisify } from 'util';
import path from 'path';

const execFileAsync = promisify(execFile);

function toPluginResult(handoff) {
  return {
    success: handoff?.status === 'success',
    data: handoff?.data ?? {},
    warnings: handoff?.warnings ?? [],
    errors: handoff?.errors ?? []
  };
}

export default definePlugin({
  name: 'aedmd-workspace-init',
  version: '1.0.0',
  description: 'Initialize isolated workspace from template',

  async execute({ template, target, force = false }) {
    const projectRoot = process.cwd();
    const pythonPlugin = path.join(projectRoot, 'scripts/infra/plugins/workspace_init.py');

    const args = ['--template', template, '--target', target];
    if (force) args.push('--force');

    try {
      const { stdout } = await execFileAsync('python3', [pythonPlugin, ...args]);
      const handoff = JSON.parse(stdout);
      return toPluginResult(handoff);
    } catch (error) {
      return {
        success: false,
        data: {},
        warnings: [],
        errors: [error?.message ?? String(error)]
      };
    }
  }
});
