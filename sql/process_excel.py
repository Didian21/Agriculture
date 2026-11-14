import openpyxl
import re
import calendar
import datetime
import pandas as pd

excel_path = r'C:\Users\Nhiel R. Radores\Downloads\Price_Commodity_Farmgate (1).xlsx'
wb = openpyxl.load_workbook(excel_path)
sheet = wb.active

headers = [cell.value for cell in sheet[1]]

crop_map = {
    'Ampalaya': 'Ampalaya (Bitter Gourd)',
    'Sitao': 'Sitaw (Yardlong Bean)',
    'Petchay (Tagalog)': 'Pechay (Tagalog)',
    'Kalabasa': 'Kalabasa (Squash)',
    'Talong': 'Talong (Eggplant)',
    'Kamatis': 'Kamatis (Tomato)',
    'Labanos': 'Labanos (Radish)',
    'Sili (Panigang)': 'Sili (Panigang)',
    'Okra': 'Okra',
    'Upo(Per pcs)': 'Upo (Bottle Gourd)',
    'Patola': 'Patola (Luffa)',
    'Patatas': 'Patatas (Potato)',
    'Mustasa': 'Mustasa (Mustard)',
    'Repolyo': 'Repolyo (Cabbage)',
    'Carrot': 'Carrot',
    'Beans': 'Beans',
    'Petchay (Baguio)': 'Petchay (Baguio)',
    'Gabi': 'Gabi (Taro)',
    'Bawang': 'Bawang (Garlic)',
    'Sibuyas': 'Sibuyas (Onion)',
    'Kangkong': 'Kangkong',
    'Celery': 'Celery',
    'Pipino': 'Pipino (Cucumber)',
    'Sayote': 'Sayote (Chayote)',
    'Sili (hot)': 'Sili (Hot Chili)',
    'Bellpepper': 'Bell Pepper',
    'Kamote': 'Sweet Potato (Kamote)',
    'Luya': 'Luya (Ginger)',
    'Kalamansi': 'Kalamansi',
    'Saba': 'Saging (Saba)',
    'Lakatan': 'Saging (Lakatan)',
    'Tordan': 'Saging (Latundan)',
    'Coconut': 'Coconut'
}

sql_rows_mfp = []
sql_rows_hist = []

count = 0
for r in range(2, sheet.max_row + 1):
    row_vals = [cell.value for cell in sheet[r]]
    raw_veg = str(row_vals[0]).strip() if row_vals[0] is not None else ''
    if not raw_veg:
        continue
    veg_name = crop_map.get(raw_veg, raw_veg)

    for c in range(1, len(row_vals)):
        dt_cell = headers[c]
        val = row_vals[c]
        if val is None or pd.isna(val):
            continue
        val_str = str(val).strip()
        num_match = re.search(r'(\d+(?:\.\d+)?)', val_str)
        if not num_match:
            continue
        fg_price = float(num_match.group(1))
        if fg_price <= 0:
            continue

        year = 2026
        if isinstance(dt_cell, datetime.datetime):
            month_num = dt_cell.month
            day_num = dt_cell.year % 100
            if dt_cell.year == 1930:
                day_num = 30
        else:
            month_num = 5
            day_num = 25

        month_name = calendar.month_name[month_num]
        date_str = f"{year}-{month_num:02d}-{day_num:02d}T00:00:00Z"
        mkt_price = round(fg_price * 1.4, 2)

        count += 1
        mp_id = f"MP_EXCEL_2026_{count:04d}"
        hist_id = f"HIST_EXCEL_2026_{count:04d}"

        clean_veg = veg_name.replace("'", "''")
        sql_rows_mfp.append(f"('{mp_id}', '{clean_veg}', {fg_price}, {mkt_price}, '{date_str}', 'Pagsanjan Public Market', 'MAO Pagsanjan')")
        sql_rows_hist.append(f"('{hist_id}', '{clean_veg}', {year}, '{month_name}', 0.0, {fg_price}, 'MAO Pagsanjan')")

with open(r'sql/upload_farmgate_excel.sql', 'w', encoding='utf-8') as f:
    f.write("-- SQL SCRIPT FOR IMPORTING EXCEL COMMODITY FARMGATE PRICES (2026 WEEKLY DATES) INTO SUPABASE\n\n")
    f.write("-- 1. INSERT INTO market_farmgate_prices\n")
    f.write("INSERT INTO public.market_farmgate_prices (id, vegetable, farmgate_price, market_price, date, market_location, uploaded_by)\nVALUES\n")
    f.write(",\n".join(sql_rows_mfp))
    f.write("\nON CONFLICT (id) DO UPDATE SET\n  farmgate_price = EXCLUDED.farmgate_price,\n  market_price = EXCLUDED.market_price;\n\n")

    f.write("-- 2. INSERT INTO historical_records\n")
    f.write("INSERT INTO public.historical_records (id, crop, year, month, production_mt, price_per_kg, uploaded_by)\nVALUES\n")
    f.write(",\n".join(sql_rows_hist))
    f.write("\nON CONFLICT (id) DO UPDATE SET\n  price_per_kg = EXCLUDED.price_per_kg;\n")

print(f"Successfully processed {count} records with accurate 2026 weekly dates and generated sql/upload_farmgate_excel.sql")
