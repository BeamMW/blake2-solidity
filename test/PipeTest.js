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

    it('getContractVariableHash', async () => {
        const beamContractId = Buffer.from('7965a18aefaf3050ccd404482eb919f6641daaf111c7c4a7787c2e932942aa91', 'hex');
        const key = Buffer.from('0255010000', 'hex');
        const value = Buffer.from('a05ea9b3dd329bbf3e8ef68415eae102021f1d9a995d4a727cb3e307e5d17321', 'hex');
        const ret = await pipeContract.getContractVariableHash2.call(beamContractId, 0, key, value);
        assert.equal(ret, '0xbd9dcfaf618e60c370415f153a25cee2d416c4668cb2e82e2e7c579f7d5c5dff', 'hash mismatch');
      })
})