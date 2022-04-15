const Government = artifacts.require("Government");
const Organization = artifacts.require("Organization");
const Vaccine = artifacts.require("Vaccine");
const OrganizationFactory = artifacts.require("OrganizationFactory")
const VaccineFactory = artifacts.require("VaccineFactory")

const { ethers } = require("ethers");
const fs = require('fs');

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

const organizations = [
    {
        'name': 'Grande International Hospital',
        'url': 'https://www.grandehospital.com/',
        'logo_hash': 'bafybeib3toxyr6lmcdlzek2is5idtzlrfcheilby3ls64vkqg3actwoora',
        'document_hash': 'bafybeigxzmvpldldmag5goksedjlfgb62yclqjzv5oix3vkhv2mhwmhq4q',
        'location': '27.753094359189657, 85.3258460820991',
        'phone': '+977-1-5159266,',
        'email': 'info@grandehospital.com',
    },
    {
        'name': 'Norvic International Hospital',
        'url': 'https://www.norvichospital.com/',
        'logo_hash': 'bafybeieit4ymr72soz7ceaiatfsnutefl5sroqanwgnlpzlmugbliegd5y',
        'document_hash': 'bafybeifgmtjxhbgc4fpbuclhw55hp5q6zv2zxuutune27cf2vbhnvctlai',
        'location': '27.690222585866792, 85.31913930908078',
        'email': 'info@norvichospital.com',
        'phone': '+977 1-5970032',
    },
    {
        'name': 'Nepal Mediciti Hospital',
        'url': 'https://www.nepalmediciti.com/',
        'logo_hash': 'bafybeiasjbr55o65vh43if7swweaflbnclk3fei4g7idpzyqn27t7ph2dm',
        'document_hash': 'bafybeibsupaycibuy3i2qgzxbvmzvkgi6ur23mgjc5ecja27g7de57wmni',
        'location': '27.66259787526539, 85.30307300001515',
        'email': 'info@nepalmediciti.com',
        'phone': '+977-1-4217766',
    },
]

const vaccines = [
    {
        "name": "CoronaVac",
        "schedule": [0, 14],
        "platform": "IV",
        "route": "IM",
        "developers ": "Sinovac Research and Development Co., Ltd",
        "ipfs_hash": "ipfs_hash",
    },
    {
        "name": "Verocell",
        "schedule": [0, 21],
        "platform": "IV",
        "route": "IM",
        "developers ": "Sinopharm; China National Biotec Group Co;Wuhan Institute of Biological Products ",
        "ipfs_hash": "ipfs_hash"
    },
    {
        "name": "Vaxzevria",
        "schedule": [0, 28],
        "platform": "VVnr",
        "route": "IM",
        "developers ": "AstraZeneca; University of Oxford",
        "ipfs_hash": "ipfs_hash"
    },
    // {
    //     "name": "Adenovirus",
    //     "schedule": [0],
    //     "platform": "VVnr",
    //     "route": "IM ",
    //     "developers ": "CanSino Biological Inc.; Beijing Institute of Biotechnology",
    //     "ipfs_hash": "ipfs_hash"
    // },
    // {
    //     "name": "Sputnik V",
    //     "schedule": [0, 21],
    //     "platform": "VVnr",
    //     "route": "IM",
    //     "developers ": "Gamaleya Research Institute ; Health Ministry of the Russian Federation\n",
    //     "ipfs_hash": "ipfs_hash"
    // },
    // {
    //     "name": "Ad26.COV2.S",
    //     "schedule": [0, 56],
    //     "platform": "VVnr",
    //     "route": "IM",
    //     "developers ": "Janssen Pharmaceutical; Johnson & Johnson",
    //     "ipfs_hash": "ipfs_hash"
    // },
    // {
    //     "name": "Spikevax",
    //     "schedule": [0, 28],
    //     "platform": "RNA",
    //     "route": "IM",
    //     "developers ": "Moderna;  National Institute of Allergy and Infectious Diseases (NIAID)",
    //     "ipfs_hash": "ipfs_hash"
    // },
    // {
    //     "name": "Comirnaty",
    //     "schedule": [0, 21],
    //     "platform": "RNA",
    //     "route": "IM",
    //     "developers ": " Pfizer\/BioNTech; Fosun Pharma ",
    //     "ipfs_hash": "ipfs_hash"
    // },
    // {
    //     "name": "Zifivax ",
    //     "schedule": [0, 28, 56],
    //     "platform": "PS",
    //     "route": "IM",
    //     "developers ": "Chinese Academy of Sciences",
    //     "ipfs_hash": "ipfs_hash"
    // },
    // {
    //     "name": "CVnCoV Vaccine",
    //     "schedule": [0, 28],
    //     "platform": "RNA",
    //     "route": "IM",
    //     "developers ": "CureVac AG",
    //     "ipfs_hash": "ipfs_hash"
    // },
    // {
    //     "name": "QazCovid",
    //     "schedule": [0, 21],
    //     "platform": "IV",
    //     "route": "IM",
    //     "developers ": "Research Institute for Biological Safety Problems, Rep of Kazakhstan",
    //     "ipfs_hash": "ipfs_hash"
    // },
    // {
    //     "name": "INO-4800",
    //     "schedule": [0, 28],
    //     "platform": "IV",
    //     "route": "ID ",
    //     "developers ": "Inovio Pharmaceuticals;  International Vaccine Institute;  Advaccine ",
    //     "ipfs_hash": "ipfs_hash"
    // },
    // {
    //     "name": "Covaxine",
    //     "schedule": [0, 14],
    //     "platform": "DNA",
    //     "route": "IM",
    //     "developers ": "Bharat Biotech International Limited",
    //     "ipfs_hash": "ipfs_hash"
    // }
]

