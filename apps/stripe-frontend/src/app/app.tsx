import NxWelcome from './nx-welcome';
import { Route, Routes, Link } from 'react-router-dom';
import { PaymentForm } from './payment-form';

export function App() {
  return (
    <div>
      <NxWelcome title="stripe-frontend" />

      {/* START: routes */}
      {/* These routes and navigation have been generated for you */}
      {/* Feel free to move and update them to fit your needs */}
      <br />
      <hr />
      <br />
      <div role="navigation">
        <ul>
          <li>
            <Link to="/">Home</Link>
          </li>
          <li>
            <Link to="/pay">Pay</Link>
          </li>
        </ul>
      </div>
      <Routes>
        <Route
          path="/"
          element={
            <div>
              This is the generated root route.{' '}
              <Link to="/pay">Click here to pay.</Link>
            </div>
          }
        />
        <Route
          path="/pay"
          element={<PaymentForm />}
        />
      </Routes>
      {/* END: routes */}
    </div>
  );
}

export default App;
