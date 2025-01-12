<script>
    import { ethers } from "ethers";
    import EnergyCredits from "../components/EnergyCredits.svelte";
    import ProducerDashboard from "../components/ProducerDashboard.svelte";
    import { onMount } from "svelte";
    let contract;
    let userAddress;
    let userRole;
    const contractAddress = "0x197f47C7a0542cD0cE3CeC618B53b3bF7624Ca6A";

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
    "function getTotalCreditsPurchased(address buyer) external view returns (uint256)",
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
let priceInEUR = 0.1867 // € per KWh
let ethAmount=0
let priceInETH = ""
let totalPrice = 0
let quantity = 0
let totalCredits = 0

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

async function fetchTotalCredits() {
  if(account){
    totalCredits = await contractWithSigner.getTotalCreditsPurchased(account);
  }
  
}

async function fetchAvailableCredits() {
  if (!contractWithSigner) return;
  try {
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
          price: ethers.formatEther(credit.price)
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
        await listEnergyCredit(amount, priceInETH);
    }

async function listEnergyCredit(amount,priceInETH) {
    if (!isProducer) {
      alert("Only a producer can add credits!");
      return;
    }
    console.log(priceInETH)

    let truncatedString 
    ethAmount = priceInETH.toString()

    try{
      let [integerPart, decimalPart] = ethAmount.split(".");
      if (!decimalPart) {
      pass
      }
      if (decimalPart.length > 18) {
      decimalPart = decimalPart.slice(0, 18);
    }
    truncatedString = integerPart + "." + decimalPart;
    } catch(err){
      console.log(err)
    }
    console.log("truncated",{truncatedString})
    price = ethers.parseEther(truncatedString)

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

      const priceInWei = ethers.parseUnits(credit.price.toString(), 18);
      const totalCost = priceInWei * BigInt(quantityToBuy);


      const tx = await contractWithSigner.purchaseEnergyCredit(selectedCreditId, quantityToBuy, {
        value: totalCost
      });
      
      console.log("Transaction sent:", tx.hash);
      await tx.wait();

      console.log("Credits purchased successfully!");
      displaySuccessPopup();
      await fetchAvailableCredits(); 
    } catch (err) {
      console.error("Error purchasing credits:", err);
      if (err.message && err.message.includes("insufficient funds")) {
      alert("Insufficient funds for this transaction. Please check your balance.");
    } else {
      alert("An error occurred while purchasing credits. Please try again.");
    }
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
async function getCurrencyConversions(){
  try{
    const response = await fetch(`http://77.239.3.207:3001/currency-conversion?priceInEUR=${priceInEUR}`);
    console.log(response)
    const data = await response.json()

    if (data.Response === "Error") {
            console.error("Error fetching data:", data.Message);
            return;
    }
    let truncatedString 
    const returnedPrice = data.priceInETH
    ethAmount = returnedPrice.toString()

    try{
      let [integerPart, decimalPart] = ethAmount.split(".");
      if (!decimalPart) {
      pass
      }
      if (decimalPart.length > 18) {
      decimalPart = decimalPart.slice(0, 18);
    }
    truncatedString = integerPart + "." + decimalPart;
    } catch(err){
      console.log(err)
    }
    console.log("truncated",{truncatedString})
    const wei = ethers.parseEther(truncatedString);
    console.log("Wei: ",{wei})
    console.log(`${priceInEUR} EUR is approximately ${ethAmount} ETH`);
    } catch(err){
    console.log(err)
  }
}
function displaySuccessPopup() {
  const successPopup = document.getElementById("success-popup");
  successPopup.style.display = "block"; // Show the popup

  // Hide the popup after 3 seconds
  setTimeout(() => {
    successPopup.style.display = "none";
  }, 3000);
}


function updateTotalPrice() {
    try {
      const credit = availableCredits.find(c => c.id === selectedCreditId);
      totalPrice = credit.price * quantity
  }catch(err){
    console.log(err)
  }
}
  function handleQuantityChange(event) {
    quantity = event.target.value;
    updateTotalPrice();
  }
  $: account, fetchTotalCredits();
  $: totalCredits, fetchTotalCredits();
   onMount(async () => {
    onMount(connectMetaMask);
    getCurrencyConversions()
    updateTotalPrice();
	});
  </script>
  
  <div>
    <h1>Energy Trading App</h1>
    <h2>1kWh = {ethAmount} ETH = {priceInEUR} €</h2>   
    <!-- Connect to MetaMask -->
     {#if !account}
    <button on:click={connectMetaMask} class="button">Connect to MetaMask</button>
    {/if}

    {#if account}
      <p>Connected Account: {accAddr}</p>
      <div class="credits-card">
      <h3>Total Credits Purchased</h3>
      <p>{totalCredits} kWh</p>
    </div>
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
      
          <label for="price">Price (ETH per kWh):</label>
          <input type="number" id="price" bind:value={priceInETH} />
      
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
                <strong>Price:</strong> {credit.price} ETH per kWh
                <button on:click={() => selectedCreditId = credit.id} class="card-button">Select</button>
              </li>
            {/each}
          </ul>
          {/if}
          <div class="buyer-view">
            {#if selectedCreditId !== null}
              <div>
                <h3>Buy Credits</h3>
                <input type="number" min="1" bind:value={quantityToBuy} placeholder="Quantity (kWh)" on:input={handleQuantityChange}/>
                <button on:click={purchaseCredits} class="button">Buy Credits</button>
              </div>
              <div id="priceDisplay">
                <p>Total Price: {totalPrice.toFixed(18)} ETH</p>
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
            <strong>Price:</strong> {credit.price} ETH per kWh
            <button on:click={() => selectedCreditId = credit.id} class="card-button">Select</button>
          </li>
        {/each}
      </ul>
      {/if}
        <div class="buyer-view">
            {#if selectedCreditId !== null}
            <div>
              <h3>Buy Credits</h3>
              <input type="number" min="1" bind:value={quantityToBuy} placeholder="Quantity (kWh)" on:input={handleQuantityChange} />
              <button on:click={purchaseCredits} class="button">Buy Credits</button>
            </div>
            <div id="priceDisplay">
              <p>Total Price: {totalPrice.toFixed(18)} ETH</p>
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
  
      <label for="price">Price (ETH per kWh):</label>
      <input type="number" id="price" bind:value={priceInETH} />
  
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
            <strong>Price:</strong> {credit.price} ETH per kWh
            <button on:click={() => selectedCreditId = credit.id} class="card-button">Select</button>
          </li>
        {/each}
      </ul>
      {/if}
        <div class="buyer-view">
          {#if selectedCreditId !== null}
            <div>
              <h3>Buy Credits</h3>
              <input type="number" min="1" bind:value={quantityToBuy} placeholder="Quantity (kWh)" on:input={handleQuantityChange} />
              <button on:click={purchaseCredits} class="button">Buy Credits</button>
            </div>
            <div id="priceDisplay">
              <p>Total Price: {totalPrice.toFixed(18)} ETH</p>
            </div>
          {/if}
        </div>
      {/if}
  
      <div id="success-popup" class="popup" style="display: none;">
        <p>Credits Purchased Successfully!</p>
      </div>
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
  .popup {
  position: fixed;
  top: 50%;
  left: 50%;
  transform: translate(-50%, -50%);
  padding: 20px;
  background-color: #28a745;
  color: white;
  border-radius: 5px;
  box-shadow: 0 0 10px rgba(0, 0, 0, 0.1);
  z-index: 1000;
  display: none;
}
.credits-card {
    position: fixed;
    top: 20px;
    right: 20px;
    padding: 15px;
    background-color: #28a745;
    color: white;
    border-radius: 5px;
    box-shadow: 0 0 10px rgba(0, 0, 0, 0.1);
    z-index: 1000;
  }
  </style>