export function groupTradeRequests(requests, boxes = []) {
  const boxNameById = boxes.reduce((acc, b) => {
    acc[b.id] = b.name;
    return acc;
  }, {});

  const byGroup = requests.reduce((acc, r) => {
    if (!acc[r.request_group_id]) {
      acc[r.request_group_id] = {
        groupId: r.request_group_id,
        requestedAt: r.requested_at,
        decidedAt: r.decided_at,
        status: r.status,
        teamName: r.pool_team?.team_name,
        ownerName: r.pool_team?.owner_name,
        byBox: {},
      };
    }

    const boxId = r.pool_box.id;
    if (!acc[r.request_group_id].byBox[boxId]) {
      acc[r.request_group_id].byBox[boxId] = {
        poolBoxId: boxId,
        boxName: boxNameById[boxId] ?? null,
        position: r.pool_box.position,
      };
    }
    acc[r.request_group_id].byBox[boxId][r.action] = r;

    return acc;
  }, {});

  return Object.values(byGroup)
    .map((g) => ({
      ...g,
      pairs: Object.values(g.byBox)
        .sort((a, b) => a.position - b.position)
        .map((pair) => ({
          ...pair,
          maxBackdate: pair.add?.max_backdate ?? pair.drop?.max_backdate ?? null,
        })),
    }))
    .sort((a, b) => {
      const aTime = new Date(a.decidedAt ?? a.requestedAt);
      const bTime = new Date(b.decidedAt ?? b.requestedAt);
      return bTime - aTime;
    });
}
