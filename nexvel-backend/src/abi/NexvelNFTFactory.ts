export default [
  {
    "type": "constructor",
    "inputs": [
      {
        "name": "admin_",
        "type": "address",
        "internalType": "address"
      },
      {
        "name": "registry_",
        "type": "address",
        "internalType": "address"
      },
      {
        "name": "erc721Impl_",
        "type": "address",
        "internalType": "address"
      },
      {
        "name": "erc721AImpl_",
        "type": "address",
        "internalType": "address"
      }
    ],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "admin",
    "inputs": [],
    "outputs": [
      {
        "name": "",
        "type": "address",
        "internalType": "address"
      }
    ],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "createNFT",
    "inputs": [
      {
        "name": "name_",
        "type": "string",
        "internalType": "string"
      },
      {
        "name": "symbol_",
        "type": "string",
        "internalType": "string"
      },
      {
        "name": "nftType",
        "type": "uint8",
        "internalType": "enum NexvelNFTFactory.NFTType"
      },
      {
        "name": "operator_",
        "type": "address",
        "internalType": "address"
      },
      {
        "name": "creators_",
        "type": "address[]",
        "internalType": "address[]"
      },
      {
        "name": "maxSupply_",
        "type": "uint256",
        "internalType": "uint256"
      }
    ],
    "outputs": [
      {
        "name": "collection",
        "type": "address",
        "internalType": "address"
      }
    ],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "erc721AImpl",
    "inputs": [],
    "outputs": [
      {
        "name": "",
        "type": "address",
        "internalType": "address"
      }
    ],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "erc721Impl",
    "inputs": [],
    "outputs": [
      {
        "name": "",
        "type": "address",
        "internalType": "address"
      }
    ],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "registry",
    "inputs": [],
    "outputs": [
      {
        "name": "",
        "type": "address",
        "internalType": "contract IMarketplaceAddressRegistry"
      }
    ],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "setImplementations",
    "inputs": [
      {
        "name": "erc721Impl_",
        "type": "address",
        "internalType": "address"
      },
      {
        "name": "erc721AImpl_",
        "type": "address",
        "internalType": "address"
      }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "updateRegistry",
    "inputs": [
      {
        "name": "newRegistry",
        "type": "address",
        "internalType": "address"
      }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "event",
    "name": "CollectionCreated",
    "inputs": [
      {
        "name": "creator",
        "type": "address",
        "indexed": true,
        "internalType": "address"
      },
      {
        "name": "collection",
        "type": "address",
        "indexed": true,
        "internalType": "address"
      },
      {
        "name": "implementation",
        "type": "address",
        "indexed": true,
        "internalType": "address"
      },
      {
        "name": "nftType",
        "type": "uint8",
        "indexed": false,
        "internalType": "enum NexvelNFTFactory.NFTType"
      },
      {
        "name": "name",
        "type": "string",
        "indexed": false,
        "internalType": "string"
      },
      {
        "name": "symbol",
        "type": "string",
        "indexed": false,
        "internalType": "string"
      },
      {
        "name": "maxSupply",
        "type": "uint256",
        "indexed": false,
        "internalType": "uint256"
      }
    ],
    "anonymous": false
  },
  {
    "type": "event",
    "name": "ImplementationsUpdated",
    "inputs": [
      {
        "name": "erc721Impl",
        "type": "address",
        "indexed": false,
        "internalType": "address"
      },
      {
        "name": "erc721AImpl",
        "type": "address",
        "indexed": false,
        "internalType": "address"
      }
    ],
    "anonymous": false
  },
  {
    "type": "event",
    "name": "RegistryUpdated",
    "inputs": [
      {
        "name": "newRegistry",
        "type": "address",
        "indexed": true,
        "internalType": "address"
      }
    ],
    "anonymous": false
  },
  {
    "type": "error",
    "name": "ERC1167FailedCreateClone",
    "inputs": []
  },
  {
    "type": "error",
    "name": "ReentrancyGuardReentrantCall",
    "inputs": []
  }
];
