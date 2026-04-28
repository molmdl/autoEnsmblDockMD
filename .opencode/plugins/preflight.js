import { definePlugin } from '@opencode-ai/plugin';
import { execFile } from 'child_process';
import { promisify } from 'util';
import path from 'path';

const execFileAsync = promisify(execFile);
const PYTHON_RELATIVE_PATH = 'scripts/infra/plugins/preflight.py';

function toPluginResult(handoff) {
  return {
    success: handoff?.status === 'success' || handoff?.status === 'needs_review',
    data: handoff?.data ?? {},
    warnings: handoff?.warnings ?? [],
    errors: handoff?.errors ?? []
  };
}

export default definePlugin({
  name: 'aedmd-preflight',
  version: '1.0.0',
  description: 'Validate config, tools, and inputs before workflow execution',

  async execute({ config, workspace }) {
    if (!config) {
      return {
        success: false,
        data: {},
        warnings: [],
        errors: ['Config path is required.']
      };
    }

    const projectRoot = process.cwd();
    const pythonPlugin = path.join(projectRoot, PYTHON_RELATIVE_PATH);
    const workspacePath = workspace ?? projectRoot;

    try {
      const { stdout } = await execFileAsync('python3', [
        pythonPlugin,
        '--config',
        config,
        '--workspace',
        workspacePath
      ]);
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
