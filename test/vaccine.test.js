"use strict";

const Vaccination = artifacts.require("Vaccination");
const assert = require("chai").assert;
const BigNumber = require("bignumber.js");

// const web3 = require("Web3");

//accounts[0] = admin
//accounts[9] = organization, Sahid Hospital, Kalanki
//account[8] = healthperson

contract("Vaccination", (accounts) => {
    let vaccination;

    before(async () => {
        vaccination = await Vaccination.new();
    });

    describe("Proper roles", async () => {
        it("SuperAdmin", async () => {
            assert.equal(await vaccination.superAdmin(), accounts[0]);
        });

        it("Organization must first register", async () => {
            try {
                await vaccination.approveOrganization(accounts[8]);
            } catch (error) {
                const notRegistered = error.message.search('Organization must first register')
                assert.isAtLeast(notRegistered, 0);
            }
        });

        it("Registering Organization - Sahid Hospital", async () => {
            await vaccination.registerOrganization(
                "Sahid Hospital",
                "Kalanki",
                { from: accounts[9], value: 100 }
            );
        });

        it("Registering Users - prajwolgyawali, kritanbanstola", async () => {
            await vaccination.registerIndividual(1999, 0, 'prajwolgyawali', 'imagehash', { from: accounts[1] }
            );
            await vaccination.registerIndividual(1999, 0, 'kritanbanstola', 'imagehash', { from: accounts[2] }
            );
        });

        it("Organization must be approved before Health Person can register to that organization", async () => {
            try {
                await vaccination.registerHealthPerson(accounts[9], { from: accounts[8] })
            } catch (error) {
                const invalidOrganization = error.message.search("Organization must be registered.")
                console.log(error.message)
                assert.isAtLeast(invalidOrganization, 0)
            }
        });

        it("Approving organization - Sahid Hospital", async () => {
            await vaccination.approveOrganization(accounts[9]);
        });

        it("Registering as health person", async () => {
            try {
                await vaccination.registerHealthPerson(accounts[9], { from: accounts[8] })
            } catch (error) {
                console.log(error.message)
            }
        });

        it("Approving HealthPerson", async () => {
            try {
                await vaccination.approveHealthPerson(accounts[8], { from: accounts[9] });
            } catch (error) {
                console.log(error.message)
            }

        });
    });


    describe("Approving vaccine and batch", async () => {
        it("Vaccine must be approved before adding batch.", async () => {
            try {
                await vaccination.addBatch("verocell", 1, 1, 1, 1, 1);
            } catch (error) {
                console.log(error.message)
                const unapprovedVaccine = error.message.search(
                    "Vaccine is not approved."
                );
                assert.isAtLeast(unapprovedVaccine, 0);
            }
        });

        it("Initial vaccine status must be false.", async () => {
            let initialVerificationStatus;
            try {
                initialVerificationStatus =
                    await vaccination.getVaccineApprovalStatus("verocell");
            } catch (error) {
                console.log(error);
            }
            assert.equal(initialVerificationStatus, false);
        });

        it("Approving Vaccine.", async () => {
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

        it("After approving, vaccine Status must be true.", async () => {
            let finalVerficationStatus =
                await vaccination.getVaccineApprovalStatus("verocell");
            assert.equal(finalVerficationStatus, true);
        });

        it("Adding a batch", async () => {
            //defrost date: 1 day earlier
            //expiry date: 30 days after
            //use by date: 25 days after
            const batchId = 1
            const currentTime = await vaccination.now();
            const defrostDate = currentTime - 1 * 86400
            const expiryDate = currentTime + 30 * 86400
            const useByDate = currentTime + 25 * 86400
            try {
                await vaccination.addBatch("verocell", batchId, defrostDate, expiryDate, useByDate, 10);
            } catch (error) {
                console.log(error)
            }
        });
        it('Transferring a batch', async () => {
            try {
                await vaccination.transfer(accounts[9], "covishield", 1, 4)
            } catch (error) {
                console.log(error.message)
            }
        })

        it('Transferring a batch', async () => {
            try {
                await vaccination.transfer(accounts[9], "verocell", 1, 4)
            } catch (error) {
                console.log(error.message)
            }
        })
    });

    describe("Vaccinating", async () => {
        it("Unapproved health person", async () => {
            // let initialCount = await vaccination.getUserVaccineCount(
            //     accounts[1]
            // );
            // initialCount = BigNumber(initialCount).toNumber();
            try {
                await vaccination.vaccinate(accounts[1], "verocell", 1);
            } catch (error) {
                const invalidPerson = error.message.search("HealthPerson");
                assert.isAtLeast(invalidPerson, 0);
            }
        });



        it("Invalid Vaccine", async () => {
            try {
                await vaccination.vaccinate(accounts[1], "verocelllllllll", 1, {
                    from: accounts[8],
                });
            } catch (error) {
                const invalidVaccine = error.message.search(
                    "Vaccine not approved"
                );
                assert.isAtLeast(invalidVaccine, 0);
            }
        });

        it("Invalid Batch", async () => {
            try {
                await vaccination.vaccinate(accounts[1], "verocell", 100, {
                    from: accounts[8],
                });
            } catch (error) {
                console.log(error.message)
                const invalidBatch = error.message.search("Invalid batch");
                assert.isAtLeast(invalidBatch, 0);
            }
        });

        it("First Vaccine to account 1", async () => {
            let status = await vaccination.getVaccineStatusOf(accounts[1]);
            status = BigNumber(status).toNumber();
            assert.equal(status, 0);
            try {
                await vaccination.vaccinate(accounts[1], "verocell", 1, {
                    from: accounts[8],
                });
            } catch (error) {
                console.log(error.message);
            }
            status = await vaccination.getVaccineStatusOf(accounts[1]);
            status = BigNumber(status).toNumber();
            assert.equal(status, 1);
        });

        it("First Vaccine to account 2", async () => {
            let status = await vaccination.getVaccineStatusOf(accounts[2]);
            status = BigNumber(status).toNumber();
            assert.equal(status, 0);
            try {
                await vaccination.vaccinate(accounts[2], "verocell", 1, {
                    from: accounts[8],
                });
            } catch (error) {
                console.log(error.message);
            }
            status = await vaccination.getVaccineStatusOf(accounts[2]);
            status = BigNumber(status).toNumber();
            assert.equal(status, 1);
        });

        it("Second Vaccine to account 1", async () => {
            let status = await vaccination.getVaccineStatusOf(accounts[1]);
            status = BigNumber(status).toNumber();
            assert.equal(status, 1);
            await vaccination.vaccinate(accounts[1], "verocell", 1, {
                from: accounts[8],
            });
            status = await vaccination.getVaccineStatusOf(accounts[1]);
            status = BigNumber(status).toNumber();
            assert.equal(status, 2);
        });
        it("Third Vaccine to account 1", async () => {
            let status = await vaccination.getVaccineStatusOf(accounts[1]);
            status = BigNumber(status).toNumber();
            assert.equal(status, 2);
            try {
                await vaccination.vaccinate(accounts[1], "verocell", 1, {
                    from: accounts[8],
                });
            } catch (error) {
                const alreadyFull = error.message.search(
                    "Fully vaccinated already."
                );
                assert.isAtLeast(alreadyFull, 0);
            }
        });
        it("Second vaccine", async () => {
            let initialCount = await vaccination.getUserVaccineCount(
                accounts[1]
            );
            initialCount = BigNumber(initialCount).toNumber();
            await vaccination.vaccinate(accounts[2], "verocell", 1, {from: accounts[8]});
            let finalCount = await vaccination.getUserVaccineCount(accounts[1]);
            finalCount = BigNumber(finalCount).toNumber();
            // assert.equal(finalCount, initialCount + 1);
        });

    });

});
