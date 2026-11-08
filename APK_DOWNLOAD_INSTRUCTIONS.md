# PAGRI - Application APK Build & Release Instructions

This document provides instructions for building and downloading the release **APK** packages for **PAGRI Farmer** and **PAGRI Municipal Admin**.

---

## 📱 Application Versions

* **App Name**: PAGRI (Pagsanjan Agricultural Decision Support System)
* **Target Platforms**: Android 5.0 (API 21+) / Windows 10/11
* **Database**: Supabase (`https://dlgetsqzvwwrbqltjcct.supabase.co`)
* **Machine Learning Engine**: Random Forest Yield Estimation & ARIMA Price Forecasting

---

## 🚀 Building Release APKs

Run the following commands in your terminal to build standalone Android installation APKs:

### 1. Build PAGRI Farmer APK
```bash
flutter build apk --target=lib/main_farmer.dart --release
```
* **Output APK**: `build/app/outputs/flutter-apk/app-release.apk`
* **Rename to**: `PAGRI_Farmer_v1.0.apk`

---

### 2. Build PAGRI Municipal Admin APK
```bash
flutter build apk --target=lib/main_admin.dart --release
```
* **Output APK**: `build/app/outputs/flutter-apk/app-release.apk`
* **Rename to**: `PAGRI_Admin_v1.0.apk`

---

## 📊 Machine Learning & DSS Supabase Connections

| Component | Location | Function |
|---|---|---|
| **ML Notebook** | `ml/DSS_Pagsanjan_ML.ipynb` | Original Machine Learning Google Colab notebook |
| **Python Pipeline** | `ml/dss_pagsanjan_ml.py` | Training script for Random Forest & ARIMA models |
| **SQL Schema** | `sql/app_schema_changes.sql` | Supabase SQL script for ML precomputed result tables |
| **Weekly Retraining** | `.github/workflows/dss_ml_weekly.yml` | Automated weekly GitHub Actions ML retraining |
| **Flutter ML Service** | `lib/services/dss_ml_service.dart` | Queries `yield_estimates` and `price_forecasts` from Supabase |
| **DSS Engine** | `lib/services/dss_service.dart` | Calculates harvest yield, income, and profit using ML predictions |
| **Farmer DSS UI** | `lib/screens/dashboard/tabs/dss_tab.dart` | Displays ML crop advisories and harvest estimates |
