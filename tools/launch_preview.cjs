const {spawnSync} = require('node:child_process');
const {join} = require('node:path');
const choices = process.platform === 'win32' ? [['py', '-3'], ['python']] : [['python3'], ['python']];
for (const [binary, ...prefix] of choices) {
  const probe = spawnSync(binary, [...prefix, '--version'], {stdio: 'ignore'});
  if (probe.error || probe.status !== 0) continue;
  const result = spawnSync(binary, [...prefix, join(__dirname, 'preview.py'), ...process.argv.slice(2)], {stdio: 'inherit'});
  process.exit(result.status ?? 1);
}
console.error('Python 3.10+ fehlt. Installieren und Terminal neu öffnen.');
process.exit(1);
