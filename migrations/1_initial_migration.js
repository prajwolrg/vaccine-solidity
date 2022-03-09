const Vaccination = artifacts.require("Vaccination");

module.exports = function (deployer, network, accounts) {
    deployer.deploy(Vaccination);
};
