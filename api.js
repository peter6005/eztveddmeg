const express = require('express');
const bodyParser = require('body-parser');
const mariadb = require('mariadb');

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(bodyParser.json());

// MariaDB Pool
const pool = mariadb.createPool({
  host: 'localhost',
  user: 'peter',
  password: "jelszo",
  database: 'eztveddmeg',
  waitForConnections: true,
  connectionLimit: 5
});

// Database Initialization
async function initializeDatabase() {
  let conn;
  try {
    conn = await pool.getConnection();
    console.log('Connected to MariaDB database');

    // Create shopping_items table if not exists
    await conn.query(`CREATE TABLE IF NOT EXISTS shopping_items (
      id INT AUTO_INCREMENT PRIMARY KEY,
      name VARCHAR(255) NOT NULL
    )`);

    console.log('shopping_items table checked/created');

    // Create products table if not exists
    await conn.query(`CREATE TABLE IF NOT EXISTS products (
      id INT AUTO_INCREMENT PRIMARY KEY,
      name VARCHAR(255) NOT NULL,
      barcode VARCHAR(255) NOT NULL
    )`);

    console.log('products table checked/created');
  } catch (err) {
    console.error('Error initializing database:', err);
  } finally {
    if (conn) conn.release();
  }
}

initializeDatabase();

// API endpoints

// Create a new shopping item
app.post('/additem', async (req, res) => {
  const { name } = req.body;
  if (!name) {
    return res.status(400).json({ error: 'Name is required' });
  }
  try {
    const conn = await pool.getConnection();
    const result = await conn.query('INSERT INTO shopping_items (name) VALUES (?)', [name]);
    conn.release();
    res.json({ id: result.insertId.toString(), name: name });
  } catch (err) {
    console.error('Error inserting into database:', err);
    return res.status(500).json({ error: 'Database error' });
  }
});

// Get all shopping items
app.get('/mylist', async (req, res) => {
  try {
    const conn = await pool.getConnection();
    const results = await conn.query('SELECT * FROM shopping_items');
    conn.release();
    res.json(results);
  } catch (err) {
    console.error('Error querying database:', err);
    return res.status(500).json({ error: 'Database error' });
  }
});

// Update a shopping item
app.put('/updateitem/:id', async (req, res) => {
  const { id } = req.params;
  const { name } = req.body;
  if (!name) {
    return res.status(400).json({ error: 'Name is required' });
  }
  try {
    const conn = await pool.getConnection();
    await conn.query('UPDATE shopping_items SET name = ? WHERE id = ?', [name, id]);
    conn.release();
    res.json({ id: id, name: name });
  } catch (err) {
    console.error('Error updating database:', err);
    return res.status(500).json({ error: 'Database error' });
  }
});

// Delete a shopping item
app.delete('/deleteitem/:id', async (req, res) => {
  const { id } = req.params;
  try {
    const conn = await pool.getConnection();
    await conn.query('DELETE FROM shopping_items WHERE id = ?', [id]);
    conn.release();
    res.json({ message: 'Shopping item deleted successfully' });
  } catch (err) {
    console.error('Error deleting from database:', err);
    return res.status(500).json({ error: 'Database error' });
  }
});

// Add product to shopping list by barcode
app.post('/additembybarcode', async (req, res) => {
  const { barcode } = req.body;
  if (!barcode) {
    return res.status(400).json({ error: 'Barcode is required' });
  }
  try {
    const conn = await pool.getConnection();
    const result = await conn.query('SELECT name FROM products WHERE barcode = ?', [barcode]);
    if (result.length === 0) {
      conn.release();
      return res.status(404).json({ error: 'Product not found for barcode' });
    }
    const productName = result[0].name;
    await conn.query('INSERT INTO shopping_items (name) VALUES (?)', [productName]);
    conn.release();
    res.json({ message: 'Product added to shopping list successfully', productName: productName });
  } catch (err) {
    console.error('Error querying/inserting into database:', err);
    return res.status(500).json({ error: 'Database error' });
  }
});

// Add product to database
app.post('/addproduct', async (req, res) => {
  const { name, barcode } = req.body;
  if (!name || !barcode) {
    return res.status(400).json({ error: 'Name and barcode are required' });
  }
  try {
    const conn = await pool.getConnection();
    const result = await conn.query('INSERT INTO products (name, barcode) VALUES (?, ?)', [name, barcode]);
    conn.release();
    res.json({ message: 'Product added successfully', productName: name, barcode: barcode });
  } catch (err) {
    console.error('Error inserting into database:', err);
    return res.status(500).json({ error: 'Database error' });
  }
});

// Start the server
app.listen(PORT, () => {
  console.log(`Server is running on port ${PORT}`);
});
