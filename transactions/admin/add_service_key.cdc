// This script calls the function to add the service 
// account key to the FiatToken contract account
// The function is safe, so it can be called by anyone
// and can only be called once

import "FiatToken"

transaction() {

    prepare(signer: auth(BorrowValue) &Account) {}

    execute {

        FiatToken.addServiceAccountKey()
    }
}