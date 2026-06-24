from web3 import Web3
import json


class BlockchainService:
    def __init__(self):
        self.w3 = Web3(Web3.HTTPProvider("http://127.0.0.1:7545"))
        assert self.w3.is_connected()

        with open("ProductRegistryABI.json") as f:
            abi = json.load(f)

        self.contract = self.w3.eth.contract(
            address="0x43BA950f559F6d313E3EfAC188fFfDF366197871",
            abi=abi
        )

    # --------------------------------------------------
    # Register product (manufacturer only)
    # --------------------------------------------------
    def register_product(self, product_id, product_hash_hex, from_address):
        product_hash_bytes = self.w3.to_bytes(hexstr=product_hash_hex)

        tx = self.contract.functions.registerProduct(
        product_id,
        product_hash_bytes
    ).transact({"from": from_address})

        self.w3.eth.wait_for_transaction_receipt(tx)


    # --------------------------------------------------
    # Read-only
    # --------------------------------------------------
    def get_product(self, product_id):
        return self.contract.functions.getProduct(product_id).call()

    # --------------------------------------------------
    # Ownership transfer (MUST be current owner)
    # --------------------------------------------------
    def transfer_ownership(self, product_id, new_owner, from_address):
        tx = self.contract.functions.transferOwnership(
            product_id,
            new_owner
        ).transact({"from": from_address})
        self.w3.eth.wait_for_transaction_receipt(tx)

