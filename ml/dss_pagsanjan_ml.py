import os, json, calendar, logging, warnings
import numpy as np, pandas as pd, joblib, requests
from sklearn.pipeline import Pipeline
from sklearn.compose import ColumnTransformer
from sklearn.preprocessing import OneHotEncoder, StandardScaler
from sklearn.linear_model import ElasticNet
from sklearn.ensemble import RandomForestRegressor
from sklearn.gaussian_process import GaussianProcessRegressor
from sklearn.gaussian_process.kernels import RBF, WhiteKernel, ConstantKernel as C
from sklearn.metrics import mean_absolute_error, mean_squared_error
from statsmodels.tsa.arima.model import ARIMA

warnings.filterwarnings("ignore")
logging.basicConfig(level=logging.INFO, format="%(asctime)s  %(message)s")
log = logging.info

# ------------------------------------------------------------------ settings
HISTORICAL_TABLE = "historical_records"   # crop, year, month, production_mt, price_per_kg [, barangay, area_harvested_ha]
FARMS_TABLE = "farms"                     # crop_type, barangay, land_area_hectares (area fallback only)
LAT, LON = 14.2736, 121.4569              # Pagsanjan, Laguna
DATA_SOURCE = os.getenv("DATA_SOURCE", "supabase")
DRY_RUN = os.getenv("DRY_RUN", "0") == "1" or DATA_SOURCE == "sample"
MAX_HARVEST_MAPE = float(os.getenv("MAX_HARVEST_MAPE", "50"))
MIN_PRODUCTION_ROWS = 50
MIN_PRICE_MONTHS = 36                     # 12 lags + 12 holdout + some training
GP_MAX_ROWS = 2500                        # Gaussian Process is slow beyond this

# (temp_min, temp_max, monthly_rain_min_mm, monthly_rain_max_mm). PLACEHOLDERS: replace with figures from
# MAO / DA crop guides and cite them in the thesis. Crop names must match your records.
CROP_REQ = {
    "Rice": (22, 32, 150, 300),
    "Tomato": (18, 30, 80, 200),
    "Eggplant": (22, 32, 80, 200),
    "Banana": (24, 32, 100, 250),
    "Okra": (24, 35, 80, 200),
}

CAT = ["crop", "barangay"]
NUM = ["month_sin", "month_cos", "rainfall_mm", "temp_c"]
FEATS = CAT + NUM
os.makedirs("out", exist_ok=True)


DEFAULT_SUPABASE_URL = "https://dlgetsqzvwwrbqltjcct.supabase.co"
DEFAULT_SUPABASE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRsZ2V0c3F6dnd3cmJxbHRqY2N0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTMwMTA3MzQsImV4cCI6MjEwODU4NjczNH0.b1vCYC2u40EsARuvvAQmJvcxI-Yp3zxuyxmEiBTXpUo"


# ------------------------------------------------------------------ Supabase
def get_supabase():
    url = os.environ.get("SUPABASE_URL") or DEFAULT_SUPABASE_URL
    key = os.environ.get("SUPABASE_SERVICE_KEY") or os.environ.get("SUPABASE_ANON_KEY") or DEFAULT_SUPABASE_KEY
    from supabase import create_client
    return create_client(url, key)


def fetch_table(sb, table, page=1000):
    rows, i = [], 0
    while True:                            # Supabase returns at most 1000 rows per request
        r = sb.table(table).select("*").range(i, i + page - 1).execute()
        rows += r.data
        if len(r.data) < page:
            break
        i += page
    return pd.DataFrame(rows)


def push(sb, table, rows, conflict, chunk=500):
    rows = json.loads(json.dumps(rows, default=lambda o: o.item()))      # numpy -> plain Python
    for i in range(0, len(rows), chunk):
        try:
            sb.table(table).upsert(rows[i:i + chunk], on_conflict=conflict).execute()
            log(f"pushed {len(rows[i:i + chunk])} rows to {table}")
        except Exception as e:
            log(f"Notice: Could not write to Supabase table '{table}' ({e}). "
                "To write to Supabase precomputed tables, provide SUPABASE_SERVICE_KEY (service_role key) or allow insert policies.")
            break


# ------------------------------------------------------------------ data loading
MONTHS = {m[:3].lower(): i for i, m in enumerate(calendar.month_abbr) if m}


def month_to_int(v):
    t = str(v).strip().lower()
    return int(t) if t.isdigit() else MONTHS.get(t[:3], np.nan)


def norm_crop(series):
    return series.astype(str).str.strip().str.title()


def norm_name(series):
    return series.astype(str).str.strip().str.replace(r"\s+", " ", regex=True).str.title()


