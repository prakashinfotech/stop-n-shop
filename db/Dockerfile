# Database image. BUILD CONTEXT = REPO ROOT (see docker-compose*.yml / deploy-main.yml).
#
# ShopNStopDB/ is the single source of truth for the schema. This image compiles it into a
# DACPAC and the entrypoint publishes it on EVERY start, so a rebuild + `up -d` brings any
# database (fresh or existing) up to date. Nothing to run by hand.

# ---- stage 1: build the DACPAC and fetch sqlpackage -------------------------------------
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS dacpac
WORKDIR /src
RUN apt-get update \
 && apt-get install -y --no-install-recommends unzip curl ca-certificates \
 && rm -rf /var/lib/apt/lists/*
RUN curl -fsSL https://aka.ms/sqlpackage-linux -o /tmp/sqlpackage.zip \
 && mkdir /sqlpackage && unzip -q /tmp/sqlpackage.zip -d /sqlpackage
COPY ShopNStopDB/ ./ShopNStopDB/
RUN dotnet build ShopNStopDB/ShopNStopDB.sqlproj -c Release -o /out \
 && ls -l /out/ShopNStopDB.dacpac

# ---- stage 2: SQL Server + dacpac + sqlpackage ------------------------------------------
FROM mcr.microsoft.com/mssql/server:2022-latest
USER root
ENV DOTNET_SYSTEM_GLOBALIZATION_INVARIANT=1
RUN mkdir -p /db-init
COPY --from=dacpac /out/ShopNStopDB.dacpac /db-init/ShopNStopDB.dacpac
COPY --from=dacpac /sqlpackage /opt/sqlpackage
COPY db/seed.sql /db-init/seed.sql
COPY db/entrypoint.sh /entrypoint.sh
RUN chmod +x /opt/sqlpackage/sqlpackage /entrypoint.sh
USER mssql
ENTRYPOINT ["/entrypoint.sh"]
