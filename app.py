import os

import gradio as gr
import pandas as pd
import spaces
from dotenv import load_dotenv

from db.connection import get_schema, run_select
from rag.answer_chain import generate_answer
from rag.sql_chain import generate_sql
from rag.sql_guard import clean_sql, is_safe_select

load_dotenv()

CONFIG_ERROR = None
if not os.environ.get("GEMINI_API_KEY") or not os.environ.get("DATABASE_URL"):
    CONFIG_ERROR = (
        "Missing configuration. Set GEMINI_API_KEY and DATABASE_URL as environment "
        "variables (a local .env file, or HF Space secrets in production)."
    )

SCHEMA = get_schema()


@spaces.GPU
def answer_question(question: str):
    """This Space was created on ZeroGPU hardware, which requires at least one
    @spaces.GPU-decorated function to start - this app makes no actual GPU
    calls (it's a Gemini + Postgres API proxy), so the decorator is a no-op
    here purely to satisfy that platform requirement."""
    if CONFIG_ERROR:
        return CONFIG_ERROR, "", pd.DataFrame()
    if not question or not question.strip():
        return "Please enter a question.", "", pd.DataFrame()

    try:
        sql_query = clean_sql(generate_sql(question, SCHEMA))
    except Exception as e:
        return f"Failed to generate SQL: {e}", "", pd.DataFrame()

    if not is_safe_select(sql_query):
        return (
            "The generated query isn't a safe read-only SELECT, so it wasn't run. "
            "Try rephrasing your question.",
            sql_query,
            pd.DataFrame(),
        )

    try:
        rows = run_select(sql_query)
        answer = generate_answer(question, sql_query, rows)
    except Exception as e:
        return f"An error occurred: {e}", sql_query, pd.DataFrame()

    return answer, sql_query, pd.DataFrame(rows)


with gr.Blocks(title="Protein Database Query System") as demo:
    gr.Markdown(
        "# Protein Database Query System\n"
        "Ask a natural-language question; it's translated to SQL and run against a "
        "UniProt-derived Postgres database."
    )
    if CONFIG_ERROR:
        gr.Markdown(f"⚠️ **{CONFIG_ERROR}**")

    question_box = gr.Textbox(label="Enter your question", lines=3)
    submit_btn = gr.Button("Get Answer", variant="primary")
    answer_box = gr.Textbox(label="Answer", interactive=False)

    with gr.Accordion("View generated SQL", open=False):
        sql_box = gr.Code(label="SQL", language="sql", interactive=False)

    result_table = gr.Dataframe(label="Raw query result")

    outputs = [answer_box, sql_box, result_table]
    submit_btn.click(answer_question, inputs=question_box, outputs=outputs)
    question_box.submit(answer_question, inputs=question_box, outputs=outputs)

if __name__ == "__main__":
    demo.launch()
