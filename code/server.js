// server.js
const express = require('express');
const bodyParser = require('body-parser');
const cors = require('cors');
const { Pool } = require('pg');

// Replace with your actual PostgreSQL RDS credentials
const pool = new Pool({
  user: 'your-username',
  host: 'your-rds-endpoint',
  database: 'your-database-name',
  password: 'your-password',
  port: 5432,
});

const app = express();
app.use(bodyParser.json());
app.use(cors());

// Function to create the table if it doesn't exist
const createTableIfNotExists = async () => {
  try {
    await pool.query(`
      CREATE TABLE IF NOT EXISTS tasks (
        id SERIAL PRIMARY KEY,
        name VARCHAR(255) NOT NULL
      );
    `);
    console.log("Table 'tasks' ensured to exist.");
  } catch (err) {
    console.error("Error ensuring tasks table exists:", err);
  }
};

// Call this function at server startup
createTableIfNotExists();

// Endpoint to get all tasks
app.get('/tasks', async (req, res) => {
  try {
    const result = await pool.query('SELECT * FROM tasks');
    res.json(result.rows);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Database error' });
  }
});

// Endpoint to create a new task
app.post('/tasks', async (req, res) => {
  const { name } = req.body;
  try {
    await pool.query('INSERT INTO tasks (name) VALUES ($1)', [name]);
    res.status(201).json({ message: 'Task added' });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Database error' });
  }
});

// Endpoint to update an existing task
app.put('/tasks/:id', async (req, res) => {
  const { id } = req.params;
  const { name } = req.body;
  try {
    await pool.query('UPDATE tasks SET name = $1 WHERE id = $2', [name, id]);
    res.status(200).json({ message: 'Task updated' });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Database error' });
  }
});

// Endpoint to delete a task
app.delete('/tasks/:id', async (req, res) => {
  const { id } = req.params;
  try {
    await pool.query('DELETE FROM tasks WHERE id = $1', [id]);
    res.status(200).json({ message: 'Task deleted' });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Database error' });
  }
});

// Start server
const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`Server is running on port ${PORT}`);
});
