// This pauses the contract by a Pauser if capability was granted

import FiatToken from 0x{{.FiatToken}}

transaction {
    prepare (pauser: auth(BorrowValue) &Account) {

        let pauser = pauser.storage.borrow<&FiatToken.Pauser>(from: FiatToken.PauserStoragePath) ?? panic("cannot borrow own private path")
        pauser.pause();
    } 

    post {
        FiatToken.paused: "pause contract error"
    }
}
