// MinterController uses this to configure minter allowance 
// It succeeds of MinterController has assigned Minter from MasterMinter

import "FiatToken"

transaction (amount: UFix64) {
    prepare(minterController: auth(BorrowValue) &Account) {
        let mc = minterController.storage.borrow<&FiatToken.MinterController>(from: FiatToken.MinterControllerStoragePath)
            ?? panic ("no minter controller resource avaialble");

        mc.configureMinterAllowance(allowance: amount);
    }
}
