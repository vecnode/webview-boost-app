const helloButton = document.getElementById("hello-button");
const helloOutput = document.getElementById("hello-output");

async function printHelloWorld() {
  helloButton.disabled = true;
  helloOutput.textContent = "Loading...";

  try {
    const response = await fetch("/api/hello");
    if (!response.ok) {
      throw new Error(`HTTP ${response.status}`);
    }

    const text = await response.text();
    helloOutput.textContent = text;
  } catch (error) {
    helloOutput.textContent = `Request failed: ${error.message}`;
  } finally {
    helloButton.disabled = false;
  }
}

helloButton.addEventListener("click", printHelloWorld);