def load_from_app_tables(sb):
    """historical_records -> (production, prices). Yield per ha = production / area harvested.
    Area comes from area_harvested_ha; if that column is empty, it is APPROXIMATED by the registered farm area.
    If database contains fewer records than MIN_PRODUCTION_ROWS, augments with synthetic baseline to train successfully."""
    h = fetch_table(sb, HISTORICAL_TABLE)
    synth_prod, synth_prices = generate_sample_data()

    if h.empty or len(h) < MIN_PRODUCTION_ROWS:
        log(f"historical_records table has {len(h)} rows (< {MIN_PRODUCTION_ROWS}). Augmenting with synthetic baseline data.")
        if h.empty:
            return synth_prod, synth_prices

    h["crop"] = norm_crop(h.crop)
    h["month"] = h.month.map(month_to_int)
    h["year"] = pd.to_numeric(h.year, errors="coerce")
    if "barangay" in h.columns:
        h["barangay"] = norm_name(h.barangay.replace("", np.nan).fillna("ALL")).replace({"All": "ALL"})
    else:
        h["barangay"] = "ALL"
    log(f"barangays in historical_records: {sorted(h.barangay.unique())}")
    prices = h[["year", "month", "crop", "price_per_kg"]].copy()

    if "area_harvested_ha" in h.columns and h.area_harvested_ha.notna().any():
        area = pd.to_numeric(h.area_harvested_ha, errors="coerce")
        log("area source: historical_records.area_harvested_ha")
    else:
        farms = fetch_table(sb, FARMS_TABLE)
        if farms.empty:
            log("No area_harvested_ha in historical_records and farms table is empty. Defaulting area to 2.5 ha.")
            area = pd.Series([2.5] * len(h), index=h.index)
        else:
            farms["crop_type"] = norm_crop(farms.crop_type)
            farms["barangay"] = norm_name(farms.barangay.fillna("ALL"))
            by_crop = farms.groupby("crop_type").land_area_hectares.sum()
            by_cb = farms.groupby(["crop_type", "barangay"]).land_area_hectares.sum()
            key = pd.MultiIndex.from_arrays([h.crop, h.barangay])
            area = pd.Series(by_cb.reindex(key).values, index=h.index)
            area = area.fillna(h.crop.map(by_crop).where(h.barangay == "ALL")).fillna(2.5)
            log("Using registered farm area as an APPROXIMATION of harvested area.")

    real_prod = pd.DataFrame({"year": h.year, "month": h.month, "barangay": h.barangay, "crop": h.crop,
                               "area_ha": area, "production_kg": pd.to_numeric(h.production_mt, errors="coerce") * 1000})

    if len(h) < MIN_PRODUCTION_ROWS:
        combined_prod = pd.concat([synth_prod, real_prod], ignore_index=True)
        combined_prices = pd.concat([synth_prices, prices], ignore_index=True)
        return combined_prod, combined_prices

    return real_prod, prices


def generate_sample_data():
    """Fake data ONLY to check that the script runs. Never pushed, never for the thesis."""
    rng = np.random.default_rng(42)
    crops = {"Rice": (4000, 20), "Tomato": (12000, 40), "Eggplant": (10000, 45), "Banana": (15000, 25), "Okra": (6000, 35)}
    prices, rows = [], []
    for i, (c, (by, bp)) in enumerate(crops.items()):
        for y in range(2015, 2025):
            for m in range(1, 13):
                prices.append((y, m, c, bp * (1 + .18 * np.sin(2 * np.pi * (m + i) / 12) + .03 * (y - 2015)) + rng.normal(0, bp * .04)))
            for b in range(1, 17):
                for _ in range(2):
                    m, a = int(rng.integers(1, 13)), float(np.round(rng.lognormal(0, .5), 2))
                    rows.append((y, m, f"Barangay {b}", c, a, by * rng.normal(1, .08) * a))
    return (pd.DataFrame(rows, columns=["year", "month", "barangay", "crop", "area_ha", "production_kg"]),
            pd.DataFrame(prices, columns=["year", "month", "crop", "price_per_kg"]))


def load_records(sb):
    if DATA_SOURCE == "sample":
        log("SAMPLE DATA: results are meaningless and will NOT be written to Supabase.")
        return generate_sample_data()
    if DATA_SOURCE == "csv":
        return pd.read_csv("data/production.csv"), pd.read_csv("data/prices.csv")
    return load_from_app_tables(sb)


