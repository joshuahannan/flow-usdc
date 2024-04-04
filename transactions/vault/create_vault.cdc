// This script is used to add a Vault resource to their account so that they can use FiatToken 
//
// If the Vault already exist for the account, the script will return immediately without error
// 
// If not onchain-multisig is required, pubkeys and key weights can be empty
// Vault resource must follow the FuntibleToken interface where initialiser only takes the balance
// As a result, the Vault owner is required to directly add public keys to the OnChainMultiSig.Manager
// via the `addKeys` method in the OnchainMultiSig.KeyManager interface.
// 
// Therefore if multisig is required for the vault, the account itself should have the same key weight
// distribution as it does for the Vault.
import "FungibleToken"
import "FiatToken"
import OnChainMultiSig from 0x{{.OnChainMultiSig}}

transaction {

    prepare(signer: auth(Storage, BorrowValue, Capabilities, AddContract) &Account) {

        // Return early if the account already stores a FiatToken Vault
        if signer.storage.borrow<&FiatToken.Vault>(from: FiatToken.VaultStoragePath) != nil {
            return
        }

        // Create a new ExampleToken Vault and put it in storage
        signer.storage.save(
            <-FiatToken.createEmptyVault(),
            to: FiatToken.VaultStoragePath
        )

        // Create a public capability to the Vault that only exposes
        // the deposit function through the Receiver interface
        let receiver = signer.capabilities.issue<&FiatToken.Vault{FungibleToken.Receiver}>(
            FiatToken.VaultStoragePath
        )
        signer.capabilities.publish(receiver, at: FiatToken.VaultReceiverPubPath)

        // Create a public capability to the Vault that only exposes
        // the UUID() function through the VaultUUID interface
        signer.capabilities.publish(receiver, at: FiatToken.VaultUUIDPubPath)

        // Create a public capability to the Vault that only exposes
        // the balance field through the Balance interface
        signer.capabilities.publish(receiver, at: FiatToken.VaultBalancePubPath)

    }
}
