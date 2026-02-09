/**
 * Slime Split - One-Click Build & Deploy Script
 *
 * Builds all distribution packages and pushes them to itch.io via butler.
 *
 * Usage:
 *   node deploy.js                  Build all + deploy all
 *   node deploy.js --build-only     Build all, skip deploy
 *   node deploy.js --deploy-only    Skip build, deploy existing artifacts
 *   node deploy.js --web            Build & deploy web only
 *   node deploy.js --win            Build & deploy windows only
 *   node deploy.js --dry-run        Show what would be pushed, don't actually push
 *   node deploy.js --version 1.2.0  Tag this push with a version number
 */

const fs = require('fs');
const path = require('path');
const { execSync, spawnSync } = require('child_process');

// ─── Configuration ──────────────────────────────────────────────────────────

const CONFIG = {
    // itch.io
    ITCH_USER: 'chanmeng666',
    ITCH_GAME: 'slime-split',

    // Channels (auto-tagged by butler based on name)
    CHANNELS: {
        web:  'html5',
        win:  'windows',
        love: 'love',
    },

    // Paths
    LOVE_DIR:     'C:\\Program Files\\LOVE',
    BUTLER_PATH:  'D:\\tools\\butler\\butler.exe',
    PROJECT_ROOT: __dirname,
    BUILD_DIR:    path.join(__dirname, 'build'),

    // Game
    GAME_NAME: 'slime-split',
    SRC_FILES: ['main.lua', 'conf.lua', 'src'],
};

// ─── Helpers ────────────────────────────────────────────────────────────────

const log = (msg) => console.log(msg);
const ok  = (msg) => console.log(`  [OK] ${msg}`);
const err = (msg) => { console.error(`  [ERROR] ${msg}`); process.exit(1); };

function run(cmd, opts = {}) {
    const result = spawnSync(cmd, { shell: true, stdio: 'inherit', cwd: CONFIG.PROJECT_ROOT, ...opts });
    if (result.status !== 0) {
        err(`Command failed (exit ${result.status}): ${cmd}`);
    }
    return result;
}

function runSilent(cmd) {
    return execSync(cmd, { cwd: CONFIG.PROJECT_ROOT, encoding: 'utf-8' }).trim();
}

function ensureDir(dir) {
    fs.mkdirSync(dir, { recursive: true });
}

function fileSize(filepath) {
    try {
        const bytes = fs.statSync(filepath).size;
        if (bytes > 1024 * 1024) return (bytes / 1024 / 1024).toFixed(1) + ' MB';
        return (bytes / 1024).toFixed(0) + ' KB';
    } catch { return '?'; }
}

// ─── Parse CLI args ─────────────────────────────────────────────────────────

const args = process.argv.slice(2);
const flags = {
    buildOnly:  args.includes('--build-only'),
    deployOnly: args.includes('--deploy-only'),
    webOnly:    args.includes('--web'),
    winOnly:    args.includes('--win'),
    dryRun:     args.includes('--dry-run'),
    version:    null,
};

const vIdx = args.indexOf('--version');
if (vIdx !== -1 && args[vIdx + 1]) {
    flags.version = args[vIdx + 1];
}

const doBuild  = !flags.deployOnly;
const doDeploy = !flags.buildOnly;
const targets  = {
    web:  !flags.winOnly,
    win:  !flags.webOnly,
    love: !flags.winOnly && !flags.webOnly,
};

// ─── Preflight checks ──────────────────────────────────────────────────────

function preflight() {
    log('\n=== Preflight Checks ===\n');

    // butler
    if (!fs.existsSync(CONFIG.BUTLER_PATH)) {
        err(`butler not found at ${CONFIG.BUTLER_PATH}\n  Download from https://itchio.itch.io/butler`);
    }
    const butlerVer = runSilent(`"${CONFIG.BUTLER_PATH}" version`);
    ok(`butler: ${butlerVer}`);

    // butler login
    const credsPath = path.join(process.env.USERPROFILE || process.env.HOME, '.config', 'itch', 'butler_creds');
    if (!fs.existsSync(credsPath)) {
        err(`butler not logged in. Run: "${CONFIG.BUTLER_PATH}" login`);
    }
    ok('butler credentials found');

    // LOVE
    if (doBuild && targets.win) {
        const loveExe = path.join(CONFIG.LOVE_DIR, 'love.exe');
        if (!fs.existsSync(loveExe)) {
            log(`  [WARN] LOVE not found at ${CONFIG.LOVE_DIR}, Windows build will be skipped`);
            targets.win = false;
        } else {
            ok(`LOVE: ${CONFIG.LOVE_DIR}`);
        }
    }

    // Node (for web build)
    if (doBuild && targets.web) {
        const nodeVer = runSilent('node --version');
        ok(`Node.js: ${nodeVer}`);
    }

    // Source files
    for (const f of CONFIG.SRC_FILES) {
        const p = path.join(CONFIG.PROJECT_ROOT, f);
        if (!fs.existsSync(p)) err(`Source not found: ${p}`);
    }
    ok('Source files present');

    log('');
}

// ─── Build: .love file ─────────────────────────────────────────────────────

function buildLove() {
    log('[Build] Creating .love file...');
    ensureDir(CONFIG.BUILD_DIR);

    const lovePath = path.join(CONFIG.BUILD_DIR, `${CONFIG.GAME_NAME}.love`);

    // Remove old .love
    try { fs.unlinkSync(lovePath); } catch {}
    // Remove temp zip too
    const zipPath = lovePath.replace('.love', '.zip');
    try { fs.unlinkSync(zipPath); } catch {}

    // Create zip via PowerShell
    const srcList = CONFIG.SRC_FILES.map(f => `'${f}'`).join(',');
    run(`powershell -Command "Compress-Archive -Path ${srcList} -DestinationPath '${zipPath}' -Force"`);

    // Rename .zip → .love
    fs.renameSync(zipPath, lovePath);
    ok(`${lovePath} (${fileSize(lovePath)})`);
    return lovePath;
}

