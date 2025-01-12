<script>
    import { ethers } from "ethers";
    import EnergyCredits from "../components/EnergyCredits.svelte";
    import ProducerDashboard from "../components/ProducerDashboard.svelte";
    import { onMount } from "svelte";
    let contract;
    let userAddress;
    let userRole;
    const contractAddress = "0x3FcbCAc98Cb663fc7447C8326A50ba7Ee8C160a7";

    const abi = [
    "function getRole(address user) external view returns (uint8)",
    "function assignRole(address user, uint8 role) external",
    "event RoleAssigned(address indexed user, uint8 role)",
    "function registerProducer(address producer)",
    {
    inputs: [
      { internalType: "uint256", name: "quantity", type: "uint256" },
      { internalType: "uint256", name: "price", type: "uint256" }
    ],
    name: "listEnergyCredit",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function"
    },
    "function purchaseEnergyCredit(uint256 creditId, uint256 quantity)",
    "function getEnergyCredit(uint256 creditId)",
    "function getAvailableCredits()",

  ];
  let account = null;
  let role = null;
  let provider;
  let signer;
  let isAdmin = false;
  let isBuyer = false;
  let isProducer = false;
  let accAddr = null;
let price = 1;
let amount = 0;
let quantityToBuy = 0;
let availableCredits = [];
let selectedCreditId = null;
let contractWithSigner=null;
let producerAddress = "";
let valueName="";

    async function connectMetaMask() {
  // Check if MetaMask is installed
  if (typeof window.ethereum === "undefined") {
    alert("Please install MetaMask!");
    return;
  }

  try {
    const accounts = await window.ethereum.request({ method: "eth_requestAccounts" });
    if (accounts.length === 0) {
      console.error("No accounts found in MetaMask");
      return;
    }

    provider = new ethers.BrowserProvider(window.ethereum);
    signer = await provider.getSigner()
    account = (await signer).getAddress()
    console.log(account)
    account.then((result)=>{
        accAddr=result
    })
    contract = new ethers.Contract(contractAddress, abi, provider);
    contractWithSigner = contract.connect(signer);
    userRole = await(contract).getRole(account)
    role = userRole.toString(); // 1 = Admin, 2 = Producer, 3 = Buyer
    console.log("User Role: ", role)
    isAdmin = role === "1";
    isProducer = role === "2";
    isBuyer = role === "3";
    return { account, role, isAdmin, isProducer, isBuyer, contractWithSigner };
} catch (err) {
console.error("Error connecting to MetaMask:", err);
}
}

async function fetchAvailableCredits() {
  if (!contractWithSigner) return;
    try {
        const creditIds = await contractWithSigner.getAvailableCredits();
        availableCredits = [];
        for (let id of creditIds) {
            const credit = await contractWithSigner.getEnergyCredit(id);
            if (credit.isAvailable) {
                availableCredits.push({
                    id: credit.id,
                    producer: credit.producer,
                    quantity: credit.quantity,
                    price: credit.price
                });
            }
        }
    } catch (err) {
        console.error("Error fetching available credits:", err);
    }
}

    async function listEnergyCreditHandler() {
        await listEnergyCredit(amount, price);
    }

async function listEnergyCredit(amount,price) {
    if (!isProducer) {
      alert("Only a producer can add credits!");
      return;
    }

    try {
        if (!amount || !price) {
            alert("Please provide valid quantity and price values.");
            return;
        }
        if (!contractWithSigner) {
            throw new Error("Contract not connected with signer!");
        }

      const tx = await (contractWithSigner).listEnergyCredit(amount,price);
      if (!tx || !tx.hash) {
            throw new Error("Transaction object is invalid");
        }
      console.log("Credits added transaction sent:", tx.hash);
      await tx.wait();

      availableCredits += amount; // Update frontend available credits
      console.log("Credits added!");
    } catch (err) {
      console.error("Error adding credits:", err);
    }
  }

  async function purchaseCredits() {
    if (selectedCreditId === null || quantityToBuy <= 0) {
      alert("Please select a credit and quantity to buy!");
      return;
    }
    try {
      const credit = availableCredits.find(c => c.id === selectedCreditId);
      const totalCost = ethers.BigNumber.from(quantityToBuy).mul(credit.price);

      const tx = await contractWithSigner.purchaseEnergyCredit(selectedCreditId, quantityToBuy, {
        value: totalCost
      });
      
      console.log("Transaction sent:", tx.hash);
      await tx.wait();

      console.log("Credits purchased successfully!");
      await fetchAvailableCredits(); 
    } catch (err) {
      console.error("Error purchasing credits:", err);
    }
  }

  async function registerProducers(producerAddress) {
    try {
        let tx = await contractWithSigner.registerProducer(producerAddress);
        console.log("Register producer transaction sent:", tx.hash);
        await tx.wait();
        console.log("Producer registered successfully!");
        alert("Producer registered!");
    } catch (error) {
        console.error("Error registering producer:", error);
        alert("Failed to register producer.");
    }
}

