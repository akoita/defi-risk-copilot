-- Remote model for text generation (Gemini)
CREATE OR REPLACE MODEL `${PROJECT_ID}.${DATASET}.rm_gemini_25_flash`
REMOTE WITH CONNECTION `${CONNECTION_NAME}`
OPTIONS (
  ENDPOINT = 'gemini-2.5-flash'
);

-- Remote model for text embeddings
CREATE OR REPLACE MODEL `${PROJECT_ID}.${DATASET}.rm_textembedding`
REMOTE WITH CONNECTION `${CONNECTION_NAME}`
OPTIONS (
  ENDPOINT = 'text-embedding-005'
);
