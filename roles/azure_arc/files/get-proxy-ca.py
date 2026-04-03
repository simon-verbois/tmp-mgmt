import socket, threading, subprocess, sys

PROXY_HOST = sys.argv[1]
PROXY_PORT = int(sys.argv[2])
TARGET_HOST = sys.argv[3]
TARGET_PORT = int(sys.argv[4])
OUTPUT = sys.argv[5]

srv = socket.socket()
srv.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
srv.bind(('127.0.0.1', 18443))
srv.listen(1)

def relay():
    conn, _ = srv.accept()
    prx = socket.create_connection((PROXY_HOST, PROXY_PORT), timeout=10)
    prx.sendall(
        ('CONNECT {0}:{1} HTTP/1.1\r\nHost: {0}:{1}\r\n\r\n'.format(TARGET_HOST, TARGET_PORT)).encode()
    )
    r = b''
    while b'\r\n\r\n' not in r:
        r += prx.recv(1)
    stop = threading.Event()
    def fwd(src, dst):
        try:
            while not stop.is_set():
                d = src.recv(4096)
                if not d: break
                dst.sendall(d)
        finally:
            stop.set()
    threading.Thread(target=fwd, args=(conn, prx)).start()
    threading.Thread(target=fwd, args=(prx, conn)).start()
    stop.wait(30)

t = threading.Thread(target=relay)
t.daemon = True
t.start()

out, _ = subprocess.Popen(
    ['openssl', 's_client', '-showcerts', '-connect', '127.0.0.1:18443'],
    stdin=open('/dev/null'), stdout=subprocess.PIPE, stderr=subprocess.PIPE
).communicate()

certs, buf = [], []
for line in out.decode('latin-1').splitlines():
    if '-----BEGIN CERTIFICATE-----' in line: buf = [line]
    elif '-----END CERTIFICATE-----' in line and buf:
        buf.append(line); certs.append('\n'.join(buf)); buf = []
    elif buf: buf.append(line)

if not certs:
    sys.stderr.write('NO CERT FOUND\n')
    sys.exit(1)

with open(OUTPUT, 'w') as f:
    f.write(certs[-1] + '\n')