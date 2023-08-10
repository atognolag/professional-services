PROJECT_ID=my-test-gcp-org
PROJECT_NUMBER=999999999999
GITLAB_PROJECT=my-test-gitlab-project
GITLAB_GROUP=test-gitlab-org
BRANCH_FILTER=project_path\:${GITLAB_GROUP}\/${GITLAB_PROJECT}\:ref_type\:branch\:ref\:main
# ^ Must escape weird characters
SA_NAME=gitlab-ci-${GITLAB_PROJECT}-sa
SA_ROLE=roles/bigquery.dataViewer
# ^ Must include token creator privileges!

# More info here: https://docs.gitlab.com/ee/ci/secrets/id_token_authentication.html
# Here: https://cloud.google.com/iam/docs/workload-identity-federation
# https://cloud.google.com/iam/docs/workload-identity-federation-with-other-providers
# https://cloud.google.com/iam/docs/best-practices-for-using-workload-identity-federation

gcloud iam service-accounts create ${SA_NAME} \
    --description="Service account to run gitlab ci jobs from the ${GITLAB_PROJECT} project" \
    --display-name="${SA_NAME}"

gcloud projects add-iam-policy-binding ${PROJECT_ID} \
    --member="serviceAccount:${SA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com" \
    --role="${SA_ROLE}"

gcloud iam workload-identity-pools create gitlab-com \
    --location="global" \
    --description="Gitlab access" \
    --display-name="Gitlab Access"

gcloud iam workload-identity-pools providers create-oidc gitlab-com \
    --workload-identity-pool="gitlab-com" \
   --display-name="My workload pool provider" \
   --description="My workload pool provider description" \
    --issuer-uri="https://gitlab.com" \
    --location="global" \
    --attribute-mapping="google.subject=assertion.sub" \
    --allowed-audiences="https://gitlab.com" \
    --attribute-condition="assertion.ref_protected == 'true'"
    # ^ only allow protected branches

gcloud iam service-accounts add-iam-policy-binding "${SA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com" \
  --role=roles/iam.workloadIdentityUser \
  --member=principal://iam.googleapis.com/projects/${PROJECT_NUMBER}/locations/global/workloadIdentityPools/gitlab-com/subject/${BRANCH_FILTER}