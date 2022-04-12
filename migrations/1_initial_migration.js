const fs = require('fs');
const Vaccination = artifacts.require("Vaccination");
// const ethers = require('ethers')

const { ethers, providers, BigNumber } = require("ethers");
const axios = require('axios');

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
        "batches": [1141, 1151]
    }
]

organizations = [
    {
        'name': 'Grande International Hospital',
        'url': 'https://www.grandehospital.com/',
        'ipfs_hash': 'https://www.grandehospital.com/',
        'location': '27.753094359189657, 85.3258460820991',
        'contact': {
            'email1': 'info@grandehospital.com',
            'phone1': '+977-1-5159266,',
            'phone2': '+977-1-5159267,',
            'phone3': '+977-9801202550'
        }
    },
    {
        'name': 'Norvic International Hospital',
        'url': 'https://www.norvichospital.com/',
        'ipfs_hash': 'https://www.norvichospital.com/',
        'location': '27.690222585866792, 85.31913930908078',
        'contact': {
            'email1': 'info@norvichospital.com',
            'phone1': '+977 1-5970032',
            'phone2': '+977-1-4218230',
            'phone3': '+977-1-4101600'
        }
    },
    {
        'name': 'Nepal Mediciti Hospital',
        'url': 'https://www.nepalmediciti.com/',
        'ipfs_hash': 'https://www.nepalmediciti.com/',
        'location': '27.66259787526539, 85.30307300001515',
        'contact': {
            'email1': 'info@nepalmediciti.com',
            'phone1': '+977-1-4217766',
            'phone2': '+977-981-0136491',
        }
    },
]

module.exports = async function (deployer, network, accounts) {
    console.log(`Deployer: ${deployer}`)
    console.log(`Network: ${network}`)
    console.log(`Accounts: ${accounts}`)

    // await checkUser(accounts[6], network)

    await deployer.deploy(Vaccination);
    const vaccination = await Vaccination.deployed()
    console.log('Adding data to contractAddresses')
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
        console.log(`Adding user ${userAccounts[i].name}: ${accounts[6 + i]}`)
        await vaccination.registerIndividual(
            userAccounts[i]['yearOfBirth'],
            userAccounts[i]['gender'],
            ethers.utils.id(userAccounts[i]['name']),
            userAccounts[i]['ipfs_hash'],
            { from: accounts[6 + i] })

        // let user = await vaccination.users(accounts[6 + i])
        // console.log(user)
        // await checkUser(accounts[6 + i], network)
    }

    //Add vaccines
    for (let i = 0; i < vaccines.length; i++) {
        console.log(`Approving Vaccine: ${vaccines[i].name}`)
        await vaccination.approveVaccine(vaccines[i].name, vaccines[i].schedule)
        console.log(vaccines[i].batches)
        for (let j = 0; j < vaccines[i].batches.length; j++) {
            const batchId = vaccines[i].batches[j]
            const currentTime = await vaccination.now();
            const defrostDate = currentTime - (1 * 86400)
            const expiryDate = currentTime.toNumber() + (30 * 86400)
            const useByDate = currentTime.toNumber() + (25 * 86400)
            await vaccination.addBatch(vaccines[i].name, batchId, defrostDate, expiryDate, useByDate, 200);
            console.log(`current Time: ${currentTime}`)
            console.log(`defrost date: ${defrostDate}`)
            console.log(`expiry date: ${expiryDate}`)
            console.log(`use by date: ${useByDate}`)
            console.log(`Adding ${vaccines[i].name} - Batch: ${batchId}`)
        }

    }
    //Approving healthPersons
    console.log(`Approving healthperson: ${accounts[9]}`)
    await vaccination.approveHealthPerson(accounts[9], { from: accounts[2] })
    console.log(`Approving healthperson: ${accounts[8]}`)
    await vaccination.approveHealthPerson(accounts[8], { from: accounts[2] })

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

const checkUser = async (userAddress, network) => {
    console.log(`Checking user ${userAddress}`)
    var provider = new providers.JsonRpcProvider('http://20.124.248.232:8545')
    if (network == 'development') {
        provider = new providers.JsonRpcProvider('http://127.0.0.1:8545')
    }
    let jsonAbi = await fs.readFileSync('./build/contracts/Vaccination.json')
    jsonAbi = jsonAbi.toString()
    jsonAbi = JSON.parse(jsonAbi)


    //   let response = await axios.get('https://raw.githubusercontent.com/prajwolrg/vaccine-solidity/main/build/contracts/Vaccination.json')

    let response = await fs.readFileSync('contractAddresses.json')
    response = response.toString()
    response = JSON.parse(response)
    const contractAddress = response[response.length - 1].contracts['Vaccination']
    console.log(contractAddress)

    const contract = new ethers.Contract(
        contractAddress,
        JSON.stringify(jsonAbi["abi"]),
        provider
    );

    const userDetails = await contract.users(userAddress)
    console.log(jsUser(userDetails))
}

const Gender = ['Male', 'Female', 'Unspecified']

const jsUser = (solUser) => {
    let year_of_birth = BigNumber.from(solUser.year_of_birth)
    year_of_birth = year_of_birth.toNumber()

    let gender = Gender[solUser.gender]

    let vaccine_count = BigNumber.from(solUser.vaccine_count)
    vaccine_count = vaccine_count.toNumber()

    return {
        yearOfBirth: year_of_birth,
        gender: gender,
        namehash: solUser.namehash,
        imagehash: solUser.imagehash,
        vaccine_name: solUser.vaccine_name,
        batches: solUser.batches,
        dateTime: solUser.datetime,
        vaccine_count: vaccine_count,
        registered: solUser.registered
    }
}
