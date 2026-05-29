import { Routes, Route, Navigate } from "react-router-dom";
import { RequireAuth } from "@c/auth/RequireAuth";
import { Dashboard } from "@c/pool/Dashboard";
import AuthForm from "@c/auth/AuthForm";
import BoxGenerator from "@c/boxes/BoxGenerator";
import JoinPoolPrompt from "@c/pool/JoinPoolPrompt";
import PoolDetails from "@c/pool/PoolDetails";
import ReportStandings from "@c/reports/ReportStandings";
import ReportCategories from "@c/reports/ReportCategories";
import ReportTeams from "@c/reports/ReportTeams";
import PoolScoring from "@c/pool/PoolScoring";
import PoolTeamDetails from "@c/pool/PoolTeamDetails";
import PlayerSelection from "@c/players/PlayerSelection";

export function AppRouter() {

  return (
    <div className="app-wrapper">
      <Routes>
        <Route path="/login" element={<AuthForm />} />

        <Route element={<RequireAuth />}>
          <Route path="/" element={<Dashboard />}/>

          <Route path="/pools/:poolId/invite" element={<JoinPoolPrompt />} />
          <Route path="/pools/:poolId" element={<PoolDetails />} />
          <Route path="/pools/:poolId/scoring" element={<PoolScoring />} />
          <Route path="/pools/:poolId/box_generator" element={<BoxGenerator />} />
          <Route path="/pools/:poolId/teams/:teamId" element={<PoolTeamDetails />} />
          <Route path="/pools/:poolId/teams/:teamId/select" element={<PlayerSelection />} />
          <Route path="/pools/:poolId/reports/standings" element={<ReportStandings />} />
          <Route path="/pools/:poolId/reports/categories" element={<ReportCategories />} />
          <Route path="/pools/:poolId/reports/teams" element={<ReportTeams />} />
          <Route path="/pools/:poolId/reports/teams/:teamId" element={<ReportTeams />} />
        </Route>
      </Routes>
    </div>
  );
}
