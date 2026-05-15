import os
import time
import json
import datetime
import platform
from flask import Flask, render_template, request, jsonify, Response
import requests as http_requests

app = Flask(__name__)

SCRIPT_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PROMPT_FILE = os.path.join(SCRIPT_DIR, "system_prompt.txt")
CONFIG_FILE = os.path.join(SCRIPT_DIR, "config.json")
HISTORY_DIR = os.path.join(SCRIPT_DIR, "history")

os.makedirs(HISTORY_DIR, exist_ok=True)

def load_config():
    try:
        with open(CONFIG_FILE, "r") as f:
            return json.load(f)
    except:
        return {"backend": "ollama", "model": "camchat", "web_port": 5000}

def get_backend():
    env = os.environ.get("BACKEND", "")
    if env:
        return env
    return load_config().get("backend", "ollama")
def get_llama_url():
    """URL unifiée sur le port 11434 pour Ollama ET llama.cpp"""
    return "http://127.0.0.1:11434/v1/chat/completions"
    port = load_config().get("llama_port", 8080)
    return f"http://127.0.0.1:{port}/v1/chat/completions"

def get_model_name():
    backend = get_backend()
    if backend == "ollama":
        config = load_config()
        return config.get("model", "camchat")
    return None

def load_system_prompt():
    try:
        with open(PROMPT_FILE, "r", encoding="utf-8") as f:
            return f.read().strip()
    except:
        return "You are a helpful local AI assistant."

conversations = {}

bot_stats = {
    "start_time": datetime.datetime.now(),
    "text_queries": 0,
    "last_user": "None",
    "total_tokens": 0,
    "avg_response_time": 0,
    "total_response_time": 0
}

recent_activity = []
saved_conversations = []

def get_uptime():
    delta = datetime.datetime.now() - bot_stats["start_time"]
    days = delta.days
    hours, remainder = divmod(delta.seconds, 3600)
    minutes, _ = divmod(remainder, 60)
    if days > 0:
        return f"{days}d {hours}h {minutes}m"
    elif hours > 0:
        return f"{hours}h {minutes}m"
    return f"{minutes}m"

def log_activity(action, user, prompt, result="OK"):
    entry = {
        "time": datetime.datetime.now().strftime("%H:%M:%S"),
        "type": action,
        "user": user,
        "prompt": prompt[:60] + "..." if len(prompt) > 60 else prompt,
        "result": result
    }
    recent_activity.insert(0, entry)
    if len(recent_activity) > 50:
        recent_activity.pop()

@app.route("/")
def index():
    return render_template("index.html")

@app.route("/chat", methods=["POST"])
def chat():
    data = request.json
    message = data.get("message", "")
    session_id = data.get("session_id", "default")
    username = data.get("username", "user")

    if not message.strip():
        return jsonify({"error": "Empty message"}), 400

    if session_id not in conversations:
        conversations[session_id] = []

    conversations[session_id].append({"role": "user", "content": message})

    if len(conversations[session_id]) > 30:
        conversations[session_id] = conversations[session_id][-30:]

    system_prompt = load_system_prompt()
    messages = [{"role": "system", "content": system_prompt}] + conversations[session_id]

    payload = {
        "messages": messages,
        "temperature": data.get("temperature", 0.7),
        "max_tokens": data.get("max_tokens", 2048),
        "stream": True
    }

    model = get_model_name()
    if model:
        payload["model"] = model

    bot_stats["text_queries"] += 1
    bot_stats["last_user"] = username
    log_activity("CHAT", username, message)

    def generate():
        t_start = time.time()
        try:
            with http_requests.post(get_llama_url(), json=payload, stream=True, timeout=180) as resp:
                if resp.status_code != 200:
                    yield f"data: {json.dumps({'error': f'Server error: {resp.status_code}'})}\n\n"
                    return

                full_response = ""
                for line in resp.iter_lines():
                    if line:
                        line = line.decode("utf-8")
                        if line.startswith("data: "):
                            chunk = line[6:]
                            if chunk.strip() == "[DONE]":
                                break
                            try:
                                obj = json.loads(chunk)
                                delta = obj["choices"][0].get("delta", {})
                                content = delta.get("content", "")
                                if content:
                                    full_response += content
                                    yield f"data: {json.dumps({'content': content})}\n\n"
                            except (json.JSONDecodeError, KeyError, IndexError):
                                continue

                conversations[session_id].append({"role": "assistant", "content": full_response})
                token_count = len(full_response.split())
                bot_stats["total_tokens"] += token_count

                elapsed = time.time() - t_start
                bot_stats["total_response_time"] += elapsed
                if bot_stats["text_queries"] > 0:
                    bot_stats["avg_response_time"] = bot_stats["total_response_time"] / bot_stats["text_queries"]

                yield f"data: {json.dumps({'done': True, 'tokens': token_count, 'time': round(elapsed, 1)})}\n\n"

        except http_requests.ConnectionError:
            yield f"data: {json.dumps({'error': 'Backend not reachable. Is the server running?'})}\n\n"
        except Exception as e:
            yield f"data: {json.dumps({'error': str(e)})}\n\n"

    return Response(generate(), mimetype="text/event-stream")

