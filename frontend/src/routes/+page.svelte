<script>
    import { ethers } from "ethers";
    import EnergyCredits from "../components/EnergyCredits.svelte";
    import ProducerDashboard from "../components/ProducerDashboard.svelte";
    import { onMount } from "svelte";
    let contract;
    let userAddress;
    let userRole;
    const contractAddress = "0x1779B32012d4Fe7D6ff82dB00090D4AB8ba3a818";

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
    {
    "inputs": [
      {
        "internalType": "uint256",
        "name": "creditId",
        "type": "uint256"
      }
    ],
    "name": "getEnergyCredit",
    "outputs": [
      {
        "internalType": "struct EnergyCredit",
        "name": "",
        "type": "tuple",
        "components": [
          {
            "internalType": "uint256",
            "name": "id",
            "type": "uint256"
          },
          {
            "internalType": "address",
            "name": "producer",
            "type": "address"
          },
          {
            "internalType": "uint256",
            "name": "quantity",
            "type": "uint256"
          },
          {
            "internalType": "uint256",
            "name": "price",
            "type": "uint256"
          },
          {
            "internalType": "bool",
            "name": "isAvailable",
            "type": "bool"
          }
        ]
      }
    ],
    "stateMutability": "view",
    "type": "function"
  },
    "function applyForProducer()",
    "function getAvailableCredits() external view returns (uint256[])",
    "function getDetailedAvailableCredits()",
    "function purchaseEnergyCredit(uint256 creditId, uint256 quantity)",  
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
let loading = true; //check if credits loaded

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
    isAdmin = role === "2";
    isProducer = role === "1";
    isBuyer = role === "0";
    console.log( account, role, isAdmin, isProducer, isBuyer, contractWithSigner )
    fetchAvailableCredits()
    return { account, role, isAdmin, isProducer, isBuyer, contractWithSigner };
  } catch (err) {
  console.error("Error connecting to MetaMask:", err);
  }
}



async function fetchAvailableCredits() {
  if (!contractWithSigner) return;
  try {
    console.log("Here1")
    const creditIds = await contractWithSigner.getAvailableCredits();
    const creditIdArray = Array.isArray(creditIds) 
    ? creditIds.map(id => id.toString()) 
    : []; // if not iterable declare empty
    console.log("Credit IDs:", creditIdArray);
    if (!Array.isArray(creditIds)) {
      console.error("Unexpected creditIds type:", creditIds);
      return;
    }
    availableCredits = [];
    for (let id of creditIdArray) {
      const credit = await contractWithSigner.getEnergyCredit(id);
      console.log(`Credit ${id}:`, credit);
      if (credit.isAvailable) {
        availableCredits.push({
          id: id, 
          producer: credit.producer,
          quantity: credit.quantity.toString(),
          price: credit.price.toString()
        });
      }
    }
    console.log(availableCredits)
  } catch (err) {
    console.error("Error fetching credits:", err);
  } finally {
    loading = false;
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
      alert("Credits added successfully.")
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
      const totalCost = BigInt(quantityToBuy) * BigInt(credit.price);


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
async function applyForProducer() {
  try{
    let tx = await contractWithSigner.applyForProducer();
    console.log("Apply for producer tx sent:", tx.hash);
    await tx.wait();
    console.log("Successfuly registered")
    alert("Successfuly registered, please refresh your page.")
  } catch (error) {
  console.log("Error:", error)
  alert("Couldn't register for producer.");
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
      <!-- Check if admin -->
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
          {#if loading}
          <p>Loading credits, please wait....</p>
          {:else}
          <h2>Available Energy Credits</h2>
          <ul>
            {#each availableCredits as credit}
              <li class="card">
                <strong>Credit ID:</strong> {credit.id}, 
                <strong>Producer:</strong> {credit.producer},
                <strong>Quantity:</strong> {credit.quantity} kWh, 
                <strong>Price:</strong> {credit.price} wei per kWh
                <button on:click={() => selectedCreditId = credit.id} class="card-button">Select</button>
              </li>
            {/each}
          </ul>
          {/if}
          <div class="buyer-view">
            {#if selectedCreditId !== null}
              <div>
                <h3>Buy Credits</h3>
                <input type="number" min="1" bind:value={quantityToBuy} placeholder="Quantity (kWh)" />
                <button on:click={purchaseCredits} class="button">Buy Credits</button>
              </div>
            {/if}
          </div>
        </div>
      {/if}
      <!-- Check if buyer -->
      {#if isBuyer}
      {#if loading}
      <p>Loading credits, please wait....</p>
      {:else}
      <h2>Available Energy Credits</h2>
      <ul>
        {#each availableCredits as credit}
          <li class="card">
            <strong>Credit ID:</strong> {credit.id}, 
            <strong>Producer:</strong> {credit.producer},
            <strong>Quantity:</strong> {credit.quantity} kWh, 
            <strong>Price:</strong> {credit.price} wei per kWh
            <button on:click={() => selectedCreditId = credit.id} class="card-button">Select</button>
          </li>
        {/each}
      </ul>
      {/if}
        <div class="buyer-view">
            {#if selectedCreditId !== null}
            <div>
              <h3>Buy Credits</h3>
              <input type="number" min="1" bind:value={quantityToBuy} placeholder="Quantity (kWh)" />
              <button on:click={purchaseCredits} class="button">Buy Credits</button>
            </div>
          {/if}
        </div>
        <div class="register-as-producer">
          <p>Input your wallet address</p>
          <input type="text" id="producer" bind:value={producerAddress} />
          <button on:click={applyForProducer()} class="button">Register as Producer</button>
        </div>
      {/if}
      <!-- Check if producer -->
      {#if isProducer}
      
      <label for="quantity">Quantity (kWh):</label>
      <input type="number" id="quantity" bind:value={amount} />
  
      <label for="price">Price (wei per kWh):</label>
      <input type="number" id="price" bind:value={price} />
  
      <button on:click={listEnergyCreditHandler}>List Energy Credit</button>
      {#if loading}
      <p>Loading credits, please wait....</p>
      {:else}
      <h2>Available Energy Credits</h2>
      <ul>
        {#each availableCredits as credit}
          <li class="card">
            <strong>Credit ID:</strong> {credit.id}, 
            <strong>Producer:</strong> {credit.producer},
            <strong>Quantity:</strong> {credit.quantity} kWh, 
            <strong>Price:</strong> {credit.price} wei per kWh
            <button on:click={() => selectedCreditId = credit.id} class="card-button">Select</button>
          </li>
        {/each}
      </ul>
      {/if}
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