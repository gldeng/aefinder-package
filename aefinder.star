aefinder_silo_module = import_module("/silo.star")
aefinder_dbmigrator_module = import_module("/dbmigrator.star")
aefinder_blockchain_eventhandler_module = import_module("/blockchain_eventhandler.star")
aefinder_eventhandler_module = import_module("/eventhandler.star")
aefinder_authserver_module = import_module("/authserver.star")
aefinder_api_module = import_module("/api.star")
aeindexer_utils_module = import_module("/aeindexer/utils.star")
aeindexer_creator_module = import_module("/aeindexer/creator.star")
aeindexer_apphost_module = import_module("/aeindexer/apphost.star")

def run(
    plan, 
    advertised_ip, 
    mongodb_url, 
    redis_url, 
    elasticsearch_url, 
    kafka_host_port, 
    rabbitmq_node_names, 
    authserver_port=8081
):
    aefinder_dbmigrator_module.run(plan, mongodb_url)

    aefinder_silo_module.run(
        plan,
        advertised_ip,
        redis_url=redis_url, 
        mongodb_url=mongodb_url, 
        elasticsearch_url=elasticsearch_url, 
        kafka_host_port=kafka_host_port, 
        rabbitmq_node_names=rabbitmq_node_names
    )
    aefinder_blockchain_eventhandler_module.run(
        plan,
        redis_url,
        mongodb_url,
        rabbitmq_node_names
    )

    aefinder_eventhandler_module.run(
        plan,
        redis_url=redis_url,
        mongodb_url=mongodb_url,
        elasticsearch_url=elasticsearch_url,
        rabbitmq_node_names=rabbitmq_node_names
    )

    authserver_url = aefinder_authserver_module.run(
        plan,
        mongodb_url=mongodb_url,
        redis_url=redis_url
    )
    api_url = aefinder_api_module.run(
        plan,
        authserver_url=authserver_url,
        redis_url=redis_url,
        mongodb_url=mongodb_url,
        elasticsearch_url=elasticsearch_url,
        rabbitmq_node_names=rabbitmq_node_names
    )

    return {
        "authserver_url": authserver_url,
        "api_url": api_url
    }

def run_apphost(
    plan, 
    authserver_url, 
    api_url, 
    app_id, 
    app_name,
    dll_artifact,
    manifest_artifact,
    aelf_node_url, 
    mongodb_url, 
    elasticsearch_url, 
    kafka_host_port, 
    rabbitmq_node_names, 
    port_number=8800
):

    aeindexer_utils_module.create_org_and_user(plan, authserver_url, api_url)
    # Note: confusing usage of app_id and app_name. To avoid confusion, use app_id that aligns with app_name.
    # See: https://github.com/AeFinderProject/aefinder/blob/c1ff566e2c0ea192842d0451dbe92aa4f47ec895/src/AeFinder.Application/Apps/AppService.cs#L61-L78
    aeindexer_creator_module.run(
        plan, 
        authserver_url=authserver_url, 
        api_url=api_url, 
        app_id=app_id, 
        app_name=app_name, 
        dll_artifact=dll_artifact, 
        manifest_artifact=manifest_artifact
    )

    app_url = aeindexer_apphost_module.run(
        plan, 
        app_id, 
        aelf_node_url, 
        api_url, 
        mongodb_url, 
        elasticsearch_url, 
        kafka_host_port, 
        rabbitmq_node_names
    )

    return {
        "app_url": app_url
    }
