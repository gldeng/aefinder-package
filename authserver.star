SERVICE_NAME = "aefinder-authserver"
IMAGE_NAME = "gldeng/aefinder.authserver:sha-82977ce"
APPSETTINGS_TEMPLATE_FILE = "/static_files/authserver/appsettings.json.template"

def run(plan, mongodb_url, redis_url, authserver_port=8081):

    artifact_name = plan.render_templates(
        config = {
            "appsettings.json": struct(
                template=read_file(APPSETTINGS_TEMPLATE_FILE),
                data={
                    "RedisHostPort": redis_url.split("/")[-1],
                    "MongoDbUrl": mongodb_url,
                    "Host": SERVICE_NAME,
                    "Port": authserver_port,
                },
            ),
        },
    )


    config = ServiceConfig(
        image = IMAGE_NAME,
        ports={
            "http": PortSpec(number=authserver_port),
        },
        files={
            "/app/config": artifact_name,
        },
        entrypoint = [
            "/bin/sh", 
            "-c", 
            "cp /app/config/appsettings.json /app/appsettings.json && cat /app/appsettings.json && dotnet AeFinder.AuthServer.dll"
        ],
    )
    plan.add_service(SERVICE_NAME, config)
    return "http://{host}:{port}".format(host=SERVICE_NAME, port=authserver_port)