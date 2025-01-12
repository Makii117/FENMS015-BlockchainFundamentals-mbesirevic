<script>
    export let contract;
    let quantity, price;
  
    async function listEnergyCredit() {
      await contract.listEnergyCredit(quantity, price);
      alert("Energy credit listed!");
    }
  </script>
  
  <form on:submit|preventDefault={listEnergyCredit}>
    <label>Quantity (kWh):</label>
    <input type="number" bind:value={quantity} required />
  
    <label>Price (wei/kWh):</label>
    <input type="number" bind:value={price} required />
  
    <button type="submit">List Energy Credit</button>
  </form>
  