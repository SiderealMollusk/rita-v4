# 0005 - Systemd Templates For AI Workers
Date: 2026-03-05
Status: Active research note

## Scope
Provide concrete `systemd` templates for:
1. `stt-worker.service`
2. `tts-worker.service`
3. `ai-gateway.service`

Target host: Debian GPU machine used for local Nextcloud AI workloads.

## Directory layout
Recommended layout:
1. `/opt/ai-workers/stt/` (STT app code)
2. `/opt/ai-workers/tts/` (TTS app code)
3. `/opt/ai-workers/gateway/` (API gateway code/config)
4. `/etc/ai-workers/` (env files)
5. `/var/log/ai-workers/` (optional app logs)

Create service user:
```bash
sudo useradd --system --home /opt/ai-workers --shell /usr/sbin/nologin aiworkers
sudo mkdir -p /opt/ai-workers/{stt,tts,gateway} /etc/ai-workers /var/log/ai-workers
sudo chown -R aiworkers:aiworkers /opt/ai-workers /var/log/ai-workers
```

## Environment files
Use env files so secrets and tunables stay outside unit files.

### `/etc/ai-workers/stt.env`
```bash
HOST=0.0.0.0
PORT=8091
MODEL_SIZE=small
COMPUTE_TYPE=float16
DEVICE=cuda
MAX_AUDIO_SECONDS=7200
LOG_LEVEL=info
```

### `/etc/ai-workers/tts.env`
```bash
HOST=0.0.0.0
PORT=8092
TTS_VOICE=en_US-amy-medium
TTS_RATE=1.0
LOG_LEVEL=info
```

### `/etc/ai-workers/gateway.env`
```bash
HOST=0.0.0.0
PORT=8090
OLLAMA_BASE_URL=http://127.0.0.1:11434
VLLM_BASE_URL=http://127.0.0.1:8000
STT_BASE_URL=http://127.0.0.1:8091
TTS_BASE_URL=http://127.0.0.1:8092
API_TOKEN=replace-with-long-random-token
LOG_LEVEL=info
```

Lock down env permissions:
```bash
sudo chown root:aiworkers /etc/ai-workers/*.env
sudo chmod 640 /etc/ai-workers/*.env
```

## Unit templates

### `/etc/systemd/system/stt-worker.service`
```ini
[Unit]
Description=AI STT Worker (faster-whisper API)
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=aiworkers
Group=aiworkers
WorkingDirectory=/opt/ai-workers/stt
EnvironmentFile=/etc/ai-workers/stt.env
ExecStart=/opt/ai-workers/stt/.venv/bin/python -m app
Restart=always
RestartSec=3
TimeoutStopSec=20
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=strict
ProtectHome=true
ReadWritePaths=/opt/ai-workers/stt /var/log/ai-workers
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
```

### `/etc/systemd/system/tts-worker.service`
```ini
[Unit]
Description=AI TTS Worker (Piper/Coqui API)
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=aiworkers
Group=aiworkers
WorkingDirectory=/opt/ai-workers/tts
EnvironmentFile=/etc/ai-workers/tts.env
ExecStart=/opt/ai-workers/tts/.venv/bin/python -m app
Restart=always
RestartSec=3
TimeoutStopSec=20
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=strict
ProtectHome=true
ReadWritePaths=/opt/ai-workers/tts /var/log/ai-workers
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
```

### `/etc/systemd/system/ai-gateway.service`
```ini
[Unit]
Description=AI Gateway (routes LLM/STT/TTS)
After=network-online.target ollama.service
Wants=network-online.target

[Service]
Type=simple
User=aiworkers
Group=aiworkers
WorkingDirectory=/opt/ai-workers/gateway
EnvironmentFile=/etc/ai-workers/gateway.env
ExecStart=/opt/ai-workers/gateway/.venv/bin/uvicorn app:app --host ${HOST} --port ${PORT}
Restart=always
RestartSec=3
TimeoutStopSec=20
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=strict
ProtectHome=true
ReadWritePaths=/opt/ai-workers/gateway /var/log/ai-workers
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
```

## Enable and run
```bash
sudo systemctl daemon-reload
sudo systemctl enable --now stt-worker.service tts-worker.service ai-gateway.service
sudo systemctl status stt-worker.service tts-worker.service ai-gateway.service
```

## Health checks
```bash
curl -fsS http://127.0.0.1:8091/healthz
curl -fsS http://127.0.0.1:8092/healthz
curl -fsS -H "Authorization: Bearer $API_TOKEN" http://127.0.0.1:8090/healthz
```

## Firewall (internal-only)
Example with UFW (adjust CIDR):
```bash
sudo ufw allow from 192.168.0.0/16 to any port 8090 proto tcp
sudo ufw deny 8090/tcp
sudo ufw deny 8091/tcp
sudo ufw deny 8092/tcp
```

## Notes for Ollama and vLLM coexistence
1. Keep Ollama and vLLM bound to localhost where possible.
2. Let `ai-gateway` be the only network-visible API.
3. Cap per-service concurrency to avoid GPU memory contention.
4. Pin model choices in config and avoid hot-swapping during production calls.
