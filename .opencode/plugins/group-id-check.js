import { definePlugin } from '@opencode-ai/plugin';
import { execFile } from 'child_process';
import { promisify } from 'util';
import path from 'path';

const execFileAsync = promisify(execFile);
const PYTHON_RELATIVE_PATH = 'scripts/infra/plugins/group_id_check.py';

function toPluginResult(handoff) {
  return {
    success: handoff?.status === 'success' || handoff?.status === 'needs_review',
    data: handoff?.data ?? {},
    warnings: handoff?.warnings ?? [],
    errors: handoff?.errors ?? []
  };
}

export default definePlugin({
  name: 'aedmd-group-id-check',
  version: '1.0.0',
  description: 'Validate MM/PBSA group IDs against index.ndx',

  async execute({ workspace }) {
    if (!workspace) {
      return {
        success: false,
        data: {},
        warnings: [],
        errors: ['Workspace path is required.']
      };
    }

    const projectRoot = process.cwd();
    const pythonPlugin = path.join(projectRoot, PYTHON_RELATIVE_PATH);

    try {
      const { stdout } = await execFileAsync('python3', [
        pythonPlugin,
        '--workspace',
        workspace
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
