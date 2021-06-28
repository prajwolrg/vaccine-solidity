const Migrations = artifacts.require("Migrations");
const Vaccination = artifacts.require("Vaccination");

module.exports = function (deployer, network, accounts) {
    deployer.deploy(Migrations);
    deployer.deploy(Vaccination);
};
