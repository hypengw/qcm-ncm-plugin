local qcm = require('qcm.mod')
local json = require('json')
local Api = require('api.comments')
local M = {}
local prefixes = {Song = 'R_SO_4_', Album = 'R_AL_3_', Mix = 'A_PL_0_'}

local function id(value)
    if math.type(value) == 'integer' then value = tostring(value) end
    if type(value) ~= 'string' or not value:match('^%d+$') or not value:match('[1-9]') then return nil end
    return value
end
local function object(value) return type(value) == 'table' and value or {} end
local function number(value)
    return math.type(value) == 'integer' and value >= 0 and value or nil
end
local function target(value)
    local prefix = prefixes[value.item_type]
    local native_id = id(value.native_id)
    return prefix and native_id and prefix .. native_id or nil
end
local function author(value)
    value = object(value)
    local avatar = value.avatarUrl
    if type(avatar) ~= 'string' or not avatar:match('^https?://[^/]+') then avatar = nil end
    return {id = id(value.userId) or '', name = type(value.nickname) == 'string' and value.nickname or '', avatar_url = avatar}
end
local function quote(value)
    value = object(value)
    return {id = id(value.commentId) or id(value.beRepliedCommentId) or '',
        author = author(value.user), content = type(value.content) == 'string' and value.content or '',
        deleted = value.status == -5 or value.content == nil or value.content == qcm.null}
end
local function comment(value, depth)
    assert(type(value) == 'table' and id(value.commentId), 'invalid comment identity')
    local floor = object(value.showFloorComment)
    local out = {id = id(value.commentId), author = author(value.user),
        content = type(value.content) == 'string' and value.content or '',
        time_ms = number(value.time),
        like_count = number(value.likedCount), reply_count = number(floor.replyCount) or number(value.replyCount),
        deleted = value.status == -5, previews = {}}
    if type(value.liked) == 'boolean' then out.liked = value.liked end
    if type(value.beReplied) == 'table' and value.beReplied[1] then out.quote = quote(value.beReplied[1]) end
    if depth < 1 then
        for i, row in ipairs(object(floor.comments)) do
            if i > 3 then break end
            out.previews[#out.previews + 1] = comment(row, depth + 1)
        end
    end
    return out
end
local function state(request, thread, parent)
    if not request.state then return {page = 1, cursor = parent and '-1' or '0'} end
    local value = json.decode(request.state)
    assert(type(value) == 'table' and value.thread == thread and value.parent == parent
        and value.order == request.order and value.limit == request.limit
        and math.type(value.page) == 'integer' and value.page > 1
        and type(value.cursor) == 'string', 'invalid comment continuation')
    return value
end
local function page(data, request, previous, thread, parent)
    assert(type(data) == 'table' and type(data.comments) == 'table'
        and type(data.hasMore) == 'boolean', 'invalid comments response')
    local rows = {}
    for _, row in ipairs(data.comments) do rows[#rows + 1] = comment(row, 0) end
    local more = data.hasMore
    local cursor = parent and data.time or data.cursor
    if math.type(cursor) == 'integer' then cursor = tostring(cursor) end
    if more then
        assert(type(cursor) == 'string' and cursor ~= '' and cursor ~= previous.cursor,
            'comment continuation did not advance')
        assert(#rows > 0, 'empty comment continuation')
    end
    local next_state
    if more then
        next_state = json.encode {thread = thread, parent = parent, page = previous.page + 1,
            cursor = cursor, order = request.order, limit = request.limit}
    end
    return {comments = rows, order = request.order, orders = {'Hot', 'Latest'},
        total = number(data.totalCount), has_more = more, next_state = next_state,
        can_reply = true, can_like = true}
end

function M.list(client, value, request, parent)
    local thread = target(value)
    if not thread then return nil end
    assert(request.order == 'Hot' or request.order == 'Latest', 'unsupported comment order')
    assert(math.type(request.limit) == 'integer' and request.limit >= 1 and request.limit <= 50,
        'invalid comment limit')
    if parent then assert(id(parent), 'invalid parent comment') end
    local previous = state(request, thread, parent)
    local api
    if parent then
        api = Api.new('/resource/comment/floor/get', {threadId = thread, parentCommentId = parent,
            time = previous.cursor, limit = request.limit}, true)
    else
        local cursor = request.order == 'Hot' and ('normalHot#' .. ((previous.page - 1) * request.limit))
            or previous.cursor
        api = Api.new('/v2/resource/comments', {threadId = thread, pageNo = previous.page,
            pageSize = request.limit, showInner = true, sortType = request.order == 'Hot' and 2 or 3,
            cursor = cursor}, true)
    end
    return page(client:perform(api, 30).data, request, previous, thread, parent)
end

function M.like(client, value, comment_id, liked)
    local thread = target(value)
    if not thread then qcm.error {code = 'not_implemented'} end
    assert(id(comment_id) and type(liked) == 'boolean', 'invalid comment reaction')
    client:perform(Api.new('/v1/comment/' .. (liked and 'like' or 'unlike'),
        {threadId = thread, commentId = comment_id}, false), 30)
    return {liked = liked}
end

return M
