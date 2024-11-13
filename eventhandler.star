
SERVICE_NAME = "aefinder-entityeventhandler"
IMAGE_NAME = "gldeng/aefinder.entityeventhandler:sha-82977ce"
APPSETTINGS_TEMPLATE_FILE = "/static_files/eventhandler/appsettings.json.template"

def run(
    plan,
    redis_url,
    mongodb_url,
    elasticsearch_url,
    rabbitmq_node_names,
):
    rabbitmq_service = plan.get_service(rabbitmq_node_names[0])

    artifact_name = plan.render_templates(
        config = {
            "appsettings.json": struct(
                template=read_file(APPSETTINGS_TEMPLATE_FILE),
                data={
                    "RedisHostPort": redis_url.split("/")[-1],
                    "ElasticsearchUrl": elasticsearch_url,
                    "MongoDbUrl": mongodb_url,
                    "RabbitMqHost": rabbitmq_service.hostname,
                    "RabbitMqPort": rabbitmq_service.ports["amqp"].number,
                },
            ),
        },
    )


    config = ServiceConfig(
        image = IMAGE_NAME,
        files={
            "/app/config": artifact_name,
        },
        entrypoint = [
            "/bin/sh", 
            "-c", 
            "cp /app/config/appsettings.json /app/appsettings.json && cat /app/appsettings.json && dotnet AeFinder.EntityEventHandler.dll"
        ],
    )
    plan.add_service(SERVICE_NAME, config)
