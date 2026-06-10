import { createContext, useContext } from "react";

const PoolContext = createContext(null);

export function usePool() {
  return useContext(PoolContext);
}

export default PoolContext;
