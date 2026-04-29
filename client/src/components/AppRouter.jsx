import { Routes, Route, Navigate } from "react-router-dom";
import { RequireAuth } from "./RequireAuth";
import { Dashboard } from "./Dashboard";
import AuthForm from "./AuthForm";
import JoinPoolPrompt from "./JoinPoolPrompt";
import PoolDetails from "./PoolDetails";
import PoolScoring from "./PoolScoring";
import PoolTeamDetails from "./PoolTeamDetails";
import PlayerSelection from "./PlayerSelection";

export function AppRouter() {

  return (
    <div style={{ padding: "40px" }}>
      <Routes>
        <Route path="/login" element={<AuthForm />} />

        <Route element={<RequireAuth />}>
          <Route path="/" element={<Dashboard />}/>

          <Route path="/pools/:poolId/invite" element={<JoinPoolPrompt />} />
          <Route path="/pools/:poolId" element={<PoolDetails />} />
          <Route path="/pools/:poolId/scoring" element={<PoolScoring />} />
          <Route path="/pools/:poolId/teams/:teamId" element={<PoolTeamDetails />} />
          <Route path="/pools/:poolId/teams/:teamId/select" element={<PlayerSelection />} />
        </Route>
      </Routes>
    </div>
  );
}
