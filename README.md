# ASK-SQL

ASK-SQL is a natural language to SQL query system that lets users interact with databases using plain text or voice.  
It automatically converts questions into optimized SQL queries, executes them on PostgreSQL, and displays results in a user-friendly web frontend.

---

## Features
- Upload CSV, Excel, or SQL files to load tables into PostgreSQL.
- Ask natural language questions — converted to SQL using **Llama-3 SQLCoder**.
- Supports **multi-table schemas** with context from top rows.
- Returns both generated SQL and executed query results.
- Simple web frontend with chat-style interaction.

---

## Project Structure
```
ASK-SQL/
│── Frontend/
│   ├── index.html       # Web UI
│   ├── script.js        # Client-side logic (connects to backend at localhost:3001)
│   ├── style.css        # Styling
│   └── sql.png          # Logo
│
│── sample-files-for-testing  # Example datasets for testing
│── sample-queries       # Example NL-to-SQL prompts
│── main.py              # Main FastAPI backend (upload, ask, delete-data)
│── Model_API.py         # SQLCoder model API (deployed via ngrok / server)
│── requirements.txt     # Dependencies
│── README.md            # Project documentation
```

---

## Setup & Installation

### 1. Clone repo
```bash
git clone https://github.com/your-repo/ask-sql.git
cd ask-sql
```

### 2. Install dependencies
```bash
pip install -r requirements.txt
```

### 3. Start **Model API**
This hosts the **Llama-3 SQLCoder** model.

```bash
python Model_API.py
```

- Expose it via **ngrok**:
```bash
ngrok http 8000
```
- Copy the ngrok HTTPS URL and update it in `main.py` under:
```python
SQLCODER_API_URL = "https://<your-ngrok>.ngrok-free.app/generate"
```

### 4. Start **Main API**
Runs the FastAPI backend for file upload, ask endpoint, and table management.

```bash
uvicorn main:app --reload --port 3001
```

### 5. Start **Frontend**
Serve frontend with:
```bash
cd Frontend
python -m http.server 8080
```
Now open [http://localhost:8080](http://localhost:8080) in your browser.

---

## Endpoints (Main API)

- `POST /upload` → Upload dataset (CSV, Excel, SQL).
- `POST /ask` → Ask natural language question, get SQL + results.
- `DELETE /delete-data` → Drop uploaded tables from DB.

---

## 🛠 Tech Stack
- **Backend**: FastAPI, SQLAlchemy, asyncpg, Pandas
- **Model**: Llama-3 SQLCoder -8B (HuggingFace Transformers, quantized for efficiency)
- **Database**: PostgreSQL
- **Frontend**: HTML, CSS, JavaScript
- **Deployment**: ngrok (for exposing model API)

---

## Demo
1. Upload your dataset.  
2. Ask: *"Show me the top 5 customers with highest sales."*  
3. System generates SQL → Executes on PostgreSQL → Returns results instantly.  

---

## Future Improvements
- Voice input (via Whisper integration).
- Chart/graph visualizations of query results.
- Authentication & multi-user support.

---

## Author
Developed by **Shaheer Abdullah**
