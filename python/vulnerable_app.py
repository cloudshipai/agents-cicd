#!/usr/bin/env python3
"""
INSECURE Python Application for Security Testing
This file contains intentional security vulnerabilities for testing purposes.
"""

import os
import pickle
import subprocess
import sqlite3
import hashlib
from flask import Flask, request, render_template_string

app = Flask(__name__)

# INSECURE: Hardcoded secrets
SECRET_KEY = 'super-secret-key-12345'
API_KEY = 'sk-1234567890abcdef1234567890abcdef'
DATABASE_PASSWORD = 'supersecret123'

# INSECURE: Hardcoded database credentials
DB_CONNECTION = "postgresql://admin:password123@localhost:5432/demo"

app.secret_key = SECRET_KEY

# INSECURE: SQL Injection vulnerability
@app.route('/user/<user_id>')
def get_user(user_id):
    conn = sqlite3.connect('users.db')
    cursor = conn.cursor()
    
    # INSECURE: Direct string formatting leads to SQL injection
    query = f"SELECT * FROM users WHERE id = {user_id}"
    cursor.execute(query)
    
    result = cursor.fetchall()
    conn.close()
    return str(result)

# INSECURE: Command Injection vulnerability
@app.route('/ping', methods=['POST'])
def ping_host():
    host = request.json.get('host')
    
    # INSECURE: Executing user input directly
    result = subprocess.run(f'ping -c 1 {host}', shell=True, capture_output=True, text=True)
    return {'output': result.stdout}

# INSECURE: Insecure Deserialization
@app.route('/load_config', methods=['POST'])
def load_config():
    config_data = request.data
    
    # INSECURE: Unpickling untrusted data
    config = pickle.loads(config_data)
    return {'config': str(config)}

# INSECURE: Server-Side Template Injection (SSTI)
@app.route('/hello')
def hello():
    name = request.args.get('name', 'World')
    
    # INSECURE: Rendering user input as template
    template = f"<h1>Hello {name}!</h1>"
    return render_template_string(template)

# INSECURE: Path Traversal vulnerability
@app.route('/file/<path:filename>')
def read_file(filename):
    # INSECURE: No path sanitization
    try:
        with open(f'/app/files/{filename}', 'r') as f:
            return f.read()
    except FileNotFoundError:
        return 'File not found', 404

# INSECURE: Weak cryptography
def hash_password(password):
    # INSECURE: Using MD5 for password hashing
    return hashlib.md5(password.encode()).hexdigest()

# INSECURE: Information disclosure
@app.route('/debug')
def debug_info():
    # INSECURE: Exposing sensitive environment information
    return {
        'env_vars': dict(os.environ),
        'secret_key': SECRET_KEY,
        'api_key': API_KEY,
        'db_password': DATABASE_PASSWORD
    }

# INSECURE: Missing authentication
@app.route('/admin')
def admin_panel():
    # INSECURE: No authentication required for admin panel
    return "Welcome to admin panel!"

# INSECURE: Eval injection
@app.route('/calc', methods=['POST'])
def calculate():
    expression = request.json.get('expression')
    
    # INSECURE: Using eval() with user input
    try:
        result = eval(expression)
        return {'result': result}
    except Exception as e:
        return {'error': str(e)}

# INSECURE: Weak session management
@app.route('/login', methods=['POST'])
def login():
    username = request.json.get('username')
    password = request.json.get('password')
    
    # INSECURE: Weak authentication logic
    if username == 'admin' and hash_password(password) == hash_password('123456'):
        # INSECURE: Predictable session token
        session_token = hashlib.md5(f"{username}:{SECRET_KEY}".encode()).hexdigest()
        return {'token': session_token}
    
    return {'error': 'Invalid credentials'}, 401

# INSECURE: XML External Entity (XXE)
import xml.etree.ElementTree as ET

@app.route('/parse_xml', methods=['POST'])
def parse_xml():
    xml_data = request.data.decode()
    
    # INSECURE: Parsing XML without disabling external entities
    try:
        root = ET.fromstring(xml_data)
        return {'parsed': ET.tostring(root).decode()}
    except ET.ParseError as e:
        return {'error': str(e)}

if __name__ == '__main__':
    print(f"Starting app with secret key: {SECRET_KEY}")  # INSECURE: Logging secrets
    print(f"API Key: {API_KEY}")  # INSECURE: Logging secrets
    print(f"Database password: {DATABASE_PASSWORD}")  # INSECURE: Logging secrets
    
    # INSECURE: Running in debug mode in production
    app.run(host='0.0.0.0', port=5000, debug=True)