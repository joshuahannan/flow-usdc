import "FungibleToken"
import "FungibleTokenMetadataViews"
import "MetadataViews"
import "Burner"

access(all) contract FiatToken: FungibleToken {

    // ------- FiatToken Events -------
    
    // Pauser events
    access(all) event Paused()
    access(all) event Unpaused()
    
    // Blocklister events
    access(all) event Blocklisted(resourceId: UInt64)
    access(all) event Unblocklisted(resourceId: UInt64)
    
    // FiatToken.Vault events
    access(all) event NewVault(resourceId: UInt64)
    access(all) event DestroyVault(resourceId: UInt64)
    access(all) event FiatTokenWithdrawn(amount: UFix64, from: UInt64)
    access(all) event FiatTokenDeposited(amount: UFix64, to: UInt64)

    // Minting events
    access(all) event MinterCreated(resourceId: UInt64)
    access(all) event Mint(minter: UInt64, amount: UFix64)
    access(all) event Burn(minter: UInt64, amount: UFix64)

    // ------- FungibleToken Events -------
    access(all) event TokensWithdrawn(amount: UFix64, from: Address?)
    access(all) event TokensDeposited(amount: UFix64, to: Address?)


    // ------- FiatToken Paths -------

    access(all) let VaultStoragePath: StoragePath
    access(all) let VaultBalancePubPath: PublicPath
    access(all) let VaultReceiverPubPath: PublicPath

    access(all) let BlocklisterStoragePath: StoragePath
    access(all) let PauserStoragePath: StoragePath
    access(all) let MinterStoragePath: StoragePath


    // ------- FiatToken States / Variables -------

    access(all) let name: String
    access(all) var version: String
    // Set to true if the contract is paused
    access(all) var paused: Bool
    // The token total supply
    access(all) var totalSupply: UFix64
    // Blocked resources dictionary {resourceId: Block Height}
    access(contract) let blocklist: {UInt64: UInt64}

    // -------- ViewResolver Functions for MetadataViews --------

    access(all) view fun getContractViews(resourceType: Type?): [Type] {
        return [
            Type<FungibleTokenMetadataViews.FTView>(),
            Type<FungibleTokenMetadataViews.FTDisplay>(),
            Type<FungibleTokenMetadataViews.FTVaultData>(),
            Type<FungibleTokenMetadataViews.TotalSupply>()
        ]
    }

    access(all) fun resolveContractView(resourceType: Type?, viewType: Type): AnyStruct? {
        switch viewType {
            case Type<FungibleTokenMetadataViews.FTView>():
                return FungibleTokenMetadataViews.FTView(
                    ftDisplay: self.resolveContractView(resourceType: nil, viewType: Type<FungibleTokenMetadataViews.FTDisplay>()) as! FungibleTokenMetadataViews.FTDisplay?,
                    ftVaultData: self.resolveContractView(resourceType: nil, viewType: Type<FungibleTokenMetadataViews.FTVaultData>()) as! FungibleTokenMetadataViews.FTVaultData?
                )
            case Type<FungibleTokenMetadataViews.FTDisplay>():
                let media = MetadataViews.Media(
                        file: MetadataViews.HTTPFile(
                        url: ""
                    ),
                    mediaType: ""
                )
                let medias = MetadataViews.Medias([media])
                return FungibleTokenMetadataViews.FTDisplay(
                    name: "Bridged Circle USDC",
                    symbol: "USDC",
                    description: "This is the Flow Bridged version of USDC in Cadence",
                    externalURL: MetadataViews.ExternalURL("https://www.circle.com/en/usdc"),
                    logos: medias,
                    socials: {
                        "twitter": MetadataViews.ExternalURL("https://twitter.com/circle")
                    }
                )
            case Type<FungibleTokenMetadataViews.FTVaultData>():
                return FungibleTokenMetadataViews.FTVaultData(
                    storagePath: self.VaultStoragePath,
                    receiverPath: self.VaultReceiverPubPath,
                    metadataPath: self.VaultBalancePubPath,
                    receiverLinkedType: Type<&FiatToken.Vault>(),
                    metadataLinkedType: Type<&FiatToken.Vault>(),
                    createEmptyVaultFunction: (fun(): @{FungibleToken.Vault} {
                        return <-FiatToken.createEmptyVault(vaultType: Type<@FiatToken.Vault>())
                    })
                )
            case Type<FungibleTokenMetadataViews.TotalSupply>():
                return FungibleTokenMetadataViews.TotalSupply(
                    totalSupply: FiatToken.totalSupply
                )
        }
        return nil
    }

    // ------- FiatToken Interfaces  -------

    access(all) resource interface ResourceId {
        access(all) fun UUID(): UInt64
    }

    // ------- FiatToken Resources -------

    access(all) resource Vault:
        ResourceId,
        FungibleToken.Vault {
        
        access(all) var balance: UFix64

        /// Called when a fungible token is burned via the `Burner.burn()` method
        /// The total supply will only reflect the supply in the Cadence version
        /// of the FiatToken smart contract
        access(contract) fun burnCallback() {
            if self.balance > 0.0 {
                FiatToken.totalSupply = FiatToken.totalSupply - self.balance
            }
            self.balance = 0.0
        }

        access(all) view fun getViews(): [Type] {
            return FiatToken.getContractViews(resourceType: nil)
        }

        access(all) fun resolveView(_ view: Type): AnyStruct? {
            return FiatToken.resolveContractView(resourceType: nil, viewType: view)
        }

        /// getSupportedVaultTypes optionally returns a list of vault types that this receiver accepts
        access(all) view fun getSupportedVaultTypes(): {Type: Bool} {
            let supportedTypes: {Type: Bool} = {}
            supportedTypes[self.getType()] = true
            return supportedTypes
        }

        /// Returns whether the specified type can be deposited
        access(all) view fun isSupportedVaultType(type: Type): Bool {
            return self.getSupportedVaultTypes()[type] ?? false
        }

        /// Asks if the amount can be withdrawn from this vault
        access(all) view fun isAvailableToWithdraw(amount: UFix64): Bool {
            return amount <= self.balance
        }

        access(all) fun createEmptyVault(): @FiatToken.Vault {
            return <-create Vault(balance: 0.0)
        }

        access(FungibleToken.Withdraw) fun withdraw(amount: UFix64): @{FungibleToken.Vault} {
            pre {
                !FiatToken.paused: "FiatToken contract paused"
                FiatToken.blocklist[self.uuid] == nil: "Vault Blocklisted"
            }
            self.balance = self.balance - amount
            emit FiatTokenWithdrawn(amount: amount, from: self.uuid)
            emit TokensWithdrawn(amount: amount, from: self.owner?.address)
            return <-create Vault(balance: amount)
        }

        access(all) fun deposit(from: @{FungibleToken.Vault}) {
            pre {
                !FiatToken.paused: "FiatToken contract paused"
                FiatToken.blocklist[from.uuid] == nil: "Receiving Vault Blocklisted"
                FiatToken.blocklist[self.uuid] == nil: "Vault Blocklisted"
            }
            let vault <- from as! @FiatToken.Vault
            self.balance = self.balance + vault.balance
            emit FiatTokenDeposited(amount: vault.balance, to: self.uuid)
            emit TokensDeposited(amount: vault.balance, to: self.owner?.address)
            vault.balance = 0.0
            destroy vault
        }

        access(all) view fun UUID(): UInt64 {
            return self.uuid
        }

        init(balance: UFix64) {
            self.balance = balance
        }
    }

    access(all) entitlement Owner

    access(all) resource MinterResource: ResourceId {

        access(FiatToken.Owner) fun mint(amount: UFix64): @{FungibleToken.Vault} {
            pre {
                !FiatToken.paused: "FiatToken contract paused"
                FiatToken.blocklist[self.uuid] == nil: "Minter Blocklisted"
            }
            let newTotalSupply = FiatToken.totalSupply + amount
            FiatToken.totalSupply = newTotalSupply

            emit Mint(minter: self.uuid, amount: amount)
            return <-create Vault(balance: amount)
        }

        access(FiatToken.Owner) fun burn(vault: @{FungibleToken.Vault}) {
            pre {
                !FiatToken.paused: "FiatToken contract paused"
                FiatToken.blocklist[self.uuid] == nil: "Minter Blocklisted"
            }
            let toBurn <- vault as! @FiatToken.Vault
            let amount = toBurn.balance

            assert(FiatToken.totalSupply >= amount, message: "burning more than total supply")

            // This function updates FiatToken.totalSupply and sets the Vault's value to 0.0
            Burner.burn(<-toBurn)
            emit Burn(minter: self.uuid, amount: amount)
        }

        access(all) view fun UUID(): UInt64 {
            return self.uuid
        }
    }

    access(all) resource PauserResource {

        access(all) fun pause() {
            FiatToken.paused = true
            emit Paused()
        }

        access(all) fun unpause() {
            FiatToken.paused = false
            emit Unpaused()
        }
    }

    access(all) resource BlocklisterResource {

        access(all) fun blocklist(resourceId: UInt64){
            let block = getCurrentBlock()
            FiatToken.blocklist.insert(key: resourceId, block.height)
            emit Blocklisted(resourceId: resourceId)
        }

        access(all) fun unblocklist(resourceId: UInt64){
            FiatToken.blocklist.remove(key: resourceId)
            emit Unblocklisted(resourceId: resourceId)
        }
    }

    // ------- FiatToken functions -------

    access(all) fun createEmptyVault(vaultType: Type): @Vault {
        let r <-create Vault(balance: 0.0)
        emit NewVault(resourceId: r.uuid)
        return <-r
    }

    access(all) fun getBlocklist(resourceId: UInt64): UInt64?{
        return FiatToken.blocklist[resourceId]
    }

    // ------- FiatToken Initializer -------
    init(
        VaultStoragePath: StoragePath,
        VaultBalancePubPath: PublicPath,
        VaultReceiverPubPath: PublicPath,
        BlocklisterStoragePath: StoragePath,
        PauserStoragePath: StoragePath,
        MinterStoragePath: StoragePath,
        tokenName: String,
        version: String,
        initTotalSupply: UFix64,
        initPaused: Bool
    ) {
        // Set the State
        self.name = tokenName
        self.version = version
        self.paused = initPaused
        self.totalSupply = initTotalSupply
        self.blocklist = {}

        self.VaultStoragePath = VaultStoragePath
        self.VaultBalancePubPath = VaultBalancePubPath
        self.VaultReceiverPubPath = VaultReceiverPubPath

        self.BlocklisterStoragePath =  BlocklisterStoragePath
        self.PauserStoragePath = PauserStoragePath

        self.MinterStoragePath = MinterStoragePath
 
        // Create a Vault with the initial totalSupply
        let vault <- create Vault(balance: self.totalSupply)
        self.account.storage.save(<-vault, to: self.VaultStoragePath)

        // Create public capabilities to the vault
        let tokenCap = self.account.capabilities.storage.issue<&FiatToken.Vault>(self.VaultStoragePath)
        self.account.capabilities.publish(tokenCap, at: self.VaultReceiverPubPath)
        let receiverCap = self.account.capabilities.storage.issue<&FiatToken.Vault>(self.VaultStoragePath)
        self.account.capabilities.publish(receiverCap, at: self.VaultBalancePubPath)
    }
}
