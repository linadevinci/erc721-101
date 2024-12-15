const hre = require("hardhat");

async function main(){
    //Deploying contracts
    const ExcerciceSolution = await hre.ethers.getContractFactory("ExerciceSolution");

    const excerciceSolution = await ExcerciceSolution.deploy();
    console.log(
        'ExerciceSolution deployed at ${exerciceSolution.address}'
    );
}

main().catch((error) => {
    console.error(error);
    ProcessingInstruction.exitCode = 1;
});