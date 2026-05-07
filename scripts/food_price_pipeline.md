# Food Price Daily Pipeline

This pipeline updates currency columns in your food CSV with **actual market prices** (not INR FX conversions) using live product offers from PricesAPI.

## 1) Get API key

1. Sign up: `https://pricesapi.io/signup`
2. Copy your key (starts with `pricesapi_...`)

## 2) Run once manually

```bash
export PRICESAPI_KEY="pricesapi_your_key_here"
python3 scripts/update_food_prices_actual_market.py \
  --input "/Users/prajna/Downloads/main_food_items_list 2.csv" \
  --output "/Users/prajna/Desktop/Canada-Live copy 4/main_food_items_list_2_actual_market_daily.csv"
```

## 3) Notes

- Output file is separate; input file is unchanged.
- Script caches results and reuses fresh entries (`--ttl-days`, default 7).
- It updates supported currencies: `USD, EUR, GBP, INR, BRL, JPY, AUD, CAD, SGD, AED, SAR`.
- `CNY` is currently unsupported by this provider and remains unchanged.
- Use `--max-api-calls` to cap daily API usage.
