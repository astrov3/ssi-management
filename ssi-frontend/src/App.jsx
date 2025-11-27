import { Toaster } from 'react-hot-toast';
import { Route, BrowserRouter as Router, Routes } from 'react-router-dom';
import Layout from './components/Layout';
import Dashboard from './pages/Dashboard';
import DIDManagement from './pages/DIDManagement';
import Settings from './pages/Settings';
import VCOperations from './pages/VCOperations';

function App() {
  return (
    <Router>
      <div className="App">
        <Layout>
          <Routes>
            <Route path="/" element={<Dashboard />} />
            <Route path="/did" element={<DIDManagement />} />
            <Route path="/vc" element={<VCOperations />} />
            <Route path="/settings" element={<Settings />} />
          </Routes>
        </Layout>
        <Toaster/>
      </div>
    </Router>
  );
}

export default App;
