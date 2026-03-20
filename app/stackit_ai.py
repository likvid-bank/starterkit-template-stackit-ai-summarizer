import os
from openai import OpenAI


# Create a client that talks to STACKIT's OpenAI-compatible endpoint
client = OpenAI(
    base_url=os.environ.get("STACKIT_AI_BASE_URL", "").rstrip("/"),
    api_key=os.environ.get("STACKIT_AI_API_KEY", ""),
)

# Name of the model served by STACKIT AI Model Serving
MODEL_NAME = os.environ.get("STACKIT_AI_MODEL", "")


def summarize_text(text: str) -> str:
    """
    Call the STACKIT chat model and return a bullet point summary.

    This function is intentionally synchronous. FastAPI will call it via
    run_in_threadpool so that the event loop stays responsive.
    """
    if not client.api_key or not client.base_url or not MODEL_NAME:
        raise RuntimeError(
            "STACKIT_AI_BASE_URL, STACKIT_AI_API_KEY or STACKIT_AI_MODEL environment variables are not set."
        )

    response = client.chat.completions.create(
        model=MODEL_NAME,
        messages=[
            {
                "role": "system",
                "content": (
                    "You summarize texts objectively into 3-5 concise bullet points. "
                    "Reduce the content to its essentials. "
                    "Always respond in the same language as the input text."
                ),
            },
            {
                "role": "user",
                "content": f"Summarize this text to its key points:\n\n{text}",
            },
        ],
        temperature=0.4,
        max_tokens=400,
    )

    # Return only the generated summary text
    return response.choices[0].message.content
