-- Create a vector index for nearest-neighbor queries (cosine)
CREATE VECTOR INDEX `${PROJECT_ID}.${DATASET}.vx_contract_embedding`
ON `${PROJECT_ID}.${DATASET}.contract_embedding`(embed)
OPTIONS (distance_type = 'COSINE');
