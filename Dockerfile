FROM mcr.microsoft.com/dotnet/aspnet:5.0-focal AS base
WORKDIR /app
EXPOSE 3000

ENV ASPNETCORE_URLS=http://+:3000
ENV skip_client_build true

# Creates a non-root user with an explicit UID and adds permission to access the /app folder
# For more info, please refer to https://aka.ms/vscode-docker-dotnet-configure-containers
RUN adduser -u 5678 --disabled-password --gecos "" appuser && chown -R appuser /app
USER appuser

FROM mcr.microsoft.com/dotnet/sdk:5.0 AS server-build
WORKDIR /src
COPY ["bmonsterman.security.web.csproj", "./"]
RUN dotnet restore "bmonsterman.security.web.csproj"
COPY . .
WORKDIR "/src/."
RUN dotnet build "bmonsterman.security.web.csproj" -c Release -o /app/build

FROM server-build AS server-publish
RUN dotnet publish "bmonsterman.security.web.csproj" -c Release -o /app/publish

FROM node:16-alpine as client-build
WORKDIR /ClientApp
COPY ./ClientApp/package.json .
COPY ./ClientApp/package-lock.json .
RUN npm install
COPY ./ClientApp/ . 
RUN npm run build  

FROM base AS final
WORKDIR /app
RUN mkdir /app/ClientApp
RUN mkdir /app/ClientApp/build
COPY --from=server-publish /app/publish .
COPY --from=client-build /ClientApp/build ./ClientApp/build
ENTRYPOINT [ "dotnet","bmonsterman.security.web.dll" ]
