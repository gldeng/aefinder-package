
SERVICE_NAME = "aefinder-api"
IMAGE_NAME = "gldeng/aefinder.httpapi.host:sha-82977ce"
STATIC_FILES_DIR = "/static_files/api"
APPSETTINGS_TEMPLATE_FILE = "{STATIC_FILES_DIR}/appsettings.json.template".format(STATIC_FILES_DIR=STATIC_FILES_DIR)

def run(
    plan, 
    authserver_url, 
    redis_url,
    mongodb_url,
    elasticsearch_url,
    rabbitmq_node_names,
    api_port=8080
):
    rabbitmq_service = plan.get_service(rabbitmq_node_names[0])

    artifact_name = plan.render_templates(
        config = {
            "appsettings.json": struct(
                template=read_file(APPSETTINGS_TEMPLATE_FILE),
                data={
                    "AuthServerUrl": authserver_url,
                    "RedisHostPort": redis_url.split("/")[-1],
                    "MongoDbUrl": mongodb_url,
                    "ElasticsearchUrl": elasticsearch_url,
                    "RabbitMqHost": rabbitmq_service.hostname,
                    "RabbitMqPort": rabbitmq_service.ports["amqp"].number,
                    "Host": SERVICE_NAME,
                    "Port": api_port,
                },
            ),
            "kubeconfig.yml": struct(
                template=read_file(STATIC_FILES_DIR+"/kubeconfig.yml"),
                data={},
            ), 
        },
    )
    dll_artifact_name = plan.upload_files(STATIC_FILES_DIR+"/AeFinder.Application.dll")
    plan.add_service(SERVICE_NAME, ServiceConfig(
        image=IMAGE_NAME,
        ports={
            "http": PortSpec(number=api_port),
        },
        files={
            "/app/config": artifact_name,
            "/app/dll_overwrite": dll_artifact_name,
        },
        entrypoint = [
            "/bin/sh", 
            "-c", 
            "cp /app/config/* /app/ && cat /app/appsettings.json && mkdir -p /app/KubeConfig && cp /app/kubeconfig.yml /app/KubeConfig/config.txt && cp /app/dll_overwrite/AeFinder.Application.dll /app/ && dotnet AeFinder.HttpApi.Host.dll"
        ],
    ))
    return "http://{host}:{port}".format(host=SERVICE_NAME, port=api_port)