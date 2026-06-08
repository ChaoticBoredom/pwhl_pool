export const PWHL_TEAMS = {
  'BOS': { name: 'Boston Fleet', bg: '#173F35', text: '#B5E3D8' },
  'MIN': { name: 'Minnesota Frost', bg: '#250E62', text: '#A77BCA' },
  'MTL': { name: 'Montréal Victoire', bg: '#862633', text: '#E4D5C4' },
  'NY':  { name: 'New York Sirens', bg: '#00BFB3', text: '#041E42' },
  'OTT': { name: 'Ottawa Charge', bg: '#A6192E', text: '#FFB81C' },
  'TOR': { name: 'Toronto Sceptres', bg: '#0067B9', text: '#FFD100' },
  'SEA': { name: 'Seattle Torrent', bg: '#0C5256', text: '#E1DBC9' },
  'VAN': { name: 'Vancouver Goldeneyes', bg: '#0F4777', text: '#EEE9D8' },
  'default': { name: 'Unknown Team', bg: '#444', text: '#ccc' },
}

export const PWHL_TEAM_CODES = Object.keys(PWHL_TEAMS).filter((c) => c !== "default");
