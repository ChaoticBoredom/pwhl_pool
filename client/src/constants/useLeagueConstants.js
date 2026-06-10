// This is technically a hook, but is the entry point for 
// components to make use of all constants, so it lives in constants
import { useMemo } from "react";
import { usePool } from "@/context/PoolContext";
import { getLeagueConstants } from "@/constants";

export function useLeagueConstants() {
  const { pool } = usePool();
  return useMemo(
    () => getLeagueConstants(pool?.league?.short_name),
    [pool?.league?.short_name]
  );
}
