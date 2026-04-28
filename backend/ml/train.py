"""
Script d'entraînement — à exécuter une seule fois depuis backend/
    python ml/train.py

Dataset attendu : ml/yield_df.csv
Colonnes Kaggle typiques :
    Area, Item, Year, hg/ha_yield, average_rain_fall_mm_per_year, pesticides_tonnes, avg_temp

Sorties :
    ml/model.pkl       — pipeline sklearn complet (préprocessing + XGBoost)
    ml/known_crops.pkl — liste des cultures connues du modèle
"""

import os
import sys
import pandas as pd
import numpy as np
import joblib
from sklearn.pipeline import Pipeline
from sklearn.compose import ColumnTransformer
from sklearn.preprocessing import OneHotEncoder, StandardScaler
from sklearn.model_selection import train_test_split
from sklearn.metrics import r2_score, mean_absolute_error
import xgboost as xgb

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
CSV_PATH   = os.path.join(SCRIPT_DIR, "yield_df.csv")
MODEL_PATH = os.path.join(SCRIPT_DIR, "model.pkl")
CROPS_PATH = os.path.join(SCRIPT_DIR, "known_crops.pkl")

COLUMN_MAP = {
    "hg/ha_yield":                    "yield_hg_ha",
    "average_rain_fall_mm_per_year":  "rainfall_mm",
    "avg_temp":                       "avg_temp_c",
    "Item":                           "culture_type",
    "Area":                           "region",
}

FEATURES    = ["culture_type", "rainfall_mm", "avg_temp_c", "pesticides_tonnes"]
TARGET      = "yield_t_ha"
CATEGORICAL = ["culture_type"]
NUMERICAL   = ["rainfall_mm", "avg_temp_c", "pesticides_tonnes"]


def load_and_clean(path: str) -> pd.DataFrame:
    df = pd.read_csv(path)
    df = df.rename(columns={k: v for k, v in COLUMN_MAP.items() if k in df.columns})

    if "yield_hg_ha" not in df.columns:
        sys.exit("Colonne 'hg/ha_yield' introuvable dans le CSV.")

    df[TARGET] = df["yield_hg_ha"] / 10000  # hg/ha → t/ha

    required = FEATURES + [TARGET]
    df = df.dropna(subset=required)

    # Retire les rendements aberrants (> 99e percentile)
    p99 = df[TARGET].quantile(0.99)
    df = df[df[TARGET] <= p99]

    print(f"Dataset : {len(df):,} lignes | {df['culture_type'].nunique()} cultures")
    return df


def build_pipeline() -> Pipeline:
    preprocessor = ColumnTransformer([
        ("cat", OneHotEncoder(handle_unknown="ignore", sparse_output=False), CATEGORICAL),
        ("num", StandardScaler(), NUMERICAL),
    ])

    model = xgb.XGBRegressor(
        n_estimators=400,
        max_depth=6,
        learning_rate=0.05,
        subsample=0.8,
        colsample_bytree=0.8,
        min_child_weight=3,
        random_state=42,
        n_jobs=-1,
        verbosity=0,
    )

    return Pipeline([("preprocessor", preprocessor), ("model", model)])


def main():
    if not os.path.exists(CSV_PATH):
        sys.exit(f"Fichier introuvable : {CSV_PATH}\nTélécharge le dataset depuis Kaggle et place-le dans backend/ml/")

    df = load_and_clean(CSV_PATH)
    X, y = df[FEATURES], df[TARGET]

    X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)

    pipeline = build_pipeline()
    print("Entraînement en cours…")
    pipeline.fit(X_train, y_train)

    y_pred = pipeline.predict(X_test)
    print(f"\n── Évaluation ──────────────────")
    print(f"  R²  : {r2_score(y_test, y_pred):.4f}")
    print(f"  MAE : {mean_absolute_error(y_test, y_pred):.4f} t/ha")
    print(f"────────────────────────────────\n")

    joblib.dump(pipeline, MODEL_PATH)
    print(f"Modèle sauvegardé  → {MODEL_PATH}")

    known_crops = sorted(df["culture_type"].unique().tolist())
    joblib.dump(known_crops, CROPS_PATH)
    print(f"Cultures ({len(known_crops)}) → {CROPS_PATH}")


if __name__ == "__main__":
    main()
