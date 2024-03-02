# A blockchain-based casino with Goldwasser-Micali Cryptosystem and Homomorphic Encryption

##  Introduction

This is a blockchain-based casino project. This casino supports only one type of bet: the bettor puts down a deposit of 0.01 ETH. With probability 0.5, the bet is won and you have to pay them 1 eth. Similarly, with probability 0.5, the bet is lost and you get to keep their deposit.

## Restriction
The authorities are quite strict and they want to make sure that you cannot fraudulently control the result of the bets. So, they require you to prove to them that the bets are actually fair.
However, they are also pretty open-minded (or at least they claim to be) and are willing to help you in the generation of the required random numbers. Specifically, they have heard that you have a protocol in mind in which a random number can be generated by the participation of any number 𝑛 of players.
The authorities require you to ensure that they always control at least 𝑡 = ⌈ 𝑛/2 + 1⌉ of the players, so that the public can trust your casino. They also require your protocol to be open to the public, so that anyone can sign up and contribute to the random number generation if they wish to do so.

Unfortunately, although the public trusts the authorities, you as the casino owner cannot trust them, you worry that they might use their huge influence in the RNG process to tamper with the results and help their friends win a lot of bets in your casino.

Finally, although you are aware of the standard methods of random number generation on the blockchain, none of them really appeal to you. They are all slow and take a long time to generate even one random number. Your bettors like to see the results of their bets immediately. You cannot ask a bettor to wait for a VDF to be computed, or for many RNG participants to reveal their choices or perform secret reconstruction. They expect almost-instant results, i.e. within a few blocks.

## Scheme
1. At the beginning of the day, we use a specialized RNG protocol with the above properties requiredby the authorities, to generate a random number 𝑟. However, we ensure that 𝑟 is only visible to the casino and no one else has any information about it.
2. We fix a deterministic pseudo-random number generator function, e.g. the rand() function in a standard implementation of C, which can have any seed.
3. The casino deposits a huge amount of money in the smart contract.
4. Each bettor deposits 1 schilling for each bet and also provides a random number 𝑘 of their choosing. These are recorded in the smart contract. In response, the casino uses 𝑘 + 𝑟 as the seed and computes a random number, i.e. it performs srand(𝑘 + 𝑟); 𝑥 = rand(); The casino discloses neither 𝑟 nor 𝑥. It only tells the smart contract whether 𝑥 is even or odd. This announcement is recorded in the contract. If 𝑥 is even, the bettor has won. Otherwise, they have lost. The contract pays the bettor accordingly.
5. At the end of the day, the casino announces the value of 𝑟 that was used during the day. The authorities and every bettor can verify that (i) 𝑟 was really generated by the RNG process of Step 1 and was therefore not under the casino’s control, and (ii) the casino did not cheat in any of the bets.
6. If any cheating is detected, it can be reported to the smart contract, which would use the casino’s deposit to pay twice as much as their losses to the wronged bettors.
7. If no cheating is reported to the smart contract after a fixed deadline, or if all the reports were false, the casino can get its money back.

## Problems of the contract (TO DO)
1. It treats the players (authority vs non-authority) differently. For example, it requires the authority to move last
2. Casino's deposit is fixed, which may not be enough, or might on the other hand be too much and unaffordable for the casino. This has to be dynamic.
3. This contract allows the same value of k to be reused. So, when a bettor wins, they can make many more bets with the same k. 
