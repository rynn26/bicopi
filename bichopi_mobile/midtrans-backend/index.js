const express = require('express');
const midtransClient = require('midtrans-client');
const app = express();
app.use(express.json());

const snap = new midtransClient.Snap({
  isProduction: false,
  serverKey: 'SB-Mid-server-dRgDOT5ClnHI_kI72XCLjcK5'
});

app.post('/create-transaction', async (req, res) => {
  try {
    const parameter = {
      transaction_details: {
        order_id: req.body.order_id,
        gross_amount: req.body.gross_amount
      },
      customer_details: {
        first_name: req.body.first_name,
        email: req.body.email,
        phone: req.body.phone
      }
    };

    const transaction = await snap.createTransaction(parameter);
    res.json({ snapToken: transaction.token });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.listen(3000, () => console.log('Server running on port 3000'));
