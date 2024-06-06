// This gets the current version of the contract

import FiatToken from 0x{{.FiatToken}}

access(all) fun main(): String {
    return FiatToken.version
}
