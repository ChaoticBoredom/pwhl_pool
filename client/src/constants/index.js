import { PWHL_DEFAULT_BOXES } from "./boxes";
import { PWHL_ROSTER_TYPE_LABELS } from "./rosterTypes";
import { PWHL_STAT_ICON_MAP } from "./statIcons";
import { PWHL_TEAMS, PWHL_TEAM_CODES } from "./teams";
import { PWHL_POSITION_GROUPS, PWHL_POSITION_STYLES } from "./positions";

export const LEAGUE_CONSTANTS = {
  PWHL: {
    defaultBoxes: PWHL_DEFAULT_BOXES,
    rosterTypeLabels: PWHL_ROSTER_TYPE_LABELS,
    statIconMap: PWHL_STAT_ICON_MAP,
    teams: PWHL_TEAMS,
    teamCodes: PWHL_TEAM_CODES,
    positionGroups: PWHL_POSITION_GROUPS,
    positionStyles: PWHL_POSITION_STYLES,
  },
};

export function getLeagueConstants(leagueShortName) {
  return LEAGUE_CONSTANTS[leagueShortName] ?? LEAGUE_CONSTANTS.PWHL;
}
