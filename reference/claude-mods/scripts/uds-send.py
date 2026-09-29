#!/usr/bin/env python3
"""Write one user message straight into a running Claude Code session's peer socket.

usage: uds-send.py <CLAUDE_CONFIG_DIR> <pid> <text> [--from-name NAME]

Reads <config>/sessions/<pid>.json (messagingSocketPath, sessionId) and the peerToken in
<config>/sessions/<pid>.*.key, then sends an auth frame and a `type: "user"` frame, one JSON
object per line. The session exists in sessions/ only after workspace trust is accepted.
"""
import argparse
import glob
import json
import socket
import sys
import uuid


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("config_dir")
    ap.add_argument("pid")
    ap.add_argument("text")
    ap.add_argument("--from-name", default="lab-sender")
    args = ap.parse_args()

    state_path = f"{args.config_dir}/sessions/{args.pid}.json"
    keys = glob.glob(f"{args.config_dir}/sessions/{args.pid}.*.key")
    if not keys:
        print(f"no key file for pid {args.pid} under {args.config_dir}/sessions", file=sys.stderr)
        return 1
    with open(state_path) as f:
        state = json.load(f)
    with open(keys[0]) as f:
        token = json.load(f)["peerToken"]

    mid = f"lab-{uuid.uuid4().hex[:8]}"
    content = (
        f'<cross-session-message from="lab" from-name="{args.from_name}" from-mode="prompting">\n'
        f"{args.text}\n</cross-session-message>"
    )
    frames = [
        {"type": "auth", "token": token},
        {"type": "user", "session_id": state["sessionId"], "msg_id": mid, "message": {"content": content}},
    ]
    payload = "".join(json.dumps(fr) + "\n" for fr in frames).encode()

    s = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
    s.connect(state["messagingSocketPath"])
    s.sendall(payload)
    s.settimeout(2)
    try:
        data = s.recv(4096)
        print("recv", repr(data))
    except socket.timeout:
        print("recv none (no reply within 2 s; delivery shows only on the receiving session)")
    finally:
        s.close()
    print("sent", mid, "to", state["messagingSocketPath"])
    return 0


if __name__ == "__main__":
    sys.exit(main())
