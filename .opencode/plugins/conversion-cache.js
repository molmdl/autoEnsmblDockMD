import { definePlugin } from '@opencode-ai/plugin';
import { execFile } from 'child_process';
import { promisify } from 'util';

const execFileAsync = promisify(execFile);
const PYTHON_MODULE_PATH = 'scripts/infra/plugins/conversion_cache.py';

const PYTHON_DRIVER = `
import argparse
import json
import importlib.util
from pathlib import Path

parser = argparse.ArgumentParser()
parser.add_argument('--workspace', required=True)
parser.add_argument('--operation', required=True, choices=['get', 'put', 'clear'])
parser.add_argument('--source-file', default='')
parser.add_argument('--target-format', default='')
parser.add_argument('--result-file', default='')
parser.add_argument('--module-path', required=True)
args = parser.parse_args()

spec = importlib.util.spec_from_file_location('conversion_cache', args.module_path)
if spec is None or spec.loader is None:
    raise RuntimeError(f'Unable to load conversion cache module: {args.module_path}')
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)
ConversionCache = module.ConversionCache

cache = ConversionCache(Path(args.workspace))
payload = {'status': 'success', 'data': {}, 'warnings': [], 'errors': []}

try:
    if args.operation == 'get':
        cached = cache.get(Path(args.source_file), args.target_format)
        payload['data'] = {'cached_path': str(cached) if cached else None}
    elif args.operation == 'put':
        cache.put(Path(args.source_file), args.target_format, Path(args.result_file))
        payload['data'] = {'cached': True}
    elif args.operation == 'clear':
        src = Path(args.source_file) if args.source_file else None
        cache.clear(src)
        payload['data'] = {'cleared': True}
except Exception as exc:
    payload['status'] = 'failure'
    payload['errors'] = [str(exc)]

print(json.dumps(payload))
`;

export default definePlugin({
  name: 'aedmd-conversion-cache',
  version: '1.0.0',
  description: 'Manage conversion cache with staleness detection',

  async execute({ workspace, operation, sourceFile, targetFormat, resultFile }) {
    try {
      const projectRoot = process.cwd();
      const args = [
        '-c',
        PYTHON_DRIVER,
        '--workspace',
        workspace,
        '--operation',
        operation,
        '--source-file',
        sourceFile ?? '',
        '--target-format',
        targetFormat ?? '',
        '--result-file',
        resultFile ?? '',
        '--module-path',
        `${projectRoot}/${PYTHON_MODULE_PATH}`
      ];

      const { stdout } = await execFileAsync('python3', args);
      const handoff = JSON.parse(stdout);

      return {
        success: handoff?.status === 'success',
        data: handoff?.data ?? {},
        warnings: handoff?.warnings ?? [],
        errors: handoff?.errors ?? []
      };
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