// ─── Build: Windows exe ─────────────────────────────────────────────────────

function buildWin(lovePath) {
    log('[Build] Creating Windows executable...');
    const winDir = path.join(CONFIG.BUILD_DIR, `${CONFIG.GAME_NAME}-win64`);
    ensureDir(winDir);

    const loveExe = path.join(CONFIG.LOVE_DIR, 'love.exe');
    const outExe = path.join(winDir, `${CONFIG.GAME_NAME}.exe`);

    // Fuse love.exe + .love → game.exe
    run(`copy /b "${loveExe}"+"${lovePath}" "${outExe}"`, { stdio: 'pipe' });

    // Copy DLLs
    const dllFiles = fs.readdirSync(CONFIG.LOVE_DIR).filter(f => f.endsWith('.dll'));
    for (const dll of dllFiles) {
        fs.copyFileSync(path.join(CONFIG.LOVE_DIR, dll), path.join(winDir, dll));
    }

    // Copy license
    const licenseSrc = path.join(CONFIG.LOVE_DIR, 'license.txt');
    if (fs.existsSync(licenseSrc)) {
        fs.copyFileSync(licenseSrc, path.join(winDir, 'license.txt'));
    }

    ok(`${winDir} (${fileSize(outExe)} exe + DLLs)`);
    return winDir;
}

// ─── Build: Web version ─────────────────────────────────────────────────────

function buildWeb() {
    log('[Build] Creating web version (love.js)...');

    // Remove stale files from web dir (e.g. .love left by old builds)
    const webDir = path.join(CONFIG.BUILD_DIR, 'web');
    if (fs.existsSync(webDir)) {
        for (const f of fs.readdirSync(webDir)) {
            if (f.endsWith('.love')) {
                fs.unlinkSync(path.join(webDir, f));
            }
        }
    }

    run('node build_web.js');

    const jsPath = path.join(webDir, `${CONFIG.GAME_NAME}.js`);
    ok(`build/web/ (${fileSize(jsPath)} JS bundle)`);
    return webDir;
}

// ─── Deploy via butler ──────────────────────────────────────────────────────

function butlerPush(localPath, channel) {
    const target = `${CONFIG.ITCH_USER}/${CONFIG.ITCH_GAME}:${channel}`;

    let cmd = `"${CONFIG.BUTLER_PATH}" push "${localPath}" ${target}`;
    if (flags.version) cmd += ` --userversion ${flags.version}`;
    if (flags.dryRun)  cmd += ` --dry-run`;

    log(`[Deploy] ${localPath} → ${target}${flags.version ? ' v' + flags.version : ''}`);
    run(cmd);
    ok(`Pushed to ${target}`);
}

// ─── Main ───────────────────────────────────────────────────────────────────

function main() {
    log('╔══════════════════════════════════════╗');
    log('║   Slime Split - Build & Deploy       ║');
    log('╚══════════════════════════════════════╝');

    preflight();

    let lovePath = path.join(CONFIG.BUILD_DIR, `${CONFIG.GAME_NAME}.love`);
    let winDir   = path.join(CONFIG.BUILD_DIR, `${CONFIG.GAME_NAME}-win64`);
    let webDir   = path.join(CONFIG.BUILD_DIR, 'web');

    // ── Build phase ──
    if (doBuild) {
        log('=== Build Phase ===\n');
        lovePath = buildLove();
        if (targets.win)  winDir = buildWin(lovePath);
        if (targets.web)  webDir = buildWeb();
        log('\n=== Build Complete ===\n');
    }

    // ── Deploy phase ──
    if (doDeploy) {
        log('=== Deploy Phase ===\n');

        if (flags.dryRun) log('  (DRY RUN — nothing will actually be pushed)\n');

        if (targets.web) {
            if (!fs.existsSync(path.join(webDir, 'index.html'))) {
                err(`Web build not found at ${webDir}. Run without --deploy-only first.`);
            }
            butlerPush(webDir, CONFIG.CHANNELS.web);
        }

        if (targets.win) {
            const exePath = path.join(winDir, `${CONFIG.GAME_NAME}.exe`);
            if (!fs.existsSync(exePath)) {
                err(`Windows build not found at ${winDir}. Run without --deploy-only first.`);
            }
            butlerPush(winDir, CONFIG.CHANNELS.win);
        }

        if (targets.love) {
            if (!fs.existsSync(lovePath)) {
                err(`.love file not found at ${lovePath}. Run without --deploy-only first.`);
            }
            butlerPush(lovePath, CONFIG.CHANNELS.love);
        }

        log('\n=== Deploy Complete ===\n');
        log(`  View your game: https://${CONFIG.ITCH_USER}.itch.io/${CONFIG.ITCH_GAME}`);

        if (flags.dryRun) {
            log('\n  This was a DRY RUN. Re-run without --dry-run to actually push.');
        }
    }

    // ── Summary ──
    log('\n--- Artifacts ---');
    const artifacts = [
        [lovePath,  fileSize(lovePath),  'Cross-platform .love'],
        [winDir,    '-',                 'Windows standalone'],
        [webDir,    '-',                 'Web (browser play)'],
    ];
    for (const [p, size, desc] of artifacts) {
        const exists = fs.existsSync(p);
        log(`  ${exists ? '+' : '-'} ${desc}: ${p}${exists && size !== '-' ? ' (' + size + ')' : ''}`);
    }
    log('');
}

main();
