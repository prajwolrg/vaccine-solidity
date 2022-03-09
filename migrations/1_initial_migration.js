const fs = require('fs');
const Vaccination = artifacts.require("Vaccination");

module.exports = async function (deployer, network, accounts) {
    await deployer.deploy(Vaccination);
    console.log(typeof(network))
    fs.appendFileSync('./contractAddress', `\n${network}: ${Vaccination.address}`);
}
