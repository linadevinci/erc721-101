const hre = require("hardhat");

async function main() {
    try {
        // Deploy the contract
        const ExerciseSolution = await hre.ethers.getContractFactory("ExerciseSolution");
        const exerciseSolution = await ExerciseSolution.deploy();
        await exerciseSolution.deployed();
        console.log(`ExerciseSolution deployed at ${exerciseSolution.address}`);

        // Get the Evaluator contract
        const evaluator = await hre.ethers.getContractAt("Evaluator", "0x7759a66191f6e80ff8A2C0ab833886C7b632bbB7");

        // Submit exercise with gas limit
        const submitTx = await evaluator.submitExercice(exerciseSolution.address, { gasLimit: 200000 });
        await submitTx.wait();
        console.log("Exercise submitted to evaluator");

        // Transfer token 1 with gas limit
        const transferTx = await exerciseSolution.transferFrom(
            await exerciseSolution.ownerOf(1),
            evaluator.address,
            1,
            { gasLimit: 200000 }
        );
        await transferTx.wait();
        console.log("Token 1 transferred to Evaluator");

        // Get random animal attributes
        const getAttrTx = await evaluator.ex2a_getAnimalToCreateAttributes({ gasLimit: 200000 });
        await getAttrTx.wait();
        console.log("Got random animal attributes");

        // Read the assigned attributes
        const [signer] = await hre.ethers.getSigners();
        const name = await evaluator.readName(signer.address);
        const legs = await evaluator.readLegs(signer.address);
        const sex = await evaluator.readSex(signer.address);
        const wings = await evaluator.readWings(signer.address);
        
        console.log(`Need to create animal with: name=${name}, legs=${legs}, sex=${sex}, wings=${wings}`);

        // Register as breeder first
        console.log("Registering as breeder...");
        const regPrice = hre.ethers.utils.parseEther("0.01"); // 0.01 ETH
        const regTx = await exerciseSolution.registerMeAsBreeder({ 
            value: regPrice,
            gasLimit: 200000 
        });
        await regTx.wait();
        console.log("Registered as breeder");

        // Verify breeder registration
        const isBreeder = await exerciseSolution.isBreeder(signer.address);
        console.log("Is breeder status:", isBreeder);

        // Create the animal
        console.log("Creating animal...");
        const createTx = await exerciseSolution.declareAnimal(
            sex,
            legs, 
            wings,
            name,
            { gasLimit: 500000 }
        );
        console.log("Waiting for animal creation transaction...");
        const receipt = await createTx.wait();
        console.log("Animal creation transaction confirmed");
        
        // Get the animal ID from the Transfer event
        const transferEvent = receipt.events.find(e => e.event === 'Transfer');
        if (!transferEvent) {
            console.log("All events:", receipt.events);
            throw new Error("Transfer event not found");
        }
        const animalId = transferEvent.args.tokenId;
        console.log(`Created animal with ID: ${animalId.toString()}`);

        // Transfer to evaluator
        const transfer2Tx = await exerciseSolution.transferFrom(
            signer.address,
            evaluator.address,
            animalId,
            { gasLimit: 200000 }
        );
        await transfer2Tx.wait();
        console.log("Animal transferred to evaluator");

        // Verify the animal
        const verifyTx = await evaluator.ex2b_testDeclaredAnimal(animalId, { gasLimit: 500000 });
        await verifyTx.wait();
        console.log("Exercise 2 completed");

    } catch (error) {
        console.error("Detailed error:", error);
        if (error.transaction) {
            console.log("Failed transaction:", error.transaction);
        }
    }
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});