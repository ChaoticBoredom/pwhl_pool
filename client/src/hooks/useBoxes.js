import { useQuery, useMutation } from "@tanstack/react-query";
import { useAuth } from "@/context/AuthContext";

export function useBoxesIndex(poolId, { enabled = true } = {}) {
  const { authHeaders } = useAuth();

  return useQuery({
    queryKey: ["commissioner-pool-boxes", poolId],
    queryFn: async () => {
      const res = await fetch(`/api/commissioner/${poolId}/pool_boxes`, {
        headers: authHeaders,
      });
      if (!res.ok) throw new Error("Failed to load boxes");
      return res.json();
    },
    staleTime: Infinity,
    enabled,
  });
}

export function useBoxesDefault(poolId, { enabled = true } = {}) {
  const { authHeaders } = useAuth();

  return useQuery({
    queryKey: ["pool-boxes-generate", poolId],
    queryFn: async () => {
      const res = await fetch(`/api/commissioner/${poolId}/pool_boxes/default`, {
        headers: authHeaders,
      });
      if (!res.ok) throw new Error("Failed to load default boxes");
      return res.json();
    },
    staleTime: Infinity,
    enabled,
  });
}

export function useBoxesGenerate(poolId) {
  const { authHeaders } = useAuth();

  return useMutation({
    mutationFn: async (config) => {
      const res = await fetch(`/api/commissioner/${poolId}/pool_boxes/generate`, {
        method: "POST",
        headers: authHeaders,
        body: JSON.stringify(config),
      });
      if (!res.ok) throw new Error("Failed to generate boxes");
      return res.json();
    },
  });
}
