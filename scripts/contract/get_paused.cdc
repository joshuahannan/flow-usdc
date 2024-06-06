// Gets the pause state of the contract

import FiatToken from 0x{{.FiatToken}}

access(all) fun main(): Bool {
    return FiatToken.paused
}
