const express = require('express');
const bodyParser = require('body-parser');
const midtransClient = require('midtrans-client');
const cors = require('cors');
const { createClient } = require('@supabase/supabase-js');

const app = express();
const port = 3000;

app.use(cors());
app.use(bodyParser.json());

// Midtrans Setup
let snap = new midtransClient.Snap({
  isProduction: false,
  serverKey: 'SB-Mid-server-dRgDOT5ClnHI_kI72XCLjcK5',
  clientKey: 'SB-Mid-client-4fTrE0vSv0JHDKtY'
});

// Supabase Setup
const supabaseUrl = 'https://nfafmiaxogrxxwjuyqfs.supabase.co';
const supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5mYWZtaWF4b2dyeHh3anV5cWZzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDAyNTIzMDcsImV4cCI6MjA1NTgyODMwN30.tsapVtnxkicRa-eTQLhKTBQtm7H9U1pfwBBdGdqryW0';
const supabase = createClient(supabaseUrl, supabaseAnonKey);

// In-memory order status tracking
const orderStatuses = {};

function updateOrderStatus(orderId, status) {
  orderStatuses[orderId] = status;
  console.log(`[Backend] Order ${orderId} status updated to: ${status}`);
}

// Endpoint: Create QRIS transaction
app.post('/create-qris-transaction', async (req, res) => {
  const { order_id, first_name, email, phone, items, table_number, total_harga } = req.body;

  const itemDetails = items?.map(item => ({
    id: item.item_name?.replace(/\s+/g, '-').toLowerCase() || 'unknown-item',
    price: item.price || 0,
    quantity: item.quantity || 1,
    name: item.item_name || 'Nama Item Tidak Tersedia',
  })) || [];

  const request = {
    payment_type: 'qris',
    transaction_details: {
      order_id,
      gross_amount: total_harga,
    },
    customer_details: {
      first_name,
      email,
      phone,
    },
    item_details: itemDetails,
    qris: { type: 'DYNAMIC' },
  };

  try {
    const transaction = await snap.createTransaction(request);
    const qrCodeAction = transaction.actions?.find(action => action.name === 'generate-qr-code');
    if (qrCodeAction?.url) {
      updateOrderStatus(order_id, 'PENDING');
      return res.json({ status: 'success', qr_code_url: qrCodeAction.url });
    } else {
      return res.status(500).json({ status: 'error', message: 'QR Code URL not found' });
    }
  } catch (error) {
    console.error('[QRIS] Error:', error);
    res.status(500).json({ status: 'error', message: error.message });
  }
});

// Endpoint: Create Snap Token
app.post('/create-transaction', async (req, res) => {
  const { order_id, gross_amount, first_name, email, phone } = req.body;

  const request = {
    transaction_details: {
      order_id,
      gross_amount,
    },
    customer_details: {
      first_name,
      email,
      phone,
    },
  };

  try {
    const snapToken = await snap.createTransactionToken(request);
    res.json({ snapToken });
  } catch (error) {
    console.error('[Snap] Error:', error);
    res.status(500).json({ status: 'error', message: error.message });
  }
});

// Endpoint: Payment notification from Midtrans (Webhook)
app.post('/payment-notification', async (req, res) => {
  const notification = req.body;
  const transactionStatus = notification.transaction_status;
  const orderId = notification.order_id;
  const paymentType = notification.payment_type;
  const grossAmount = notification.gross_amount;
  const transactionTime = notification.transaction_time;

  console.log('[Webhook] Received:', notification);

  // Log detail pembayaran secara terpisah
  console.log('[Webhook] Order ID:', orderId);
  console.log('[Webhook] Status:', transactionStatus);
  console.log('[Webhook] Payment Type:', paymentType);
  console.log('[Webhook] Gross Amount:', grossAmount);
  console.log('[Webhook] Transaction Time:', transactionTime);

  updateOrderStatus(orderId, transactionStatus);

  // Simpan transaksi ke Supabase
  const { error: saveError } = await supabase.from('transactions').insert([
    {
      order_id: orderId,
      status: transactionStatus,
      payment_type: paymentType,
      gross_amount: parseInt(grossAmount),
      transaction_time: transactionTime,
    }
  ]);

  if (saveError) {
    console.error('[Supabase] Gagal menyimpan transaksi:', saveError.message);
  }

  // Jika transaksi sukses (settlement), tambahkan poin afiliasi
  if (transactionStatus === 'settlement') {
    const { error: affiliateError } = await supabase.from('affiliate_points_log').insert([
      {
        order_id: orderId,
        points: 10, // Atur sesuai sistem poin Anda
        description: 'Poin dari transaksi Midtrans',
      }
    ]);

    if (affiliateError) {
      console.error('[Supabase] Gagal menambahkan poin afiliasi:', affiliateError.message);
    }
  }

  res.sendStatus(200);
});

// Endpoint: Cek status pembayaran
app.get('/check-payment-status/:orderId', (req, res) => {
  const { orderId } = req.params;
  res.json({ status: orderStatuses[orderId] || 'NOT_FOUND' });
});

// Start server
app.listen(port, () => {
  console.log(`[Backend] Server is running on http://localhost:${port}`);
});