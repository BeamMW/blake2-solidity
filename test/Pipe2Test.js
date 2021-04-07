const Pipe = artifacts.require('../contracts/Pipe.sol');
const PipeUser = artifacts.require('../contracts/PipeUser.sol');
const BeamToken = artifacts.require('../contracts/BeamToken.sol');

contract('Pipe2', function(accounts) {
    let beamToken;
    let pipeA;
    let pipeB;
    let userA;
    let userB;
    let supply = BigInt(200000000000000000000); // 100 TEST coins
    let toContract = BigInt(100000000000000000000); // 100 TEST coins

    beforeEach(async () => {
        beamToken = await BeamToken.new(supply);
        
        pipeA = await Pipe.new();
        pipeB = await Pipe.new();
        userA = await PipeUser.new(pipeA.address, beamToken.address);
        userB = await PipeUser.new(pipeB.address, beamToken.address);

        await beamToken.transfer(userB.address, toContract);
    })

    // TODO: fix ?
    // it('two pipe', async() => {
    //     let receiver = accounts[1];
    //     let value = 5000;

    //     await beamToken.approve(userA.address, value);
    //     await userA.lock(receiver, value);

    //     let msg = await pipeA.getLocalMessageToSend();

    //     /*console.log('r', msg.receiver);
    //     console.log('v', msg.value);*/

    //     let r = msg.receiver;
    //     let v = msg.value;

    //     await pipeB.pushRemoteMessage(r, v);
    //     await pipeB.validateRemoteMessage(r);
    //     await userB.proccessMessage(r);

    //     let receiverBalance = await beamToken.balanceOf(receiver);

    //     console.log('balance = ', receiverBalance.toString());
    // })
})