from scripts.helpful_scripts import get_account, LOCAL_BLOCKCHAIN_ENVIRONMENTS
from scripts.deploy import deploy_fund_me
from brownie import network, accounts, exceptions
import pytest


def test_can_fund_and_withdraw():
    account = get_account()
    fund_me = deploy_fund_me()
    entrance_fee = (
        fund_me.getEntranceFee() + 1000000000
    )  # +100 para asegurarme que el monto sea mayor que el minimo
    tx = fund_me.fund({"from": account, "value": entrance_fee})
    tx.wait(1)
    assert (
        fund_me.addressToAmountFunded(account.address) == entrance_fee
    )  # Para verificar la cantidad. Uso el mapping para verificar que la cantidad que envia la direccion coincida con la cantidad
    tx2 = fund_me.withdraw({"from": account})
    tx2.wait(1)
    assert (
        fund_me.addressToAmountFunded(account.address) == 0
    )  # Verifico que el monto ahora sea 0


# Verificar que no se pueda correr en ciertas networks


def test_only_owner_can_withdraw():
    if network.show_active() not in LOCAL_BLOCKCHAIN_ENVIRONMENTS:
        # Para saltarme una prueba uso pytest skip
        pytest.skip(
            "Only for local testing"
        )  # Si detecta que la red no pertenece, se salta el test
        # Ejecuto: brownie test -k test_only_owner_can_withdraw --network sepolia  para verificar que este test funciona ya que sepolia no es una red local
    fund_me = deploy_fund_me()
    bad_actor = (
        accounts.add()
    )  # Aca guardo la cuenta que no tiene permiso de ejecutar el test
    with pytest.raises(
        exceptions.VirtualMachineError
    ):  # Como se que  esto va a fallar, puedo usar las excepciones que tiene pytest para que no me marque un error
        fund_me.withdraw(
            {"from": bad_actor}
        )  # Aca pruebo a ver si el bad_actor puede ejecutar un withdrow, ya que no es el owner (el que ejecutó el contrato)

    # Ejecuto brownie test -k test_only_owner_can_withdraw para ver que pasa la prueba (desde development). No lo ejecuto en ganache porque sino daria otro error ya que no con account.add no estaria obteniendo la cuenta correctamente
