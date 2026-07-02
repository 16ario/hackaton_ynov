from flask import Flask, render_template, request, jsonify
import requests
import os

app = Flask(__name__)

OLLAMA_URL = os.getenv("OLLAMA_URL", "http://localhost:11434")
MODEL_NAME = os.getenv("OLLAMA_MODEL", "techcorp-phi-financial")


@app.route("/")
def index():
    return render_template("index.html")


@app.route("/api/chat", methods=["POST"])
def chat():
    data = request.get_json() or {}
    user_message = data.get("message", "").strip()

    if not user_message:
        return jsonify({"error": "Message vide."}), 400

    payload = {
        "model": MODEL_NAME,
        "messages": [
            {
                "role": "user",
                "content": user_message
            }
        ],
        "stream": False
    }

    try:
        response = requests.post(
            f"{OLLAMA_URL}/api/chat",
            json=payload,
            timeout=120
        )
        response.raise_for_status()

        result = response.json()
        answer = result.get("message", {}).get("content", "")

        return jsonify({
            "answer": answer,
            "model": result.get("model", MODEL_NAME)
        })

    except requests.exceptions.RequestException as error:
        return jsonify({
            "error": f"Erreur de communication avec Ollama : {error}"
        }), 500


@app.route("/health")
def health():
    try:
        response = requests.get(f"{OLLAMA_URL}/api/tags", timeout=5)
        return jsonify({
            "status": "ok",
            "ollama_available": response.status_code == 200,
            "model": MODEL_NAME
        })
    except requests.exceptions.RequestException:
        return jsonify({
            "status": "error",
            "ollama_available": False,
            "model": MODEL_NAME
        }), 500


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000, debug=True)
