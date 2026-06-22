import { useQuery } from "@tanstack/react-query";
import { useAuth } from "@/context/AuthContext";

export function useScoringIndex(poolId, { enabled = true } = {}) {
  const { authHeaders } = useAuth();

  return useQuery({
    queryKey: ["pool-scoring", poolId],
    queryFn: async () => {
      const res = await fetch(`/api/pools/${poolId}/pool_scoring`, {
        headers: authHeaders,
      });
      if (!res.ok) throw new Error("Failed to load scoring");
      return res.json();
    },
    staleTime: Infinity,
    enabled,
  });
}
