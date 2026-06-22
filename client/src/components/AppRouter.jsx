import { lazy, Suspense } from "react";
import { Routes, Route, Navigate, Outlet } from "react-router-dom";
import { RequireAuth } from "@c/auth/RequireAuth";
import { Dashboard } from "@c/pool/Dashboard";
import PoolLayout from "@c/nav/PoolLayout"
import TopBar from "@c/nav/TopBar";
import LoadingState from "@c/shared/LoadingState";

import CreatePool from "@c/pool/CreatePool";

import AuthForm from "@c/auth/AuthForm";
import JoinPoolPrompt from "@c/pool/JoinPoolPrompt";
import PoolDetails from "@c/pool/PoolDetails";
import ScoringView from "@c/pool/ScoringView";
import PoolTeamDetails from "@c/pool/PoolTeamDetails";
import TeamSelection from "@c/players/TeamSelection";

// Commissioner specific paths, lazy load them
const PoolBuilder = lazy(() => import("@c/pool/PoolBuilder"));
const BoxGenerator = lazy(() => import("@c/boxes/BoxGenerator"));
const BoxConfig = lazy(() => import("@c/boxes/BoxConfig"));
const PoolSettingsConfig = lazy(() => import("@c/pool/PoolSettingsConfig"));
const ScoringConfig = lazy(() => import("@c/pool/ScoringConfig"));
const ReportStandings = lazy(() => import("@c/reports/ReportStandings"));
const ReportCategories = lazy(() => import("@c/reports/ReportCategories"));
const ReportTeams = lazy(() => import("@c/reports/ReportTeams"));

// Dev specific pages
const NoticeTestPage = lazy(() => import("@c/dev/NoticeTestPage"));

export function AppRouter() {

  return (
    <Routes>
      <Route path="/login" element={<AuthForm />} />

      <Route element={<RequireAuth />}>
        <Route element={
          <div className="pool-layout">
            <TopBar />
            <main className="pool-layout__main"><Outlet /></main>
          </div>
        }>
          <Route path="/" element={<Dashboard />}/>

          <Route path="/pools/new" element={<CreatePool />} />
        </Route>

        <Route path="/pools/:poolId" element={<PoolLayout />}>
          {import.meta.env.DEV && (
            <Route
              path="/pools/:poolId/dev/notices"
              element={<NoticeTestPage />}
            />
          )}

          <Route path="/pools/:poolId" element={<PoolDetails />} />
          <Route path="/pools/:poolId/invite" element={<JoinPoolPrompt />} />
          <Route path="/pools/:poolId/scoring" element={<ScoringView />} />
          <Route path="/pools/:poolId/teams/:teamId" element={<PoolTeamDetails />} />
          <Route path="/pools/:poolId/teams/:teamId/select" element={<TeamSelection />} />

          <Route
            element={
              <Suspense fallback={<LoadingState />}>
                <Outlet />
              </Suspense>
            }
          >
            <Route path="/pools/:poolId/setup" element={<PoolBuilder />} />

            <Route path="/pools/:poolId/edit" element={<PoolSettingsConfig />} />
            <Route path="/pools/:poolId/boxes/edit" element={<BoxConfig />} />
            <Route path="/pools/:poolId/scoring/edit" element={<ScoringConfig />} />
            <Route path="/pools/:poolId/box_generator" element={<BoxGenerator />} />
            <Route path="/pools/:poolId/reports/standings" element={<ReportStandings />} />
            <Route path="/pools/:poolId/reports/categories" element={<ReportCategories />} />
            <Route path="/pools/:poolId/reports/teams" element={<ReportTeams />} />
            <Route path="/pools/:poolId/reports/teams/:teamId" element={<ReportTeams />} />
          </Route>
        </Route>
      </Route>
    </Routes>
  );
}