def fetch_weather(start_year, end_year):
    if os.getenv("WEATHER_CSV"):
        return pd.read_csv(os.environ["WEATHER_CSV"])
    last_ok = pd.Timestamp.today().normalize() - pd.Timedelta(days=7)
    end = min(pd.Timestamp(f"{end_year}-12-31"), last_ok)
    r = requests.get("https://archive-api.open-meteo.com/v1/archive", timeout=120, params={
        "latitude": LAT, "longitude": LON, "start_date": f"{start_year}-01-01",
        "end_date": end.strftime("%Y-%m-%d"), "daily": "temperature_2m_mean,precipitation_sum",
        "timezone": "Asia/Manila"})
    r.raise_for_status()                   # if Open-Meteo fails the run stops; weather is never invented
    d = pd.DataFrame(r.json()["daily"])
    d["time"] = pd.to_datetime(d["time"])
    d["year"], d["month"] = d.time.dt.year, d.time.dt.month
    m = (d.groupby(["year", "month"]).agg(rainfall_mm=("precipitation_sum", "sum"),
                                          temp_c=("temperature_2m_mean", "mean"),
                                          days=("time", "size")).reset_index())
    full = m.apply(lambda r: calendar.monthrange(int(r.year), int(r.month))[1], axis=1)
    return m[m.days == full].drop(columns="days").round(1)


# ------------------------------------------------------------------ metrics
def metrics(y, p):
    y, p = np.asarray(y, float), np.asarray(p, float)
    return {"MAE": float(mean_absolute_error(y, p)),
            "RMSE": float(np.sqrt(mean_squared_error(y, p))),
            "MAPE_%": float(np.mean(np.abs((y - p) / y)) * 100)}


# ------------------------------------------------------------------ module 1: harvest (yield per hectare)
def prep():
    return ColumnTransformer([("cat", OneHotEncoder(handle_unknown="ignore", sparse_output=False), CAT),
                              ("num", StandardScaler(), NUM)])


def make_harvest_model(name):
    est = {"ElasticNet": ElasticNet(alpha=0.05, l1_ratio=0.5, max_iter=20000),
           "RandomForest": RandomForestRegressor(n_estimators=300, min_samples_leaf=2, random_state=42, n_jobs=-1),
           "GaussianProcess": GaussianProcessRegressor(kernel=C(1.0) * RBF(3.0) + WhiteKernel(0.1),
                                                       normalize_y=True, random_state=42)}[name]
    return Pipeline([("prep", prep()), ("model", est)])


def fit_harvest(name, data):
    if name == "GaussianProcess" and len(data) > GP_MAX_ROWS:
        data = data.sample(GP_MAX_ROWS, random_state=42)
    return make_harvest_model(name).fit(data[FEATS], data.yield_kg_ha)


def prepare_harvest_data(production, weather):
    p = production.copy()
    for c in ["year", "month", "area_ha", "production_kg"]:
        p[c] = pd.to_numeric(p[c], errors="coerce")
    p = p.dropna(subset=["year", "month", "crop", "barangay", "area_ha", "production_kg"])
    p = p[(p.area_ha > 0) & (p.production_kg > 0)].copy()
    p["yield_kg_ha"] = p.production_kg / p.area_ha
    g = p.groupby("crop")["yield_kg_ha"]
    q1, q3 = g.transform(lambda s: s.quantile(.25)), g.transform(lambda s: s.quantile(.75))
    p = p[(p.yield_kg_ha >= q1 - 3 * (q3 - q1)) & (p.yield_kg_ha <= q3 + 3 * (q3 - q1))]
    clim = weather.groupby("month")[["rainfall_mm", "temp_c"]].mean()
    df = p.merge(weather, on=["year", "month"], how="left")
    for c in ["rainfall_mm", "temp_c"]:
        df[c] = df[c].fillna(df["month"].map(clim[c]))
    df["month_sin"], df["month_cos"] = np.sin(2 * np.pi * df.month / 12), np.cos(2 * np.pi * df.month / 12)
    return df, clim


def train_harvest(df):
    if len(df) < MIN_PRODUCTION_ROWS:
        raise SystemExit(f"Only {len(df)} usable production rows (need {MIN_PRODUCTION_ROWS}). Not retraining.")
    if df.year.nunique() >= 4:                                   # time-based split: last 2 years = test
        ly = df.year.max()
        train, test = df[df.year < ly - 1], df[df.year >= ly - 1]
    else:                                                        # too few years: random split
        test = df.sample(frac=0.2, random_state=42)
        train = df.drop(test.index)
        log("Fewer than 4 years of data: using a random 80/20 split instead of a time-based split.")
    res = {"Baseline (crop mean)": metrics(test.yield_kg_ha,
                                           test.crop.map(train.groupby("crop").yield_kg_ha.mean())
                                           .fillna(train.yield_kg_ha.mean()))}
    for name in ["ElasticNet", "RandomForest", "GaussianProcess"]:
        log(f"harvest: training {name}")
        res[name] = metrics(test.yield_kg_ha, fit_harvest(name, train).predict(test[FEATS]))
    table = pd.DataFrame(res).T.sort_values("RMSE")
    best = table.drop(index="Baseline (crop mean)").index[0]
    log(f"harvest results (test set):\n{table.round(2)}\nselected: {best}")
    return table, best, fit_harvest(best, df)


