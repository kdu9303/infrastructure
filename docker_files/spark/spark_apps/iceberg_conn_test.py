from pyspark.sql import SparkSession
from pyspark.sql.types import StructType, StructField, StringType, IntegerType, TimestampType
from datetime import datetime, timedelta


class IcebergSparkSession:
    """
    # 기본 설정으로 사용
    iceberg_session = IcebergSparkSession()
    spark = iceberg_session.get_spark()
    
    # 또는 with 문 사용
    with IcebergSparkSession(app_name="MyApp", s3_endpoint="http://minio2:9000") as spark:
        # 스파크 작업 수행
        df = spark.sql("SELECT 1")
        df.show()
        
    # 또는 사용자 정의 설정으로 사용
    custom_session = IcebergSparkSession(
        app_name="CustomApp",
        warehouse_path="s3a://my-warehouse/",
        s3_endpoint="http://custom-minio:9000",
        s3_access_key="mykey",
        s3_secret_key="mysecret",
        region="us-west-2"
    )
    spark = custom_session.get_spark()
    # 작업 후 종료
    custom_session.stop()
    """
    
    def __init__(self, app_name="IcebergTest", warehouse_path="s3a://warehouse/", 
                s3_endpoint="http://minio1:9000", s3_access_key="admin", 
                s3_secret_key="admin1234", region="us-east-1", install_packages=False
        ):
        self.app_name = app_name
        self.warehouse_path = warehouse_path
        self.s3_endpoint = s3_endpoint
        self.s3_access_key = s3_access_key
        self.s3_secret_key = s3_secret_key
        self.region = region
        self.install_packages = install_packages
        self.spark = self.create_spark_session()
        self.configure_s3()

    def create_spark_session(self, install_packages=False):
        """
        SparkSession을 생성합니다.
        
        Args:
            install_packages (bool): 추가 패키지를 설치할지 여부. 기본값은 True입니다.
                                    False로 설정하면 패키지 설치를 건너뜁니다.
        
        Returns:
            SparkSession: 구성된 SparkSession 객체
        """
        # 기본 SparkSession 빌더 생성
        builder = SparkSession.builder.appName(self.app_name)
        
        # 패키지 설치가 활성화된 경우에만 패키지 설정 추가
        if install_packages:
            packages = [
                "org.apache.hadoop:hadoop-aws:3.3.4",
                'org.apache.iceberg:iceberg-spark-runtime-3.4_2.12:1.8.1',
                'com.amazonaws:aws-java-sdk-bundle:1.12.769'
            ]
            builder = builder.config("spark.jars.packages", ",".join(packages))
        
        # 공통 설정 추가
        builder = builder \
            .config("spark.sql.extensions", "org.apache.iceberg.spark.extensions.IcebergSparkSessionExtensions") \
            .config("spark.sql.catalog.spark_catalog", "org.apache.iceberg.spark.SparkSessionCatalog") \
            .config("spark.sql.catalog.spark_catalog.type", "hive") \
            .config("spark.sql.catalog.local", "org.apache.iceberg.spark.SparkCatalog") \
            .config("spark.sql.catalog.local.type", "hadoop") \
            .config("spark.sql.catalog.local.warehouse", self.warehouse_path) \
            .config("spark.sql.catalog.local.io-impl", "org.apache.iceberg.aws.s3.S3FileIO") \
            .config("spark.sql.defaultCatalog", "local") \
            .config("spark.driver.extraJavaOptions", f"-Daws.region={self.region} -Daws.s3.path.style.access=true") \
            .config("spark.executor.extraJavaOptions", f"-Daws.region={self.region} -Daws.s3.path.style.access=true")
    
        return builder.getOrCreate()
      

    def configure_s3(self):
        # S3 기본 설정
        self.spark.conf.set("spark.hadoop.fs.s3a.access.key", self.s3_access_key)
        self.spark.conf.set("spark.hadoop.fs.s3a.secret.key", self.s3_secret_key)
        self.spark.conf.set("spark.hadoop.fs.s3a.endpoint", self.s3_endpoint)
        self.spark.conf.set("spark.hadoop.fs.s3a.path.style.access", "true")
        self.spark.conf.set("spark.hadoop.fs.s3a.impl", "org.apache.hadoop.fs.s3a.S3AFileSystem")
        self.spark.conf.set("spark.hadoop.fs.s3a.aws.credentials.provider", "org.apache.hadoop.fs.s3a.SimpleAWSCredentialsProvider")
        self.spark.conf.set("spark.hadoop.fs.s3a.region", self.region)
        
        # S3 연결 설정
        self.spark.conf.set("spark.hadoop.fs.s3a.connection.ssl.enabled", "false")
        self.spark.conf.set("spark.hadoop.fs.s3a.impl.disable.cache", "true")
        self.spark.conf.set("spark.hadoop.fs.s3a.debug.detailed.exceptions", "true")
        self.spark.conf.set("spark.hadoop.fs.s3a.bucket.probe", "0")
        self.spark.conf.set("spark.hadoop.fs.s3a.change.detection.mode", "none")
        
        # Iceberg S3 설정
        self.spark.conf.set("spark.sql.catalog.local.s3.region", self.region)
        self.spark.conf.set("spark.sql.catalog.local.s3.access-key-id", self.s3_access_key)
        self.spark.conf.set("spark.sql.catalog.local.s3.secret-access-key", self.s3_secret_key)
        self.spark.conf.set("spark.sql.catalog.local.s3.endpoint", self.s3_endpoint)
        self.spark.conf.set("spark.sql.catalog.local.s3.path-style-access", "true")
        
    def get_spark(self):
        """SparkSession 객체 반환"""
        return self.spark
    
    def stop(self):
        """SparkSession 종료"""
        if self.spark:
            self.spark.stop()
            
    def __enter__(self):
        """컨텍스트 매니저 지원"""
        return self.spark
    
    def __exit__(self, exc_type, exc_val, exc_tb):
        """컨텍스트 매니저 종료 시 SparkSession 종료"""
        self.stop()
        

