import { lazy, Suspense } from "react";
import { Routes, Route, Navigate, Outlet } from "react-router-dom";
import { RequireAuth } from "@c/auth/RequireAuth";
import { Dashboard } from "@c/pool/Dashboard";
import PoolLayout from "@c/nav/PoolLayout"
import TopBar from "@c/nav/TopBar";

import CreatePool from "@c/pool/CreatePool";

import AuthForm from "@c/auth/AuthForm";
import JoinPoolPrompt from "@c/pool/JoinPoolPrompt";
import PoolDetails from "@c/pool/PoolDetails";
import PoolScoring from "@c/pool/PoolScoring";
import PoolTeamDetails from "@c/pool/PoolTeamDetails";
import PlayerSelection from "@c/players/PlayerSelection";

// Commissioner specific paths, lazy load them
const BoxSetup = lazy(() => import("@c/boxes/BoxSetup"));
const BoxGenerator = lazy(() => import("@c/boxes/BoxGenerator"));
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
          <Route path="/pools/:poolId/invite" element={<JoinPoolPrompt />} />
        </Route>

        <Route path="/pools/:poolId" element={<PoolLayout />}>
          {import.meta.env.DEV && (
            <Route
              path="/pools/:poolId/dev/notices"
              element={<NoticeTestPage />}
            />
          )}

          <Route path="/pools/:poolId" element={<PoolDetails />} />
          <Route path="/pools/:poolId/scoring" element={<PoolScoring />} />
          <Route path="/pools/:poolId/teams/:teamId" element={<PoolTeamDetails />} />
          <Route path="/pools/:poolId/teams/:teamId/select" element={<PlayerSelection />} />

          <Route
            element={
              <Suspense fallback={<div className="report-loading">Loading...</div>}>
                <Outlet />
              </Suspense>
            }
          >
            <Route path="/pools/:poolId/boxes/setup" element={<BoxSetup />} />
            <Route path="/pools/:poolId/scoring/setup" element={<PoolScoring setupMode />} />

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
