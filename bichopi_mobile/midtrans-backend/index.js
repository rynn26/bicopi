const express = require('express');
const bodyParser = require('body-parser');
const midtransClient = require('midtrans-client');
const cors = require('cors');
const { createClient } = require('@supabase/supabase-js');

const app = express();
const port = 3000;

// Setup Middleware
app.use(cors());
app.use(bodyParser.json());

// Setup Midtrans Snap (Sandbox mode)
let snap = new midtransClient.Snap({
  isProduction: false,
  serverKey: 'SB-Mid-server-dRgDOT5ClnHI_kI72XCLjcK5', // GANTI DENGAN SERVER KEY SANDBOX ANDA!
  clientKey: 'SB-Mid-client-4fTrE0vSv0JHDKtY'       // GANTI DENGAN CLIENT KEY SANDBOX ANDA!
});

// Setup Supabase Client (Mungkin tidak terlalu relevan untuk masalah Midtrans saat ini)
const supabaseUrl = 'https://nfafmiaxogrxxwjuyqfs.supabase.co'; // Ganti dengan URL proyek Supabase Anda
const supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5mYWZtaWF4b2dyeHh3anV5cWZzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDAyNTIzMDcsImV4cCI6MjA1NTgyODMwN30.tsapVtnxkicRa-eTQLhKTBQtm7H9U1pfwBBdGdqryW0'; // Ganti dengan API anon key Supabase Anda
const supabase = createClient(supabaseUrl, supabaseAnonKey);

// In-memory storage untuk status pesanan
const orderStatuses = {};

function updateOrderStatus(orderId, status) {
  orderStatuses[orderId] = status;
  console.log(`[Backend] Order ${orderId} status updated to: ${status}`);
}

// Endpoint untuk membuat transaksi QRIS
app.post('/create-qris-transaction', async (req, res) => {
  const { order_id, first_name, email, phone, items, table_number, total_harga } = req.body;

  console.log('[Backend - QRIS] Request Body:', req.body);

  const itemDetails = items ? items.map(item => ({
    id: item.item_name?.replace(/\s+/g, '-').toLowerCase() || 'unknown-item',
    price: item.price || 0,
    quantity: item.quantity || 1,
    name: item.item_name || 'Nama Item Tidak Tersedia',
  })) : [];

  const transactionDetails = {
    order_id: order_id,
    gross_amount: total_harga,
  };

  const customerDetails = {
    first_name: first_name,
    email: email,
    phone: phone,
  };

  const request = {
    payment_type: 'qris',
    transaction_details: transactionDetails,
    customer_details: customerDetails,
    item_details: itemDetails,
    qris: {
      type: 'DYNAMIC', // Atur ke 'STATIC' jika Anda menggunakan QRIS statis
    },
  };

  console.log('[Backend - QRIS] Request to Midtrans:', request);

  try {
    const transaction = await snap.createTransaction(request);
    console.log('[Backend - QRIS] Midtrans Response:', transaction);

    if (transaction.actions && Array.isArray(transaction.actions)) {
      const qrCodeAction = transaction.actions.find(action => action.name === 'generate-qr-code');
      if (qrCodeAction && qrCodeAction.url) {
        res.json({ status: 'success', qr_code_url: qrCodeAction.url });
        updateOrderStatus(order_id, 'PENDING');
      } else {
        console.error('[Backend - QRIS] QR Code URL not found in actions:', transaction);
        res.status(500).json({ status: 'error', message: 'Failed to retrieve QR Code URL from actions' });
      }
    } else {
      console.error('[Backend - QRIS] Actions array missing:', transaction);
      res.status(500).json({ status: 'error', message: 'Failed to retrieve QR Code URL - actions missing' });
    }

  } catch (error) {
    console.error('[Backend - QRIS] Error creating transaction:', error);
    res.status(500).json({ status: 'error', message: error.message });
  }
});

// Endpoint untuk mendapatkan Snap Token (untuk metode pembayaran lain)
app.post('/create-transaction', async (req, res) => {
  const { order_id, gross_amount, first_name, email, phone } = req.body;

  console.log('[Backend - Snap] Request Body:', req.body);

  const transactionDetails = {
    order_id: order_id,
    gross_amount: gross_amount,
  };

  const customerDetails = {
    first_name: first_name,
    email: email,
    phone: phone,
  };

  const request = {
    transaction_details: transactionDetails,
    customer_details: customerDetails,
  };

  console.log('[Backend - Snap] Request to Midtrans:', request);

  try {
    const snapToken = await snap.createTransactionToken(request);
    console.log('[Backend - Snap] Midtrans Snap Token:', snapToken);
    res.json({ snapToken: snapToken });
  } catch (error) {
    console.error('[Backend - Snap] Error getting Snap token:', error);
    res.status(500).json({ status: 'error', message: error.message });
  }
});

// Endpoint untuk menerima notifikasi pembayaran dari Midtrans (Webhook)
app.post('/payment-notification', async (req, res) => {
  console.log('[Backend] Payment Notification Received:', req.body);
  res.sendStatus(200);
});

// Endpoint untuk memeriksa status pembayaran (opsional)
app.get('/check-payment-status/:orderId', async (req, res) => {
  const { orderId } = req.params;
  console.log(`[Backend] Checking payment status for order: ${orderId}`);
  res.json({ status: orderStatuses[orderId] || 'NOT_FOUND' });
});

// Menjalankan server
app.listen(port, () => {
  console.log(`[Backend] Server is running on http://localhost:${port}`);
});