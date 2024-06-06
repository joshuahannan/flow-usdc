// remove contract 

import FiatToken from 0x{{.FiatToken}}

transaction (name: String) {
    prepare(owner: auth(Contracts) &Account) {
        owner.contracts.remove(name: name)
    }
}