async function assignRole(userAddress, userRole) {
    try {
        console.log("assigning role")
        const tx = await contractWithSigner.assignRole(userAddress, 3);
     
      console.log("Role assignment transaction sent:", tx.hash);
      await tx.wait();
      console.log("Role assigned!");
    } catch (err) {
      console.error("Error assigning role:", err);
    }
  }
async function getUserRole(contract, valueName) {
  try {
    console.log(valueName)
    if (!contract || !valueName) console.log("missing addr or contract");
    
    let role = await (contract).getRole(valueName);

    const roleMap = {
      0: "None",
      1: "Admin",
      2: "Producer",
      3: "Buyer",
    };
    console.log(roleMap[role])
    return roleMap[role] || "Unknown Role";
  } catch (error) {
    console.error("Error fetching user role:", error);
    return "Error";
  }
}



   onMount(async () => {
    onMount(connectMetaMask);
		fetchAvailableCredits()
	});
  </script>
  
  <div>
    <h1>Energy Trading App</h1>
    <h2>1 wei = 1kWh</h2>   
    <!-- Connect to MetaMask -->
     {#if !account}
    <button on:click={connectMetaMask} class="button">Connect to MetaMask</button>
    {/if}
    {#if account}
      <p>Connected Account: {accAddr}</p>
      <!-- Check for Admin Role -->
      {#if isAdmin}
        <div class="admin-view">
          <h2>Admin View</h2>
          <p>Check wallet status (producer or buyer)</p>
          <input id="name" type="text" bind:value={valueName}>
          <button type="submit" on:click={()=>getUserRole(contract,valueName)}>Send</button>

          <label for="producer">Producer Address:</label>
          <input type="text" id="producer" bind:value={producerAddress} />
          <button on:click={()=>registerProducers(producerAddress)}>Register Producer</button>
          <label for="quantity">Quantity (kWh):</label>
          <input type="number" id="quantity" bind:value={amount} />
      
          <label for="price">Price (wei per kWh):</label>
          <input type="number" id="price" bind:value={price} />
      
          <button on:click={listEnergyCreditHandler}>List Energy Credit</button>
          <EnergyCredits {contractWithSigner}/>
        </div>
      {/if}
      {#if isBuyer}
      <h2>Available Energy Credits</h2>
      <ul>
        {#each availableCredits as credit}
          <li class="card">
            <strong>Credit ID:</strong> {credit.id}, 
            <strong>Producer:</strong> {credit.producer},
            <strong>Quantity:</strong> {credit.quantity} kWh, 
            <strong>Price:</strong> {ethers.utils.formatUnits(credit.price.toString(), "wei")} wei per kWh
            <button on:click={() => selectedCreditId = credit.id} class="button">Select</button>
          </li>
        {/each}
      </ul>
        <div class="buyer-view">
            {#if selectedCreditId !== null}
            <div>
              <h3>Buy Credits</h3>
              <input type="number" min="1" bind:value={quantityToBuy} placeholder="Quantity (kWh)" />
              <button on:click={purchaseCredits} class="button">Buy Credits</button>
            </div>
          {/if}
        </div>
      {/if}
      {#if isProducer}
      
      <label for="quantity">Quantity (kWh):</label>
      <input type="number" id="quantity" bind:value={amount} />
  
      <label for="price">Price (wei per kWh):</label>
      <input type="number" id="price" bind:value={price} />
  
      <button on:click={listEnergyCreditHandler}>List Energy Credit</button>
      {/if}
      {#if selectedCreditId !== null}
      <div>
        <h3>Buy Credits</h3>
        <input type="number" min="1" bind:value={quantityToBuy} placeholder="Quantity (kWh)" />
        <button on:click={purchaseCredits} class="button">Buy Credits</button>
      </div>
        {/if}
  
      <!-- Check for Buyer Role -->


      {#if isBuyer && !isAdmin && !isProducer} 
      <input type="text" id="producer" bind:value={producerAddress} />
      <button on:click={registerProducerHandler} class="button">Register as Producer</button>
      {/if}
    {/if}
  </div>
  

  <style>
    /* Optional: Style for the frontend */
    .admin-view, .buyer-view {
    background-color: #f4f4f4;
    padding: 20px;
    border-radius: 10px;
    margin-top: 20px;
  }
  .button {
    padding: 10px;
    margin-top: 10px;
    background-color: #4CAF50;
    color: white;
    border: none;
    border-radius: 5px;
    cursor: pointer;
  }
  .button:hover {
    background-color: #45a049;
  }
  .card {
    border: 1px solid #ccc;
    padding: 1rem;
    margin: 0.5rem;
    border-radius: 8px;
    box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
  }
  .card-button {
    background-color: #007bff;
    color: white;
    border: none;
    padding: 0.5rem 1rem;
    border-radius: 4px;
    cursor: pointer;
  }
  .card-button:hover {
    background-color: #0056b3;
  }
  </style>