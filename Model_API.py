from fastapi import FastAPI
from pydantic import BaseModel
from transformers import AutoTokenizer, AutoModelForCausalLM, BitsAndBytesConfig
from fastapi.middleware.cors import CORSMiddleware
from typing import List, Any, Optional
import torch

# Use only GPU:1 if available
device = torch.device("cuda:1" if torch.cuda.is_available() else "cpu")

app = FastAPI()

# CORS config
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

model_id = "defog/llama-3-sqlcoder-8b"
quant_config = BitsAndBytesConfig(
    load_in_4bit=True,
    bnb_4bit_compute_dtype=torch.float16,
    bnb_4bit_use_double_quant=True,
    bnb_4bit_quant_type="nf4"
)
tokenizer = AutoTokenizer.from_pretrained(model_id, trust_remote_code=True)
model = AutoModelForCausalLM.from_pretrained(
    model_id,
    device_map={"": device},
    trust_remote_code=True,
    quantization_config=quant_config
)

# === Multi-table aware input models ===
class SingleSchema(BaseModel):
    columns: List[str]
    top_rows: List[List[Any]]

class SQLRequestSingle(BaseModel):
    schema: SingleSchema
    query: str
    table_name: str = "data"

class TableSchema(BaseModel):
    table_name: str
    columns: List[str]
    top_rows: List[List[Any]]

class SQLRequestMulti(BaseModel):
    schemas: List[TableSchema]
    query: str

@app.post("/generate")
def generate_sql(request: dict):
    """
    Handles both:
      - Single-table requests (schema, table_name, query)
      - Multi-table requests (schemas, query)
    """
    if "schemas" in request:  # Multi-table mode
        schemas = request["schemas"]
        user_query = request["query"]
        schema_str = ""
        for table in schemas:
            schema_str += f"Table name: {table['table_name']}\n"
            schema_str += f"Columns: {', '.join(table['columns'])}\n"
            schema_str += "Top rows:\n"
            for row in table['top_rows']:
                schema_str += f"{dict(zip(table['columns'], row))}\n"
            schema_str += "\n"
        prompt = (
            "You are an expert SQL developer working with PostgreSQL.\n"
            "ALWAYS wrap every table and column name in double quotes (\"\") exactly as shown below. For example, write SELECT \"P\" FROM \"data\", not SELECT P FROM data.\n"
            "Do NOT use table aliases unless asked in the user question.\n"
            "Do NOT guess or hallucinate table or column names not shown in the schema below.\n"
            "If a table or column name contains spaces, case, or unusual characters, you MUST use double quotes (\"\").\n"
            "Given the schemas and example rows for multiple tables below, write a valid SQL query.\n\n"
            f"{schema_str}"
            f"User question:\n{user_query}\n\n"
            "Respond ONLY with the SQL query and nothing else."
        )
        print(f"Generated prompt for multi-table: {prompt}")
    else:  # Single-table fallback (legacy)
        schema = request["schema"]
        user_query = request["query"]
        table_name = request.get("table_name", "data")
        schema_str = f"Table name: {table_name}\n"
        schema_str += f"Columns: {', '.join(schema['columns'])}\n"
        schema_str += "Top rows:\n"
        for row in schema["top_rows"]:
            schema_str += f"{dict(zip(schema['columns'], row))}\n"
        prompt = (
            "You are an expert SQL developer working with PostgreSQL.\n"
            "ALWAYS wrap every table and column name in double quotes (\"\") exactly as shown below. For example, write SELECT \"P\" FROM \"data\", not SELECT P FROM data.\n"
            "Do NOT use table aliases unless asked in the user question.\n"
            "Do NOT guess or hallucinate table or column names not shown in the schema below.\n"
            "If a table or column name contains spaces, case, or unusual characters, you MUST use double quotes (\"\").\n"
            "Given the schema and example rows below, write a valid SQL query.\n\n"
            f"{schema_str}"
            f"User question:\n{user_query}\n\n"
            f"Only refer to the table as \"{table_name}\" in the SQL. Respond ONLY with the SQL query and nothing else."
        )
        print(f"Generated prompt for single-table: {prompt}")

    # LLM chat-style prompt
    messages = [
        {
            "role": "user",
            "content": prompt
        }
    ]

    inputs = tokenizer.apply_chat_template(
        messages,
        add_generation_prompt=True,
        return_tensors="pt"
    ).to(device)

    outputs = model.generate(
        inputs,
        max_new_tokens=128,
        do_sample=False
    )

    sql = tokenizer.decode(
        outputs[0][inputs.shape[-1]:],
        skip_special_tokens=True
    )

    return {"sql": sql.strip()}
