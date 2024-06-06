// This script gets the weight of a stored access(all)lic key in a multiSigManager for a resource 

import OnChainMultiSig from 0x{{.OnChainMultiSig}}
import FiatToken from 0x{{.FiatToken}}

access(all) fun main(resourceAddr: Address, key: String, resourcePubSignerPath: PublicPath): UFix64 {
    let resourceAcct = getAccount(resourceAddr)
    let ref = resourceAcct.capabilities.get<&{OnChainMultiSig.PublicSigner}>(resourcePubSignerPath)
        .borrow()
        ?? panic("Could not borrow Pub Signer reference to the Vault")

    let attr = ref.getSignerKeyAttr(publicKey: key)!
    return attr.weight
}
