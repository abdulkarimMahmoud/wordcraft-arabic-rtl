#!/usr/bin/env python3
"""Launch the installed GUI under Xvfb and verify its Arabic control response."""
import json, os, pathlib, socket, subprocess, sys, tempfile, time

binary = os.environ.get('WORDCRAFT_TEST_BINARY', '/usr/bin/wordcraft')
port = 17981
workspace = pathlib.Path(os.environ.get('RUNNER_TEMP', '/tmp'))
profile = pathlib.Path(tempfile.mkdtemp(prefix='wordcraft-ci-profile-', dir=workspace))
runtime = profile / 'runtime'
runtime.mkdir(mode=0o700)
screenshot = pathlib.Path(os.environ.get('WORDCRAFT_GUI_SCREENSHOT', str(workspace / 'wordcraft-arabic-gui.png')))
log_path = workspace / 'wordcraft-gui-smoke.log'
env = os.environ.copy()
env.update({
    'WORDCRAFT_PROFILE_DIR': str(profile),
    'WORDCRAFT_LANGUAGE': 'ar',
    'XDG_RUNTIME_DIR': str(runtime),
    'LIBGL_ALWAYS_SOFTWARE': '1',
    'WGPU_BACKEND': 'gl',
    'XDG_SESSION_TYPE': 'x11',
})
key_file = profile / f'control-key.local-{port}'

def call(key, method, params):
    request = {'id': 1, 'key': key, 'method': method, 'params': params}
    with socket.create_connection(('127.0.0.1', port), timeout=10) as conn:
        conn.settimeout(30)
        conn.sendall((json.dumps(request) + '\n').encode())
        with conn.makefile('rb') as stream:
            line = stream.readline(4 * 1024 * 1024)
    if not line:
        raise RuntimeError('App returned no control reply')
    reply = json.loads(line)
    if not reply.get('ok'):
        raise RuntimeError('App control error: ' + str(reply.get('error')))
    return reply.get('result', {})

with log_path.open('wb') as log:
    process = subprocess.Popen([binary, '--sample', '--control', str(port)], env=env, stdout=log, stderr=subprocess.STDOUT)
    try:
        deadline = time.monotonic() + 75
        response = None
        while time.monotonic() < deadline:
            if process.poll() is not None:
                raise RuntimeError(f'GUI exited early with code {process.returncode}')
            if key_file.is_file():
                try:
                    key = key_file.read_text(encoding='utf-8').strip()
                    response = call(key, 'engine.execute', {'command': 'ui.language', 'params': {}})
                    break
                except (OSError, TimeoutError):
                    pass
            time.sleep(0.5)
        if response is None:
            raise RuntimeError('GUI control channel did not become ready')
        if response.get('effective') != 'ar':
            raise RuntimeError('Arabic is not active; reported effective=' + str(response.get('effective')))
        print('GUI_ARABIC_OK: running GUI reports effective language ar', flush=True)
        phrase = 'مرحبا بالعالم'
        call(key, 'engine.execute', {'command': 'text.insert', 'params': {'text': phrase}})
        document = call(key, 'document.inspect', {'text': True})
        if phrase not in json.dumps(document, ensure_ascii=False):
            raise RuntimeError('Arabic text did not round-trip through the editor')
        print('GUI_ARABIC_TEXT_OK: Arabic text round-tripped through the editor', flush=True)
        time.sleep(2)  # allow the edited frame to be presented on the virtual display
        for attempt in range(3):
            try:
                call(key, 'ui.screenshot', {'path': str(screenshot)})
                break
            except RuntimeError:
                if attempt == 2:
                    raise
                time.sleep(2)
        if not screenshot.is_file() or screenshot.stat().st_size < 1000:
            raise RuntimeError('GUI screenshot missing or too small')
        print('GUI_SCREENSHOT_OK:', screenshot, screenshot.stat().st_size, 'bytes', flush=True)
    except Exception:
        log.flush()
        print('GUI smoke test failed; app log follows:', file=sys.stderr, flush=True)
        try:
            print(log_path.read_text(encoding='utf-8', errors='replace')[-12000:], file=sys.stderr)
        except OSError:
            pass
        raise
    finally:
        process.terminate()
        try:
            process.wait(timeout=10)
        except subprocess.TimeoutExpired:
            process.kill()
            process.wait(timeout=10)
