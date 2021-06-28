"use strict";

const Vaccination = artifacts.require("Vaccination");
const assert = require("chai").assert;
const BigNumber = require("bignumber.js");

contract("Vaccination", (accounts) => {
    let vaccination;

    before(async () => {
        vaccination = await Vaccination.new();
    });

    describe("SuperAdmin", async () => {
        it("Initial superAdmin setup", async () => {
            let superAdmin = await vaccination.superAdmin();
            assert.equal(superAdmin, accounts[0]);
        });
    });

    describe("Adding vaccine", async () => {
        it("Vaccine is initially not registerd.", async () => {
            try {
                await vaccination.addBatch("verocell", 1, 1, 1, 1, 1);
            } catch (error) {
                const unapprovedVaccine = error.message.search(
                    "Vaccine is not yet approved."
                );
                assert.isAtLeast(unapprovedVaccine, 0);
            }
        });
        it("Vaccine Status is false", async () => {
            let initialVerificationStatus;
            try {
                initialVerificationStatus =
                    await vaccination.getVaccineApprovalStatus("verocell");
            } catch (error) {
                console.log(error);
            }
            assert.equal(initialVerificationStatus, false);
        });
        it("Registering Vaccine.", async () => {
            let initalVerifiedVaccines =
                await vaccination.getApprovedVaccinesLength();
            initalVerifiedVaccines = BigNumber(
                initalVerifiedVaccines
            ).toNumber();
            try {
                await vaccination.approveVaccine("verocell", [0, 21]);
            } catch (error) {
                console.log(error);
            }
            let finalVerifiedVaccines =
                await vaccination.getApprovedVaccinesLength();
            finalVerifiedVaccines = BigNumber(finalVerifiedVaccines).toNumber();
            assert.equal(finalVerifiedVaccines, initalVerifiedVaccines + 1);
        });
        it("Vaccine Status is true.", async () => {
            let finalVerficationStatus =
                await vaccination.getVaccineApprovalStatus("verocell");
            assert.equal(finalVerficationStatus, true);
        });
        it("Adding a batch", async () => {
            await vaccination.addBatch("verocell", 1, 1, 1, 1, 6);
        });

        // it("Unknown vaccine must fail.", async () => {
        //     try {
        //         await vaccination.vaccinate(accounts[1], "verell", 1);
        //     } catch (error) {
        //         const unapprovedVaccine = error.message.search(
        //             "Vaccine is not approved."
        //         );
        //         assert.isAtLeast(unapprovedVaccine, 0);
        //     }
        // });
    });

    describe("Proper roles", async () => {
        it("SuperAdmin", async () => {
            assert.equal(await vaccination.superAdmin(), accounts[0]);
        });

        it("Organization must register before being approved", async () => {
            // let initialRegistrationStatus = await vaccination.organizations(
            //     accounts[9]
            // ).registraion;
            try {
                await vaccination.transfer(accounts[9], "vercell", 1, 3);
            } catch (error) {
                const invalidOrganization =
                    error.message.search("organization");
                assert.isAtLeast(invalidOrganization, 0);
            }
            // assert.equal(initialRegistrationStatus, false);
        });

        it("Organization must be approved before being able to recieve.", async () => {
            // let initialRegistrationStatus = await vaccination.organizations(
            //     accounts[9]
            // ).registraion;
            await vaccination.registerOrganization(
                "Sahid Hospital",
                "Kalanki",
                { from: accounts[9], value: 100 }
            );

            try {
                await vaccination.transfer(accounts[9], "vercell", 1, 3);
            } catch (error) {
                const invalidOrganization =
                    error.message.search("Organization");
                assert.isAtLeast(invalidOrganization, 0);
            }
            // assert.equal(initialRegistrationStatus, false);
            // assert.equal(finalRegistrationStatus, true);
        });

        it("Approving organization", async () => {
            // let initialApprovedStatus = await vaccination.organizations(
            //     accounts[9]
            // ).approved;
            // assert.equal(initialApprovedStatus, false);
            await vaccination.approveOrganization(accounts[9]);
            try {
                await vaccination.transfer(accounts[9], "vercell", 1, 3);
            } catch (error) {
                const notApproved = error.message.search("Vaccine");
                assert.isAtLeast(notApproved, 0);
            }
            await vaccination.transfer(accounts[9], "verocell", 1, 3);
            // let finalApprovedStatus = await vaccination.organizations(
            //     accounts[9]
            // ).approved;
            // assert.equal(finalApprovedStatus, true);
        });
    });

    // describe("Vaccinating", async () => {
    //     it("First vaccine", async () => {
    //         let initialCount = await vaccination.getUserVaccineCount(
    //             accounts[1]
    //         );
    //         initialCount = BigNumber(initialCount).toNumber();
    //         await vaccination.vaccinate(accounts[1], "verocell", 1);
    //         let finalCount = await vaccination.getUserVaccineCount(accounts[1]);
    //         finalCount = BigNumber(finalCount).toNumber();
    //         assert.equal(finalCount, initialCount + 1);
    //     });

    //     it("Second vaccine", async () => {
    //         let initialCount = await vaccination.getUserVaccineCount(
    //             accounts[1]
    //         );
    //         initialCount = BigNumber(initialCount).toNumber();
    //         await vaccination.vaccinate(accounts[1], "verocell", 1);
    //         let finalCount = await vaccination.getUserVaccineCount(accounts[1]);
    //         finalCount = BigNumber(finalCount).toNumber();
    //         assert.equal(finalCount, initialCount + 1);
    //     });

    //     it("More vaccine", async () => {
    //         try {
    //             await vaccination.vaccinate(accounts[1], "verocell", 1);
    //         } catch (error) {
    //             const fullyVaccined = error.message.search("Fully vaccinated");
    //             assert.isAtLeast(fullyVaccined, 0);
    //         }
    //     });
    // });
});
