// This file is MIT Licensed.
//
// Copyright 2017 Christian Reitwiessner
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
// The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
pragma solidity ^0.8.0;
library Pairing {
    struct G1Point {
        uint X;
        uint Y;
    }
    // Encoding of field elements is: X[0] * z + X[1]
    struct G2Point {
        uint[2] X;
        uint[2] Y;
    }
    /// @return the generator of G1
    function P1() pure internal returns (G1Point memory) {
        return G1Point(1, 2);
    }
    /// @return the generator of G2
    function P2() pure internal returns (G2Point memory) {
        return G2Point(
            [10857046999023057135944570762232829481370756359578518086990519993285655852781,
             11559732032986387107991004021392285783925812861821192530917403151452391805634],
            [8495653923123431417604973247489272438418190587263600148770280649306958101930,
             4082367875863433681332203403145435568316851327593401208105741076214120093531]
        );
    }
    /// @return the negation of p, i.e. p.addition(p.negate()) should be zero.
    function negate(G1Point memory p) pure internal returns (G1Point memory) {
        // The prime q in the base field F_q for G1
        uint q = 21888242871839275222246405745257275088696311157297823662689037894645226208583;
        if (p.X == 0 && p.Y == 0)
            return G1Point(0, 0);
        return G1Point(p.X, q - (p.Y % q));
    }
    /// @return r the sum of two points of G1
    function addition(G1Point memory p1, G1Point memory p2) internal view returns (G1Point memory r) {
        uint[4] memory input;
        input[0] = p1.X;
        input[1] = p1.Y;
        input[2] = p2.X;
        input[3] = p2.Y;
        bool success;
        assembly {
            success := staticcall(sub(gas(), 2000), 6, input, 0xc0, r, 0x60)
            // Use "invalid" to make gas estimation work
            switch success case 0 { invalid() }
        }
        require(success);
    }


    /// @return r the product of a point on G1 and a scalar, i.e.
    /// p == p.scalar_mul(1) and p.addition(p) == p.scalar_mul(2) for all points p.
    function scalar_mul(G1Point memory p, uint s) internal view returns (G1Point memory r) {
        uint[3] memory input;
        input[0] = p.X;
        input[1] = p.Y;
        input[2] = s;
        bool success;
        assembly {
            success := staticcall(sub(gas(), 2000), 7, input, 0x80, r, 0x60)
            // Use "invalid" to make gas estimation work
            switch success case 0 { invalid() }
        }
        require (success);
    }
    /// @return the result of computing the pairing check
    /// e(p1[0], p2[0]) *  .... * e(p1[n], p2[n]) == 1
    /// For example pairing([P1(), P1().negate()], [P2(), P2()]) should
    /// return true.
    function pairing(G1Point[] memory p1, G2Point[] memory p2) internal view returns (bool) {
        require(p1.length == p2.length);
        uint elements = p1.length;
        uint inputSize = elements * 6;
        uint[] memory input = new uint[](inputSize);
        for (uint i = 0; i < elements; i++)
        {
            input[i * 6 + 0] = p1[i].X;
            input[i * 6 + 1] = p1[i].Y;
            input[i * 6 + 2] = p2[i].X[1];
            input[i * 6 + 3] = p2[i].X[0];
            input[i * 6 + 4] = p2[i].Y[1];
            input[i * 6 + 5] = p2[i].Y[0];
        }
        uint[1] memory out;
        bool success;
        assembly {
            success := staticcall(sub(gas(), 2000), 8, add(input, 0x20), mul(inputSize, 0x20), out, 0x20)
            // Use "invalid" to make gas estimation work
            switch success case 0 { invalid() }
        }
        require(success);
        return out[0] != 0;
    }
    /// Convenience method for a pairing check for two pairs.
    function pairingProd2(G1Point memory a1, G2Point memory a2, G1Point memory b1, G2Point memory b2) internal view returns (bool) {
        G1Point[] memory p1 = new G1Point[](2);
        G2Point[] memory p2 = new G2Point[](2);
        p1[0] = a1;
        p1[1] = b1;
        p2[0] = a2;
        p2[1] = b2;
        return pairing(p1, p2);
    }
    /// Convenience method for a pairing check for three pairs.
    function pairingProd3(
            G1Point memory a1, G2Point memory a2,
            G1Point memory b1, G2Point memory b2,
            G1Point memory c1, G2Point memory c2
    ) internal view returns (bool) {
        G1Point[] memory p1 = new G1Point[](3);
        G2Point[] memory p2 = new G2Point[](3);
        p1[0] = a1;
        p1[1] = b1;
        p1[2] = c1;
        p2[0] = a2;
        p2[1] = b2;
        p2[2] = c2;
        return pairing(p1, p2);
    }
    /// Convenience method for a pairing check for four pairs.
    function pairingProd4(
            G1Point memory a1, G2Point memory a2,
            G1Point memory b1, G2Point memory b2,
            G1Point memory c1, G2Point memory c2,
            G1Point memory d1, G2Point memory d2
    ) internal view returns (bool) {
        G1Point[] memory p1 = new G1Point[](4);
        G2Point[] memory p2 = new G2Point[](4);
        p1[0] = a1;
        p1[1] = b1;
        p1[2] = c1;
        p1[3] = d1;
        p2[0] = a2;
        p2[1] = b2;
        p2[2] = c2;
        p2[3] = d2;
        return pairing(p1, p2);
    }
}

