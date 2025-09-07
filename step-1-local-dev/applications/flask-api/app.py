# Stage 1: Basic Flask API
# Intentionally has areas for improvement that Station agents can guide on

from flask import Flask, jsonify, request
import os
import sqlite3
import hashlib
import time

app = Flask(__name__)

# TODO: Station agent should suggest environment-based configuration
DATABASE = 'users.db'
SECRET_KEY = 'super-secret-key-123'  # Station agent should flag this

def init_db():
    """Initialize the database"""
    conn = sqlite3.connect(DATABASE)
    cursor = conn.cursor()
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS users (
            id INTEGER PRIMARY KEY,
            username TEXT UNIQUE,
            email TEXT,
            password_hash TEXT,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
    ''')
    conn.commit()
    conn.close()

def get_db_connection():
    """Get database connection"""
    # Station agent should suggest connection pooling
    conn = sqlite3.connect(DATABASE)
    conn.row_factory = sqlite3.Row
    return conn

@app.route('/')
def home():
    """Basic health check endpoint"""
    return jsonify({
        "service": "flask-api",
        "status": "healthy",
        "version": "1.0.0"
    })

@app.route('/users', methods=['GET'])
def get_users():
    """Get all users"""
    try:
        conn = get_db_connection()
        users = conn.execute('SELECT id, username, email, created_at FROM users').fetchall()
        conn.close()
        
        return jsonify([dict(user) for user in users])
    except Exception as e:
        # Station agent should suggest proper error handling
        return jsonify({"error": str(e)}), 500

@app.route('/users', methods=['POST'])
def create_user():
    """Create a new user"""
    data = request.json
    
    # Station agent should suggest input validation
    username = data.get('username')
    email = data.get('email')
    password = data.get('password')
    
    if not username or not email or not password:
        return jsonify({"error": "Missing required fields"}), 400
    
    # Basic password hashing (Station agent should suggest better security)
    password_hash = hashlib.md5(password.encode()).hexdigest()
    
    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        cursor.execute(
            'INSERT INTO users (username, email, password_hash) VALUES (?, ?, ?)',
            (username, email, password_hash)
        )
        user_id = cursor.lastrowid
        conn.commit()
        conn.close()
        
        return jsonify({
            "id": user_id,
            "username": username,
            "email": email,
            "message": "User created successfully"
        }), 201
        
    except sqlite3.IntegrityError:
        return jsonify({"error": "Username already exists"}), 409
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route('/users/<int:user_id>', methods=['GET'])
def get_user(user_id):
    """Get a specific user"""
    conn = get_db_connection()
    user = conn.execute(
        'SELECT id, username, email, created_at FROM users WHERE id = ?',
        (user_id,)
    ).fetchone()
    conn.close()
    
    if user is None:
        return jsonify({"error": "User not found"}), 404
    
    return jsonify(dict(user))

@app.route('/health')
def health():
    """Detailed health check"""
    # Station agent should suggest more comprehensive health checks
    db_status = "unknown"
    try:
        conn = get_db_connection()
        conn.execute('SELECT 1').fetchone()
        conn.close()
        db_status = "healthy"
    except:
        db_status = "unhealthy"
    
    return jsonify({
        "service": "flask-api",
        "status": "healthy" if db_status == "healthy" else "degraded",
        "database": db_status,
        "uptime": time.time(),  # Station agent should suggest proper uptime tracking
        "version": "1.0.0"
    })

# Station agent should suggest proper configuration management
if __name__ == '__main__':
    init_db()
    # Station agent should flag running in debug mode in production
    app.run(debug=True, host='0.0.0.0', port=5000)