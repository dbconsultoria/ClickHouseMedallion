@rem
@rem Copyright 2015 the original author or authors.
@rem
@rem Licensed under the Apache License, Version 2.0 (the "License");
@rem you may not use this file except in compliance with the License.
@rem You may obtain a copy of the License at
@rem
@rem      https://www.apache.org/licenses/LICENSE-2.0
@rem
@rem Unless required by applicable law or agreed to in writing, software
@rem distributed under the License is distributed on an "AS IS" BASIS,
@rem WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
@rem See the License for the specific language governing permissions and
@rem limitations under the License.
@rem

@if "%DEBUG%"=="" @echo off
@rem ##########################################################################
@rem
@rem  airbyte-server startup script for Windows
@rem
@rem ##########################################################################

@rem Set local scope for the variables with windows NT shell
if "%OS%"=="Windows_NT" setlocal

set DIRNAME=%~dp0
if "%DIRNAME%"=="" set DIRNAME=.
@rem This is normally unused
set APP_BASE_NAME=%~n0
set APP_HOME=%DIRNAME%..

@rem Resolve any "." and ".." in APP_HOME to make it shorter.
for %%i in ("%APP_HOME%") do set APP_HOME=%%~fi

@rem Add default JVM options here. You can also use JAVA_OPTS and AIRBYTE_SERVER_OPTS to pass JVM options to this script.
set DEFAULT_JVM_OPTS="-XX:+ExitOnOutOfMemoryError" "-XX:MaxRAMPercentage=75.0"

@rem Find java.exe
if defined JAVA_HOME goto findJavaFromJavaHome

set JAVA_EXE=java.exe
%JAVA_EXE% -version >NUL 2>&1
if %ERRORLEVEL% equ 0 goto execute

echo.
echo ERROR: JAVA_HOME is not set and no 'java' command could be found in your PATH.
echo.
echo Please set the JAVA_HOME variable in your environment to match the
echo location of your Java installation.

goto fail

:findJavaFromJavaHome
set JAVA_HOME=%JAVA_HOME:"=%
set JAVA_EXE=%JAVA_HOME%/bin/java.exe

if exist "%JAVA_EXE%" goto execute

echo.
echo ERROR: JAVA_HOME is set to an invalid directory: %JAVA_HOME%
echo.
echo Please set the JAVA_HOME variable in your environment to match the
echo location of your Java installation.

goto fail

:execute
@rem Setup the command line