contract Verifier {
    using Pairing for *;
    struct VerifyingKey {
        Pairing.G1Point alpha;
        Pairing.G2Point beta;
        Pairing.G2Point gamma;
        Pairing.G2Point delta;
        Pairing.G1Point[] gamma_abc;
    }
    struct Proof {
        Pairing.G1Point a;
        Pairing.G2Point b;
        Pairing.G1Point c;
    }
    function verifyingKey() pure internal returns (VerifyingKey memory vk) {
        vk.alpha = Pairing.G1Point(uint256(0x04191030b2a0bf52e9fa5007a255dcdb91767f879721b8e600f7741f21f3797c), uint256(0x0c66121e95961e1fda9e722e903ee05b75c8f34dd95e270287b171df28d12702));
        vk.beta = Pairing.G2Point([uint256(0x2162792bd51627e31d0c1c95a089cb5573f3a6433301d8dfbe0e58887dc1266c), uint256(0x141011d4203d15a2dcec57caa72785e80904232f681da3daf3d557504e4b53ae)], [uint256(0x0fe25404af9cac36f2d4faf387ccc774f725bb6e9a6230cb4382b5f1a3bc8b5d), uint256(0x2d526e49b3e95eb69c1df6d8124e8ba774955d0e8b787e35ea083bca96fde91b)]);
        vk.gamma = Pairing.G2Point([uint256(0x042705f7c3fa4e15c4dae6f418e816e39828be9c2e56f871fdbe39c4c5a980b4), uint256(0x299b5c30622f780146b94489321aa740ed34f06cc01bd09db204f69fbae049a5)], [uint256(0x0c68cacb7e60054c6b6eb45127ce75b0aa512a9b8b4bbe100e52196e6a5146f4), uint256(0x0c1483465156eef0f697d974a2fef873850e3aefc7e3780845c4cc6b5f3d7ffe)]);
        vk.delta = Pairing.G2Point([uint256(0x0f8ccc6b254d858143ef12df69217716def45e57b42a41de1f3f2931ba3c82e3), uint256(0x1cc98312fb9f0b5a7ee145ba07052a886630eef995386ce0186bcdbac7df5adf)], [uint256(0x1c58e0e991052624fcdef22bc63c86e78727654a308c1013f1160be16a1690b1), uint256(0x1f60bb63d800e54406968b218d7048af12b01481b837c171a352486047d80c54)]);
        vk.gamma_abc = new Pairing.G1Point[](8);
        vk.gamma_abc[0] = Pairing.G1Point(uint256(0x0585c97b50e111c08b2f931d1bf26760915df1b33aef9b1bceb757f6926cfbc7), uint256(0x1ca8e01aec5146546b9ac6f637877e37c2b512c7dd1ace5f059eb8f69c38427a));
        vk.gamma_abc[1] = Pairing.G1Point(uint256(0x077e7f404e8a88719e1428558ae8f874b92dfd4ece9628f9979dde838d385f6b), uint256(0x1f1a8b5af6a388d90f61581c0f3117b6910f18a8bb13387c6ca232328b8201c7));
        vk.gamma_abc[2] = Pairing.G1Point(uint256(0x06ba59fadd115c05d5ddc2e3f77a152524068e37595aef5581c2fbe1892430f6), uint256(0x132fedde0b992d91bfecb14c5f5f0c20e516791bfcef5bb3f7855d59d86c99b7));
        vk.gamma_abc[3] = Pairing.G1Point(uint256(0x2a8796f5254f84bb3b5a911830c0d0e40d6aaa48ce2a39c38a7cde96fd061828), uint256(0x2ff854480642847cf34c6a4c60fe7631f3ac45e735078737e9c791eea52df49a));
        vk.gamma_abc[4] = Pairing.G1Point(uint256(0x185d8552395291fac3e7679db288fefd9e1277d52ff1660beb887a478e4b0398), uint256(0x1ddf13d97dd43e8f1d9e847b3b91dad5c86e3d3ee78661b93a71f7941789042d));
        vk.gamma_abc[5] = Pairing.G1Point(uint256(0x0e284b62ac3daddecf8c4b9db24a922ae9aa9910a84206b28b12ca74335f269d), uint256(0x28bcd919bb4034d38213fa592d8c1899455833a1f141279fbe187bca5228fb40));
        vk.gamma_abc[6] = Pairing.G1Point(uint256(0x2bde39a249080296735d06b41f444f6dcc8c18924130a502696e5aabc0a78302), uint256(0x06f7abbe442a04113ceab07eca5ed753302cd719ccb14433f41506fca70f063c));
        vk.gamma_abc[7] = Pairing.G1Point(uint256(0x0dfc24929891b08a05814563791c13abdfbd455efaff4508c6459e471917c0d7), uint256(0x2fb894722685e2bee723965de0e290da04671a40d7c9d8f67212d2872e01ddf3));
    }
    function verify(uint[] memory input, Proof memory proof) internal view returns (uint) {
        uint256 snark_scalar_field = 21888242871839275222246405745257275088548364400416034343698204186575808495617;
        VerifyingKey memory vk = verifyingKey();
        require(input.length + 1 == vk.gamma_abc.length);
        // Compute the linear combination vk_x
        Pairing.G1Point memory vk_x = Pairing.G1Point(0, 0);
        for (uint i = 0; i < input.length; i++) {
            require(input[i] < snark_scalar_field);
            vk_x = Pairing.addition(vk_x, Pairing.scalar_mul(vk.gamma_abc[i + 1], input[i]));
        }
        vk_x = Pairing.addition(vk_x, vk.gamma_abc[0]);
        if(!Pairing.pairingProd4(
             proof.a, proof.b,
             Pairing.negate(vk_x), vk.gamma,
             Pairing.negate(proof.c), vk.delta,
             Pairing.negate(vk.alpha), vk.beta)) return 1;
        return 0;
    }
    function verifyTx(
            Proof memory proof, uint[7] memory input
        ) public view returns (bool r) {
        uint[] memory inputValues = new uint[](7);
        
        for(uint i = 0; i < input.length; i++){
            inputValues[i] = input[i];
        }
        if (verify(inputValues, proof) == 0) {
            return true;
        } else {
            return false;
        }
    }
}
