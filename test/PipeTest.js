const Pipe = artifacts.require('../contracts/Pipe.sol');
const PipeUser = artifacts.require('../contracts/PipeUser.sol');
const BeamToken = artifacts.require('../contracts/BeamToken.sol');

contract('Pipe', function(accounts) {
    let beamToken;
    let pipeContract;
    let userContract;
    let supply = BigInt(100000000000); // 1000 TEST coins

    beforeEach(async () => {
        beamToken = await BeamToken.new(supply);
        
        pipeContract = await Pipe.new();
        userContract = await PipeUser.new(pipeContract.address, beamToken.address);

        await beamToken.transfer(userContract.address, supply);
    })

    it('stadard case', async() => {
        let receiver = accounts[1];
        let beamPipeContractId = Buffer.from('888e2f37e1d16606dffbd079d206f135d80eaef287976ab1b3aa54f2d6b41fd2', 'hex');

        let packageId = 3;
        let msgId = 1;
        let msgSender = Buffer.from('30fb852e06679d6639418cded099687b9f935dfd8cca959a9a44741bfc877195', 'hex');
        let msgReceiver = Buffer.from('30fb852e06679d6639418cded099687b9f935dfd8cca959a9a44741bfc877195', 'hex');
        let messageBody = Buffer.from('f17f52151ebef6c7334fad080c5704d77216b732000000000000000000000000000037178900000000', 'hex')

        await pipeContract.setRemote(beamPipeContractId);
        await pipeContract.pushRemoteMessage(packageId, msgId, msgSender, msgReceiver, messageBody);

        const height = 1455;
        const prevHash = Buffer.from('1b8b59d41e200ff5228d0b94fbe5c0377ad86475bba98dd452be7099634e08be', 'hex');
        const chainWork = Buffer.from('00000000000000000000000000000000000000000000000000028c90c18d7300', 'hex');
        const kernels = Buffer.from('78f7c7fb0a3ed60c008b3973d8715e84df3d41ddcabe9d999ad1723369b58410', 'hex');
        const definition = Buffer.from('9a4e7cdc76a9ad63bbc439253b348ea529f5f4f9bb22e9a7a34ec576a0f5fba5', 'hex');
        const timestamp = 1617803205;
        const pow = Buffer.from('000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000088386aa5e9f1e831b51e0810', 'hex');
        const rulesHash = Buffer.from('67cba123218c10c34ea3cb41d2d472ecbdc1fb58027cd3d7efed33a4c46cde87', 'hex');

        const proof = Buffer.from('01883621774b2d3fa4f18b378b52b8d0892177de1d5ea8a2a7da95961edb1e4e6c0143372f55884e55edcf0370a43c9a1cae7b1680359a7b9b544d0ba1dcd012299c015ad58346c0f7d458f2010d324fa48717fd642f03eff543ddaeb9afdc00a0c9820012f045112e66cfe9aa22dc7a4e5000724c2435568d3d6179e8a2200d348883cc00da5ca12eb03a0ff0eda4aeb3b5328950db3b350ac31abf8151079df44a51fb0c01f5a5fd42d16a20302798ef6ed309979b43003d2320d9f0e8ea9831a92759fb4b00b9bf4c98cba4e04d9510743a991e388db6d90db4d829b902e2ca6d48a9027f6f', 'hex');

        await pipeContract.validateRemoteMessage(packageId, msgId, prevHash, chainWork, kernels, definition, height, timestamp, pow, rulesHash, proof);

        await userContract.proccessMessage(packageId, msgId);

        let receiverBalance = await beamToken.balanceOf(receiver);

        console.log('balance = ', receiverBalance.toString());
        assert.equal(receiverBalance.toString(), 2300000000, 'output mismatch');
    })
})