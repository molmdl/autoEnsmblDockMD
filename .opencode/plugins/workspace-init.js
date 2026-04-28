import { definePlugin } from '@opencode-ai/plugin';
import { execFile } from 'child_process';
import { promisify } from 'util';
import path from 'path';

const execFileAsync = promisify(execFile);
const PYTHON_RELATIVE_PATH = 'scripts/infra/plugins/workspace_init.py';

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
    if (!template || !target) {
      return {
        success: false,
        data: {},
        warnings: [],
        errors: ['Both template and target are required.']
      };
    }

    const projectRoot = process.cwd();
    const pythonPlugin = path.join(projectRoot, PYTHON_RELATIVE_PATH);

    const args = ['--template', template, '--target', target];
    if (force) args.push('--force');

    try {
      const { stdout } = await execFileAsync('python3', [pythonPlugin, ...args]);
      const handoff = JSON.parse(stdout);
      return toPluginResult(handoff);
    } catch (error) {
      const stderr = error?.stderr?.toString?.().trim?.();
      const message = stderr || error?.message || String(error);
      return {
        success: false,
        data: {},
        warnings: [],
        errors: [message]
      };
    }
  }
});
