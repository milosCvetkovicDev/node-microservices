import { CardElement, useStripe, useElements } from '@stripe/react-stripe-js';
import { FormEvent, useState } from 'react';
import { createPaymentIntent } from '../stripeApi';

export function PaymentForm() {
  const stripe = useStripe();
  const elements = useElements();
  const [message, setMessage] = useState('');
  const [loading, setLoading] = useState(false);

  const handleSubmit = async (e: FormEvent) => {
    e.preventDefault();
    if (!stripe || !elements) return;
    setLoading(true);
    setMessage('');
    try {
      // Example: $10.00 USD = 1000 cents
      const { client_secret } = await createPaymentIntent(1000, 'usd');
      const cardElement = elements.getElement(CardElement);
      if (!cardElement) throw new Error('CardElement not found');
      const { error, paymentIntent } = await stripe.confirmCardPayment(client_secret, {
        payment_method: { card: cardElement },
      });
      if (error) {
        setMessage(error.message || 'Payment failed');
      } else if (paymentIntent && paymentIntent.status === 'succeeded') {
        setMessage('Payment successful!');
      } else {
        setMessage('Payment processing.');
      }
    } catch (err: any) {
      setMessage(err.message || 'Error processing payment');
    } finally {
      setLoading(false);
    }
  };

  return (
    <form onSubmit={handleSubmit} style={{ maxWidth: 400, margin: '2rem auto' }}>
      <CardElement options={{ hidePostalCode: true }} />
      <button type="submit" disabled={!stripe || loading} style={{ marginTop: 16 }}>
        {loading ? 'Processing...' : 'Pay'}
      </button>
      {message && <div style={{ marginTop: 12, color: message.includes('success') ? 'green' : 'red' }}>{message}</div>}
    </form>
  );
} 