@app.route("/reset", methods=["POST"])
def reset():
    data = request.json
    session_id = data.get("session_id", "default")
    conversations[session_id] = []
    return jsonify({"status": "ok"})

@app.route("/status")
def status():
    try:
        r = requests.get("http://127.0.0.1:11434/health", timeout=5)
        return jsonify({
            "status": "online" if r.status_code == 200 else "error",
            "backend": get_backend()
        })
    except:
        return jsonify({"status": "offline", "backend": get_backend()})

@app.route("/stats")
def stats():
    return jsonify({
        "uptime": get_uptime(),
        "text_queries": bot_stats["text_queries"],
        "last_user": bot_stats["last_user"],
        "total_tokens": bot_stats["total_tokens"],
        "avg_response_time": round(bot_stats["avg_response_time"], 1),
        "backend": get_backend(),
        "activity": recent_activity[:20]
    })

@app.route("/prompt", methods=["GET", "POST"])
def prompt_editor():
    if request.method == "GET":
        return jsonify({"prompt": load_system_prompt()})
    elif request.method == "POST":
        data = request.json
        new_prompt = data.get("prompt", "")
        if new_prompt.strip():
            with open(PROMPT_FILE, "w", encoding="utf-8") as f:
                f.write(new_prompt)
            log_activity("SYSTEM", "admin", "System prompt updated")
            return jsonify({"status": "ok"})
        return jsonify({"error": "Empty prompt"}), 400

@app.route("/export", methods=["POST"])
def export_chat():
    data = request.json
    session_id = data.get("session_id", "default")
    conv = conversations.get(session_id, [])
    if not conv:
        return jsonify({"error": "No conversation to export"}), 400

    timestamp = datetime.datetime.now().strftime("%Y%m%d_%H%M%S")
    filename = f"chat_{timestamp}.json"
    filepath = os.path.join(HISTORY_DIR, filename)

    export_data = {
        "exported_at": datetime.datetime.now().isoformat(),
        "messages": conv
    }

    with open(filepath, "w", encoding="utf-8") as f:
        json.dump(export_data, f, indent=2, ensure_ascii=False)

    log_activity("EXPORT", "user", f"Exported {len(conv)} messages")
    return jsonify({"status": "ok", "filename": filename, "messages": len(conv)})

@app.route("/history")
def list_history():
    try:
        files = [f for f in os.listdir(HISTORY_DIR) if f.endswith(".json")]
        files.sort(reverse=True)
        history = []
        for f in files[:20]:
            filepath = os.path.join(HISTORY_DIR, f)
            with open(filepath, "r", encoding="utf-8") as fh:
                data = json.load(fh)
                msg_count = len(data.get("messages", []))
                first_msg = ""
                for m in data.get("messages", []):
                    if m["role"] == "user":
                        first_msg = m["content"][:60]
                        break
                history.append({"filename": f, "messages": msg_count, "preview": first_msg, "date": data.get("exported_at", "")})
        return jsonify({"history": history})
    except:
        return jsonify({"history": []})

@app.route("/history/<filename>")
def load_history(filename):
    if ".." in filename or "/" in filename or "\\" in filename:
        return jsonify({"error": "Invalid filename"}), 400
    try:
        filepath = os.path.join(HISTORY_DIR, filename)
        with open(filepath, "r", encoding="utf-8") as f:
            data = json.load(f)
        return jsonify(data)
    except:
        return jsonify({"error": "File not found"}), 404

@app.route("/models")
def list_models():
    backend = get_backend()
    if backend == "ollama":
        try:
            resp = http_requests.get("http://127.0.0.1:11434/api/tags", timeout=5)
            if resp.status_code == 200:
                data = resp.json()
                models = [m["name"] for m in data.get("models", [])]
                config = load_config()
                current = config.get("model", "camchat")
                return jsonify({"models": models, "current": current})
        except:
            pass
    return jsonify({"models": ["camchat"], "current": "camchat"})

if __name__ == "__main__":
    port = int(os.environ.get("WEB_PORT", load_config().get("web_port", 5000)))
    backend = get_backend()
    print(f"\n[CamChat] Backend: {backend}")
    print(f"[CamChat] Web interface: http://localhost:{port}")
    print(f"[CamChat] System prompt: {PROMPT_FILE}\n")
    app.run(host="0.0.0.0", port=port, debug=False)
