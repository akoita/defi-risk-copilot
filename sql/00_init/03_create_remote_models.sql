-- Remote model for text generation (Gemini)
CREATE OR REPLACE MODEL `${PROJECT_ID}.${DATASET}.rm_gemini_15_flash`
REMOTE WITH CONNECTION `${CONNECTION_NAME}`
OPTIONS (
  ENDPOINT = 'gemini-1.5-flash',
  REMOTE_SERVICE_TYPE = 'CLOUD_AI'
);

-- Remote model for text embeddings
CREATE OR REPLACE MODEL `${PROJECT_ID}.${DATASET}.rm_textembedding`
REMOTE WITH CONNECTION `${CONNECTION_NAME}`
OPTIONS (
  ENDPOINT = 'text-embedding-005',
  REMOTE_SERVICE_TYPE = 'CLOUD_AI'
);
