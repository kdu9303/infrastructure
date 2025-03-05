from minio import Minio

client = Minio(
    "192.168.0.17:9000",
    access_key="qi1YTKEyxSCbBlwQ2NL0", # test keys
    secret_key="R5vd9POHKATStFliYW1j936Vig4NhsurH77rbIwW", # test keys
    secure=False,
)

minio_bucket = "my-first-bucket"
found = client.bucket_exists(minio_bucket)
if not found:
    client.make_bucket(minio_bucket)

# destination_file = 'data.csv'
# source_file = './data/data.csv'  # Ensure this file exists in the project folder
# client.fput_object(minio_bucket, destination_file, source_file)