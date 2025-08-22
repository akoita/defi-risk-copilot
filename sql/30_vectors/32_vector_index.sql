-- Create a vector index for nearest-neighbor queries (cosine)
CREATE VECTOR INDEX `${PROJECT_ID}.${DATASET}.vx_contract_embedding`
ON `${PROJECT_ID}.${DATASET}.contract_embedding`(embed)
OPTIONS (
  index_type = 'IVF',
  distance_type = 'COSINE'
);
