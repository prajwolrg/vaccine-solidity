const Government = artifacts.require("Government");
const Organization = artifacts.require("Organization");
const Vaccine = artifacts.require("Vaccine");
const OrganizationFactory = artifacts.require("OrganizationFactory")
const VaccineFactory = artifacts.require("VaccineFactory")

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

organizations = [
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



module.exports = async function (deployer, network, accounts) {
    console.log(network)
    console.log(accounts)
    var tx_result;

    await deployer.deploy(Government, 'Nepal', 'NP', 'np_ipfs_hash');
    const govt = await Government.deployed();
    console.log(`Government contract deployed: ${Government.address}`)

    await deployer.deploy(OrganizationFactory)
    const orgFactory = await OrganizationFactory.deployed()

    for (let i=0; i <organizations.length; i++) {
        console.log(`Adding organization ${organizations[i].name}: ${accounts[1 + i]}`)
        await orgFactory.createOrganization(
            Government.address,
            organizations[i]['name'],
            organizations[i]['url'],
            organizations[i]['logo_hash'],
            organizations[i]['document_hash'],
            organizations[i]['location'],
            organizations[i]['phone'],
            organizations[i]['email'],

            { from: accounts[1 + i] })
        console.log(`Approving organization ${organizations[i].name}: ${accounts[1 + i]}`)
    }

    const orgAddresses = await orgFactory.getOrganizations()
    console.log(tx_result)

    tx_result = await orgFactory.getOrganizationDetails(orgAddresses[0])
    console.log(tx_result)

    tx_result = await orgFactory.getAllOrganizationsWithDetails()
    console.log(tx_result)

    await deployer.deploy(VaccineFactory)
    const vFactory = await VaccineFactory.deployed()
    console.log('Vaccine Factory')

    await govt.approveOrganization(orgAddresses[0]);
    console.log(`Organization approved.`)

    await deployer.deploy(Vaccine, 'Verocell', 'VC');
    const verocell = await Vaccine.deployed();
    console.log(`Vaccine contract deployed: ${Vaccine.address}`)

    const currentTime = Date.now();
    const defrostDate = Math.floor((currentTime - (1 * 86400)) / 1000)
    const expiryDate = Math.floor((currentTime + (30 * 86400)) / 1000)
    const useByDate = Math.floor((currentTime + (25 * 86400)) / 1000)
    await verocell.addBatch('101', defrostDate, expiryDate, useByDate, 200)
    await verocell.addBatch('102', defrostDate, expiryDate, useByDate, 200)

    await govt.registerIndividual(1999, 0, 'prajwolhash', 'imagehash', { from: accounts[9] });
    await govt.registerIndividual(1999, 0, 'prajwolhash', 'imagehash', { from: accounts[8] });

    await verocell.transfer(orgAddresses[0], '101', 10);
    await verocell.transfer(orgAddresses[0], '102', 10);
    console.log(`Vaccine batch added: 101 and 102`)

    const org = await Organization.at(orgAddresses[0])
    console.log(`Individual registered.`)
    await org.approveHealthPerson(accounts[9]);
    console.log(`Individual approved as healthperson.`)

    tx_result = await org.getApprovedHealthPersons()
    console.log(tx_result)

    await org.vaccinate(accounts[8], Vaccine.address, '101', { from: accounts[9] });

};
