import "FungibleToken"
// import "EVM"

/// FlowEVMBridgeHandlerInterfaces
///
/// This contract defines the interfaces for the FlowEVM Bridge Handlers. These Handlers are intended to encapsulate
/// the logic for bridging edge case assets between Cadence and EVM and require configuration by the bridge account to
/// enable. Contracts implementing these resources should be deployed to the bridge account so that privileged methods,
/// particularly those related to fulfilling bridge requests remain in the closed loop of bridge contract logic and
/// defined assets in the custody of the bridge account.
///
access(all) contract FlowEVMBridgeHandlerInterfaces {

    /******************
        Entitlements
    *******************/

    /// Entitlement related to administrative setters
    access(all) entitlement Admin
    /// Entitlement related to minting handled assets
    access(all) entitlement Mint

    // /*************
    //     Events
    // **************/
    
    // /// Event emitted when a handler is enabled between a Cadence type and an EVM address
    // access(all) event HandlerEnabled(handlerType: Type, targetType: Type, targetEVMAddress: EVM.EVMAddress)

    // /****************
    //     Constructs
    // *****************/
    
    // /// Non-privileged interface for querying handler information
    // ///
    // access(all) resource interface HandlerInfo {
    //     /// Returns whether the Handler is enabled
    //     access(all)	view fun isEnabled(): Bool
    //     /// Returns the Cadence type handled by the Handler, nil if not set
    //     access(all) view fun getTargetType(): Type?
    //     /// Returns the EVM address handled by the Handler, nil if not set
    //     access(all) view fun getTargetEVMAddress(): EVM.EVMAddress?
    // }

    // /// Administrative interface for Handler configuration
    // ///
    // access(all) resource interface HandlerAdmin : HandlerInfo {
    //     /// Sets the target Cadence Type handled by this resource
    //     access(Admin) fun setTargetType(_ type: Type) {
    //         pre {
    //             self.getTargetType() == nil: "Target Type has already been set"
    //         }
    //         post {
    //             self.getTargetType()! == type: "Problem setting target type"
    //         }
    //     }
    //     /// Sets the target EVM address handled by this resource
    //     access(Admin) fun setTargetEVMAddress(_ address: EVM.EVMAddress) {
    //         pre {
    //             self.getTargetEVMAddress() == nil: "Target EVM address has already been set"
    //         }
    //         post {
    //             self.getTargetEVMAddress()!.bytes == address!.bytes: "Problem setting target EVM address"
    //         }
    //     }
    //     /// Enables the Handler to fulfill bridge requests for the configured targets
    //     access(Admin) fun enableBridging() {
    //         pre {
    //             self.getTargetType() != nil && self.getTargetEVMAddress() != nil:
    //                 "Cannot enable before setting bridge targets"
    //             !self.isEnabled(): "Handler already enabled"
    //         }
    //         post {
    //             self.isEnabled(): "Problem enabling Handler"
    //             emit HandlerEnabled(
    //                 handlerType: self.getType(),
    //                 targetType: self.getTargetType()!,
    //                 targetEVMAddress: self.getTargetEVMAddress()!
    //             )
    //         }
    //     }
    // }

    /// Minter interface for configurations requiring the minting of Cadence fungible tokens
    ///
    access(all) resource interface TokenMinter {
        /// Returns the Cadence type minted by this resource
        access(all) view fun getMintedType(): Type
        /// Mints the specified amount of the Cadence 
        access(Mint) fun mint(amount: UFix64): @{FungibleToken.Vault} {
            pre {
                amount > 0.0: "Amount must be greater than 0"
            }
            post {
                result.getType() == self.getMintedType(): "Invalid Vault type returned"
                result.balance == amount: "Minted amount does not match requested amount"
            }
        }
    }

    // /// Handler interface for bridging FungibleToken assets. Implementations should be stored within the bridge account
    // /// and called be the bridge contract for bridging operations on the Handler's target Type and EVM contract.
    // ///
    // access(all) resource interface TokenHandler : HandlerInfo, HandlerAdmin {
    //     /// Fulfills a request to bridge tokens from the Cadence side to the EVM side
    //     access(account) fun fulfillTokensToEVM(
    //         tokens: @{FungibleToken.Vault},
    //         to: EVM.EVMAddress
    //     ) {
    //         pre {
    //             self.isEnabled(): "Handler is not yet enabled"
    //             tokens.getType() == self.getTargetType(): "Invalid Vault type"
    //         }
    //     }
        // /// Fulfills a request to bridge tokens from the EVM side to the Cadence side
        // access(account) fun fulfillTokensFromEVM(
        //     owner: EVM.EVMAddress,
        //     type: Type,
        //     amount: UInt256,
        //     protectedTransferCall: fun (): EVM.Result
        // ): @{FungibleToken.Vault} {
        //     pre {
        //         self.isEnabled(): "Handler is not yet enabled"
        //     }
        //     post {
        //         result.getType() == self.getTargetType(): "Invalid Vault type returned"
        //     }
        // }
    // }
}