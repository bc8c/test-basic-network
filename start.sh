#!/bin/bash
#
# Copyright IBM Corp All Rights Reserved
#
# SPDX-License-Identifier: Apache-2.0
#
# Exit on first error, print all commands.
set -ev

# don't rewrite paths for Windows Git Bash users
export MSYS_NO_PATHCONV=1

docker-compose -f docker-compose.yml down

#docker-compose -f docker-compose.yml up -d ca.example.com orderer.example.com peer0.org1.example.com couchdb

docker-compose -f docker-compose.yml up -d orderer.example.com \
	       ca.org1.example.com peer0.org1.example.com cli_org1 couchdb1 \
	       ca.org2.example.com peer0.org2.example.com cli_org2 couchdb2 \
	       ca.org3.example.com peer0.org3.example.com cli_org3 couchdb3 

docker ps -a

# wait for Hyperledger Fabric to start
# incase of errors when running later commands, issue export FABRIC_START_TIMEOUT=<larger number>
export FABRIC_START_TIMEOUT=10
#echo ${FABRIC_START_TIMEOUT}
sleep ${FABRIC_START_TIMEOUT}

# Create the channel
#docker exec -e "CORE_PEER_LOCALMSPID=Org1MSP" -e "CORE_PEER_MSPCONFIGPATH=/etc/hyperledger/msp/users/Admin@org1.example.com/msp" peer0.org1.example.com peer channel create -o orderer.example.com:7050 -c mychannel -f /etc/hyperledger/configtx/channel.tx
# Join peer0.org1.example.com to the channel.
#docker exec -e "CORE_PEER_LOCALMSPID=Org1MSP" -e "CORE_PEER_MSPCONFIGPATH=/etc/hyperledger/msp/users/Admin@org1.example.com/msp" peer0.org1.example.com peer channel join -b mychannel.block

# Create the channel
docker exec cli_org1 peer channel create -o orderer.example.com:7050 -c mychannel -f /etc/hyperledger/configtx/channel.tx
sleep 10
# Join peer0.org1.example.com to the channel.
docker exec peer0.org1.example.com peer channel join -b /etc/hyperledger/configtx/mychannel.block
sleep 10
docker exec peer0.org2.example.com peer channel join -b /etc/hyperledger/configtx/mychannel.block
sleep 10
docker exec peer0.org3.example.com peer channel join -b /etc/hyperledger/configtx/mychannel.block
sleep 10
docker exec cli_org1 peer chaincode install -n fabcar -v 1.0 -p github.com/fabcar/go
docker exec cli_org2 peer chaincode install -n fabcar -v 1.0 -p github.com/fabcar/go
docker exec cli_org3 peer chaincode install -n fabcar -v 1.0 -p github.com/fabcar/go
docker exec cli_org1 peer chaincode instantiate -o orderer.example.com:7050 -C mychannel -n fabcar -v 1.0 -c '{"Args":[]}' -P "OR ('Org1MSP.member','Org2MSP.member')"
sleep 10
docker exec cli_org1 peer chaincode invoke -o orderer.example.com:7050 -C mychannel -n fabcar -c '{"function":"initLedger","Args":[]}'

