from fastapi import FastAPI, UploadFile, File
from fastapi.responses import JSONResponse
from pydantic import BaseModel
from fastapi.middleware.cors import CORSMiddleware
import pandas as pd
import numpy as np
import sqlalchemy
from sqlalchemy import create_engine, text, inspect
import asyncpg
import tempfile
import re
import os
from datetime import datetime, date
import requests
import traceback

# ================== CONFIG =====================
SQLCODER_API_URL = "" 
POSTGRES_URL = ""
ASYNC_POSTGRES_URL = ""

app = FastAPI()
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

engine = create_engine(POSTGRES_URL, future=True)

DATAFRAME_STORAGE = {
    "table_name": None,
    "all_tables": [],
    "all_dataframes": {}
}

def make_json_serializable(obj):
    if pd.isna(obj):
        return None
    elif isinstance(obj, (datetime, date, pd.Timestamp)):
        return str(obj)
    elif isinstance(obj, np.integer):
        return int(obj)
    elif isinstance(obj, np.floating):
        return float(obj)
    elif isinstance(obj, np.ndarray):
        return obj.tolist()
    else:
        return str(obj)

# ================== UPLOAD ENDPOINT =====================
@app.post("/upload")
async def upload_file(file: UploadFile = File(...)):
    ext = file.filename.split('.')[-1].lower()
    temp = tempfile.NamedTemporaryFile(delete=False, suffix='.' + ext)
    temp.write(await file.read())
    temp.close()
    table_names = []
    try:
        table_name = "data"
        if ext == "csv":
            try:
                df = pd.read_csv(temp.name, encoding="utf-8")
            except UnicodeDecodeError:
                df = pd.read_csv(temp.name, encoding="cp1252")
            df.to_sql(table_name, engine, if_exists="replace", index=False)
            table_names = [table_name]
        elif ext in ["xls", "xlsx"]:
            df = pd.read_excel(temp.name)
            df.to_sql(table_name, engine, if_exists="replace", index=False)
            table_names = [table_name]
        elif ext == "sql":
            with open(temp.name, 'r', encoding='utf-8', errors='ignore') as f:
                sql_text = f.read()
            with engine.connect() as conn:
                for statement in sql_text.split(";"):
                    stmt = statement.strip()
                    if stmt:
                        try:
                            conn.execute(text(stmt))
                        except Exception as e:
                            continue
                conn.commit()
            insp = inspect(engine)
            table_names = [t.lower() for t in insp.get_table_names()]
        else:
            return JSONResponse({"error": "Unsupported file format. Supported: .csv, .xlsx, .sql"}, status_code=400)

        # Save dataframes preview for the first 20 rows
        DATAFRAME_STORAGE["all_tables"] = table_names
        DATAFRAME_STORAGE["table_name"] = table_names[0] if table_names else None
        DATAFRAME_STORAGE["all_dataframes"] = {}
        for tbl in table_names:
            try:
                DATAFRAME_STORAGE["all_dataframes"][tbl] = pd.read_sql(
                    f'SELECT * FROM "{tbl}" LIMIT 20', engine
                )
            except Exception:
                DATAFRAME_STORAGE["all_dataframes"][tbl] = pd.DataFrame()

        preview_table = DATAFRAME_STORAGE["table_name"]
        preview_df = pd.read_sql(
            f'SELECT * FROM "{preview_table}" LIMIT 20', engine
        ) if preview_table else pd.DataFrame()

        return {
            "message": "File uploaded successfully",
            "columns": list(preview_df.columns),
            "rows": preview_df.to_dict(orient="records"),
            "table_name": preview_table,
            "all_tables": table_names,
            "total_rows": len(preview_df),
            "preview_rows": min(20, len(preview_df)),
        }
    except Exception as e:
        traceback.print_exc()
        return JSONResponse({"error": str(e)}, status_code=500)
    finally:
        try:
            os.unlink(temp.name)
        except Exception:
            pass

# ================== QUESTION ENDPOINT (SQLCODER) =====================
class QuestionRequest(BaseModel):
    query: str

@app.post("/ask")
async def ask_question(item: QuestionRequest):
    all_tables = DATAFRAME_STORAGE["all_tables"]
    all_dataframes = DATAFRAME_STORAGE.get("all_dataframes", {})
    table_name = DATAFRAME_STORAGE["table_name"]

    if not all_tables or not table_name:
        return JSONResponse({"error": "No data uploaded yet."}, status_code=400)

    try:
        # --- Prepare multi-table schema for SQLCoder ---
        schemas = []
        for tbl in all_tables:
            df = all_dataframes[tbl]
            columns = list(df.columns)
            # Top-5 rows for more context
            top_rows = [
                [make_json_serializable(val) for val in row]
                for _, row in df.head(5).iterrows()
            ]
            schemas.append({
                "table_name": tbl,
                "columns": columns,
                "top_rows": top_rows
            })

        # Final payload (multi-table)
        schema_payload = {
            "schemas": schemas,
            "query": item.query
        }
        print("\n=== Sending to SQLCoder ===")
        # Debugging: Print the schema payload
        print("Schema Payload:", schema_payload)    
        # === Send to SQLCoder ===
        try:
            response = requests.post(
                SQLCODER_API_URL,
                json=schema_payload,
                timeout=30
            )
            response.raise_for_status()
            sql = response.json().get("sql")
        except Exception as e:
            print("\n=== ERROR calling SQLCoder endpoint ===")
            print(e)
            return JSONResponse({"error": f"SQLCoder endpoint error: {str(e)}"}, status_code=500)

        if not sql:
            return JSONResponse({"error": "SQL generation failed."}, status_code=500)

        sql = sql.strip().replace("```sql", "").replace("```", "").strip()

        # (Optional: You may want to perform table name fixing here, as in your code.)

        # Execute the SQL
        try:
            conn = await asyncpg.connect(ASYNC_POSTGRES_URL)
            rows = await conn.fetch(sql)
            await conn.close()
            result_dict = [dict(row) for row in rows]
            columns = list(result_dict[0].keys()) if result_dict else []
        except Exception as e:
            print("\n=== ERROR executing SQL ===")
            print(e)
            return JSONResponse({"error": f"PostgreSQL execution error: {str(e)}"}, status_code=400)

        return {
            "sql": sql,
            "result": result_dict,
            "result_rows": len(result_dict),
            "columns": columns,
            "query": item.query,
            "tables_used": all_tables
        }
    except Exception as e:
        print("\n=== ERROR IN /ask ENDPOINT ===")
        print(traceback.format_exc())
        return JSONResponse({"error": f"Unexpected error: {str(e)}"}, status_code=500)


# ================== DELETE ALL TABLES =====================
@app.delete("/delete-data")
async def delete_data():
    try:
        all_tables = DATAFRAME_STORAGE.get("all_tables", [])
        if not all_tables:
            return {"message": "No data to delete", "deleted_tables": []}
        deleted_tables = []
        with engine.connect() as conn:
            for table_name in all_tables:
                try:
                    conn.execute(text(f'DROP TABLE IF EXISTS "{table_name}"'))
                    deleted_tables.append(table_name)
                except Exception:
                    pass
            conn.commit()
        DATAFRAME_STORAGE["table_name"] = None
        DATAFRAME_STORAGE["all_tables"] = []
        DATAFRAME_STORAGE["all_dataframes"] = {}
        return {
            "message": f"Successfully deleted {len(deleted_tables)} table(s)",
            "deleted_tables": deleted_tables
        }
    except Exception as e:
        traceback.print_exc()
        return JSONResponse({"error": f"Failed to delete data: {str(e)}"}, status_code=500)

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8001)

