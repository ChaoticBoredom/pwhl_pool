import { useParams, Outlet } from "react-router-dom";
import { useQuery } from "@tanstack/react-query";
import { useAuth } from "@/context/AuthContext";
import SideNav from "./SideNav";
import TopBar from "./TopBar";

export default function PoolLayout() {
  const { poolId } = useParams();
  const { authHeaders, currentUser, isGod } = useAuth();

  const { data: pool } = useQuery({
    queryKey: ["pool", poolId],
    queryFn: () => fetch(`/api/pools/${poolId}`, { headers: authHeaders }).then(r => r.json()),
    staleTime: 60_000,
  });

  const isAdmin = pool && (pool.admin.id === currentUser || isGod);

  return (
    <div className="pool-layout">
      <TopBar pool={pool} />
      <div className="pool-layout__body">
        <SideNav poolId={poolId} pool={pool} isAdmin={isAdmin} />
        <main className="pool-layout__main">
          <Outlet />
        </main>
      </div>
    </div>
  );
}