if __name__ == "__main__":
    """
    --conf "spark.driver.extraJavaOptions=-Daws.region=us-east-1" \
    --conf "spark.executor.extraJavaOptions=-Daws.region=us-east-1" \
    --conf "spark.hadoop.fs.s3a.region=us-east-1" \
    
    """
    
    # Create Spark session with command line arguments
    with IcebergSparkSession(
        app_name="IcebergTest",
        warehouse_path="s3a://warehouse/",
        s3_endpoint="http://minio1:9000",
        s3_access_key="admin",
        s3_secret_key="admin1234",
        region="us-east-1") as spark:
        # Test data generation
        now = datetime.now()
        data = [
            (3, "제품C", 150, now - timedelta(days=3)),
            (4, "제품D", 300, now - timedelta(days=2)),
            (5, "제품E", 250, now - timedelta(days=1)),
            (6, "제품F", 150, now - timedelta(days=3)),
            (7, "제품G", 300, now - timedelta(days=2)),
            (8, "제품H", 250, now - timedelta(days=1))
        ]

        # 스키마 정의
        schema = StructType([
            StructField("id", IntegerType(), False),
            StructField("name", StringType(), False),
            StructField("price", IntegerType(), True),
            StructField("created_at", TimestampType(), True)
        ])

        # 데이터프레임 생성
        test_df = spark.createDataFrame(data, schema)

        # 데이터베이스 생성 테스트
        try:
            # 1. 데이터베이스가 이미 존재하는 경우 제거
            print("기존 데이터베이스가 있으면 제거합니다...")
            spark.sql("DROP DATABASE IF EXISTS local.test_db CASCADE")
            
            # 2. 데이터베이스 생성
            print("데이터베이스 'test_db'를 생성합니다...")
            spark.sql("CREATE DATABASE IF NOT EXISTS local.test_db")
            print("데이터베이스가 성공적으로 생성되었습니다.")
            
            # 3. 데이터베이스 목록 확인
            print("생성된 데이터베이스 목록:")
            spark.sql("SHOW DATABASES").show()
            
            # 4. 현재 데이터베이스 사용
            spark.sql("USE local.test_db")
            print("현재 사용 중인 데이터베이스:", spark.catalog.currentDatabase())
            
        except Exception as e:
            print(f"데이터베이스 생성 중 오류 발생: {str(e)}")
        # 데이터프레임 확인
        print("생성된 데이터프레임:")
        test_df.show()
        
        # Iceberg 테이블 생성 및 제거 테스트
        table_name = "local.test_db.products"
        
        try:
            # 1. 테이블이 이미 존재하는 경우 제거
            print("기존 테이블이 있으면 제거합니다...")
            spark.sql(f"DROP TABLE IF EXISTS {table_name}")
            
            # 2. 테이블 생성
            print(f"Iceberg 테이블 '{table_name}'을 생성합니다...")
            test_df.writeTo(table_name).create()
            print("테이블이 성공적으로 생성되었습니다.")
            
            # 3. 테이블 데이터 확인
            print("테이블 데이터를 확인합니다:")
            result_df = spark.table(table_name)
            result_df.show()
            
            # 4. 테이블 메타데이터 확인
            print("테이블 메타데이터를 확인합니다:")
            spark.sql(f"DESCRIBE TABLE {table_name}").show(truncate=False)
            
            # 5. 테이블에 데이터 추가
            print("테이블에 새 데이터를 추가합니다...")
            new_data = [
                (9, "제품I", 400, now),
                (10, "제품J", 500, now)
            ]
            new_df = spark.createDataFrame(new_data, schema)
            new_df.writeTo(table_name).append()
            
            # 6. 추가된 데이터 확인
            print("추가 후 테이블 데이터:")
            spark.table(table_name).show()
            
            # 7. 테이블 스냅샷 히스토리 확인
            print("테이블 스냅샷 히스토리:")
            spark.sql(f"SELECT * FROM {table_name}.history").show(truncate=False)
            
        except Exception as e:
            print(f"테스트 중 오류 발생: {str(e)}")
        finally:
            # 8. 테이블 제거
            print(f"테스트 완료 후 테이블 '{table_name}'을 제거합니다...")
            spark.sql(f"DROP TABLE IF EXISTS {table_name}")
            print("테이블이 성공적으로 제거되었습니다.")
            
            # 9. 테이블이 제거되었는지 확인
            try:
                spark.table(table_name)
                print("오류: 테이블이 제거되지 않았습니다!")
            except:
                print("확인: 테이블이 성공적으로 제거되었습니다.")
        
