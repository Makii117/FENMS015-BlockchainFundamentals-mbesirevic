<script>
  import { onMount } from "svelte";

  export let contract;

  import { ethers } from "ethers";

  let availableCredits = [];
  let selectedCreditId = null;
  let quantityToBuy = 1;

  // Fetch available credits
  const fetchCredits = async () => {
    if (!contract) return;

    try {
      const creditIds = await contract.getAvailableCredits();
      availableCredits = await Promise.all(
        creditIds.map(async (id) => {
          const credit = await contract.getEnergyCredit(id);
          return {
            id: credit.id.toString(),
            producer: credit.producer,
            quantity: credit.quantity.toString(),
            price: credit.price.toString(),
            isAvailable: credit.isAvailable
          };
        })
      );
    } catch (err) {
      console.error("Error fetching credits:", err);
    }
  };

  // Purchase credits
  const purchaseCredits = async () => {
    if (!selectedCreditId || !quantityToBuy || quantityToBuy <= 0) {
      alert("Please enter a valid quantity.");
      return;
    }

    const selectedCredit = availableCredits.find((credit) => credit.id === selectedCreditId);
    if (!selectedCredit) {
      alert("Credit not found.");
      return;
    }

    const totalCost = ethers.utils.parseUnits((selectedCredit.price * quantityToBuy).toString(), "wei");

    try {
      const tx = await contract.purchaseEnergyCredit(selectedCreditId, quantityToBuy, { value: totalCost });
      console.log("Transaction sent:", tx.hash);
      await tx.wait();
      alert("Purchase successful!");
      fetchCredits(); // Refresh the list of credits
      selectedCreditId = null; // Reset selection
      quantityToBuy = 1;
    } catch (err) {
      console.error("Error purchasing credits:", err);
    }
  };

  // Fetch credits on mount
  onMount(() => {
    fetchCredits();
    contract?.on("CreditListed", fetchCredits);
    contract?.on("CreditPurchased", fetchCredits);
  });
</script>

<style>
  .buyer-view {
    margin-top: 20px;
  }

  .button {
    background-color: #007bff;
    color: white;
    padding: 10px;
    border: none;
    cursor: pointer;
    margin-left: 10px;
  }

  .button:hover {
    background-color: #0056b3;
  }

  input {
    padding: 5px;
    margin-right: 10px;
    width: 100px;
  }
</style>

<h2>Available Energy Credits</h2>
<ul>
  {#each availableCredits as credit}
    <li>
      <strong>Credit ID:</strong> {credit.id}, 
      <strong>Producer:</strong> {credit.producer},
      <strong>Quantity:</strong> {credit.quantity} kWh, 
      <strong>Price:</strong> {ethers.utils.formatUnits(credit.price, "wei")} wei per kWh
      <button on:click={() => (selectedCreditId = credit.id)} class="button">Select</button>
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
