// server.js (Node.js + Express)
import fetch from 'node-fetch';  // Use import instead of require
import dotenv from 'dotenv';      // Also import dotenv
import cors from 'cors';
dotenv.config();  // Load environment variables from .env
import express from 'express';
const app = express();
const port = 3001;

// Set up your CoinMarketCap API Key
const cryptoApiKey = process.env.PUBLIC_COIN_MARKET_API_KEY;
app.use(cors({ origin: '*' }));
app.get('/currency-conversion', async (req, res) => {
  const { priceInEUR } = req.query;

  const exchangeUrl = `https://pro-api.coinmarketcap.com/v2/tools/price-conversion`;

  const params = new URLSearchParams({
    amount: priceInEUR.toString(),
    id: '2790', // ID for EUR
    convert: 'ETH', // Convert to ETH
  });

  try {
    const response = await fetch(`${exchangeUrl}?${params.toString()}`, {
      headers: {
        'Content-Type': 'application/json',
        'X-CMC_PRO_API_KEY': cryptoApiKey,
      },
    });

    if (!response.ok) {
      throw new Error(`HTTP error! Status: ${response.status}, ${response}`);
    }

    const data = await response.json();

    if (data.status.error_code !== 0) {
      return res.status(500).json({ error: data.status.error_message });
    }

    return res.json({ priceInETH: data.data.quote.ETH.price });
  } catch (err) {
    console.error('Error during API call:', err);
    return res.status(500).json({ error: err.message });
  }
});

app.listen(port, () => {
  console.log(`Server running at http://localhost:${port}`);
});
