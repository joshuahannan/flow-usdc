import "FiatToken"
import "FlowEVMBridge"

/// This contract acts as a way to create a FiatToken.MinterResource
/// and send it directly to the Flow/EVM bridge trustlessly
/// It will be deployed after the Cadence 1.0 upgrades are complete

/// The bridge design is still not finalized, so this is meant
/// as an example for now and will be finished and tested in the near
/// future after the bridge implementation is complete

access(all) contract FiatTokenMinterToBridge {
    access(all) resource MinterSender {

        /// Sends the FiatToken Minter to the Flow/EVM bridge
        /// without giving any account access to the minter
        /// before it is safely in the bridge
        access(all) fun sendMinterToBridge() {
            let minter <- FiatToken.createMinter()
            FlowEVMBridge.depositFiatTokenMinter(<-minter)
        }
    }

    init() {
        // Create a MinterSender resource
        let minterSender <- create MinterSender()
        // Store it in the contract account
        self.account.storage.save(<-minterSender, to: /storage/fiatTokenMinterSender)
    }
}