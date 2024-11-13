
IMAGE_NAME = "gldeng/aefinder.dbmigrator:sha-82977ce"
APPSETTINGS_TEMPLATE_FILE = "/static_files/dbmigrator/appsettings.json.template"

def run(plan, mongodb_url):

    artifact_name = plan.render_templates(
        config = {
            "appsettings.json": struct(
                template=read_file(APPSETTINGS_TEMPLATE_FILE),
                data={
                    "MongoDbUrl": mongodb_url
                },
            ),
        },
    )
    result = plan.run_sh(
        run = "cp /app/config/appsettings.json /app/appsettings.json && dotnet /app/AeFinder.DbMigrator.dll",
        name = "aefinder-dbmigrator",
        image = IMAGE_NAME,

        env_vars = {
            "ConnectionStrings__Default": mongodb_url + "AeFinder",
            "ConnectionStrings__Orleans": mongodb_url + "AeFinderOrleansDB"
        },
        files={
            "/app/config": artifact_name,
        },
        description = "Initialize mongodb"  
    )

    plan.print(result.code)  # returns the future reference to the code
    plan.print(result.output) # returns the future reference to the output
