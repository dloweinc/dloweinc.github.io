-- Drop your generated boss->item mapping directly in this file.
-- Supported shapes:
-- 1) Nested by instance and difficulty:
-- TBC_BOSS_ITEM_MAP = {
--   ["The Blood Furnace"] = {
--      Normal = { zone = "Hellfire Citadel", bosses = { ["The Maker"] = { 24384, 24385 } } },
--      Heroic = { zone = "Hellfire Citadel", bosses = { ["The Maker"] = { 27447 } } },
--   }
-- }
-- 2) Direct instance object with bosses:
-- TBC_BOSS_ITEM_MAP = {
--   ["Karazhan"] = { zone = "Deadwind Pass", difficulty = "Raid", bosses = { ["Prince Malchezaar"] = {28770,28773} } }
-- }
-- 3) Flat list of entries with explicit fields:
-- TBC_BOSS_ITEM_MAP = {
--   { instance = "The Blood Furnace", zone = "Hellfire Citadel", difficulty = "Normal", bosses = { ["The Maker"] = {24384} } }
-- }

TBC_BOSS_ITEM_MAP = TBC_BOSS_ITEM_MAP or nil
