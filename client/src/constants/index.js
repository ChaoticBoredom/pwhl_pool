import { PWHL_ROSTER_TYPE_LABELS } from "./rosterTypes";
import { PWHL_STAT_ICON_MAP } from "./statIcons";

export const LEAGUE_CONSTANTS = {
  PWHL: {
    rosterTypeLabels: PWHL_ROSTER_TYPE_LABELS,
    statIconMap: PWHL_STAT_ICON_MAP,
  },
};

export function getLeagueConstants(leagueShortName) {
  return LEAGUE_CONSTANTS[leagueShortName] ?? LEAGUE_CONSTANTS.PWHL;
}
