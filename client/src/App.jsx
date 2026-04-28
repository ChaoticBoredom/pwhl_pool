import { useEffect } from "react";
import { useLocation, matchPath } from "react-router-dom";
import { AppRouter } from "./components/AppRouter";

function App() {
  const location = useLocation();
  const isPoolRoute = matchPath("pools/:poolId/*", location.pathname);

  useEffect(() => {
    if (!isPoolRoute) {
      document.title = "Fantasy Pools";
    }
  }, [location.pathname, isPoolRoute]);

  return (
    <AppRouter />
  );
}

export default App;
