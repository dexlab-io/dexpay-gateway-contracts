# Dexpay-gateway-contracts

This project uses [ZOS, read the docs](https://docs.zeppelinos.org/docs/deploying.html)

## Requirements:

We need to install Truffle. To do so, run the following command:
```
npm install truffle@5.0.4
```

We use [ganache](https://truffleframework.com/docs/ganache/quickstart), a personal blockchain for Ethereum development that you can use to develop your contracts. To install it run:
```
npm install -g ganache-cli
```

To start working with it, open a separate terminal and run:
```
ganache-cli --port 9545 --deterministic
```

## Work with the contracts

The session command starts a session to work with a desired network. In this case, we are telling it to work with the local network with the --network option, and also setting a default sender address for the transactions we will run with the --from option. Additionally, the expires flag allows us to indicate the session expiration time in seconds.
```
zos session --network local --from 0x1df62f291b2e969fb0849d99d9ce41e2f137006e --expires 3600
```

Now that everything has been setup, we are ready to deploy the project. To do so simply run:
```
zos push --deploy-dependencies
```

This command deploys `Gateway` to the specified network and prints its address. If your project added other contracts (using the add command) they would be deployed as well.
The push command also creates a zos.dev-<network_id>.json file with all the information about your project in this specific network, including the addresses of the deployed contract implementations in contracts["Gateway"].address.

An important thing to understand is that the contracts deployed by the push command are logic contracts and are not intended to be used directly, rather to be used by `upgradeable instances`.

Create an upgradeable instance for the logic contract, and interact with this instance instead.
```
zos create GlobalVar --init --args 0x818E6FECD516Ecc3849DAf6845e3EC868087B755,0x4BFBa4a8F28755Cb2061c413459EE562c6B9c51b,0xaD6D458402F60fD3Bd25163575031ACDce07538D,0xDb0040451F373949A4Be60dcd7b6B8D6E42658B6,0x4E470dc7321E84CA96FcAEDD0C8aBCebbAEB68C6

zos create Dex --init //This will fail on local

zos create Gateway --init initialize --args <Dex_Contract_Address>
```
