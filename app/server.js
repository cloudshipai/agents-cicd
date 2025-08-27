// INSECURE Node.js Application for Security Testing

const express = require('express');
const mysql = require('mysql');
const crypto = require('crypto');
const fs = require('fs');
const { exec } = require('child_process');

const app = express();
app.use(express.json());

// INSECURE: Hardcoded secrets
const API_KEY = 'sk-1234567890abcdef1234567890abcdef';
const JWT_SECRET = 'my-super-secret-jwt-key';
const DATABASE_PASSWORD = 'supersecret123';

// INSECURE: Database connection with hardcoded credentials
const db = mysql.createConnection({
  host: 'localhost',
  user: 'admin', 
  password: 'password123',  // INSECURE: Hardcoded password
  database: 'demo'
});

// INSECURE: SQL Injection vulnerability
app.get('/user/:id', (req, res) => {
  const userId = req.params.id;
  // INSECURE: Direct string interpolation leads to SQL injection
  const query = `SELECT * FROM users WHERE id = ${userId}`;
  
  db.query(query, (err, results) => {
    if (err) {
      // INSECURE: Leaking database errors to client
      res.status(500).json({ error: err.message });
      return;
    }
    res.json(results);
  });
});

// INSECURE: Command Injection vulnerability
app.post('/backup', (req, res) => {
  const filename = req.body.filename;
  
  // INSECURE: Executing user input directly
  exec(`tar -czf backups/${filename}.tar.gz data/`, (error, stdout, stderr) => {
    if (error) {
      // INSECURE: Leaking system errors
      res.status(500).json({ error: error.message });
      return;
    }
    res.json({ message: 'Backup created successfully' });
  });
});

// INSECURE: Path Traversal vulnerability  
app.get('/file/:filename', (req, res) => {
  const filename = req.params.filename;
  
  // INSECURE: No path sanitization
  const filepath = `uploads/${filename}`;
  
  fs.readFile(filepath, 'utf8', (err, data) => {
    if (err) {
      res.status(404).json({ error: 'File not found' });
      return;
    }
    res.send(data);
  });
});

// INSECURE: Weak authentication
app.post('/login', (req, res) => {
  const { username, password } = req.body;
  
  // INSECURE: Weak password validation
  if (username === 'admin' && password === '123456') {
    // INSECURE: Weak JWT signing
    const token = crypto.createHash('md5').update(username + JWT_SECRET).digest('hex');
    res.json({ token });
  } else {
    res.status(401).json({ error: 'Invalid credentials' });
  }
});

// INSECURE: Information disclosure
app.get('/debug', (req, res) => {
  // INSECURE: Exposing sensitive system information
  res.json({
    env: process.env,
    version: process.version,
    platform: process.platform,
    cwd: process.cwd(),
    uptime: process.uptime()
  });
});

// INSECURE: Missing security headers
app.use((req, res, next) => {
  // Should have security headers like helmet.js
  next();
});

// INSECURE: Logging sensitive data
app.use((req, res, next) => {
  console.log(`Request: ${req.method} ${req.url}`, req.body, req.headers);
  next();
});

const PORT = process.env.PORT || 3000;

app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
  console.log(`Database password: ${DATABASE_PASSWORD}`);  // INSECURE: Logging secrets
  console.log(`API Key: ${API_KEY}`);  // INSECURE: Logging secrets
});