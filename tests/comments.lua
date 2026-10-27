package.path = 'src/?.lua;' .. package.path
local values, calls = {}, {}
package.preload.json = function() return {
    encode = function(value) values[#values + 1] = value; return tostring(#values) end,
    decode = function(value) return values[tonumber(value)] end,
} end
package.preload['qcm.mod'] = function() return {null = {}, error = function(value) error(value.code) end} end
local Comments = require('comments')
local response
local client = {perform = function(_, api)
    calls[#calls + 1] = api
    return {data = response}
end}
local function row(id)
    return {commentId = id, user = {userId = 42, nickname = 'Listener', avatarUrl = 'https://example.invalid/a'},
        content = 'text\nline', time = 12345, liked = false, likedCount = 0, status = 0}
end
local target = {native_id = '9007199254740993', item_type = 'Song'}
local function request(order, state) return {order = order or 'Latest', limit = 2, state = state} end
response = {comments = {row('9007199254740993')}, hasMore = true, cursor = '100', totalCount = 0}
local first = Comments.list(client, target, request())
assert(first.comments[1].id == '9007199254740993' and first.comments[1].liked == false)
assert(first.comments[1].like_count == 0 and first.total == 0 and first.has_more)
assert(calls[1]:body().threadId == 'R_SO_4_9007199254740993' and calls[1]:body().cursor == '0')
assert(calls[1].retry_after_auth and calls[1]:crypto() == 'weapi')
response = {comments = {}, hasMore = false}
assert(not Comments.list(client, target, request('Latest', first.next_state)).has_more)
assert(calls[2]:body().pageNo == 2 and calls[2]:body().cursor == '100')
assert(not pcall(Comments.list, client, target, request('Hot', first.next_state)))
assert(not pcall(Comments.list, client, {native_id = '2', item_type = 'Album'}, request('Latest', first.next_state)))
response = {comments = {row(1)}, hasMore = true, cursor = 'normalHot#2'}
local hot = Comments.list(client, target, request('Hot'))
response.cursor = 'normalHot#4'
Comments.list(client, target, request('Hot', hot.next_state))
assert(calls[#calls]:body().cursor == 'normalHot#2')
response = {comments = {row(2)}, hasMore = true, time = 100}
local replies = Comments.list(client, target, request(), '7')
assert(calls[#calls]:path() == '/resource/comment/floor/get' and calls[#calls]:body().time == '-1')
response = {comments = {}, hasMore = false}
Comments.list(client, target, request('Latest', replies.next_state), '7')
assert(calls[#calls]:body().time == '100')
assert(not pcall(Comments.list, client, target, request('Latest', replies.next_state), '8'))
local quoted = row(3)
quoted.user = nil
quoted.liked = nil
quoted.beReplied = {{beRepliedCommentId = '4', status = -5}}
quoted.showFloorComment = {replyCount = 1, comments = {row(5)}}
response = {comments = {quoted}, hasMore = false}
local parsed = Comments.list(client, target, request()).comments[1]
assert(parsed.author.name == '' and parsed.liked == nil and parsed.quote.deleted)
assert(parsed.quote.id == '4' and #parsed.previews == 1)
response = {comments = {}, hasMore = true, cursor = '1'}
assert(not pcall(Comments.list, client, target, request()))
local before = #calls
assert(Comments.list(client, {native_id = 'recommend/daily', item_type = 'Mix'}, request()) == nil)
assert(Comments.list(client, {native_id = '1', item_type = 'Radio'}, request()) == nil)
assert(#calls == before)
for kind, prefix in pairs{Album = 'R_AL_3_', Mix = 'A_PL_0_'} do
    response = {comments = {}, hasMore = false}
    Comments.list(client, {native_id = '1', item_type = kind}, request())
    assert(calls[#calls]:body().threadId == prefix .. '1')
end
for _, liked in ipairs{true, false} do
    assert(Comments.like(client, target, '9007199254740993', liked).liked == liked)
    local api = calls[#calls]
    assert(api:path() == '/v1/comment/' .. (liked and 'like' or 'unlike'))
    assert(api:body().commentId == '9007199254740993' and not api.retry_after_auth)
end
assert(not pcall(Comments.like, {perform = function() error('write timeout') end}, target, '1', true))
print('comments: parsing, continuations, targets and explicit reactions passed')
