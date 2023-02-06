.PHONY: all
all: opentelemetry-javaagent.jar cache-client-extension dropwizard

opentelemetry-javaagent.jar:
	# Download OpenTelemetry Java Agent v1.21.0
	curl -o ./opentelemetry-javaagent.jar \
      -L https://github.com/open-telemetry/opentelemetry-java-instrumentation/releases/download/v1.21.0/opentelemetry-javaagent.jar

.PHONY: all
dropwizard: dropwizard/dropwizard-example/target/example.mv.db

dropwizard/dropwizard-example/pom.xml:
	# Clone the repository on version v2.1.1
	git clone git@github.com:dropwizard/dropwizard.git --branch v2.1.1 --single-branch

dropwizard/dropwizard-example/target/dropwizard-example-2.1.1.jar: dropwizard/dropwizard-example/pom.xml
	# Package the application
	cd dropwizard && ./mvnw -Dmaven.test.skip=true package

dropwizard/dropwizard-example/target/example.mv.db: dropwizard/dropwizard-example/target/dropwizard-example-2.1.1.jar
	# Prepare the H2 database
	cd dropwizard/dropwizard-example && java -jar target/dropwizard-example-2.1.1.jar db migrate example.yml

# Let Gradle (rather than Make) handle file system watching to rebuild if needed
.PHONY: cache-client-extension
cache-client-extension:
	cd cache-client-extension && ./gradlew jar

.PHONY: run-without-otel
run-without-otel: dropwizard
	cd dropwizard/dropwizard-example && java -jar target/dropwizard-example-2.1.1.jar server example.yml

.PHONY: run-app
run-app: dropwizard opentelemetry-javaagent.jar
	cd dropwizard/dropwizard-example && java -javaagent:../../opentelemetry-javaagent.jar \
      -Dotel.service.name=dropwizard-example \
      -jar target/dropwizard-example-2.1.1.jar server example.yml

.PHONY: run-app-with-extension
run-app-with-extension: dropwizard opentelemetry-javaagent.jar cache-client-extension
	cd dropwizard/dropwizard-example && java -javaagent:../../opentelemetry-javaagent.jar \
      -Dotel.service.name=dropwizard-example \
      -Dotel.javaagent.extensions=../../cache-client-extension/lib/build/libs/cache-client-extension.jar \
      -jar target/dropwizard-example-2.1.1.jar server example.yml

.PHONY: run-app-with-logs
run-app-with-logs: dropwizard opentelemetry-javaagent.jar
	cd dropwizard/dropwizard-example && java -javaagent:../../opentelemetry-javaagent.jar \
    	-Dotel.service.name=dropwizard-example -Dotel.logs.exporter=otlp \
    	-jar target/dropwizard-example-2.1.1.jar server ../../chapter8.example.yml

.PHONY: run-stack
run-stack:
	docker compose up

.PHONY: run-all
run-all: dropwizard opentelemetry-javaagent.jar
	make -j 2 run-stack run-app

.PHONY: run-all-with-extension
run-all-with-extension: dropwizard opentelemetry-javaagent.jar
	make -j 2 run-stack run-app-with-extension

.PHONY: run-all-with-logs
run-all-with-logs: dropwizard opentelemetry-javaagent.jar
	make -j 2 run-stack run-app-with-logs


.PHONY: clean
clean:
	rm -rf dropwizard
	rm -f opentelemetry-javaagent.jar
	rm -rf cache-client-extension/lib/build
	docker compose rm -f