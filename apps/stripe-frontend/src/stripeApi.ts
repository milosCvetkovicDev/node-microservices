export async function createPaymentIntent(amount: number, currency: string) {
  const response = await fetch('http://localhost:3333/api/create-payment-intent', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ amount, currency }),
  });
  if (!response.ok) throw new Error('Failed to create payment intent');
  return response.json();
} 