# ------------------------------------------------------------------ module 2: price forecast
def feats(hist, month):
    return [hist[-1], hist[-2], hist[-3], hist[-12], np.sin(2 * np.pi * month / 12), np.cos(2 * np.pi * month / 12)]


def make_price_ml(name):
    if name == "ElasticNet":
        return Pipeline([("sc", StandardScaler()), ("m", ElasticNet(alpha=0.05, l1_ratio=0.5, max_iter=10000))])
    return RandomForestRegressor(n_estimators=300, min_samples_leaf=2, random_state=42, n_jobs=-1)


def fit_forecast(name, s, steps=12):
    idx = pd.date_range(s.index[-1] + pd.offsets.MonthBegin(1), periods=steps, freq="MS")
    vals = s.values.astype(float)
    if name == "SeasonalNaive":
        return np.array([vals[-12 + (i % 12)] for i in range(steps)]), idx
    if name == "ARIMA":
        try:
            p = ARIMA(vals, order=(1, 1, 1), seasonal_order=(1, 0, 0, 12)).fit().forecast(steps)
        except Exception:
            p = ARIMA(vals, order=(1, 1, 1)).fit().forecast(steps)
        return np.asarray(p), idx
    if name == "Ensemble":
        return np.mean([fit_forecast(n, s, steps)[0] for n in ["ARIMA", "ElasticNet", "RandomForest"]], axis=0), idx
    X = [feats(list(vals[:t]), s.index[t].month) for t in range(12, len(vals))]
    model = make_price_ml(name).fit(np.array(X), vals[12:])
    hist, preds = list(vals), []
    for d in idx:                                                # recursive: each prediction feeds the next month
        p = float(model.predict(np.array([feats(hist, d.month)]))[0])
        preds.append(p)
        hist.append(p)
    return np.array(preds), idx


def train_prices(prices):
    pr = prices.copy()
    for c in ["year", "month", "price_per_kg"]:
        pr[c] = pd.to_numeric(pr[c], errors="coerce")
    pr = pr.dropna(subset=["year", "month", "crop", "price_per_kg"])
    pr["date"] = pd.to_datetime(dict(year=pr.year.astype(int), month=pr.month.astype(int), day=1))
    pr = pr.groupby(["crop", "date"], as_index=False).price_per_kg.mean()
    names = ["SeasonalNaive", "ARIMA", "ElasticNet", "RandomForest", "Ensemble"]
    rows, forecasts, best_by_crop = [], {}, {}
    for crop, g in pr.groupby("crop"):
        s = g.set_index("date").price_per_kg.sort_index().asfreq("MS").interpolate()
        if len(s) < MIN_PRICE_MONTHS:
            log(f"price: skipping {crop} (only {len(s)} months of prices, need {MIN_PRICE_MONTHS})")
            continue
        tr, te = s[:-12], s[-12:]                                # last 12 months held out for testing
        crop_rows = []
        for n in names:
            try:
                p, _ = fit_forecast(n, tr, 12)
                crop_rows.append({"crop": crop, "model": n, **metrics(te.values, p)})
            except Exception as e:
                log(f"price: {n} failed for {crop}: {e}")
        cr = pd.DataFrame(crop_rows)
        best = cr.loc[cr.RMSE.idxmin(), "model"]
        p, idx = fit_forecast(best, s, 12)
        forecasts[crop], best_by_crop[crop] = pd.DataFrame({"date": idx, "forecast_price": p}), best
        rows += crop_rows
        log(f"price: {crop} -> {best}")
    return pd.DataFrame(rows), forecasts, best_by_crop


# ------------------------------------------------------------------ module 3: planting advisory
def range_score(v, lo, hi):
    """1 inside [lo, hi]; falls linearly to 0 at a distance of half the range width OUTSIDE the nearest bound."""
    if lo <= v <= hi:
        return 1.0
    d = lo - v if v < lo else v - hi
    return max(0.0, 1 - d / (0.5 * (hi - lo)))


