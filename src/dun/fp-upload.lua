local M = {}
M.__index = M

function M.new()
    local self = setmetatable({}, M)
    return self
end

function M:path()
    return 'https://fp-upload.dun.163.com/v2/js/d'
end

function M:operation()
    return "POST"
end

function M:query()
    return {}
end

--[[
{"p":"9d0ef7e0905d422cba1ecf7e73d37e67","v":"2.0.1","vk":"d44393ca","n":"478d8ab31bd55798a04a996128929825","d":"Fd2Unn1y6MzuVsNYYL2w.KDjsDeNVOMD2izAqVlyM28q+AYpts+/+JP/tNXg+6zvtTQiBCO.ltTJ8d6e/pDBVJAIsI6ugOskTYhLx5XMwbgJ3T.jn3yCxdYJn5jMN1VYhVKAQlWHBpJDRiKfZITRSMftoX.EiOd4CnAPuGX5ioqBFg5VTvA/udutC54tv1KFfiAOSNTa2RRu+0H65cDoQ3r6QyzkXH0aX1BMar1880fXvkNL2i120Fr5dRCafc1ulzHGXR23IjTK855YpVssp2fyONgzjJWad448DN9y6/fLAHrA5iVPsJZwHyNtHWFhPjnGcSprGXxcKkeCvqVBj5+PeBAaIa6UYdRYnOAcdaXoH4NBJuwZibEukusZMZzdRC1DkdLkp/LCLT8Lg89ayTgl064kbjrmUVGb0pcRjOhc5V/4fYJwujaUS+Qd+YuAQdxFt9gAJXxatg5Iw0xKf9otw4XxQuujbdeWp4BMsuzuFS5erJEFHFEfmQkgTxIX5kcectwlDgzk8ZonRB5niKtJbvKIy00KaAuEg0YGrpQYGAjgvs3tIrn+0Z3NiXaD3AbzAGhJO8rg5LiXON9Q3Rcgg3ajr4soGyLo6zW1z3Xr4ADjv6812z/zixJp3V3Cyj0HgDPutMXHTMB+MGbp6.DTwEdhNEx4iaa.BBpAsBuBAfpKlcssVZawOWgkWYVT4xvWzl5hDLl1+4joPpUzevM1B1qJHmtvXTUcbMO4sOQi/Me1CvostMw22XGdHbKLjVDSovlwLZK3XPUdc4unQGVoUxz6TaLSZI/dqUR49NjO8oWEc+3HXk9/iSE4ozl39DPWUyhtvSbyiklkf9pl2uZTGk5vM28L21P+Q/mIpa8fznF.js5bgSlZIoUTFZQphFZBfVhhM.ArV09T/A5oPr1G46zH58YY/J2sNuTT/6qlUntY8D2hsxC/jnvt0QF8syM8tI.E.jAclsW6CemvXz5ZmNjEz+0Me14542gHjFKMbOm/d+E5bFKpSOoXdxilM6B0Y6pOkzPxdEHEV0+85/vbUHYufUO6vc1q.i2OInBttpFawDx9y2jhsICCaqNkEMOPtIZC5GBPpBCtkOkAZ4Av1Eu+QXMZQ//Jf0.KY.Ld1zJsX+Xzajb4gKdM3//oRJ+SN/DztDXOjfdZWp2Wql+j9NmsgsD8SkNFgGjssPAwVxDC5BY/in0GXxOJOFkksFHiYtXUa6bMXWhErWTNBijz.bwCrCQDAyHU1ffwoFLhocm9/W6.wnKtfsyVFE9LyKNUdcHx.yzaHCLwbp4Bk2cmM5xzptg1CMmZ/vYOrz96IEQ1yAJC0KkCv3ei35PYfNGtS3N0e6wEWHMhPwUj+dLEX3Lo4zL35yIXHu8l.9gDJht.e1lnwxE6WBOYe.Wg+MkeITohwPqlq/6vDkz9NH3/qtC5cVVvqn3CN2Rw86.dVrwYkboqJY5H35mfiEeFYx4S/OHqK0yLwtvjCFEeSzFx5m9Hrw5HVg5I4WiQZdlI.ifHWUn3lSYIbfRGdRjH2pY30nnyUpwASPo0jQ4nX48JXmoaYghCacDjOBVGeOOeGJPnLELbGD5p33XM4CiOihImfAxX6F4a9WqKMN85Obf51qHLE6ANwyrrCOLXpvIJgADjmBYfrSF86hn13I93m4mzMMPzmjk1XQawjKbpHEZVoDXrnizutNBpbG/SldrmuSlRH/6KqYzgw1kDF.pU4hbO/XI.t9iTHgWzLoXvUPWDILTwzf9sf3Y0yvdy6OP5LLrNPfF0+.IhEdRa2g+mSW03rGushXuu2tJpph.nRndkLmy36foPmUN5GO+QDgmvLj31l6KlAx8GVjFetS.83IRjGoTp4nyK42bttxr46fsvHnLbE0zfv/Sfzp0Pp2EI.av9KNNif0Mv8TFqrPviOVWKeccrR9r9qs2OaNYdlxy+hbPp3ALvGIiuQg+qlg5mF/t.t0WzHcb1lKSxvZERLZ1rzJOhvZdFkGg85DhUwHoRqoeGfKxK4Tk6dgKXNAI/GE.jtxZcwxGO.a/33YTbR5T60Oxsg56guqh8dPKncluWUWg.JX11U5ulEj2K.by1I.hDNhhhR0LD0eGzQ4DVpYAEKfSULz6/Eu4DYPP/3ztMHExIMzZZXlMSIBwGat9x8/ySVJYaH8OouOfIiiIH4/ceKpjE.K8OrqBPsVl9oCJYHfSFyomdNYPMfeKokIbU0sCY"}
]]
function M:body()
    return {}
end

--[[
{"code":200,"data":{"dt":"mHWidKiRK9pBB1VAVUKSKGFSOQpeWYun","st":1744853742270,"tid":"AS2W0u5kS9dBVhUEQQbDaGRGLVobSYvj"},"msg":"ok"}
]]

function M:parse_response(response)
    local data = response:json()
    return data
end

return M
