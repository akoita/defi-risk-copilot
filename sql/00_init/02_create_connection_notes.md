Create a BigQuery connection for Vertex AI (one-time):

Option A – Console UI
1) BigQuery > Connections > +Create Connection
2) Type: Cloud resource
3) Location: US
4) Name: vertex_us (for example)
5) Grant the connection’s service account Vertex AI User + BigQuery DataViewer/JobUser as needed.

Option B – CLI
bq mk --location=US --connection --display_name=vertex_us --connection_type=CLOUD_RESOURCE vertex_us

Then give the connection’s service account (auto-created) the IAM roles:
- Vertex AI User on the project
- BigQuery Job User on the project

In SQL below, reference it as `US.vertex_us` (or your chosen name).
