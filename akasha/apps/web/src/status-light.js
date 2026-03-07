// @flow
export function colorForState(state) {
  if (state === 'green') return '#25a85a';
  if (state === 'yellow') return '#f0b429';
  if (state === 'red') return '#d64545';
  return '#6b7280';
}
