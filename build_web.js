/**
 * Slime Split - Web Build Script
 * Replicates LÖVE Web Builder's packaging process locally.
 * Walks the game source tree and embeds each file individually into
 * the Emscripten virtual filesystem (the same way the online Web Builder works).
 *
 * Usage: node build_web.js
 */

const fs = require('fs');
const path = require('path');
const https = require('https');

const LOVE_JS_URL = 'https://schellingb.github.io/LoveWebBuilder/love.js';
const BUILD_DIR = path.join(__dirname, 'build', 'web');
const GAME_TITLE = 'Slime Split';
const GAME_FILENAME = 'slime-split';
const RES_X = 640;
const RES_Y = 480;
const MEMORY_MB = 256;
const STACK_MB = 8;

// Game source files to embed (relative to project root)
const GAME_ROOT = __dirname;
const GAME_FILES_PATTERNS = ['main.lua', 'conf.lua', 'src'];

fs.mkdirSync(BUILD_DIR, { recursive: true });

function download(url) {
    return new Promise((resolve, reject) => {
        console.log(`Downloading ${url} ...`);
        const get = (u) => {
            https.get(u, { headers: { 'User-Agent': 'Mozilla/5.0' } }, (res) => {
                if (res.statusCode >= 300 && res.statusCode < 400 && res.headers.location) {
                    get(res.headers.location);
                    return;
                }
                if (res.statusCode !== 200) {
                    reject(new Error(`HTTP ${res.statusCode}`));
                    return;
                }
                const chunks = [];
                let received = 0;
                res.on('data', (chunk) => {
                    chunks.push(chunk);
                    received += chunk.length;
                    process.stdout.write(`\r  Downloaded ${(received / 1024 / 1024).toFixed(1)} MB`);
                });
                res.on('end', () => {
                    console.log(' Done');
                    resolve(Buffer.concat(chunks));
                });
                res.on('error', reject);
            }).on('error', reject);
        };
        get(url);
    });
}

/**
 * Recursively collect all files under a directory.
 * Returns array of {absPath, relPath} where relPath is relative to rootDir.
 */
function walkDir(dir, rootDir) {
    let results = [];
    const entries = fs.readdirSync(dir, { withFileTypes: true });
    for (const entry of entries) {
        const absPath = path.join(dir, entry.name);
        const relPath = path.relative(rootDir, absPath).replace(/\\/g, '/');
        if (entry.isDirectory()) {
            results = results.concat(walkDir(absPath, rootDir));
        } else if (entry.isFile()) {
            results.push({ absPath, relPath });
        }
    }
    return results;
}

/**
 * Build the FS JavaScript: create directories and embed each file as base64.
 * The virtual FS layout is /l/<relPath> for each game file.
 * This matches how LÖVE Web Builder handles multi-file uploads.
 */
function buildFsJs() {
    let fsjs = '';
    const createdDirs = new Set();
    const allFiles = [];

    // Collect all game files
    for (const pattern of GAME_FILES_PATTERNS) {
        const fullPath = path.join(GAME_ROOT, pattern);
        const stat = fs.statSync(fullPath);
        if (stat.isDirectory()) {
            const files = walkDir(fullPath, GAME_ROOT);
            allFiles.push(...files);
        } else {
            allFiles.push({
                absPath: fullPath,
                relPath: pattern.replace(/\\/g, '/')
            });
        }
    }

    // Create root /l directory
    fsjs += "FS.mkdir('/l');\n";
    createdDirs.add('/l');

    // Create all needed subdirectories and files
    for (const file of allFiles) {
        // Ensure parent directories exist
        const parts = file.relPath.split('/');
        let dirPath = '/l';
        for (let i = 0; i < parts.length - 1; i++) {
            dirPath += '/' + parts[i];
            if (!createdDirs.has(dirPath)) {
                fsjs += "FS.mkdir('" + dirPath + "');\n";
                createdDirs.add(dirPath);
            }
        }

        const parentDir = '/l/' + parts.slice(0, -1).join('/');
        const fileName = parts[parts.length - 1];
        const parent = parts.length > 1 ? parentDir : '/l';

        // Embed file data as base64
        let data = fs.readFileSync(file.absPath);

        // Patch conf.lua: remove t.version line to avoid compatibility warning
        // (love.js runtime is LÖVE 0.11.0, our conf declares 11.4)
        if (fileName === 'conf.lua') {
            let src = data.toString('utf-8');
            src = src.replace(/^\s*t\.version\s*=\s*"[^"]*"\s*$/m, '    -- t.version removed for web build compatibility');
            data = Buffer.from(src, 'utf-8');
            console.log('  Patched conf.lua: removed t.version for web compatibility');
        }

        const b64 = data.toString('base64');

        fsjs += "FS.createDataFile('" + parent + "','" + fileName + "',FS.DEC('" + b64 + "'),!0,!0,!0);\n";
    }

    console.log(`  Embedded ${allFiles.length} files, ${createdDirs.size} directories`);
    return fsjs;
}

