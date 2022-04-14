const Government = artifacts.require("Government");
const Organization = artifacts.require("Organization");
const Vaccine = artifacts.require("Vaccine");

module.exports = async function (deployer, network, accounts) {
    // console.log(network)
    // console.log(accounts)

    // await deployer.deploy(Government, 'Nepal', 'NP', 'np_ipfs_hash');
    // const govt = await Government.deployed();
    // console.log(`Government contract deployed: ${Government.address}`)

    // await deployer.deploy(Organization, Government.address, 'Alka Hospital', 'AH', 'alka_ipfs_hash')
    // const org = await Organization.deployed();
    // console.log(`Organization contract deployed: ${Organization.address}`)

    // await govt.approveOrganization(Organization.address);
    // console.log(`Organization approved.`)

    // await deployer.deploy(Vaccine, 'Verocell', 'VC');
    // const verocell = await Vaccine.deployed();
    // console.log(`Vaccine contract deployed: ${Vaccine.address}`)

    // const currentTime = Date.now();
    // const defrostDate = Math.floor((currentTime - (1 * 86400))/1000)
    // const expiryDate = Math.floor((currentTime + (30 * 86400))/1000)
    // const useByDate = Math.floor((currentTime + (25 * 86400))/1000)

    // verocell.addBatch(101, '101', defrostDate, expiryDate, useByDate, 200)
    // console.log(`Vaccine batch added: 101`)

    // await govt.registerIndividual(1999, 0, 'prajwolhash', 'imagehash', {from: accounts[9]});
    // console.log(`Individual registered.`)
    // await org.approveHealthPerson(accounts[9]);
    // console.log(`Individual approved as healthperson.`)

    // const tx_result = await org.getApprovedHealthPersons()
    // console.log(tx_result)

    // await org.vaccinate(accounts[8], Vaccine.address, 101);

};
