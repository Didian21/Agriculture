import openpyxl
import datetime

excel_path = r'C:\Users\Nhiel R. Radores\Downloads\Price_Commodity_Farmgate (1).xlsx'
sql_out_path = r'sql\upload_market_farmgate_prices_from_excel.sql'

wb = openpyxl.load_workbook(excel_path, data_only=True)
ws = wb.active

max_r = ws.max_row
max_c = ws.max_column

# Weekly 2026 date mapping for 24 observation columns
dates = [
    "2026-05-01", "2026-06-01", "2026-06-08", "2026-06-15", "2026-06-22", "2026-06-29",
    "2026-07-06", "2026-07-13", "2026-07-20", "2026-07-27", "2026-08-03", "2026-08-10",
    "2026-08-17", "2026-08-24", "2026-08-31", "2026-09-07", "2026-09-14", "2026-09-21",
    "2026-09-28", "2026-10-05", "2026-10-12", "2026-10-19", "2026-10-26", "2026-11-02"
]

sql_rows = []

sql_rows.append("-- =========================================================")
sql_rows.append("-- SUPABASE INSERT SCRIPT FOR VEGETABLE MARKET & FARMGATE PRICES")
sql_rows.append("-- Generated from: Price_Commodity_Farmgate (1).xlsx")
sql_rows.append("-- Table: public.market_farmgate_prices")
sql_rows.append("-- =========================================================\n")

sql_rows.append("""CREATE TABLE IF NOT EXISTS public.market_farmgate_prices (
  id text NOT NULL,
  vegetable text NOT NULL,
  farmgate_price double precision NOT NULL DEFAULT 0.0,
  market_price double precision NOT NULL DEFAULT 0.0,
  date timestamp with time zone NOT NULL DEFAULT timezone('utc'::text, now()),
  market_location text NOT NULL DEFAULT 'Pagsanjan Public Market'::text,
  uploaded_by text NOT NULL DEFAULT 'MAO Staff'::text,
  date_uploaded timestamp with time zone NOT NULL DEFAULT timezone('utc'::text, now()),
  CONSTRAINT market_farmgate_prices_pkey PRIMARY KEY (id)
) TABLESPACE pg_default;\n""")

insert_count = 0

for r in range(2, max_r + 1):
    veg_raw = ws.cell(row=r, column=1).value
    if veg_raw is None or not str(veg_raw).strip():
        continue

    veg_name = str(veg_raw).strip()

    # Normalize vegetable names
    if "Upo" in veg_name:
        veg_name = "Upo (Bottle Gourd)"
    elif "Sitao" in veg_name or "Sitaw" in veg_name:
        veg_name = "Sitaw (Yardlong Bean)"
    elif "Petchay (Tagalog)" in veg_name or "Pechay" in veg_name:
        veg_name = "Pechay (Tagalog)"
    elif "Kalabasa" in veg_name or "Squash" in veg_name:
        veg_name = "Kalabasa (Squash)"
    elif "Talong" in veg_name or "Eggplant" in veg_name:
        veg_name = "Talong (Eggplant)"
    elif "Kamatis" in veg_name or "Tomato" in veg_name:
        veg_name = "Kamatis (Tomato)"
    elif "Labanos" in veg_name or "Radish" in veg_name:
        veg_name = "Labanos (Radish)"
    elif "Sili (Panigang)" in veg_name:
        veg_name = "Sili (Panigang)"
    elif "Sili (hot)" in veg_name:
        veg_name = "Sili (Hot Chili)"
    elif "Patola" in veg_name:
        veg_name = "Patola (Luffa)"
    elif "Patatas" in veg_name:
        veg_name = "Patatas (Potato)"
    elif "Mustasa" in veg_name:
        veg_name = "Mustasa (Mustard)"
    elif "Repolyo" in veg_name:
        veg_name = "Repolyo (Cabbage)"
    elif "Carrot" in veg_name:
        veg_name = "Carrot"
    elif "Gabi" in veg_name:
        veg_name = "Gabi (Taro)"
    elif "Bawang" in veg_name:
        veg_name = "Bawang (Garlic)"
    elif "Sibuyas" in veg_name:
        veg_name = "Sibuyas (Onion)"
    elif "Kangkong" in veg_name:
        veg_name = "Kangkong"
    elif "Pipino" in veg_name:
        veg_name = "Pipino (Cucumber)"
    elif "Sayote" in veg_name:
        veg_name = "Sayote (Chayote)"
    elif "Bellpepper" in veg_name or "Bell pepper" in veg_name:
        veg_name = "Bell Pepper"
    elif "Kamote" in veg_name:
        veg_name = "Sweet Potato (Kamote)"
    elif "Luya" in veg_name:
        veg_name = "Luya (Ginger)"
    elif "Kalamansi" in veg_name:
        veg_name = "Kalamansi"
    elif "Saba" in veg_name:
        veg_name = "Saging (Saba)"
    elif "Lakatan" in veg_name:
        veg_name = "Saging (Lakatan)"
    elif "Tordan" in veg_name:
        veg_name = "Saging (Latundan)"

    for c in range(2, max_c + 1):
        d_idx = c - 2
        date_str = dates[d_idx] if d_idx < len(dates) else "2026-06-15"

        fg_val = ws.cell(row=r, column=c).value
        if fg_val is not None:
            try:
                fg_price = float(fg_val)
                if fg_price <= 0:
                    continue

                # Market price estimate (40% retail markup)
                mk_price = round(fg_price * 1.4, 2)

                record_id = f"MFP_EXCEL_{r}_{c}"
                veg_escaped = veg_name.replace("'", "''")

                sql = (
                    f"INSERT INTO public.market_farmgate_prices (id, vegetable, farmgate_price, market_price, date, market_location, uploaded_by, date_uploaded) "
                    f"VALUES ('{record_id}', '{veg_escaped}', {fg_price:.2f}, {mk_price:.2f}, '{date_str} 00:00:00+00', 'Pagsanjan Public Market', 'MAO Staff', NOW()) "
                    f"ON CONFLICT (id) DO UPDATE SET farmgate_price = EXCLUDED.farmgate_price, market_price = EXCLUDED.market_price, date = EXCLUDED.date;"
                )
                sql_rows.append(sql)
                insert_count += 1
            except (ValueError, TypeError):
                continue

with open(sql_out_path, 'w', encoding='utf-8') as f:
    f.write("\n".join(sql_rows))

print(f"Generated {insert_count} SQL INSERT statements in {sql_out_path}!")