function buildHtml(title, filename, resX, resY, memoryMB, stackMB) {
    const nl = '\n';
    let html = '';

    html += '<!DOCTYPE html>' + nl;
    html += '<html lang="en-us">' + nl;
    html += '<head>' + nl;
    html += '\t<meta charset="utf-8">' + nl;
    html += '\t<meta name="viewport" content="width=device-width, initial-scale=1">' + nl;
    html += '\t<title>' + title + '</title>' + nl;
    html += '\t<style type="text/css">' + nl;
    html += 'html, body' + nl;
    html += '{' + nl;
    html += '\tbackground-color: #111128;' + nl;
    html += '\tmargin: 0;' + nl;
    html += '\theight: 100%;' + nl;
    html += '\tfont-family: "Courier New", monospace;' + nl;
    html += '\tfont-size: 18px;' + nl;
    html += '\tcolor: #e0e0f0;' + nl;
    html += '}' + nl;
    html += '#wrapper' + nl;
    html += '{' + nl;
    html += '\tmargin: 0 0 -21px;' + nl;
    html += '\tpadding: 1px;' + nl;
    html += '\tmin-height: 100%;' + nl;
    html += '\tborder-bottom: 21px solid transparent;' + nl;
    html += '\tbox-sizing: border-box;' + nl;
    html += '}' + nl;
    html += '#title' + nl;
    html += '{' + nl;
    html += '\tbackground-color: #2ecc40;' + nl;
    html += '\tmargin: 9px auto;' + nl;
    html += '\tmax-width: ' + resX + 'px;' + nl;
    html += '\tpadding: .5em;' + nl;
    html += '\tborder: 1px solid #1a8a2a;' + nl;
    html += '\tborder-radius: 10px;' + nl;
    html += '\tbox-shadow: 3px 3px 0 0 rgba(0,0,0,0.3);' + nl;
    html += '\ttext-align: center;' + nl;
    html += '\tcolor: #111128;' + nl;
    html += '\tfont-weight: bold;' + nl;
    html += '}' + nl;
    html += '#main' + nl;
    html += '{' + nl;
    html += '\tbackground-color: #1a1a3e;' + nl;
    html += '\tmargin: 9px auto;' + nl;
    html += '\tmax-width: ' + (resX + 30) + 'px;' + nl;
    html += '\tpadding: 15px 0;' + nl;
    html += '\tborder: 1px solid #333;' + nl;
    html += '\tborder-radius: 10px;' + nl;
    html += '\tbox-shadow: 3px 3px 0 0 rgba(0,0,0,0.3);' + nl;
    html += '}' + nl;
    html += '#controls' + nl;
    html += '{' + nl;
    html += '\tmargin: 8px auto;' + nl;
    html += '\tmax-width: ' + resX + 'px;' + nl;
    html += '\ttext-align: center;' + nl;
    html += '\tfont-size: 13px;' + nl;
    html += '\tcolor: #888;' + nl;
    html += '}' + nl;
    html += '#controls kbd' + nl;
    html += '{' + nl;
    html += '\tbackground: #222;' + nl;
    html += '\tborder: 1px solid #555;' + nl;
    html += '\tborder-radius: 3px;' + nl;
    html += '\tpadding: 1px 6px;' + nl;
    html += '\tfont-family: inherit;' + nl;
    html += '\tcolor: #ccc;' + nl;
    html += '}' + nl;
    html += '#footer' + nl;
    html += '{' + nl;
    html += '\tpadding-top: 3px;' + nl;
    html += '\theight: 17px;' + nl;
    html += '\tborder-top: 1px dashed #444;' + nl;
    html += '\tcolor: #666;' + nl;
    html += '\tfont-size: 9pt;' + nl;
    html += '\ttext-align: center;' + nl;
    html += '}' + nl;
    html += '#footer a { color: #2ecc40; }' + nl;
    html += '@media (max-width: 850px)' + nl;
    html += '{' + nl;
    html += '\t#wrapper { font-size: 80%; }' + nl;
    html += '\t#title { padding: .2em; }' + nl;
    html += '}' + nl;
    html += '\t</style>' + nl;
    html += '</head>' + nl;
    html += '<body>' + nl;
    html += '<div id="wrapper">' + nl;
    html += '\t<h1 id="title">' + title + '</h1>' + nl;
    html += '\t<div id="main">' + nl;
    html += '\t\t<center><canvas id="canvas" width="' + resX + '" height="' + resY + '" style="max-width:100%;background:#000;vertical-align:middle"></canvas></center>' + nl;
    html += '\t</div>' + nl;
    html += '\t<div id="controls">' + nl;
    html += '\t\t<kbd>\u2190</kbd><kbd>\u2192</kbd> Move &nbsp; ';
    html += '<kbd>Space</kbd> Jump &nbsp; ';
    html += '<kbd>Shift</kbd> Split &nbsp; ';
    html += '<kbd>M</kbd> Merge &nbsp; ';
    html += '<kbd>Tab</kbd> Switch &nbsp; ';
    html += '<kbd>R</kbd> Restart' + nl;
    html += '\t</div>' + nl;
    html += '</div>' + nl;
    html += '<div id="footer">Made with <a href="https://love2d.org/" target="_blank">L\u00D6VE</a></div>' + nl;

    // JavaScript game launcher
    html += '<scr' + 'ipt type="text/javascript">(function(){' + nl;
    html += "var TXT =" + nl;
    html += "{" + nl;
    html += "\tPLAYBTN: 'Click to Play'," + nl;
    html += "\tLOAD:    'Downloading Game...'," + nl;
    html += "\tPARSE:   'Preparing Game...'," + nl;
    html += "\tEXECUTE: 'Starting Game...'," + nl;
    html += "\tDLERROR: 'Error while downloading game data.\\nCheck your internet connection.'," + nl;
    html += "\tNOWEBGL: 'Your browser does not support <a href=\"http://khronos.org/webgl/wiki/Getting_a_WebGL_Implementation\">WebGL</a>.<br>Find out how to get it <a href=\"http://get.webgl.org/\">here</a>.'," + nl;
    html += "};" + nl;
    html += "var canvas = document.getElementById('canvas'), ctx;" + nl;
    html += "var Msg = function(m)" + nl;
    html += "{" + nl;
    html += "\tctx.clearRect(0, 0, canvas.width, canvas.height);" + nl;
    html += "\tctx.fillStyle = '#888';" + nl;
    html += "\tfor (var i = 0, a = m.split('\\n'), n = a.length; i != n; i++)" + nl;
    html += "\t\tctx.fillText(a[i], canvas.width/2, canvas.height/2-(n-1)*20+10+i*40);" + nl;
    html += "};" + nl;
    html += "var Fail = function(m)" + nl;
    html += "{" + nl;
    html += "\tcanvas.outerHTML = '<div style=\"max-width:90%;width:'+canvas.clientWidth+'px;height:'+canvas.clientHeight+'px;background:#000;display:table-cell;vertical-align:middle\"><div style=\"background-color:#FFF;color:#000;padding:1.5em;max-width:640px;width:80%;margin:auto;text-align:center\">'+TXT.NOWEBGL+(m?'<br><br>'+m:'')+'</div></div>';" + nl;
    html += "};" + nl;

    // DoExecute: run the game from /l directory
    html += "var DoExecute = function()" + nl;
    html += "{" + nl;
    html += "\tMsg(TXT.EXECUTE);" + nl;
    html += "\tModule.canvas = canvas.cloneNode(false);" + nl;
    html += "\tModule.canvas.oncontextmenu = function(e) { e.preventDefault() };" + nl;
    html += "\tModule.setWindowTitle = function(title) { };" + nl;
    html += "\tModule.postRun = function()" + nl;
    html += "\t{" + nl;
    html += "\t\tif (!Module.noExitRuntime) { Fail(); return; }" + nl;
    html += "\t\tcanvas.parentNode.replaceChild(Module.canvas, canvas);" + nl;
    html += "\t\tTxt = Msg = ctx = canvas = null;" + nl;
    html += "\t\tModule.canvas.focus();" + nl;
    html += "\t};" + nl;
    // Run from /l — the directory containing our individual game files
    html += "\tsetTimeout(function() { Module.run(['/l']); }, 50);" + nl;
    html += "};" + nl;

    // DoLoad with progress bar
    html += "var DoLoad = function()" + nl;
    html += "{" + nl;
    html += "\tMsg(TXT.LOAD);" + nl;
    html += "\tvar xhr = new XMLHttpRequest();" + nl;
    html += "\txhr.open('GET', '" + filename + ".js');" + nl;
    html += "\txhr.onprogress = function(e)" + nl;
    html += "\t{" + nl;
    html += "\t\tif (!e.lengthComputable || ctx.pCnt++ < 5) return;" + nl;
    html += "\t\tvar x = canvas.width/2-150, y = canvas.height*.6, w = Math.min(e.loaded/e.total,1)*300, g = ctx.createLinearGradient(x,0,x+w,0);" + nl;
    html += "\t\tg.addColorStop(0,'#2ecc40');g.addColorStop(1,'#45d659');" + nl;
    html += "\t\tctx.fillStyle = '#111'; ctx.fillRect(x-2,y-2,304,28);" + nl;
    html += "\t\tctx.fillStyle = '#222'; ctx.fillRect(x  ,y  ,300,24);" + nl;
    html += "\t\tctx.fillStyle = g;      ctx.fillRect(x  ,y  ,w,  24);" + nl;
    html += "\t};" + nl;
    html += "\txhr.onerror = xhr.onabort = function() { Msg(TXT.DLERROR); canvas.disabled = false; };" + nl;
    html += "\txhr.onload = function()" + nl;
    html += "\t{" + nl;
    html += "\t\tif (xhr.status != 200) { Msg(TXT.DLERROR + '\\nStatus: ' + xhr.statusText ); canvas.disabled = false; return; }" + nl;
    html += "\t\tMsg(TXT.PARSE);" + nl;
    html += "\t\tsetTimeout(function()" + nl;
    html += "\t\t{" + nl;
    html += "\t\t\twindow.onerror = function(e,u,l) { Fail(e+'<br>('+u+':'+l+')'); };" + nl;
    html += "\t\t\tModule = { TOTAL_MEMORY: 1024*1024*" + memoryMB + ", TOTAL_STACK: 1024*1024*" + stackMB + ", currentScriptUrl: '-', preInit: DoExecute };" + nl;
    html += "\t\t\tvar s = document.createElement('script'), d = document.documentElement;" + nl;
    html += "\t\t\ts.textContent = xhr.response;" + nl;
    html += "\t\t\td.appendChild(s);" + nl;
    html += "\t\t\td.removeChild(s);" + nl;
    html += "\t\t\txhr = xhr.response = s = s.textContent = null;" + nl;
    html += "\t\t},50);" + nl;
    html += "\t};" + nl;
    html += "\txhr.send();" + nl;
    html += "}" + nl;

    // DoSetup - click to play
    html += "var DoSetup = function()" + nl;
    html += "{" + nl;
    html += "\tcanvas.onclick = function()" + nl;
    html += "\t{" + nl;
    html += "\t\tif (canvas.disabled) return;" + nl;
    html += "\t\tcanvas.disabled = true;" + nl;
    html += "\t\tcanvas.scrollIntoView();" + nl;
    html += "\t\tctx.pCnt = 0;" + nl;
    html += "\t\tDoLoad();" + nl;
    html += "\t};" + nl;
    html += "\tctx.fillStyle = '#888';" + nl;
    html += "\tctx.fillRect(canvas.width/2-254, canvas.height/2-104, 508, 208);" + nl;
    html += "\tctx.fillStyle = '#1a1a3e';" + nl;
    html += "\tctx.fillRect(canvas.width/2-250, canvas.height/2-100, 500, 200);" + nl;
    html += "\tctx.fillStyle = '#2ecc40';" + nl;
    html += "\tctx.fillText(TXT.PLAYBTN, canvas.width/2, canvas.height/2+10);" + nl;
    html += "};" + nl;

    // Canvas init
    html += "canvas.oncontextmenu = function(e) { e.preventDefault() };" + nl;
    html += "ctx = canvas.getContext('2d');" + nl;
    html += "ctx.font = '30px \"Courier New\", monospace';" + nl;
    html += "ctx.textAlign = 'center';" + nl;
    html += "DoSetup();" + nl;
    html += '})()</scr' + 'ipt>' + nl;
    html += '</body>' + nl + '</html>' + nl;

    return html;
}

