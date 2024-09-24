# Interactuar con el contrato

from brownie import FundMe, accounts  # Importo el contrato
from scripts.helpful_scripts import get_account


def fund():
    fund_me = FundMe[
        -1
    ]  # Primero tuveque haber desplegado el contrato con deploy.py y ahora Guardo el contrato en una variable y uso la address ultima que generé [-1]
    account = get_account()
    entrance_fee = fund_me.getEntranceFee()
    version = fund_me.getVersion()
    print("Entrance Fee: ", entrance_fee)
    print("Version: ", version)
    print("Direccion de la billetera de ganache: ", account)
    print("Direccion del contrato: ", fund_me)
    print("funding")
    fund_me.fund(
        {"from": account, "value": entrance_fee + 2000000000000000000}
    )  # Tenemos que pasarle account y value, todas estas cosas entre {} en brownie son de bajo nivel


def withdraw():
    fund_me = FundMe[-1]
    account = get_account()
    print("Withdrawing")
    fund_me.withdraw({"from": account})


def main():
    fund()
    withdraw()


# Ejecutar en la terminal: brownie run scripts/fund_and_withdrow.py --network ganache-local
