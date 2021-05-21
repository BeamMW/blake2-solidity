const Blake2bTest = artifacts.require('Blake2bTest.sol');
const TestVectors = require('./blake2ref/testvectors/blake2-kat.json');

contract('Blake2bTest', function (accounts) {
    let contract;

    before(async () => {
        contract = await Blake2bTest.new();
    });

    it('smoke', async () => {
        let ret = await contract.testOneBlock.call(Buffer.alloc(0), 0);
        assert.equal(ret, '0x28c9bdf267e6096a3ba7ca8485ae67bb2bf894fe72f36e3cf1361d5f3af54fa5', 'hash mismatch');
    });

    it('eip-152 test vector 5', async () => {
        let input = Buffer.from('6162630000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000', 'hex');
        let ret = await contract.testOneBlock.call(input, 3);
        assert.equal(ret, '0xbddd813c634239723171ef3fee98579b94964e3bb1cb3e427262c8c068d52319', 'hash mismatch');
    });

    it('blake2b reftest (8 bytes input)', async () => {
        let input = Buffer.from('0001020304050607000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000', 'hex');
        let ret = await contract.testOneBlock.call(input, 8);
        assert.equal(ret, '0x77065d25b622a8251094d869edf6b4e9ba0708a8db1f239cb68e4eeb45851621', 'hash mismatch');
    });

    it('blake2b reftest (25 bytes input)', async () => {
        let input = Buffer.from('000102030405060708090a0b0c0d0e0f10111213141516171800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000', 'hex');
        let ret = await contract.testOneBlock.call(input, 25);
        assert.equal(ret, '0x3b0b9b4027203daeb62f4ff868ac6cdd78a5cbbf7664725421a613794702f4f4', 'hash mismatch');
    });

    it('blake2b reftest (255 bytes input)', async () => {
        let input = Buffer.from('000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f202122232425262728292a2b2c2d2e2f303132333435363738393a3b3c3d3e3f404142434445464748494a4b4c4d4e4f505152535455565758595a5b5c5d5e5f606162636465666768696a6b6c6d6e6f707172737475767778797a7b7c7d7e7f808182838485868788898a8b8c8d8e8f909192939495969798999a9b9c9d9e9fa0a1a2a3a4a5a6a7a8a9aaabacadaeafb0b1b2b3b4b5b6b7b8b9babbbcbdbebfc0c1c2c3c4c5c6c7c8c9cacbcccdcecfd0d1d2d3d4d5d6d7d8d9dadbdcdddedfe0e1e2e3e4e5e6e7e8e9eaebecedeeeff0f1f2f3f4f5f6f7f8f9fafbfcfdfe00', 'hex');
        let ret = await contract.testOneBlock.call(input, 255);
        assert.equal(ret, '0x1d0850ee9bca0abc9601e9deabe1418fedec2fb6ac4150bd5302d2430f9be943', 'hash mismatch');
    });

    it('equihash n=200 k=9 synthethic', async () => {
        let ret = await contract.equihashTestN200K9.call();
        assert.equal(ret.toString(), '14394687529728284581040569373478606499820061758322408099941575726000591405977', 'output mismatch');
        console.log('Gas usage', await contract.equihashTestN200K9.estimateGas());
    });

    /*it('blake2b reference test vectors', async () => {
        for (var i in TestVectors) {
            const testCase = TestVectors[i];
            if (testCase.hash !== 'blake2b' || testCase.key.length !== 0) {
                continue;
            }

            let input = Buffer.from(testCase.in, 'hex');
            let input_length = input.length;
            // Pad with zeroes.
            // FIXME: this should not be needed once the library is finished.
            if (input_length === 0 || (input_length % 128) !== 0) {
                input = Buffer.concat([input, Buffer.alloc(128 - (input_length % 128))]);
            }

            let ret = await contract.testOneBlock.call(input, input_length);
            assert.equal(ret, '0x' + testCase.out, 'hash mismatch');
        }
    });*/
});
