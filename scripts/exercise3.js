const hre = require("hardhat");
const { ethers } = hre;

async function main() {
    try {
        const [signer] = await ethers.getSigners();
        console.log("Using account:", signer.address);

        // Connect to your already deployed contract
        const ExerciseSolution = await ethers.getContractFactory("ExerciseSolution");
        const exerciseSolution = await ExerciseSolution.attach("0x4785c928AF676282d7Ba2274cbD31d91675c1cfB");
        console.log("Connected to ExerciseSolution at:", exerciseSolution.address);

        // Get the Evaluator contract
        const evaluator = await ethers.getContractAt("Evaluator", "0x7759a66191f6e80ff8A2C0ab833886C7b632bbB7");
        console.log("Evaluator address:", evaluator.address);

        // Diagnostic: Check evaluator's tokens
        console.log("Checking evaluator's tokens...");
        const evaluatorBalance = await exerciseSolution.balanceOf(evaluator.address);
        console.log("Evaluator token balance:", evaluatorBalance.toString());

        // Get the evaluator's first token
        const animalToKill = await exerciseSolution.tokenOfOwnerByIndex(evaluator.address, 0);
        console.log(`Animal to kill: ${animalToKill}`);

        // Diagnostic: Check animal characteristics before killing
        console.log("Animal characteristics before killing:");
        const beforeKill = await exerciseSolution.getAnimalCharacteristics(animalToKill);
        console.log("Before kill:", beforeKill);

        // Suggest manual method to resolve the exercise
        console.log("\n--- Exercise Completion Guide ---");
        console.log("To complete Exercise 5, you need to modify your contract's declareDeadAnimal method.");
        console.log("Suggested modification:");
        console.log(`
function declareDeadAnimal(uint256 animalNumber) public {
    // Allow the evaluator to kill an animal it owns
    require(
        ownerOf(animalNumber) == msg.sender || 
        msg.sender == address(evaluatorContractAddress), 
        "Not authorized to kill this animal"
    );
    delete animals[animalNumber];
    _burn(animalNumber);
}
`);

        // Attempt to run the evaluator's test
        console.log("\nTesting declare dead animal...");
        const deadTestTx = await evaluator.ex5_declareDeadAnimal({ gasLimit: 500000 });
        await deadTestTx.wait();
        console.log("Exercise 5 completed");

    } catch (error) {
        console.error("Error:", error);
        if (error.transaction) {
            console.log("Failed transaction:", error.transaction);
        }
        console.error("Full error details:", error);
    }
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });