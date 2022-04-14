"use strict";

const Government = artifacts.require("Government");
const Organization = artifacts.require("Organization");
const Vaccine = artifacts.require("Vaccine");

const assert = require("chai").assert;
const BigNumber = require("bignumber.js");

// const web3 = require("Web3");

//accounts[0] = admin
//accounts[9] = organization, Sahid Hospital, Kalanki
//account[8] = healthperson

contract("Vaccination", (accounts) => {
    let govt, verocell, org;

    before(async () => {
        govt = await Government.new('Nepal', 'NP', 'np_ipfs_hash');
        console.log('Government done')
        org = await Organization.new(govt.address, 'Sahid Hospital', 'SH', 'sahid_ipfs_hash');
        verocell = await Vaccine.new('Verocell', 'VC');
    });

    describe("Getting approved HealthPersons", async () => {
        it("Approving organization - Sahid Hospital", async () => {
            await govt.approveOrganization(org.address);
        });
        it("Adding a vaccine Batch", async () => {
            const currentTime = Date.now();
            const defrostDate = Math.floor((currentTime - (1 * 86400)) / 1000)
            const expiryDate = Math.floor((currentTime + (30 * 86400)) / 1000)
            const useByDate = Math.floor((currentTime + (25 * 86400)) / 1000)
            verocell.addBatch('101', defrostDate, expiryDate, useByDate, 200)
            verocell.addBatch('102', defrostDate, expiryDate, useByDate, 200)
        });
        it("Registering Individual", async () => {
            await govt.registerIndividual(1999, 0, 'prajwolhash', 'imagehash', { from: accounts[9] });
        });
        it("Approving HealthPerson", async () => {
            await org.approveHealthPerson(accounts[9]);
        });
        it("Getting HealthPerson approval status", async () => {
            const tx_result = await org.healthPersonApprovalStatus(accounts[9])
            console.log(tx_result)
        });
        it("Get approved HealthPerson", async () => {
            const tx_result = await org.getApprovedHealthPersons()
            console.log(tx_result)
        });
        it("Disapproving HealthPerson", async () => {
            await org.disapproveHealthPerson(accounts[9]);
        })
        it("Get approved HealthPerson", async () => {
            const tx_result = await org.getApprovedHealthPersons()
            console.log(tx_result)
        });
        it("Approving HealthPerson", async () => {
            await org.approveHealthPerson(accounts[9]);
        });
        it("Transferring Vaccine", async () => {
            await verocell.transfer(org.address, '101', 10);
            await verocell.transfer(org.address, '102', 10);
        });
        it("Organization Vaccines", async () => {
            let tx_result = await debug(verocell.batchesOwned(org.address));
            console.log(tx_result)
        });
        it("Vaccinating", async () => {
            await org.vaccinate(accounts[9], verocell.address, '101', { from: accounts[9] });
        });
    });


});
