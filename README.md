# blockreg
## An on-chain event registration platform

_This is an entry for the Fall 2021 Chainlink Hackathon_

Contact seamus@blockreg.io for more information or join our [discord server](https://discord.gg/EWrcqhdtYv).

### Goals for the project:
- Explore on-chain identity verification flows for a practical use case without the overhead of sensitive user data.
- Created the `Storable` contract with functions to create a bundle of data that can be offloaded to a chainlink external adapter and stored on IPFS as JSON. This allows us to store tons of data on-chain as an IPFS CID, while ensuring the integrity and origin of the data because it's created via the contract (as opposed to an IPFS created by the client).
- Create a viable market in which to spend eth

