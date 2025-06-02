local M = {}

local qcm = require("qcm.mod")

M.encode = qcm.json.encode;
M.decode = qcm.json.decode;

return M
