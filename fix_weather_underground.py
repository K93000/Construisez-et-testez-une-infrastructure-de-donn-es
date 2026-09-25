import pandas as pd
from datetime import datetime

def combine_sheets(input_xlsx, output_csv):
    xls = pd.ExcelFile(input_xlsx)
    dfs = []
    for sheet_name in xls.sheet_names:
        df = xls.parse(sheet_name)
        date = datetime.strptime(sheet_name.strip(), "%d%m%y").date()
        df["Date"] = date.isoformat()
        dfs.append(df)
    combined = pd.concat(dfs, ignore_index=True)
    combined.to_csv(output_csv, index=False)
    print(f"{output_csv} : {len(combined)} lignes, {len(xls.sheet_names)} onglets fusionnés")

combine_sheets("Weather+Underground+-+Ichtegem,+BE.xlsx", "weather_underground_ichtegem_fixed.csv")
combine_sheets("Weather+Underground+-+La+Madeleine,+FR.xlsx", "weather_underground_la_madeleine_fixed.csv")