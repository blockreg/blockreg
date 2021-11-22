const Registrations = artifacts.require("Registrations");

module.exports = function (deployer) {
  deployer.deploy(Registrations);
};
