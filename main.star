aelf_infra_module = import_module("github.com/gldeng/aelf-infra-package/main.star")
aelf_node_module = import_module("github.com/gldeng/aelf-node-package/aelf_node.star")
aefinder_module = import_module("/aefinder.star")

def run(plan, advertised_ip):
    output = {}
    aelf_infra_output = aelf_infra_module.run(
        plan,
        need_mongodb=True,
        need_redis=True,
        need_rabbitmq=True,
        need_elasticsearch=True,
        need_kafka=True
        )
    output |= aelf_infra_output
    aelf_node_output = aelf_node_module.run(
        plan,
        with_aefinder_feeder=True,
        redis_url=aelf_infra_output["redis_url"],
        rabbitmq_node_hostname=aelf_infra_output["rabbitmq_node_hostname"],
        rabbitmq_node_port=aelf_infra_output["rabbitmq_node_port"]
    )
    output |= aelf_node_output

    aefinder_output = aefinder_module.run(
        plan,
        advertised_ip,
        mongodb_url=aelf_infra_output["mongodb_url"],
        redis_url=aelf_infra_output["redis_url"],
        elasticsearch_url=aelf_infra_output["elasticsearch_url"],
        kafka_host_port=aelf_infra_output["kafka_host_port"],
        rabbitmq_node_names=aelf_infra_output["rabbitmq_node_names"]
    )
    output |= aefinder_output


    dll_artifact = plan.upload_files(
        src = "/static_files/aeindexer/sample/TomorrowDAOIndexer.dll",
        name = "sample-indexer-dll",
    )
    manifest_artifact = plan.upload_files(
        src = "/static_files/aeindexer/sample/manifest.json",
        name = "sample-indexer-manifest",
    )

    aefinder_apphost_output = aefinder_module.run_apphost(
        plan,
        authserver_url=output["authserver_url"],
        api_url=output["api_url"],
        app_id="tomorrowdao_indexer",
        app_name='"TomorrowDAO Indexer"',
        dll_artifact=dll_artifact,
        manifest_artifact=manifest_artifact,
        aelf_node_url=output["aelf_node_url"],
        mongodb_url=output["mongodb_url"],
        elasticsearch_url=output["elasticsearch_url"],
        kafka_host_port=output["kafka_host_port"],
        rabbitmq_node_names=output["rabbitmq_node_names"]
    )
    output |= aefinder_apphost_output
    return output
