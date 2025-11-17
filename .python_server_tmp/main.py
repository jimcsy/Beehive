import flask, sys, io
from flask import request, jsonify

app = flask.Flask(__name__)

@app.route("/execute", methods=["POST"])
def execute():
    code = request.form.get('code', '')
    console_output = io.StringIO()
    sys.stdout = console_output # Redirect print()

    try:
        exec(code) # Run the user's code
        output = console_output.getvalue()
        return jsonify({"output": output, "error": ""})
    except Exception as e:
        output = console_output.getvalue()
        return jsonify({"output": output, "error": str(e)}), 400
    finally:
        sys.stdout = sys.__stdout__ # Reset print()

if __name__ == "__main__":
    app.run(host='0.0.0.0', port=5000)