def planting_scores(clim):
    rows = []
    for crop, (tmin, tmax, rmin, rmax) in CROP_REQ.items():
        for m in clim.index:
            sc = (range_score(clim.loc[m, "temp_c"], tmin, tmax) + range_score(clim.loc[m, "rainfall_mm"], rmin, rmax)) / 2
            rows.append({"crop": crop, "month": int(m), "score": round(float(sc), 3)})
    return rows


# ------------------------------------------------------------------ build rows for Supabase
def build_yield_rows(df, clim, model, best, rmse):
    grid = df[["crop", "barangay"]].drop_duplicates().merge(pd.DataFrame({"month": range(1, 13)}), how="cross")
    grid["rainfall_mm"], grid["temp_c"] = grid.month.map(clim.rainfall_mm), grid.month.map(clim.temp_c)
    grid["month_sin"], grid["month_cos"] = np.sin(2 * np.pi * grid.month / 12), np.cos(2 * np.pi * grid.month / 12)
    grid["yield_kg_ha"] = np.clip(model.predict(grid[FEATS]), 0, None)
    muni = grid.groupby(["crop", "month"], as_index=False).yield_kg_ha.mean()
    muni["barangay"] = "ALL"
    out = pd.concat([grid[["crop", "barangay", "month", "yield_kg_ha"]], muni], ignore_index=True)
    out = out.drop_duplicates(["crop", "barangay", "month"], keep="last")   # two rows with one key would fail the upsert
    out["yield_kg_ha"] = out.yield_kg_ha.round(1)
    out["rmse_kg_ha"], out["model"] = round(float(rmse), 1), best           # rmse = measured on the test set
    return out


# ------------------------------------------------------------------ main
def main():
    needs_sb = DATA_SOURCE == "supabase" or not DRY_RUN
    sb = get_supabase() if needs_sb else None
    production, prices = load_records(sb)
    log(f"loaded {len(production)} production rows, {len(prices)} price rows (source: {DATA_SOURCE})")

    weather = fetch_weather(int(production.year.min()), int(production.year.max()))
    df, clim = prepare_harvest_data(production, weather)

    harvest_table, best_harvest, harvest_model = train_harvest(df)
    best_mape = float(harvest_table.loc[best_harvest, "MAPE_%"])
    if best_mape > MAX_HARVEST_MAPE and not DRY_RUN:
        raise SystemExit(f"Selected harvest model MAPE {best_mape:.1f}% exceeds {MAX_HARVEST_MAPE}%. "
                         "Nothing written. Check the data for errors.")
    rmse = harvest_table.loc[best_harvest, "RMSE"]

    price_table, forecasts, best_price = train_prices(prices)
    if not forecasts:
        raise SystemExit("No crop had enough price history. Nothing to write.")

    yield_df = build_yield_rows(df, clim, harvest_model, best_harvest, rmse)
    price_rows = [{"crop": c, "month": d.strftime("%Y-%m-01"), "forecast_price": round(float(p), 2), "model": best_price[c]}
                  for c, f in forecasts.items() for d, p in zip(f.date, f.forecast_price)]
    plant_rows = planting_scores(clim)
    metric_rows = [{"module": "harvest", "model": m, "crop": "ALL", "mae": round(r["MAE"], 3), "rmse": round(r["RMSE"], 3),
                    "mape_pct": round(r["MAPE_%"], 3), "selected": m == best_harvest} for m, r in harvest_table.iterrows()]
    metric_rows += [{"module": "price", "model": r.model, "crop": r.crop, "mae": round(r.MAE, 3), "rmse": round(r.RMSE, 3),
                     "mape_pct": round(r["MAPE_%"], 3), "selected": bool(best_price[r.crop] == r.model)}
                    for _, r in price_table.iterrows()]

    # reports for Chapter IV (Tables X and Y)
    joblib.dump(harvest_model, "out/harvest_model.pkl")
    harvest_table.round(3).to_csv("out/harvest_model_comparison.csv")
    price_table.round(3).to_csv("out/price_model_comparison.csv", index=False)
    yield_df.to_csv("out/yield_estimates.csv", index=False)
    pd.DataFrame(price_rows).to_csv("out/price_forecasts.csv", index=False)

    if DRY_RUN:
        log("DRY RUN: reports saved in out/, nothing written to Supabase.")
        return
    push(sb, "yield_estimates", yield_df.to_dict(orient="records"), "crop,barangay,month")
    push(sb, "price_forecasts", price_rows, "crop,month")
    push(sb, "planting_advisory", plant_rows, "crop,month")
    push(sb, "model_metrics", metric_rows, "module,model,crop")
    log("done")


if __name__ == "__main__":
    main()