module.exports = async function (deployer, network, accounts) {
    console.log(network)
    console.log(accounts)
    var tx_result;

    await deployer.deploy(OrganizationFactory)
    const orgFactory = await OrganizationFactory.deployed()

    await deployer.deploy(VaccineFactory)
    const vFactory = await VaccineFactory.deployed()

    await deployer.deploy(Government, 'Nepal', 'NP', 'np_ipfs_hash', VaccineFactory.address, OrganizationFactory.address);
    const govt = await Government.deployed();

    // Adding organizations
    for (let i = 0; i < organizations.length; i++) {
        console.log(`Adding organization ${organizations[i].name}: ${accounts[1 + i]}`)
        await orgFactory.createOrganization(
            Government.address,
            organizations[i]['name'],
            organizations[i]['url'],
            organizations[i]['logo_hash'],
            organizations[i]['document_hash'],
            organizations[i]['location'],
            organizations[i]['phone'],
            organizations[i]['email'])
    }

    const orgAddresses = await orgFactory.getOrganizationAddresses()
    const org = await Organization.at(orgAddresses[0])
    await govt.approveOrganization(orgAddresses[0])

    // Adding vaccines
    for (let i = 0; i < vaccines.length; i++) {
        console.log(`Adding vaccine ${vaccines[i].name}`)
        await vFactory.createVaccine(
            vaccines[i].name,
            vaccines[i].schedule,
            vaccines[i].platform,
            vaccines[i].route,
            vaccines[i].ipfs_hash
        )
    }

    const vaccineAddresses = await vFactory.getVaccineAddresses()
    //Adding vaccine batches
    for (let i = 0; i < vaccineAddresses.length; i++) {
        var vaccine = await Vaccine.at(vaccineAddresses[i])
        const noOfBatches = 2;
        batches = makeBatches(noOfBatches, 8)
        for (let j = 0; j < batches.length; j++) {
            var batchId = batches[j].batchId
            console.log(`Adding batch ${batchId} for vaccine ${vaccines[i].name}`)
            var currentTime = Date.now();
            var defrostDate = Math.floor((currentTime - (1 * 86400)) / 1000)
            var expiryDate = Math.floor((currentTime + (30 * 86400)) / 1000)
            var useByDate = Math.floor((currentTime + (25 * 86400)) / 1000)
            await vaccine.addBatch(batchId, defrostDate, expiryDate, useByDate ,batches[j].units);
        }
    }

    const verocell = await Vaccine.at(vaccineAddresses[1])
    currentTime = Date.now();
    defrostDate = Math.floor((currentTime - (1 * 86400)) / 1000)
    expiryDate = Math.floor((currentTime + (30 * 86400)) / 1000)
    useByDate = Math.floor((currentTime + (25 * 86400)) / 1000)
    await verocell.addBatch('101', defrostDate, expiryDate, useByDate, 200)
    await verocell.addBatch('102', defrostDate, expiryDate, useByDate, 200)
    console.log(`Vaccine batch added: 101 and 102`)

    await verocell.transfer(orgAddresses[0], '101', 10);
    await verocell.transfer(orgAddresses[0], '102', 10);

    tx_result = await verocell.getAllBatches()
    console.log(tx_result)
    tx_result = await verocell.getBatchDetails('101')
    console.log(tx_result)
    // tx_result = await verocell.getAllBatchesWithDetails()
    // console.log(tx_result)

    for (i = 0; i < userAccounts.length; i++) {
        console.log(`Adding user ${userAccounts[i].name}: ${accounts[6 + i]}`)
        await govt.registerIndividual(
            userAccounts[i]['yearOfBirth'],
            userAccounts[i]['gender'],
            ethers.utils.id(userAccounts[i]['name']),
            userAccounts[i]['ipfs_hash'],
            { from: accounts[6 + i] })
    }
    await org.approveHealthPerson(accounts[9], { gasLimit: '0x27100', gasPrice: '0x09184e72a00' });

    await org.vaccinate(accounts[8], vaccineAddresses[1], '101', { from: accounts[9] });

    // tx_result = await govt.getUser(accounts[8])
    // console.log(tx_result)

    if (network == 'private') {
        console.log('Adding data to contractAddresses')
        await addContractAddresses({
            'vaccineFactory': VaccineFactory.address,
            'organizationFactory': OrganizationFactory.address,
            'government': Government.address
        })
    }
};

const addContractAddresses = async (contracts) => {
    const date = new Date()
    const dateString = date.toString()
    const newdata = {
        'time': dateString,
        'contracts': contracts
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

function makeBatch(length) {
    var result = '';
    var characters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    var numerals = '1234567890';
    var charactersLength = characters.length;
    var i = 0;
    for (i; i < 2; i++) {
        result += characters.charAt(Math.floor(Math.random() * charactersLength));
    }
    for (i; i < length; i++) {
        result += numerals.charAt(Math.floor(Math.random() * numerals.length))
    }

    const units = Math.floor(Math.random() * 1000)

    return {
        'batchId': result,
        'units': units
    };
}

function makeBatches(number, length) {
    var batches = []
    for (let i = 0; i < number; i++) {
        let batch = makeBatch(length);
        batches.push(batch);
    }
    return batches;
}