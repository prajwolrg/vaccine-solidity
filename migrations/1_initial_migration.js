const fs = require('fs');
const Vaccination = artifacts.require("Vaccination");
const ethers = require('ethers')

userAccounts = [
    {
        "name": "Gaurav Pokharel",
        "yearOfBirth": 1999,
        "gender": 0,
        "ipfs_hash": 'bafybeifng4tsbkcgevckbxhqoyoovng5dsak5qw5cpphukxw7kysfv4abe'
    },
    {
        "name": "Kritan Banstola",
        "yearOfBirth": 1999,
        "gender": 0,
        "ipfs_hash": 'bafybeig5ngkg4arvwcczvj7nwy7ehjdc4gm26wznpcuo4jyyqpn3l6htai'
    },
    {
        "name": "Madhav Aryal",
        "yearOfBirth": 1999,
        "gender": 0,
        "ipfs_hash": 'bafybeihjtidn3eojxcpm6w4rvhy6euqqhl7laayklk4g3x4fkwa4qx26qu'
    },
    {
        "name": "Prajwol Gyawali",
        "yearOfBirth": 1999,
        "gender": 0,
        "ipfs_hash": 'bafybeifptqkpulmgd35g53f5xmgcqibbgoi3h2bybjtjywqt6euoui4g44'
    }
]

vaccines = [
    {
        "name": "Verocell",
        "schedule": [0, 21],
        "batches": [1121, 1131]
    }
]

module.exports = async function (deployer, network, accounts) {
    console.log(`Deployer: ${deployer}`)
    console.log(`Network: ${network}`)
    console.log(`Accounts: ${accounts}`)

    await deployer.deploy(Vaccination);
    const vaccination = await Vaccination.deployed()
    // console.log(vaccination)
    // console.log(typeof(vaccination))

    // Register Organization
    await vaccination.registerOrganization(
        "Sahid Hospital",
        "Kalanki",
        { from: accounts[2], value: 100 }
    );

    // Approve organization
    await vaccination.approveOrganization(accounts[2])


    // Add users
    for (i = 0; i < userAccounts.length; i++) {
        console.log(`Adding user ${userAccounts[i].name}`)
        await vaccination.registerIndividual(
            userAccounts[i]['yearOfBirth'],
            userAccounts[i]['gender'],
            ethers.utils.id(userAccounts[i]['name']),
            userAccounts[i]['ipfs_hash'],
            { from: accounts[6 + i] })
    }

    //Add vaccines
    for (let i = 0; i < vaccines.length; i++) {
        console.log(`Approving Vaccine: ${vaccines[i].name}`)
        await vaccination.approveVaccine(vaccines[i].name, vaccines[i].schedule)
        console.log(vaccines[i].batches)
        for (let j = 0; j < vaccines[i].batches.length; j++) {
            const batchId = vaccines[i].batches[j]
            const currentTime = await vaccination.now();
            const defrostDate = currentTime - 1 * 86400
            const expiryDate = currentTime + 30 * 86400
            const useByDate = currentTime + 25 * 86400
            await vaccination.addBatch(vaccines[i].name, batchId, defrostDate, expiryDate, useByDate, 200);
            console.log(`Adding ${vaccines[i].name} - Batch: ${batchId}`)
        }

    }
    // await vaccination.approveHealthPerson(accounts[10], { from: accounts[2]})
    // await vaccination.approveHealthPerson(accounts[9], { from: accounts[2]})

    if (network == 'private') {
        console.log('Adding data to contractAddresses')
        await addContractAddresses(Vaccination.address)
    }
}

const addContractAddresses = async (contractAddress) => {
    const date = new Date()
    const dateString = date.toString()
    const newdata = {
        'time': dateString,
        'contracts': {
            'Vaccination': contractAddress
        }
    }

    let alldata = []
    let prevdata = await fs.readFileSync('contractAddresses.json')
    prevdata = prevdata.toString()
    prevdata = JSON.parse(prevdata)

    for (let i = 0; i < prevdata.length; i++) {
        alldata.push(prevdata[i])
    }
    alldata.push(newdata)

    await fs.writeFileSync('contractAddresses.json', JSON.stringify(alldata))
}

