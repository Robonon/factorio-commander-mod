if not storage.selected then
  storage.selected = {}
end

if not storage.HQ then
  storage.HQ = {}
end

if not storage.HQ_counts then
  storage.HQ_counts = {
    [HQ_TYPES.BRIGADE] = 0,
    [HQ_TYPES.BATTALION] = 0,
    [HQ_TYPES.COMPANY] = 0,
    [HQ_TYPES.PLATOON] = 0,
  }
end