import "FiatToken"
import "FlowEVMBridgeConfig"

/// This contract acts as a way to create a FiatToken.MinterResource
/// and send it directly to the Flow/EVM bridge trustlessly
/// It will be deployed after the Cadence 1.0 upgrades are complete
/// The bridge design is still not finalized, so this is meant
/// as an example for now and will be finished and tested in the near
/// future after the bridge implementation is complete

access(all) contract FiatTokenMinterToBridge {
    access(all) resource MinterSender {
        /// The bridge address to which the Minter will be sent
        access(all) let bridgeAddress: Address
        
        init(_ bridgeAddress: Address) {
            self.bridgeAddress = bridgeAddress
        }
        /// Sends the FiatToken Minter to the Flow/EVM bridge
        /// without giving any account access to the minter
        /// before it is safely in the bridge
        access(all) fun sendMinterToBridge() {
            let minter <- FiatToken.createMinter()
            // borrow a reference to the bridge's configuration admin resource from public Capability
            let bridgeAdmin = getAccount(self.bridgeAddress).capabilities.borrow<&FlowEVMBridgeConfig.Admin>(
                    from: FlowEVMBridgeConfig.adminPublicPath
                ) ?? panic("FlowEVMBridgeConfig.Admin could not be referenced")
            // sets the FiatToken as the minter resource for all FiatToken bridge requests
            // prior to transferring the Minter, a TokenHandler will be set for FiatToken during the bridge's initial
            // configuration, setting the stage for this minter to be sent.
            bridgeAdmin.setTokenHandlerMinter(targetType: Type<@FiatToken.Vault>(), minter: <-minter)
        }
    }
    
    init(bridgeAddress: Address) {
        // Create a MinterSender resource
        let minterSender <- create MinterSender()
        // Store it in the contract account
        self.account.storage.save(<-minterSender, to: /storage/fiatTokenMinterSender)
    }
}