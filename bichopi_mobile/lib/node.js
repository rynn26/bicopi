const express = require("express");
const midtransClient = require("midtrans-client");

const app = express();
app.use(express.json());

let snap = new midtransClient.Snap({
    isProduction: false, // true untuk mode produksi
    serverKey: "YOUR_SERVER_KEY"
});

app.post("/create-transaction", async (req, res) => {
    try {
        let parameter = {
            transaction_details: {
                order_id: `ORDER-${Date.now()}`,
                gross_amount: req.body.amount
            },
            qris: true
        };

        let transaction = await snap.createTransaction(parameter);
        res.json({ qr_code: transaction.qr_code });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

app.listen(3000, () => console.log("Server running on port 3000"));
