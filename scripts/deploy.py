from brownie import FundMe, MockV3Aggregator, config, network

# Se pueden importar tanto funciones como variables
from scripts.helpful_scripts import (
    get_account,
    deploy_mocks,
    LOCAL_BLOCKCHAIN_ENVIRONMENTS,
)
from web3 import Web3


def deploy_fund_me():
    if (
        network.show_active() not in LOCAL_BLOCKCHAIN_ENVIRONMENTS
    ):  # Si no se encuentra en este array,
        price_feed_addres = config["networks"][network.show_active()][
            "eth_usd_price_feed"  # Que coga el price feed desde config
        ]
    # Creamos un feed falso a traves de los Mocks
    else:
        deploy_mocks()
        price_feed_addres = MockV3Aggregator[
            -1
        ].address  # Que coja el ultimo deployment

    account = get_account()
    fund_me = FundMe.deploy(
        price_feed_addres,  # Lo paso como parametro aca
        {"from": account},
        publish_source=config["networks"][
            network.show_active()
        ].get(  # Usamos get para que no busque "verify" por ubicacion sino que busque el parametro
            "verify"
        ),  # Publica el codigo fuente = true
    )  # Como es una funcion de tipo transact , le tenemos que decir el from account para que sepa de donde tiene que coger esto
    print(f"Contract deployed to {fund_me.address}")
    return fund_me  # Esto es para usar el contrato FundMe.deploy en los test


def main():
    deploy_fund_me()


# PARA EJECUTAR en la terminal: brownie run scripts/deploy.py --network sepolia

# Para interactuar con el contrato desplegado en la blockchain, debemos VERIFICAR que el BYTECODE coincide con el nuestro
# Dentro de Etherscan me generé una Apikey que la añado  a las variables de entorno para usarla

# DEPLOY EN RED PSEUDO-PERSISTENTE
# Ejecuto en la terminal: brownie networks add Ethereum ganache-local host=http://172.29.80.1:8545 chainid=1337
# Se crea una insancia en ganache
# Ejecuto: brownie run scripts/deploy.py --network ganache.local
# En el caso de cerrar Ganache, hay que borrar las direcciones de los contratos dentro de map.json y la carpeta 1337


# PROBAMOS MAINNET-FORK-DEV creada con Alchemy
# Ejecuto: brownie run scripts/deploy.py --network mainnet-fork-dev
# Luego puedo ejecutar las pruebas test_fund_me.py para verificar que este funcionando con: brownie test --network mainnet-fork-dev
