FROM mcr.microsoft.com/mssql/server:2022-latest

USER root

RUN mkdir -p /db-init
COPY schema.sql /db-init/schema.sql
COPY seed.sql   /db-init/seed.sql
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

USER mssql
ENTRYPOINT ["/entrypoint.sh"]