set CLASSPATH=%APP_HOME%\lib\io.airbyte-airbyte-server-0.50.33.jar;%APP_HOME%\lib\io.airbyte-airbyte-commons-server-0.50.33.jar;%APP_HOME%\lib\io.airbyte-airbyte-commons-converters-0.50.33.jar;%APP_HOME%\lib\io.airbyte-airbyte-commons-with-dependencies-0.50.33.jar;%APP_HOME%\lib\io.airbyte-airbyte-commons-temporal-0.50.33.jar;%APP_HOME%\lib\io.airbyte-airbyte-worker-models-0.50.33.jar;%APP_HOME%\lib\io.airbyte.airbyte-config-init-0.50.33.jar;%APP_HOME%\lib\io.airbyte.airbyte-persistence-job-persistence-0.50.33.jar;%APP_HOME%\lib\io.airbyte-airbyte-notification-0.50.33.jar;%APP_HOME%\lib\io.airbyte-airbyte-api-0.50.33.jar;%APP_HOME%\lib\io.airbyte-airbyte-commons-auth-0.50.33.jar;%APP_HOME%\lib\io.airbyte-airbyte-commons-license-0.50.33.jar;%APP_HOME%\lib\io.airbyte-airbyte-commons-micronaut-0.50.33.jar;%APP_HOME%\lib\micronaut-jaxrs-server-3.4.0.jar;%APP_HOME%\lib\micronaut-data-jdbc-3.10.0.jar;%APP_HOME%\lib\micronaut-data-runtime-3.10.0.jar;%APP_HOME%\lib\micronaut-data-model-3.10.0.jar;%APP_HOME%\lib\micronaut-security-3.11.1.jar;%APP_HOME%\lib\io.airbyte-airbyte-analytics-0.50.33.jar;%APP_HOME%\lib\io.airbyte-airbyte-oauth-0.50.33.jar;%APP_HOME%\lib\io.airbyte.airbyte-config-config-persistence-0.50.33.jar;%APP_HOME%\lib\io.airbyte-airbyte-data-0.50.33.jar;%APP_HOME%\lib\io.airbyte-airbyte-featureflag-0.50.33.jar;%APP_HOME%\lib\micronaut-data-tx-3.10.0.jar;%APP_HOME%\lib\micronaut-security-annotations-3.11.1.jar;%APP_HOME%\lib\io.airbyte.airbyte-config-specs-0.50.33.jar;%APP_HOME%\lib\micronaut-cache-caffeine-3.5.0.jar;%APP_HOME%\lib\micronaut-flyway-5.5.0.jar;%APP_HOME%\lib\micronaut-jdbc-hikari-4.8.1.jar;%APP_HOME%\lib\micronaut-jooq-4.8.1.jar;%APP_HOME%\lib\micronaut-jdbc-4.8.1.jar;%APP_HOME%\lib\micronaut-cache-core-3.5.0.jar;%APP_HOME%\lib\micronaut-http-server-netty-3.10.1.jar;%APP_HOME%\lib\micronaut-http-client-3.10.1.jar;%APP_HOME%\lib\micronaut-validation-3.10.1.jar;%APP_HOME%\lib\micronaut-management-3.10.1.jar;%APP_HOME%\lib\micronaut-http-server-3.10.1.jar;%APP_HOME%\lib\micronaut-http-netty-3.10.1.jar;%APP_HOME%\lib\micronaut-websocket-3.10.1.jar;%APP_HOME%\lib\micronaut-http-client-core-3.10.1.jar;%APP_HOME%\lib\micronaut-runtime-3.10.1.jar;%APP_HOME%\lib\micronaut-router-3.10.1.jar;%APP_HOME%\lib\micronaut-jackson-databind-3.10.1.jar;%APP_HOME%\lib\micronaut-jackson-core-3.10.1.jar;%APP_HOME%\lib\micronaut-json-core-3.10.1.jar;%APP_HOME%\lib\micronaut-http-3.10.1.jar;%APP_HOME%\lib\reactor-core-3.5.5.jar;%APP_HOME%\lib\micronaut-context-3.10.1.jar;%APP_HOME%\lib\io.airbyte-airbyte-commons-protocol-0.50.33.jar;%APP_HOME%\lib\io.airbyte.airbyte-metrics-metrics-lib-0.50.33.jar;%APP_HOME%\lib\io.airbyte.airbyte-db-jooq-0.50.33.jar;%APP_HOME%\lib\io.airbyte.airbyte-db-db-lib-0.50.33.jar;%APP_HOME%\lib\io.airbyte.airbyte-config-config-models-0.50.33.jar;%APP_HOME%\lib\micronaut-inject-java-3.10.1.jar;%APP_HOME%\lib\micronaut-aop-3.10.1.jar;%APP_HOME%\lib\micronaut-buffer-netty-3.10.1.jar;%APP_HOME%\lib\micronaut-inject-3.10.1.jar;%APP_HOME%\lib\jakarta.annotation-api-2.1.1.jar;%APP_HOME%\lib\javax.transaction-api-1.3.jar;%APP_HOME%\lib\jakarta.persistence-api-3.1.0.jar;%APP_HOME%\lib\flyway-core-7.14.0.jar;%APP_HOME%\lib\s3-2.16.84.jar;%APP_HOME%\lib\sts-2.20.162.jar;%APP_HOME%\lib\aws-java-sdk-s3-1.12.6.jar;%APP_HOME%\lib\aws-java-sdk-sts-1.12.6.jar;%APP_HOME%\lib\io.airbyte-airbyte-json-validation-0.50.33.jar;%APP_HOME%\lib\io.airbyte-airbyte-commons-0.50.33.jar;%APP_HOME%\lib\protocol-models-0.4.2.jar;%APP_HOME%\lib\slugify-2.4.jar;%APP_HOME%\lib\temporal-sdk-1.17.0.jar;%APP_HOME%\lib\dd-trace-ot-1.14.0.jar;%APP_HOME%\lib\dd-trace-api-1.14.0.jar;%APP_HOME%\lib\sentry-6.14.0.jar;%APP_HOME%\lib\swagger-annotations-1.6.2.jar;%APP_HOME%\lib\google-cloud-storage-2.17.2.jar;%APP_HOME%\lib\jaxb-api-2.4.0-b180830.0359.jar;%APP_HOME%\lib\micronaut-core-reactive-3.10.1.jar;%APP_HOME%\lib\aws-xml-protocol-2.20.107.jar;%APP_HOME%\lib\aws-query-protocol-2.20.162.jar;%APP_HOME%\lib\protocol-core-2.20.162.jar;%APP_HOME%\lib\aws-core-2.20.162.jar;%APP_HOME%\lib\auth-2.20.162.jar;%APP_HOME%\lib\regions-2.20.162.jar;%APP_HOME%\lib\sdk-core-2.20.162.jar;%APP_HOME%\lib\apache-client-2.20.162.jar;%APP_HOME%\lib\netty-nio-client-2.20.162.jar;%APP_HOME%\lib\http-client-spi-2.20.162.jar;%APP_HOME%\lib\profiles-2.20.162.jar;%APP_HOME%\lib\metrics-spi-2.20.162.jar;%APP_HOME%\lib\json-utils-2.20.162.jar;%APP_HOME%\lib\arns-2.20.107.jar;%APP_HOME%\lib\utils-2.20.162.jar;%APP_HOME%\lib\jooq-codegen-3.17.8.jar;%APP_HOME%\lib\jooq-meta-3.17.8.jar;%APP_HOME%\lib\jooq-3.17.8.jar;%APP_HOME%\lib\r2dbc-spi-1.0.0.RELEASE.jar;%APP_HOME%\lib\reactive-streams-1.0.4.jar;%APP_HOME%\lib\appender-log4j2-3.6.0.jar;%APP_HOME%\lib\appender-core-3.6.0.jar;%APP_HOME%\lib\elasticsearch-rest-high-level-client-7.17.9.jar;%APP_HOME%\lib\elasticsearch-7.17.9.jar;%APP_HOME%\lib\elasticsearch-x-content-7.17.9.jar;%APP_HOME%\lib\jackson-dataformat-yaml-2.15.2.jar;%APP_HOME%\lib\jackson-datatype-jsr310-2.15.2.jar;%APP_HOME%\lib\jackson-databind-nullable-0.2.5.jar;%APP_HOME%\lib\json-schema-validator-1.0.72.jar;%APP_HOME%\lib\jackson-json-reference-core-0.3.2.jar;%APP_HOME%\lib\jackson-module-kotlin-2.15.2.jar;%APP_HOME%\lib\jackson-datatype-jdk8-2.15.2.jar;%APP_HOME%\lib\aws-secretsmanager-caching-java-1.0.2.jar;%APP_HOME%\lib\aws-java-sdk-secretsmanager-1.12.510.jar;%APP_HOME%\lib\aws-java-sdk-kms-1.12.510.jar;%APP_HOME%\lib\aws-java-sdk-core-1.12.510.jar;%APP_HOME%\lib\jackson-dataformat-cbor-2.15.2.jar;%APP_HOME%\lib\jmespath-java-1.12.510.jar;%APP_HOME%\lib\jackson-databind-2.15.2.jar;%APP_HOME%\lib\postgresql-1.17.6.jar;%APP_HOME%\lib\jdbc-1.17.6.jar;%APP_HOME%\lib\database-commons-1.17.6.jar;%APP_HOME%\lib\testcontainers-1.17.6.jar;%APP_HOME%\lib\docker-java-api-3.2.13.jar;%APP_HOME%\lib\jackson-annotations-2.15.2.jar;%APP_HOME%\lib\jackson-core-2.15.2.jar;%APP_HOME%\lib\spotbugs-annotations-4.7.3.jar;%APP_HOME%\lib\temporal-serviceclient-1.17.0.jar;%APP_HOME%\lib\google-cloud-secretmanager-2.18.0.jar;%APP_HOME%\lib\proto-google-cloud-secretmanager-v1-2.18.0.jar;%APP_HOME%\lib\proto-google-cloud-secretmanager-v1beta1-2.18.0.jar;%APP_HOME%\lib\javax.annotation-api-1.3.2.jar;%APP_HOME%\lib\jna-platform-5.8.0.jar;%APP_HOME%\lib\docker-java-transport-zerodep-3.2.13.jar;%APP_HOME%\lib\jna-5.12.1.jar;%APP_HOME%\lib\google-api-client-2.2.0.jar;%APP_HOME%\lib\google-oauth-client-1.34.1.jar;%APP_HOME%\lib\grpc-services-1.55.1.jar;%APP_HOME%\lib\grpc-stub-1.55.1.jar;%APP_HOME%\lib\grpc-netty-shaded-1.55.1.jar;%APP_HOME%\lib\grpc-core-1.55.1.jar;%APP_HOME%\lib\grpc-protobuf-1.55.1.jar;%APP_HOME%\lib\grpc-protobuf-lite-1.55.1.jar;%APP_HOME%\lib\grpc-api-1.55.1.jar;%APP_HOME%\lib\google-http-client-apache-v2-1.42.3.jar;%APP_HOME%\lib\google-http-client-gson-1.43.1.jar;%APP_HOME%\lib\google-http-client-1.43.1.jar;%APP_HOME%\lib\protobuf-java-util-3.23.1.jar;%APP_HOME%\lib\opencensus-contrib-http-util-0.31.1.jar;%APP_HOME%\lib\guava-31.1-jre.jar;%APP_HOME%\lib\tally-core-0.11.1.jar;%APP_HOME%\lib\jsr305-3.0.2.jar;%APP_HOME%\lib\micrometer-core-1.10.5.jar;%APP_HOME%\lib\netty-handler-proxy-4.1.94.Final.jar;%APP_HOME%\lib\netty-codec-http2-4.1.94.Final.jar;%APP_HOME%\lib\netty-codec-http-4.1.94.Final.jar;%APP_HOME%\lib\netty-handler-4.1.94.Final.jar;%APP_HOME%\lib\netty-codec-socks-4.1.94.Final.jar;%APP_HOME%\lib\netty-codec-4.1.94.Final.jar;%APP_HOME%\lib\micrometer-registry-statsd-1.10.5.jar;%APP_HOME%\lib\netty-transport-native-epoll-4.1.94.Final-linux-aarch_64.jar;%APP_HOME%\lib\netty-transport-native-epoll-4.1.94.Final-linux-x86_64.jar;%APP_HOME%\lib\netty-transport-classes-epoll-4.1.94.Final.jar;%APP_HOME%\lib\netty-transport-native-unix-common-4.1.94.Final.jar;%APP_HOME%\lib\netty-transport-4.1.94.Final.jar;%APP_HOME%\lib\netty-buffer-4.1.94.Final.jar;%APP_HOME%\lib\micronaut-core-3.10.1.jar;%APP_HOME%\lib\json-path-2.7.0.jar;%APP_HOME%\lib\quartz-2.3.2.jar;%APP_HOME%\lib\jul-to-slf4j-1.7.36.jar;%APP_HOME%\lib\jcl-over-slf4j-1.7.36.jar;%APP_HOME%\lib\log4j-over-slf4j-1.7.36.jar;%APP_HOME%\lib\HikariCP-java7-2.4.13.jar;%APP_HOME%\lib\HikariCP-5.0.1.jar;%APP_HOME%\lib\log4j-slf4j-impl-2.19.0.jar;%APP_HOME%\lib\slf4j-api-1.7.36.jar;%APP_HOME%\lib\snakeyaml-2.0.jar;%APP_HOME%\lib\validation-api-2.0.1.Final.jar;%APP_HOME%\lib\jakarta.inject-api-2.0.1.jar;%APP_HOME%\lib\jaxrs-api-3.0.12.Final.jar;%APP_HOME%\lib\endpoints-spi-2.20.162.jar;%APP_HOME%\lib\annotations-2.20.162.jar;%APP_HOME%\lib\analytics-2.1.1.jar;%APP_HOME%\lib\moshi-kotlin-1.15.0.jar;%APP_HOME%\lib\moshi-1.15.0.jar;%APP_HOME%\lib\failsafe-okhttp-3.3.2.jar;%APP_HOME%\lib\analytics-core-2.1.1.jar;%APP_HOME%\lib\retrofit1-okhttp3-client-1.1.0.jar;%APP_HOME%\lib\opentelemetry-exporter-otlp-1.19.0.jar;%APP_HOME%\lib\opentelemetry-exporter-otlp-common-1.19.0.jar;%APP_HOME%\lib\okhttp-4.10.0.jar;%APP_HOME%\lib\okio-jvm-3.0.0.jar;%APP_HOME%\lib\kotlin-stdlib-jdk8-1.9.10.jar;%APP_HOME%\lib\commons-io-2.11.0.jar;%APP_HOME%\lib\javax.ws.rs-api-2.1.1.jar;%APP_HOME%\lib\commons-compress-1.22.jar;%APP_HOME%\lib\commons-text-1.10.0.jar;%APP_HOME%\lib\commons-lang3-3.12.0.jar;%APP_HOME%\lib\log4j-web-2.19.0.jar;%APP_HOME%\lib\log4j-core-2.19.0.jar;%APP_HOME%\lib\log4j-api-2.19.0.jar;%APP_HOME%\lib\failsafe-3.3.2.jar;%APP_HOME%\lib\commons-cli-1.4.jar;%APP_HOME%\lib\vault-java-driver-5.1.0.jar;%APP_HOME%\lib\launchdarkly-java-server-sdk-6.0.1.jar;%APP_HOME%\lib\opentelemetry-sdk-metrics-testing-1.13.0-alpha.jar;%APP_HOME%\lib\opentelemetry-sdk-testing-1.19.0.jar;%APP_HOME%\lib\opentelemetry-sdk-1.19.0.jar;%APP_HOME%\lib\opentelemetry-sdk-metrics-1.19.0.jar;%APP_HOME%\lib\opentelemetry-sdk-trace-1.19.0.jar;%APP_HOME%\lib\opentelemetry-sdk-logs-1.19.0-alpha.jar;%APP_HOME%\lib\opentelemetry-sdk-common-1.19.0.jar;%APP_HOME%\lib\opentelemetry-semconv-1.19.0-alpha.jar;%APP_HOME%\lib\opentelemetry-exporter-common-1.19.0.jar;%APP_HOME%\lib\opentelemetry-api-logs-1.19.0-alpha.jar;%APP_HOME%\lib\opentelemetry-api-1.19.0.jar;%APP_HOME%\lib\java-dogstatsd-client-4.1.0.jar;%APP_HOME%\lib\postgresql-42.5.4.jar;%APP_HOME%\lib\elasticsearch-rest-client-7.17.9.jar;%APP_HOME%\lib\httpclient-4.5.14.jar;%APP_HOME%\lib\commonmark-0.21.0.jar;%APP_HOME%\lib\commons-collections4-4.4.jar;%APP_HOME%\lib\icu4j-64.2.jar;%APP_HOME%\lib\retrofit-1.9.0.jar;%APP_HOME%\lib\gson-2.10.1.jar;%APP_HOME%\lib\opentracing-util-0.32.0.jar;%APP_HOME%\lib\opentracing-noop-0.32.0.jar;%APP_HOME%\lib\opentracing-tracerresolver-0.1.0.jar;%APP_HOME%\lib\opentracing-api-0.32.0.jar;%APP_HOME%\lib\failureaccess-1.0.1.jar;%APP_HOME%\lib\listenablefuture-9999.0-empty-to-avoid-conflict-with-guava.jar;%APP_HOME%\lib\caffeine-2.9.3.jar;%APP_HOME%\lib\error_prone_annotations-2.18.0.jar;%APP_HOME%\lib\j2objc-annotations-1.3.jar;%APP_HOME%\lib\google-http-client-jackson2-1.42.3.jar;%APP_HOME%\lib\commons-codec-1.15.jar;%APP_HOME%\lib\google-api-services-storage-v1-rev20220705-2.0.0.jar;%APP_HOME%\lib\google-cloud-core-2.18.1.jar;%APP_HOME%\lib\auto-value-annotations-1.10.1.jar;%APP_HOME%\lib\google-cloud-core-http-2.9.4.jar;%APP_HOME%\lib\google-http-client-appengine-1.42.3.jar;%APP_HOME%\lib\gax-httpjson-0.113.1.jar;%APP_HOME%\lib\google-cloud-core-grpc-2.9.4.jar;%APP_HOME%\lib\gax-2.28.1.jar;%APP_HOME%\lib\gax-grpc-2.28.1.jar;%APP_HOME%\lib\grpc-alts-1.55.1.jar;%APP_HOME%\lib\grpc-grpclb-1.55.1.jar;%APP_HOME%\lib\conscrypt-openjdk-uber-2.5.2.jar;%APP_HOME%\lib\grpc-auth-1.55.1.jar;%APP_HOME%\lib\google-auth-library-credentials-1.16.0.jar;%APP_HOME%\lib\google-auth-library-oauth2-http-1.17.0.jar;%APP_HOME%\lib\api-common-2.11.1.jar;%APP_HOME%\lib\auto-value-1.10.1.jar;%APP_HOME%\lib\opencensus-api-0.31.1.jar;%APP_HOME%\lib\grpc-context-1.55.1.jar;%APP_HOME%\lib\proto-google-iam-v1-1.14.1.jar;%APP_HOME%\lib\proto-google-common-protos-2.19.1.jar;%APP_HOME%\lib\protobuf-java-3.23.1.jar;%APP_HOME%\lib\threetenbp-1.6.8.jar;%APP_HOME%\lib\proto-google-cloud-storage-v2-2.17.2-alpha.jar;%APP_HOME%\lib\grpc-google-cloud-storage-v2-2.17.2-alpha.jar;%APP_HOME%\lib\gapic-google-cloud-storage-v2-2.17.2-alpha.jar;%APP_HOME%\lib\perfmark-api-0.26.0.jar;%APP_HOME%\lib\annotations-4.1.1.4.jar;%APP_HOME%\lib\animal-sniffer-annotations-1.23.jar;%APP_HOME%\lib\grpc-googleapis-1.55.1.jar;%APP_HOME%\lib\checker-qual-3.32.0.jar;%APP_HOME%\lib\grpc-xds-1.55.1.jar;%APP_HOME%\lib\opencensus-proto-0.2.0.jar;%APP_HOME%\lib\re2j-1.6.jar;%APP_HOME%\lib\javax.activation-api-1.2.0.jar;%APP_HOME%\lib\jackson-dataformat-smile-2.15.2.jar;%APP_HOME%\lib\kotlin-stdlib-jdk7-1.9.10.jar;%APP_HOME%\lib\kotlin-reflect-1.8.21.jar;%APP_HOME%\lib\kotlin-stdlib-1.9.10.jar;%APP_HOME%\lib\kotlin-stdlib-common-1.9.10.jar;%APP_HOME%\lib\micrometer-observation-1.10.5.jar;%APP_HOME%\lib\micrometer-commons-1.10.5.jar;%APP_HOME%\lib\netty-resolver-4.1.94.Final.jar;%APP_HOME%\lib\netty-common-4.1.94.Final.jar;%APP_HOME%\lib\eventstream-1.0.1.jar;%APP_HOME%\lib\httpcore-4.4.16.jar;%APP_HOME%\lib\third-party-jackson-core-2.20.162.jar;%APP_HOME%\lib\commons-logging-1.2.jar;%APP_HOME%\lib\ion-java-1.0.2.jar;%APP_HOME%\lib\joda-time-2.10.10.jar;%APP_HOME%\lib\backo-1.0.0.jar;%APP_HOME%\lib\json-smart-2.4.7.jar;%APP_HOME%\lib\c3p0-0.9.5.4.jar;%APP_HOME%\lib\mchange-commons-java-0.2.15.jar;%APP_HOME%\lib\opentelemetry-context-1.19.0.jar;%APP_HOME%\lib\jnr-unixsocket-0.36.jar;%APP_HOME%\lib\jakarta.xml.bind-api-3.0.0.jar;%APP_HOME%\lib\itu-1.7.0.jar;%APP_HOME%\lib\duct-tape-1.0.8.jar;%APP_HOME%\lib\annotations-17.0.0.jar;%APP_HOME%\lib\accessors-smart-2.4.7.jar;%APP_HOME%\lib\jnr-enxio-0.30.jar;%APP_HOME%\lib\jnr-posix-3.0.61.jar;%APP_HOME%\lib\jnr-ffi-2.1.16.jar;%APP_HOME%\lib\jnr-constants-0.9.17.jar;%APP_HOME%\lib\jakarta.activation-2.0.0.jar;%APP_HOME%\lib\asm-commons-7.1.jar;%APP_HOME%\lib\asm-util-7.1.jar;%APP_HOME%\lib\asm-analysis-7.1.jar;%APP_HOME%\lib\asm-tree-7.1.jar;%APP_HOME%\lib\asm-9.1.jar;%APP_HOME%\lib\jffi-1.2.23.jar;%APP_HOME%\lib\jffi-1.2.23-native.jar;%APP_HOME%\lib\jnr-a64asm-1.0.0.jar;%APP_HOME%\lib\jnr-x86asm-1.0.2.jar;%APP_HOME%\lib\junit-4.13.2.jar;%APP_HOME%\lib\HdrHistogram-2.1.12.jar;%APP_HOME%\lib\LatencyUtils-2.0.3.jar;%APP_HOME%\lib\hamcrest-core-1.3.jar;%APP_HOME%\lib\docker-java-transport-3.2.13.jar;%APP_HOME%\lib\mapper-extras-client-7.17.9.jar;%APP_HOME%\lib\parent-join-client-7.17.9.jar;%APP_HOME%\lib\aggs-matrix-stats-client-7.17.9.jar;%APP_HOME%\lib\rank-eval-client-7.17.9.jar;%APP_HOME%\lib\lang-mustache-client-7.17.9.jar;%APP_HOME%\lib\elasticsearch-lz4-7.17.9.jar;%APP_HOME%\lib\elasticsearch-cli-7.17.9.jar;%APP_HOME%\lib\elasticsearch-core-7.17.9.jar;%APP_HOME%\lib\elasticsearch-secure-sm-7.17.9.jar;%APP_HOME%\lib\elasticsearch-geo-7.17.9.jar;%APP_HOME%\lib\lucene-core-8.11.1.jar;%APP_HOME%\lib\lucene-analyzers-common-8.11.1.jar;%APP_HOME%\lib\lucene-backward-codecs-8.11.1.jar;%APP_HOME%\lib\lucene-grouping-8.11.1.jar;%APP_HOME%\lib\lucene-highlighter-8.11.1.jar;%APP_HOME%\lib\lucene-join-8.11.1.jar;%APP_HOME%\lib\lucene-memory-8.11.1.jar;%APP_HOME%\lib\lucene-misc-8.11.1.jar;%APP_HOME%\lib\lucene-queries-8.11.1.jar;%APP_HOME%\lib\lucene-queryparser-8.11.1.jar;%APP_HOME%\lib\lucene-sandbox-8.11.1.jar;%APP_HOME%\lib\lucene-spatial3d-8.11.1.jar;%APP_HOME%\lib\lucene-suggest-8.11.1.jar;%APP_HOME%\lib\hppc-0.8.1.jar;%APP_HOME%\lib\t-digest-3.2.jar;%APP_HOME%\lib\elasticsearch-plugin-classloader-7.17.9.jar;%APP_HOME%\lib\httpasyncclient-4.1.4.jar;%APP_HOME%\lib\httpcore-nio-4.4.12.jar;%APP_HOME%\lib\compiler-0.9.6.jar;%APP_HOME%\lib\lz4-java-1.8.0.jar;%APP_HOME%\lib\jopt-simple-5.0.2.jar


@rem Execute airbyte-server
"%JAVA_EXE%" %DEFAULT_JVM_OPTS% %JAVA_OPTS% %AIRBYTE_SERVER_OPTS%  -classpath "%CLASSPATH%" io.airbyte.server.Application %*

:end
@rem End local scope for the variables with windows NT shell
if %ERRORLEVEL% equ 0 goto mainEnd

:fail
rem Set variable AIRBYTE_SERVER_EXIT_CONSOLE if you need the _script_ return code instead of
rem the _cmd.exe /c_ return code!
set EXIT_CODE=%ERRORLEVEL%
if %EXIT_CODE% equ 0 set EXIT_CODE=1
if not ""=="%AIRBYTE_SERVER_EXIT_CONSOLE%" exit %EXIT_CODE%
exit /b %EXIT_CODE%

:mainEnd
if "%OS%"=="Windows_NT" endlocal

:omega
