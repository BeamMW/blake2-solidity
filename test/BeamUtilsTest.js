const BeamUtilsTest = artifacts.require('../contracts/BeamUtilsTest.sol');

contract('BeamUtilsTest', function(accounts) {
    let contract;

    beforeEach(async () => {
        contract = await BeamUtilsTest.new();
    })

    it('getContractVariableHash', async () => {
        const beamContractId = Buffer.from('7965a18aefaf3050ccd404482eb919f6641daaf111c7c4a7787c2e932942aa91', 'hex');
        const key = Buffer.from('0255010000', 'hex');
        const value = Buffer.from('a05ea9b3dd329bbf3e8ef68415eae102021f1d9a995d4a727cb3e307e5d17321', 'hex');
        const ret = await contract.getContractVariableHash.call(beamContractId, 0, key, value);
        assert.equal(ret, '0xbd9dcfaf618e60c370415f153a25cee2d416c4668cb2e82e2e7c579f7d5c5dff', 'hash mismatch');
      })

    it('getContractVariableHash2', async () => {
    const key = Buffer.from('7965a18aefaf3050ccd404482eb919f6641daaf111c7c4a7787c2e932942aa9100e1616f165a01e6e6b20df03d7de98e0dee149cf8b0ecf594582ea9bd037102050000000000', 'hex');
    const value = Buffer.from('00ab904100000000', 'hex');
    const ret = await contract.getContractVariableHash2.call(key, value);
    assert.equal(ret, '0xe58afb5015ced46149b90f9b523b7f342311bfdc24759186363dacaf90412519', 'hash mismatch');
    })

    it('interpretMerkleProof', async() => {
        const variableHash = Buffer.from('e58afb5015ced46149b90f9b523b7f342311bfdc24759186363dacaf90412519', 'hex');
        const merkleProof = Buffer.from('01e5c15b6bd9c48e9d9d7984836280eea516d8b9d9a25e7d98de21469a7460e1fd01f65825204cb886084c880f17f2135c67cb6e51b3c30ad3e2b3bfecc5eb0c81a301bfae88566989625c42ff6b2dd3438332739ad242796df792f46eac02f10904d000d7ffd0d10eea5310d85cef2216f1cccdab19f773f1efd44bc4275347d8f97f0700a38cb7799c6f4041e66635f37b30cc3dbe155bf620a9b9880223b7ff4c29d81a00a614208aed844456816d477735f232693591bad6de4e68d298fa9d9374ffaf8e00dcd8a8fda7025a5f9471cbdd40e8a611dee4f4c43b2076771d251fe420f51f2d0151e7b4733fd1278f8bea306b88aa74d9997b851ebcc2de0ed36402dfb9a7bc5900cfd73fa3a781c5f0176dcaf2dc0e64751866eea9823fcc1b7cb8a9bb0fe07b1a', 'hex')

        const ret = await contract.interpretMerkleProof.call(variableHash, merkleProof);
        console.log('Gas usage interpretMerkleProof', await contract.interpretMerkleProof.estimateGas(variableHash, merkleProof));
        assert.equal(ret, '0xbc21610f39454c88438b6a44cb17c1aa1e49b40f5e5eb208a6d2faac4c046cfa');
    })

    it('validateVariable', async () => {
        // masternet block 4508, rules 0x74419f5c71176cf69393af4b0ca53561c46b2f87ec324a7b689163be749528dd
        const height = 4508;
        const prevHash = Buffer.from('6b5307307b88221d01e11989ce1ee4e65e18b42cc8ffa4563c39e65d0532ba6b', 'hex');
        const chainWork = Buffer.from('00000000000000000000000000000000000000000000000000002686695e1f80', 'hex');
        const kernels = Buffer.from('f982e6203e86d8efdfe04d195f7a67b0b1fdeb7cfdf562392abcc5727de0648b', 'hex');
        const definition = Buffer.from('b2522cd2efe3c846533c955bf4dbe20aed96807b2d6652426fff98e7dd93e977', 'hex');
        const timestamp = 1616837602;
        const pow = Buffer.from('0fe131d22c337f6552ca35cb0ed17f438398a01a4ac041b88309503e22535be5abadb25645fe8eedc5edd2d36d66db28f8e5bf57a33c20461ad0b945a967ecc0cfee2f5036f2e261207afe6920a824f5cb8652af1a81648c29c05d42bcbd8b3cfdd485fbe9af975ad8a6ed385c83f53f2b127708', 'hex');

        // Beam pipe OutCheckpoint key:
        // [contract_id,KeyTag::Internal(uint8 0),KeyType::OutCheckpoint(uint8 2),index_BE(uint32 0)]
        const key = Buffer.from('768eb06546abb760582f558ab84a190fe68fa520463c0b1c2cd69406dfbd23e3000200000000', 'hex');
        const value = Buffer.from('99bdbad82c62444a2755efb0139eb550ef0fb42e3955ff45c3ab5ae8b0354a76', 'hex');
        const proof = Buffer.from('019d18796219317ccf50a8dc0f14c799ffab04bfdeb597a23708549269961f10500091a8efc0bea76a0b0a394a7fba8ddefde3fa5458cfb3f51762345128e37bd9a401a21893307dfd35d46d3ae469d7562e02db411ead49cd67e79e0f8b150a2c1e3801b0f63b8ec26716494705761f7df3015982c98959841b85b96efc6142ca6355f800748d5e4bf948f93e2908fc65fe9dd5677b86d9c51d7c4c98d9c385608aa5d17f00237f08f9e288ce829bbb321d66fceb2912e4b00b92b78c9b1019324041e5a6980184152fdd431e172c6b851a3c15471a3977f6a8bd8135a1a4e59066b06ff2cc2d00217f3dd89db59328ff065efb3baf2876ad8544006f4129230a7417c40d330cfc', 'hex');

        const ret = await contract.validateVariable.call(height, prevHash, chainWork, kernels, definition, timestamp, pow, key, value, proof);
        assert.equal(ret, true, 'output mismatch');
    })

    it('testMul512', async () => {
        const a = Buffer.from('7b102c50bcf70715753c3e74efa6db72604109ae0e9445dc5af126fdec353391', 'hex');
        const b = Buffer.from('f684fb35782bc3616b6b2aab3a5af70766e4a721c78fa6e2cf38a9f5ebc9b56f', 'hex');

        const {r0, r1} = await contract.testMul512.call(a, b);
        assert.equal(r0, '0xeef900aa6f55c37358864c08211ceaf5121da55ae9a70b445901cefba05fe0df');
        assert.equal(r1, '0x768177aefec7c4950977f29b28b3ec899a8d36dfc8c5e42b8e0164b161c2f393');
    })

    it('testMul512_2', async () => {
        const a = Buffer.from('1c1f89bfdb1dc6fad729188baf38ea23f34dea6f8552e9e48b73af353d5b6199', 'hex');
        const b = Buffer.from('ade0293f77aabfb01abfa2e7ed3ed81a52c8805bf3d7eafd527e552edf7bb825', 'hex');

        const {r0, r1} = await contract.testMul512.call(a, b);
        assert.equal(r0, '0xf235d735c7826a737db83509a0dde15ac371356d7236c7da45cf0235b7de131d');
        assert.equal(r1, '0x1319f03734eae4dcd8bca0cdb249704231ca731f5c9f2a0b68ccf18ce84a31d7');
    })

    it('isDifficultyTargetReached', async () => {
        {
            const rawDifficulty = Buffer.from('00000000000000000000000e0c7b600000000000000000000000000000000000', 'hex');
            const target = Buffer.from('00000000000000000000000000000000001238e5814f388e87fecdfe89ed82a5', 'hex');

            const ret = await contract.isDifficultyTargetReached.call(rawDifficulty, target);
            assert.equal(ret, true, 'output mismatch');
        }
        {        
            const rawDifficulty = Buffer.from('00000000000000000000000e0c7b600000000000000000000000000000000000', 'hex');
            const target = Buffer.from('00000000000000000000000000000000001238e5814f388e87fecdfe89ed82a6', 'hex');

            const ret = await contract.isDifficultyTargetReached.call(rawDifficulty, target);
            assert.equal(ret, false, 'output mismatch');
        }
        {
            const rawDifficulty = Buffer.from('000000000000000000000000000000000000000000000000018e9f8e00000000', 'hex');
            const target = Buffer.from('00000000a467e672a5492a5f4276eaf33524b86b7989954fb9ac087732fcebd2', 'hex');

            const ret = await contract.isDifficultyTargetReached.call(rawDifficulty, target);
            assert.equal(ret, true, 'output mismatch');
        }
        {
            const rawDifficulty = Buffer.from('000000000000000000000000000000000000000000000000018e9f8e00000000', 'hex');
            const target = Buffer.from('00000000a467e672a5492a5f4276eaf33524b86b7989954fb9ac087733fcebd2', 'hex');

            const ret = await contract.isDifficultyTargetReached.call(rawDifficulty, target);
            assert.equal(ret, false, 'output mismatch');
        }
    })
})
