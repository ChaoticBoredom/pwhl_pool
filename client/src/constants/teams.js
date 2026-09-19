export const PWHL_TEAMS = {
  'BOS': { name: 'Boston Fleet', bg: '#173F35', text: '#B5E3D8' },
  'DET': { name: 'PWHL Detroit', bg: '#C0C0C0', text: '#1A1A1A' },
  'HAM': { name: 'PWHL Hamilton', bg: '#B8860B', text: '#4A1620' },
  'LV':  { name: 'PWHL Las Vegas', bg: '#4B5320', text: '#D4AF37' },
  'MIN': { name: 'Minnesota Frost', bg: '#250E62', text: '#A77BCA' },
  'MTL': { name: 'Montréal Victoire', bg: '#862633', text: '#E4D5C4' },
  'NY':  { name: 'New York Sirens', bg: '#00BFB3', text: '#041E42' },
  'OTT': { name: 'Ottawa Charge', bg: '#A6192E', text: '#FFB81C' },
  'TOR': { name: 'Toronto Sceptres', bg: '#0067B9', text: '#FFD100' },
  'SEA': { name: 'Seattle Torrent', bg: '#1B7A85', text: '#E1DBC9' },
  'SJ':  { name: 'PWHL San Jose', bg: '#F58426', text: '#0C2340' },
  'VAN': { name: 'Vancouver Goldeneyes', bg: '#0F4777', text: '#EEE9D8' },
  'default': { name: 'Unknown Team', bg: '#444', text: '#ccc' },
}

export const PWHL_TEAM_CODES = Object.keys(PWHL_TEAMS).filter((c) => c !== "default");
