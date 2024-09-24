# Almacenamos funciones que nos van a ser de utilidad
from brownie import (
    network,
    config,
    accounts,
    MockV3Aggregator,
)  # Importamos network para saber en que red nos encontramos, Config porque queremos leer desde el brownie-config.yaml y accounts en caso de que  estemos usando development y necesitemos las cuentas locales.

from web3 import Web3

# Vamos a poner las variables de los decimales del precio estaticas (se escriben en mayusculas, aunque son modificables, no se deberian modificar):
DECIMALS = 8
STARTING_PRICE = Web3.to_wei(2000, "ether")
LOCAL_BLOCKCHAIN_ENVIRONMENTS = ["development", "ganache-local"]
# Creo una variable para trabajar con una Fork Blockchain
FORKED_LOCAL_ENVIRONMENTS = [
    "mainnet-fork",
    "mainnet-fork-dev",
]  # Tambien agrego manualmente el nombre de la fork creada en Alchemy, para que luego en el if compare los nombres y retorne account[0]


# Dependiendo si ejecuto el contrato en ganache, en una fork de ganache o en una testnet, tenemos que obtener la cuenta de distintas formas:
def get_account():
    if (
        network.show_active() in LOCAL_BLOCKCHAIN_ENVIRONMENTS
        or network.show_active() in FORKED_LOCAL_ENVIRONMENTS
    ):  # Coge todas las opciones de redes dentro de este array
        return accounts[
            0
        ]  # Si es true, devuelve la account[0] de ganache o de la ganache mainnet fork
    else:
        return accounts.add(
            config["wallets"]["from-key"]
        )  # Usamos la cuenta desde config, pero para que esto funcione debemos agregar: en el .yaml poner dotenv: .env y la wallet a partir de la private Key


def deploy_mocks():
    print(f"the active network is {network.show_active()}")
    print(f"Deploying the mocks")
    # Solo en la mocks tengo que obtener el precio de eth, porque en las otras redes el precio se obtiene de contratos ya desplegados
    MockV3Aggregator.deploy(
        DECIMALS, STARTING_PRICE, {"from": get_account()}
    )  # Esta funcion me pide 2 parametros: numero de decimales y cantidad de dinero (2000 y ocho ceros). Usamos 8 decimales porque el aggregator trabaja con 8, y luego nosotros estamos multiplicando para llegar a los 18 decimales
    # Como es una transaccion tipo transact tenemos que decirle el from account
    print(f"Mocks deployed")
