# PropertyRegistry

A digital real estate and property ownership system where property deeds can be registered, transferred, and validated by multiple jurisdictions.

## Overview

PropertyRegistry is a Clarity smart contract that enables a decentralized property registry on the Stacks blockchain. It allows authorized registrars to create digital property deeds as NFTs, jurisdictions to validate properties with assessment values, and owners to transfer these deeds securely.

## Features

- **NFT Property Deed Management**: Register, transfer, and track ownership of digital property deeds
- **Registrar Authorization**: Property registrars can register to be part of the PropertyRegistry ecosystem
- **Jurisdiction Validation**: Different jurisdictions can validate properties and set assessment values
- **Property Attributes**: Store and retrieve detailed attributes for properties
- **Access Controls**: Proper authorization checks for all sensitive operations

## Contract Functions

### Admin Functions

- `set-contract-owner`: Update the contract owner
- `register-registrar`: Register a new property registrar to the platform
- `deactivate-registrar`: Deactivate a previously registered registrar

### NFT Functions

- `register-property`: Create a new NFT property deed with metadata
- `transfer-property`: Transfer a property deed to another owner
- `set-property-validation`: Define how a jurisdiction validates a specific property
- `set-property-attributes`: Set or update a property's attributes

### Read-Only Functions

- `get-property-details`: Get basic information about a property
- `get-property-attributes`: Get the attributes of a property
- `get-property-validation`: Check how a jurisdiction validates a specific property
- `get-registrar-info`: Get information about a registered registrar
- `get-property-owner`: Get the current owner of a property
- `is-registrar-active`: Check if a registrar is currently active

## Usage

### For Registrars

1. Register as a registrar using `register-registrar`
2. Register properties for owners using `register-property`
3. Set detailed attributes for properties using `set-property-attributes`

### For Jurisdictions

1. Register as a registrar (jurisdictions are also registrars in this system)
2. Validate properties and set assessment values using `set-property-validation`

### For Property Owners

1. Receive property deeds from authorized registrars
2. Transfer property deeds to new owners when selling
3. View property validations from different jurisdictions

## Development

This contract is developed using Clarity and can be tested with Clarinet.