import configparser
import os

def get_configs():
    config = configparser.ConfigParser()
    config.read("configuration/configuration.ini")

    kafka_env = os.getenv("kafka_env")
    bootstrap_servers = os.getenv("bootstrap_servers")
    auth_method = os.getenv("auth_method")
    sasl_username = os.getenv("sasl_username")
    sasl_password = os.getenv("sasl_password")

    configs = {"bootstrap.servers": bootstrap_servers}

    if auth_method == "sasl_scram":
        configs["security.protocol"] = "SASL_SSL"
        configs["sasl.mechanism"] = "SCRAM-SHA-512"
        configs["sasl.plain.username"] = sasl_username
        configs["sasl.plain.password"] = sasl_password


    if kafka_env == "eventhub":
        ## String namespace = connectionString.substring(connectionString.indexOf("/") + 2, connectionString.indexOf("."));
        namespace =  bootstrap_servers[bootstrap_servers.index("/")+2:bootstrap_servers.index(".")]
        configs["bootstrap.servers"] = f"{namespace}.servicebus.windows.net:9093"
        configs["security.protocol"] = "SASL_SSL"
        configs["sasl.mechanism"] = "PLAIN"
        configs["sasl.username"] = sasl_username
        configs["sasl.password"] = sasl_password


    # print("configs: {0}".format(str(configs)))

    return configs