async function main() {
    console.log('=== Slime Split Web Build ===\n');

    // Step 1: Check if love.js is already cached
    const loveJsCache = path.join(__dirname, 'build', 'love.js.cache');
    let loveJs;
    if (fs.existsSync(loveJsCache)) {
        console.log('Using cached love.js runtime');
        loveJs = fs.readFileSync(loveJsCache, 'utf-8');
    } else {
        const buf = await download(LOVE_JS_URL);
        loveJs = buf.toString('utf-8');
        fs.writeFileSync(loveJsCache, loveJs);
        console.log(`Cached love.js (${(buf.length / 1024 / 1024).toFixed(1)} MB)`);
    }

    // Step 2: Walk source tree and build FS embed code
    console.log('Embedding game files into virtual filesystem...');
    const fsjs = buildFsJs();
    console.log(`  Total FS code: ${(fsjs.length / 1024).toFixed(1)} KB`);

    // Step 3: Build the combined JS file (love.js runtime + FS data)
    console.log('Building JS bundle...');
    const jsContent = loveJs + '\n' + fsjs;
    const jsPath = path.join(BUILD_DIR, GAME_FILENAME + '.js');
    fs.writeFileSync(jsPath, jsContent);
    console.log(`Written: ${GAME_FILENAME}.js (${(jsContent.length / 1024 / 1024).toFixed(1)} MB)`);

    // Step 4: Build HTML file
    console.log('Building HTML...');
    const html = buildHtml(GAME_TITLE, GAME_FILENAME, RES_X, RES_Y, MEMORY_MB, STACK_MB);
    const htmlPath = path.join(BUILD_DIR, GAME_FILENAME + '.html');
    fs.writeFileSync(htmlPath, html);
    fs.writeFileSync(path.join(BUILD_DIR, 'index.html'), html);
    console.log(`Written: ${GAME_FILENAME}.html`);
    console.log(`Written: index.html (copy)`);

    // Step 5: Summary
    const jsSize = fs.statSync(jsPath).size;
    const htmlSize = fs.statSync(htmlPath).size;
    console.log('\n=== Build Complete ===');
    console.log(`Output directory: ${BUILD_DIR}`);
    console.log(`  ${GAME_FILENAME}.html  (${(htmlSize / 1024).toFixed(1)} KB)`);
    console.log(`  ${GAME_FILENAME}.js    (${(jsSize / 1024 / 1024).toFixed(1)} MB)`);
    console.log(`  index.html      (copy of ${GAME_FILENAME}.html)`);
    console.log('\nTo test locally:');
    console.log('  npx serve build/web');
    console.log('\nTo deploy to itch.io:');
    console.log('  1. Zip the build/web/ folder');
    console.log('  2. Upload to itch.io, check "This file will be played in the browser"');
    console.log('  3. Set viewport to 640x480');
}

main().catch((err) => {
    console.error('Build failed:', err);
    process.exit(1);
});
