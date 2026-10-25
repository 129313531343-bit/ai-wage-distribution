# Owner-manager-heavy units, excluded in one sensitivity run because EEH (the earnings source)
# excludes owner-managers while EQ08 counts everyone employed.
# DRAFT, awaiting Luc's approval (decision D9). ABS Working Arrangements, Aug 2025, Table 4 gives
# form of employment only by occupation major group: Managers and Technicians and Trades Workers
# have the largest shares of independent contractors and other business operators. Within those
# groups, and for drivers, the draft lists units whose work is commonly done as an owner-operator.

owner_manager_draft <- c(
  "1211", "1212", "1213", "1214",   # Farmers and farm managers
  "1411", "1413", "1421",           # Cafe and restaurant, hotel and motel, retail managers
  "3312", "3322", "3341", "3411",   # Carpenters and joiners, painters, plumbers, electricians
  "3911",                           # Hairdressers
  "7311"                            # Automobile drivers
)
