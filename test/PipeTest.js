const Pipe = artifacts.require('../contracts/Pipe.sol');
const PipeUser = artifacts.require('../contracts/PipeUser.sol');
const BeamToken = artifacts.require('../contracts/BeamToken.sol');

contract('Pipe', function(accounts) {
    let beamToken;
    let pipeContract;
    let userContract;
    let supply = BigInt(100000000000000000000); // 100 TEST coins

    beforeEach(async () => {
        beamToken = await BeamToken.new(supply);
        
        pipeContract = await Pipe.new();
        userContract = await PipeUser.new(pipeContract.address, beamToken.address);

        await beamToken.transfer(userContract.address, supply);
    })

    it('stadard case', async() => {
        let receiver = accounts[1];
        let value = 5000;
        await pipeContract.pushRemoteMessage(receiver, value);
        await pipeContract.validateRemoteMessage(receiver);

        await userContract.proccessMessage(receiver);

        let receiverBalance = await beamToken.balanceOf(receiver);

        console.log('balance = ', receiverBalance.toString());
    })
})