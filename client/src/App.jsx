import { useEffect } from "react";
import { useLocation, matchPath } from "react-router-dom";
import { QueryClientProvider } from "@tanstack/react-query"
import { queryClient } from "./lib/queryClient"
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
    <QueryClientProvider client={queryClient}>
      <AppRouter />
    </QueryClientProvider>
  );
}

export default App;
